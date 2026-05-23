import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(__dirname, '../.env.local') });

async function main() {
  const { retellClient } = await import('../lib/retell');

  const phoneNumber = process.env.AMP_PHONE_NUMBER!;
  const agentId = process.env.AMP_AGENT_DEFAULT_V1!;

  console.log('Binding ' + phoneNumber + ' to agent ' + agentId + '...');

  const result = await retellClient.phoneNumber.update(phoneNumber, {
    inbound_agent_id: agentId,
    outbound_agent_id: agentId,
    nickname: 'AMP Production - Plumbing',
  });

  console.log('Updated:');
  console.log(JSON.stringify(result, null, 2));
}

main().catch((e) => {
  console.error('FAILED');
  console.error(e);
  process.exit(1);
});
