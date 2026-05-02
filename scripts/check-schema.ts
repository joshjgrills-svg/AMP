import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(__dirname, '../.env.local') });

async function main() {
  const { supabaseAdmin } = await import('../lib/supabase');

  // Pull one row from each table to see the column shape, even if empty
  const tables = ['amp_organizations', 'amp_agents'];

  for (const table of tables) {
    console.log('=== ' + table + ' ===');
    const { data, error } = await supabaseAdmin.from(table).select('*').limit(1);
    if (error) {
      console.error('Error:', error.message);
      continue;
    }
    if (!data || data.length === 0) {
      console.log('(empty table)');
      // Try inserting nothing to coax the schema out via error
      const probe = await supabaseAdmin.from(table).insert({}).select();
      if (probe.error) {
        console.log('Schema hint from error: ' + probe.error.message);
      }
    } else {
      console.log('Sample row keys: ' + Object.keys(data[0]).join(', '));
      console.log(JSON.stringify(data[0], null, 2));
    }
    console.log('');
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
