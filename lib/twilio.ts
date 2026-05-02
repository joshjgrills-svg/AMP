import twilio, { type Twilio } from 'twilio';

if (typeof window !== 'undefined') {
  throw new Error('lib/twilio.ts must not be imported from the browser');
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}

export const twilioClient: Twilio = twilio(
  requireEnv('TWILIO_ACCOUNT_SID'),
  requireEnv('TWILIO_AUTH_TOKEN'),
);

export interface SendSmsInput {
  to: string;
  body: string;
  from?: string;
  statusCallback?: string;
}

// Sends an SMS via Twilio. `from` defaults to TWILIO_PHONE_NUMBER (the AMP
// outbound sending number used for confirmations and reminders).
// Returns the Twilio message SID for logging/idempotency.
export async function sendSms(input: SendSmsInput): Promise<string> {
  const from = input.from ?? requireEnv('TWILIO_PHONE_NUMBER');
  const to = formatPhoneNumber(input.to);
  const message = await twilioClient.messages.create({
    to,
    from,
    body: input.body,
    ...(input.statusCallback ? { statusCallback: input.statusCallback } : {}),
  });
  return message.sid;
}

// Normalizes a phone number to E.164. Defaults to US/CA if no country code
// is present. Throws if the input cannot be coerced into a plausible E.164.
//
//   "(415) 555-1234"   -> "+14155551234"
//   "415-555-1234"     -> "+14155551234"
//   "1 415 555 1234"   -> "+14155551234"
//   "+44 20 7946 0958" -> "+442079460958"
export function formatPhoneNumber(input: string, defaultCountry: 'US' | 'CA' = 'US'): string {
  if (!input) throw new Error('formatPhoneNumber: empty input');

  const trimmed = input.trim();
  const hasPlus = trimmed.startsWith('+');
  const digits = trimmed.replace(/\D/g, '');

  if (hasPlus) {
    if (digits.length < 8 || digits.length > 15) {
      throw new Error(`formatPhoneNumber: invalid E.164 length for "${input}"`);
    }
    return `+${digits}`;
  }

  // No leading +. Apply NANP defaults for US/CA.
  if (defaultCountry === 'US' || defaultCountry === 'CA') {
    if (digits.length === 10) return `+1${digits}`;
    if (digits.length === 11 && digits.startsWith('1')) return `+${digits}`;
  }

  throw new Error(`formatPhoneNumber: cannot normalize "${input}" to E.164`);
}
