import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(__dirname, '../.env.local') });

async function main() {
  const { registerPhoneNumber, retellClient } = await import('../lib/retell');

  const phoneNumber = process.env.TWILIO_PHONE_NUMBER!;
  const agentId = process.env.AMP_PLUMBER_AGENT_ID!;
  const terminationUri = 'claireai.pstn.twilio.com';

  if (!phoneNumber || !agentId) {
    throw new Error('Missing TWILIO_PHONE_NUMBER or AMP_PLUMBER_AGENT_ID in .env.local');
  }

  console.log('Registering phone number with Retell:');
  console.log('  phoneNumber:    ' + phoneNumber);
  console.log('  terminationUri: ' + terminationUri);
  console.log('  agentId:        ' + agentId);
  console.log('');

  // Pre-flight: is this number already imported in Retell?
  const existing = await retellClient.phoneNumber.list();
  const match = existing.find((n: any) => n.phone_number === phoneNumber);
  if (match) {
    console.log('Already imported. Current binding:');
    console.log(JSON.stringify(match, null, 2));
    console.log('\nSkipping import. If you need to rebind to a different agent, delete first.');
    return;
  }

  const result = await registerPhoneNumber({
    phoneNumber,
    terminationUri,
    agentId,
    nickname: 'AMP Production - Plumber',
  });

  console.log('Imported:');
  console.log(JSON.stringify(result, null, 2));
}

main().catch((e) => {
  console.error('FAILED');
  console.error(e);
  process.exit(1);
});
