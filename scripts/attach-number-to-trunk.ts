import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(__dirname, '../.env.local') });

async function main() {
  const twilio = (await import('twilio')).default;
  const client = twilio(
    process.env.TWILIO_ACCOUNT_SID!,
    process.env.TWILIO_AUTH_TOKEN!,
  );

  const trunkSid = 'TK1be0c12fb9bfc4f7054fbde6b15885f2';
  const phoneNumber = process.env.TWILIO_PHONE_NUMBER!;

  // Find the IncomingPhoneNumber SID for +12494448711
  const numbers = await client.incomingPhoneNumbers.list({
    phoneNumber,
    limit: 1,
  });

  if (numbers.length === 0) {
    throw new Error('Phone number ' + phoneNumber + ' not found in this account');
  }

  const numberSid = numbers[0].sid;
  console.log('Found number SID:', numberSid);

  // Attach to trunk
  const result = await client.trunking.v1.trunks(trunkSid).phoneNumbers.create({
    phoneNumberSid: numberSid,
  });

  console.log('\nAttached to trunk:');
  console.log({
    phoneNumber: result.phoneNumber,
    sid: result.sid,
    trunkSid: result.trunkSid,
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
