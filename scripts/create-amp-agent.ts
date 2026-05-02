// Provisions the first AMP Retell agent + corresponding Supabase rows.
// Run with: npx tsx scripts/create-amp-agent.ts
import path from 'node:path';
import process from 'node:process';
import dotenv from 'dotenv';

dotenv.config({ path: path.resolve(process.cwd(), '.env.local') });

const ORG_NAME = 'AMP Internal Test';
const ORG_TYPE = 'plumber';
const AGENT_NAME = 'AMP Plumber - Default';
const VOICE_ID = '11labs-Adrian';
const MODEL = 'claude-4.6-sonnet';

async function main() {
  const { supabaseAdmin } = await import('../lib/supabase');
  const { createRetellAgent } = await import('../lib/retell');

  // 1. Load the plumber template
  const { data: template, error: tmplError } = await supabaseAdmin
    .from('amp_templates')
    .select('id, type, name, greeting, system_prompt')
    .eq('type', 'plumber')
    .single();

  if (tmplError) throw new Error('Failed to load plumber template: ' + tmplError.message);
  if (!template) throw new Error('No plumber template found in amp_templates');
  console.log('Loaded template: ' + template.name + ' (' + template.type + ')');

  // 2. Get or create the org (lookup by name since there is no slug)
  let { data: org, error: orgFetchError } = await supabaseAdmin
    .from('amp_organizations')
    .select('id, name, type')
    .eq('name', ORG_NAME)
    .maybeSingle();

  if (orgFetchError) throw new Error('Org lookup failed: ' + orgFetchError.message);

  if (!org) {
    console.log('Creating org: ' + ORG_NAME);
    const { data: newOrg, error: orgCreateError } = await supabaseAdmin
      .from('amp_organizations')
      .insert({
        name: ORG_NAME,
        type: ORG_TYPE,
      })
      .select('id, name, type')
      .single();

    if (orgCreateError) throw new Error('Org create failed: ' + orgCreateError.message);
    org = newOrg;
    console.log('  org id: ' + org!.id);
  } else {
    console.log('Reusing existing org: ' + org.name + ' (' + org.id + ')');
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

  // 4. Insert matching amp_agents row so the webhook handler can resolve it
  const { data: agentRow, error: agentInsertError } = await supabaseAdmin
    .from('amp_agents')
    .insert({
      organization_id: org!.id,
      template_id: template.id,
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
    console.error('FAILED to insert amp_agents row: ' + agentInsertError.message);
    console.error('Retell agent ' + agentId + ' was created but is now orphaned.');
    console.error('Either delete it via the Retell dashboard or re-run after fixing the schema.');
    throw agentInsertError;
  }

  console.log('  amp_agents row id: ' + agentRow.id);

  console.log('');
  console.log('=== Done ===');
  console.log('');
  console.log('Add these to .env.local (replacing any existing values):');
  console.log('  AMP_PLUMBER_AGENT_ID=' + agentId);
  console.log('  AMP_PLUMBER_LLM_ID=' + llmId);
  console.log('  AMP_INTERNAL_TEST_ORG_ID=' + org!.id);
}

main().catch((err) => {
  console.error('create-amp-agent failed:', err);
  process.exit(1);
});
