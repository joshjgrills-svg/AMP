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

  console.log('=== Trunk ===');
  const trunk = await client.trunking.v1.trunks(trunkSid).fetch();
  console.log({
    friendlyName: trunk.friendlyName,
    domainName: trunk.domainName,
    secure: trunk.secure,
    cnamLookupEnabled: trunk.cnamLookupEnabled,
    transferMode: trunk.transferMode,
  });

  console.log('\n=== Phone Numbers attached to trunk ===');
  const numbers = await client.trunking.v1.trunks(trunkSid).phoneNumbers.list();
  if (numbers.length === 0) console.log('(none)');
  for (const n of numbers) {
    console.log(n.phoneNumber + '  ' + (n.friendlyName ?? ''));
  }

  console.log('\n=== Origination URIs (where inbound calls go) ===');
  const origUris = await client.trunking.v1.trunks(trunkSid).originationUrls.list();
  if (origUris.length === 0) console.log('(none - inbound calls go nowhere)');
  for (const u of origUris) {
    console.log({
      sipUrl: u.sipUrl,
      enabled: u.enabled,
      priority: u.priority,
      weight: u.weight,
    });
  }

  console.log('\n=== Credential Lists ===');
  const creds = await client.trunking.v1.trunks(trunkSid).credentialsLists.list();
  if (creds.length === 0) console.log('(none)');
  for (const c of creds) {
    console.log(c.sid + '  ' + c.friendlyName);
  }

  console.log('\n=== IP Access Control Lists ===');
  const ipAcls = await client.trunking.v1.trunks(trunkSid).ipAccessControlLists.list();
  if (ipAcls.length === 0) console.log('(none)');
  for (const a of ipAcls) {
    console.log(a.sid + '  ' + a.friendlyName);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
