import { verify as verifyRetellSignature } from 'retell-sdk';
import { supabaseAdmin } from '@/lib/supabase';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

type RetellEvent = 'call_started' | 'call_ended' | 'call_analyzed';

type RetellSentiment = 'Positive' | 'Negative' | 'Neutral' | 'Unknown';

type DisconnectionReason =
  | 'user_hangup'
  | 'agent_hangup'
  | 'call_transfer'
  | 'voicemail_reached'
  | 'ivr_reached'
  | 'inactivity'
  | 'max_duration_reached'
  | 'concurrency_limit_reached'
  | 'no_valid_payment'
  | 'scam_detected'
  | 'dial_busy'
  | 'dial_failed'
  | 'dial_no_answer'
  | 'invalid_destination'
  | 'telephony_provider_permission_denied'
  | 'telephony_provider_unavailable'
  | 'sip_routing_error'
  | 'marked_as_spam'
  | 'user_declined'
  | 'transfer_bridged'
  | 'transfer_cancelled'
  | 'manual_stopped'
  | (string & {});

interface RetellCallPayload {
  call_id: string;
  agent_id: string;
  call_status?: 'registered' | 'not_connected' | 'ongoing' | 'ended' | 'error';
  direction?: 'inbound' | 'outbound';
  from_number?: string;
  to_number?: string;
  start_timestamp?: number;
  end_timestamp?: number;
  duration_ms?: number;
  transcript?: string;
  transcript_object?: unknown;
  transcript_with_tool_calls?: unknown;
  recording_url?: string;
  disconnection_reason?: DisconnectionReason;
  call_analysis?: {
    call_summary?: string;
    user_sentiment?: RetellSentiment;
    call_successful?: boolean;
    in_voicemail?: boolean;
    custom_analysis_data?: unknown;
  };
}

interface RetellWebhookBody {
  event: RetellEvent;
  call: RetellCallPayload;
}

function mapSentiment(s?: RetellSentiment): 'positive' | 'neutral' | 'negative' | null {
  if (s === 'Positive') return 'positive';
  if (s === 'Negative') return 'negative';
  if (s === 'Neutral') return 'neutral';
  return null;
}

function mapEndedStatus(reason?: DisconnectionReason): 'completed' | 'voicemail' | 'failed' {
  if (reason === 'voicemail_reached') return 'voicemail';
  if (
    reason === 'dial_busy' ||
    reason === 'dial_failed' ||
    reason === 'dial_no_answer' ||
    reason === 'invalid_destination' ||
    reason === 'telephony_provider_permission_denied' ||
    reason === 'telephony_provider_unavailable' ||
    reason === 'sip_routing_error' ||
    (typeof reason === 'string' && reason.startsWith('error_'))
  ) {
    return 'failed';
  }
  return 'completed';
}

function mapOutcome(call: RetellCallPayload):
  | 'voicemail'
  | 'transferred'
  | 'spam'
  | 'hangup'
  | 'unresolved'
  | null {
  if (call.call_analysis?.in_voicemail) return 'voicemail';
  switch (call.disconnection_reason) {
    case 'voicemail_reached':
      return 'voicemail';
    case 'call_transfer':
    case 'transfer_bridged':
      return 'transferred';
    case 'transfer_cancelled':
      return 'unresolved';
    case 'marked_as_spam':
    case 'scam_detected':
      return 'spam';
    case 'user_hangup':
    case 'agent_hangup':
      return 'hangup';
    case 'dial_busy':
    case 'dial_failed':
    case 'dial_no_answer':
    case 'invalid_destination':
    case 'inactivity':
    case 'max_duration_reached':
      return 'unresolved';
  }
  return null;
}

function buildTranscriptJson(call: RetellCallPayload) {
  if (!call.transcript && !call.transcript_object) return null;
  return {
    text: call.transcript ?? null,
    object: call.transcript_object ?? null,
    with_tool_calls: call.transcript_with_tool_calls ?? null,
  };
}

