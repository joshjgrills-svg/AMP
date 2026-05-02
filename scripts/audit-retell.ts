import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(__dirname, '../.env.local') });

async function main() {
  // Dynamic import after dotenv has loaded
  const { retellClient } = await import('../lib/retell');

  console.log('=== Retell Phone Numbers ===');
  const numbers = await retellClient.phoneNumber.list();
  if (numbers.length === 0) {
    console.log('(none)');
  }
  for (const n of numbers) {
    console.log(JSON.stringify(n, null, 2));
  }

  console.log('\n=== Retell Agents ===');
  const agents = await retellClient.agent.list();
  for (const a of agents) {
    console.log(`${a.agent_id}  ${a.agent_name ?? '(no name)'}`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
