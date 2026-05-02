import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(__dirname, '../.env.local') });

async function main() {
  const { supabaseAdmin } = await import('../lib/supabase');

  const { data, error } = await supabaseAdmin
    .from('amp_templates')
    .select('type, name, greeting, system_prompt');

  if (error) {
    console.error('Error:', error);
    return;
  }

  console.log('Templates in amp_templates: ' + (data?.length ?? 0));
  for (const t of data ?? []) {
    console.log('---');
    console.log('type:    ' + t.type);
    console.log('name:    ' + t.name);
    console.log('greeting:    ' + (t.greeting ?? '').slice(0, 100) + '...');
    console.log('prompt:  ' + (t.system_prompt ?? '').slice(0, 200) + '...');
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