export async function POST(request: Request) {
  const rawBody = await request.text();

  // Verify signature. Retell signs with the workspace API key.
  const signature = request.headers.get('x-retell-signature');
  const apiKey = process.env.RETELL_API_KEY;
  if (apiKey && signature) {
    const ok = await verifyRetellSignature(rawBody, apiKey, signature);
    if (!ok) {
      return Response.json({ error: 'invalid signature' }, { status: 401 });
    }
  } else if (apiKey && !signature) {
    return Response.json({ error: 'missing signature' }, { status: 401 });
  }

  let payload: RetellWebhookBody;
  try {
    payload = JSON.parse(rawBody) as RetellWebhookBody;
  } catch {
    return Response.json({ error: 'invalid json' }, { status: 400 });
  }

  const { event, call } = payload;
  if (!event || !call?.call_id) {
    return Response.json({ error: 'missing event or call_id' }, { status: 400 });
  }

  // Resolve AMP agent + organization from the Retell agent id. We need this
  // both to attribute new call rows and to enforce that we only ingest calls
  // for agents we actually own.
  const { data: agent, error: agentLookupError } = await supabaseAdmin
    .from('amp_agents')
    .select('id, organization_id')
    .eq('retell_agent_id', call.agent_id)
    .maybeSingle();

  if (agentLookupError) {
    console.error('[retell webhook] agent lookup failed', agentLookupError);
    return Response.json({ error: 'agent lookup failed' }, { status: 500 });
  }
  if (!agent) {
    // Unknown agent — ack with 200 so Retell stops retrying, but log it.
    console.warn('[retell webhook] no AMP agent for retell_agent_id', call.agent_id);
    return Response.json({ ok: true, ignored: 'unknown_agent' });
  }

  // Look up existing call row by retell_call_id.
  const { data: existing, error: callLookupError } = await supabaseAdmin
    .from('amp_calls')
    .select('id')
    .eq('retell_call_id', call.call_id)
    .maybeSingle();

  if (callLookupError) {
    console.error('[retell webhook] call lookup failed', callLookupError);
    return Response.json({ error: 'call lookup failed' }, { status: 500 });
  }

  // Build the field set for this event.
  const startedAt = call.start_timestamp ? new Date(call.start_timestamp).toISOString() : null;
  const endedAt = call.end_timestamp ? new Date(call.end_timestamp).toISOString() : null;
  const durationSeconds =
    typeof call.duration_ms === 'number' ? Math.round(call.duration_ms / 1000) : null;

  const baseFields: Record<string, unknown> = {
    organization_id: agent.organization_id,
    agent_id: agent.id,
    retell_call_id: call.call_id,
    direction: call.direction ?? 'inbound',
    caller_phone: call.from_number ?? null,
  };

  let eventFields: Record<string, unknown> = {};
  switch (event) {
    case 'call_started': {
      eventFields = {
        status: 'in_progress',
        started_at: startedAt,
      };
      break;
    }
    case 'call_ended': {
      eventFields = {
        status: mapEndedStatus(call.disconnection_reason),
        started_at: startedAt,
        ended_at: endedAt,
        duration_seconds: durationSeconds,
        transcript: buildTranscriptJson(call),
        recording_url: call.recording_url ?? null,
      };
      break;
    }
    case 'call_analyzed': {
      const sentiment = mapSentiment(call.call_analysis?.user_sentiment);
      eventFields = {
        summary: call.call_analysis?.call_summary ?? null,
        sentiment,
        outcome: mapOutcome(call),
        transcript: buildTranscriptJson(call) ?? undefined,
        recording_url: call.recording_url ?? undefined,
        ended_at: endedAt ?? undefined,
        duration_seconds: durationSeconds ?? undefined,
      };
      // Drop undefined keys so we don't overwrite existing values with null.
      eventFields = Object.fromEntries(
        Object.entries(eventFields).filter(([, v]) => v !== undefined),
      );
      break;
    }
    default: {
      // Unknown event — ack so Retell doesn't retry.
      return Response.json({ ok: true, ignored: 'unknown_event', event });
    }
  }

  if (existing) {
    const { error } = await supabaseAdmin
      .from('amp_calls')
      .update(eventFields)
      .eq('id', existing.id);
    if (error) {
      console.error('[retell webhook] update failed', error);
      return Response.json({ error: 'update failed' }, { status: 500 });
    }
  } else {
    const { error } = await supabaseAdmin
      .from('amp_calls')
      .insert({ ...baseFields, ...eventFields });
    if (error) {
      console.error('[retell webhook] insert failed', error);
      return Response.json({ error: 'insert failed' }, { status: 500 });
    }
  }

  return Response.json({ ok: true });
}
