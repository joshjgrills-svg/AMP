import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(__dirname, '../.env.local') });

async function main() {
  const { retellClient } = await import('../lib/retell');

  console.log('=== All Retell Phone Numbers in this workspace ===');
  const numbers = await retellClient.phoneNumber.list();
  console.log('Total: ' + numbers.length);
  console.log('');

  for (const n of numbers) {
    console.log(JSON.stringify(n, null, 2));
    console.log('---');
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
