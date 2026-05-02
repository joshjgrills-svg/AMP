import Retell from 'retell-sdk';

if (typeof window !== 'undefined') {
  throw new Error('lib/retell.ts must not be imported from the browser');
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}

export const retellClient = new Retell({
  apiKey: requireEnv('RETELL_API_KEY'),
});

type AgentCreateBody = Parameters<typeof retellClient.agent.create>[0];
type LlmCreateBody = Parameters<typeof retellClient.llm.create>[0];

export type RetellLlmModel = NonNullable<LlmCreateBody['model']>;
export type RetellLanguage = NonNullable<AgentCreateBody['language']>;

export interface CreateRetellAgentInput {
  agentName: string;
  generalPrompt: string;
  beginMessage: string;
  voiceId: string;
  model?: RetellLlmModel;
  webhookUrl?: string;
  language?: RetellLanguage;
}

export interface CreateRetellAgentResult {
  agentId: string;
  llmId: string;
}

// Provisions a Retell LLM + Agent pair for one AMP organization.
// Two-step because every Retell agent needs a Response Engine (LLM) to attach to.
export async function createRetellAgent(
  input: CreateRetellAgentInput,
): Promise<CreateRetellAgentResult> {
  const llm = await retellClient.llm.create({
    general_prompt: input.generalPrompt,
    begin_message: input.beginMessage,
    model: input.model ?? 'gpt-4.1',
  });

  const agent = await retellClient.agent.create({
    agent_name: input.agentName,
    voice_id: input.voiceId,
    response_engine: {
      type: 'retell-llm',
      llm_id: llm.llm_id,
    },
    ...(input.webhookUrl ? { webhook_url: input.webhookUrl } : {}),
    ...(input.language ? { language: input.language } : {}),
  });

  return { agentId: agent.agent_id, llmId: llm.llm_id };
}

export interface RegisterPhoneNumberInput {
  phoneNumber: string;        // E.164, e.g. "+14155551234"
  terminationUri: string;     // Twilio elastic SIP trunk, ends in ".pstn.twilio.com"
  agentId: string;
  nickname?: string;
  sipTrunkAuthUsername?: string;
  sipTrunkAuthPassword?: string;
  inboundWebhookUrl?: string;
}

// Imports a Twilio-owned number into Retell and binds it to a single agent
// for inbound calls. Outbound is bound to the same agent so the contractor
// can call back from the same line.
export async function registerPhoneNumber(input: RegisterPhoneNumberInput) {
  return retellClient.phoneNumber.import({
    phone_number: input.phoneNumber,
    termination_uri: input.terminationUri,
    inbound_agents: [{ agent_id: input.agentId, weight: 1 }],
    outbound_agents: [{ agent_id: input.agentId, weight: 1 }],
    ...(input.nickname ? { nickname: input.nickname } : {}),
    ...(input.sipTrunkAuthUsername
      ? { sip_trunk_auth_username: input.sipTrunkAuthUsername }
      : {}),
    ...(input.sipTrunkAuthPassword
      ? { sip_trunk_auth_password: input.sipTrunkAuthPassword }
      : {}),
    ...(input.inboundWebhookUrl
      ? { inbound_webhook_url: input.inboundWebhookUrl }
      : {}),
  });
}

export async function getCall(callId: string) {
  return retellClient.call.retrieve(callId);
}
