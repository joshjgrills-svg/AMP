import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(__dirname, '../.env.local') });

async function main() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;

  const res = await fetch(url + '/rest/v1/', {
    headers: {
      apikey: key,
      Authorization: 'Bearer ' + key,
    },
  });

  if (!res.ok) {
    console.error('OpenAPI fetch failed: ' + res.status + ' ' + res.statusText);
    return;
  }

  const spec = await res.json() as any;
  const tables = ['amp_organizations', 'amp_agents'];

  for (const table of tables) {
    console.log('=== ' + table + ' ===');
    const def = spec.definitions?.[table];
    if (!def) {
      console.log('not found in OpenAPI spec');
      continue;
    }
    const props = def.properties ?? {};
    const required = new Set(def.required ?? []);
    for (const [col, meta] of Object.entries<any>(props)) {
      const req = required.has(col) ? '[REQUIRED]' : '[optional]';
      const type = meta.format ?? meta.type ?? '?';
      const dflt = meta.default !== undefined ? '  default=' + JSON.stringify(meta.default) : '';
      console.log('  ' + col.padEnd(30) + req.padEnd(12) + type + dflt);
    }
    console.log('');
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
