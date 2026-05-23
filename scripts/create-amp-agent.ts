// Provisions the first AMP Retell agent + corresponding Supabase rows.
// Run with: npx tsx scripts/create-amp-agent.ts
import path from 'node:path';
import process from 'node:process';
import dotenv from 'dotenv';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const ORG_NAME = 'AMP Internal Test';
const AGENT_NAME = 'AMP Plumber - Default';
const VOICE_ID = '11labs-Adrian';
const MODEL = 'claude-4.6-sonnet';

function slugify(s: string): string {
  return s.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
}

async function main() {
  const { supabaseAdmin } = await import('../lib/supabase');
  const { createRetellAgent } = await import('../lib/retell');

  // 1. Load the plumbing template
  const { data: template, error: tmplError } = await supabaseAdmin
    .from('agent_templates')
    .select('id, industry, name, greeting, system_prompt')
    .eq('industry', 'plumbing')
    .single();

  if (tmplError) throw new Error('Failed to load plumbing template: ' + tmplError.message);
  if (!template) throw new Error('No plumbing template found in agent_templates');
  console.log('Loaded template: ' + template.name + ' (' + template.industry + ')');

  // 2. Get or create the customer (lookup by name)
  let { data: customer, error: customerFetchError } = await supabaseAdmin
    .from('customers')
    .select('id, name')
    .eq('name', ORG_NAME)
    .maybeSingle();

  if (customerFetchError) throw new Error('Customer lookup failed: ' + customerFetchError.message);

  if (!customer) {
    console.log('Creating customer: ' + ORG_NAME);
    const { data: newCustomer, error: customerCreateError } = await supabaseAdmin
      .from('customers')
      .insert({
        name: ORG_NAME,
        slug: slugify(ORG_NAME),
      })
      .select('id, name')
      .single();

    if (customerCreateError) throw new Error('Customer create failed: ' + customerCreateError.message);
    customer = newCustomer;
    console.log('  customer id: ' + customer!.id);
  } else {
    console.log('Reusing existing customer: ' + customer.name + ' (' + customer.id + ')');
  }

  // 3. Create the Retell agent
  console.log('Creating Retell LLM + agent...');
  const { agentId, llmId } = await createRetellAgent({
    agentName: AGENT_NAME,
    generalPrompt: template.system_prompt,
    beginMessage: template.greeting,
    voiceId: VOICE_ID,
    model: MODEL,
  });
  console.log('  retell agent_id: ' + agentId);
  console.log('  retell llm_id:   ' + llmId);

  // 4. Insert matching agents row so the webhook handler can resolve it
  const { data: agentRow, error: agentInsertError } = await supabaseAdmin
    .from('agents')
    .insert({
      customer_id: customer!.id,
      agent_template_id: template.id,
      name: AGENT_NAME,
      retell_agent_id: agentId,
      retell_llm_id: llmId,
      greeting: template.greeting,
      system_prompt: template.system_prompt,
      status: 'active',
    })
    .select('id')
    .single();

  if (agentInsertError) {
    console.error('FAILED to insert agents row: ' + agentInsertError.message);
    console.error('Retell agent ' + agentId + ' was created but is now orphaned.');
    console.error('Either delete it via the Retell dashboard or re-run after fixing the schema.');
    throw agentInsertError;
  }

  console.log('  agents row id: ' + agentRow.id);

  console.log('');
  console.log('=== Done ===');
  console.log('');
  console.log('Add these to .env.local (replacing any existing values):');
  console.log('  AMP_AGENT_DEFAULT_V1=' + agentId);
  console.log('  AMP_INTERNAL_TEST_ORG_ID=' + customer!.id);
  console.log('  (LLM ID ' + llmId + ' — no env var; AMP_PLUMBER_LLM_ID removed per ADR-008 rename sweep)');
}

main().catch((err) => {
  console.error('create-amp-agent failed:', err);
  process.exit(1);
});
