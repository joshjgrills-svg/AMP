# AMP — Decisions

This is the append-only Architecture Decision Record (ADR) log for AMP. Every load-bearing decision is recorded here with date, context, alternatives considered, reasoning, and what would change the decision. Decisions are not edited after being recorded — they are superseded by new decisions that reference them.

---

## ADR-001 — Orchestration Model: AMP as the Orchestration Brain

**Date:** 2026-05-12
**Status:** Accepted
**Decided by:** CEO (Josh) with PM/Architect recommendation
**Supersedes:** None
**Superseded by:** None

### Context

AMP is positioned as a multi-agent management platform for professional service businesses. The fundamental architectural question is who owns and runs the underlying agent infrastructure: AMP, or the customer.

### Decision

AMP owns and runs the underlying agent infrastructure. Customers configure their agents through the AMP dashboard but do not interact directly with the underlying services (Retell, ElevenLabs, Twilio, etc.). One signup, one bill, one dashboard, one support contact. The orchestration logic, the shared context layer, and the agent execution all live on AMP-controlled infrastructure.

### Alternatives considered

**Option B: AMP as the orchestration framework.** Customers bring their own infrastructure (their own Retell account, their own ElevenLabs account, etc.) and AMP coordinates them. Rejected because the target customer is a non-technical owner-operator who will not sign up for five separate services. The UX burden alone disqualifies this for our segment, and the defensibility is significantly weaker.

### Reasoning

Three reasons drove this decision:

1. **The target customer's buying behavior demands it.** Owner-operators of $500K-$5M service businesses decide and configure in one session with one credit card. Option B's "sign up for five services and configure each" flow is incompatible with this. We do not get to choose a customer who behaves differently than they do.

2. **Defensibility.** Option A creates a moat through accumulated customer data, agent performance learnings, and platform-wide improvements that compound. Option B is a thin coordination layer customers can route around as the underlying services become more capable. The companies that win this category (Sierra, Decagon, the eventual winner) are all Option A.

3. **Quality control.** Voice agent quality is the product (per North Star). Option A gives us full control over the execution path, the observability, and the iteration loop. Option B introduces variability we cannot manage — a customer's misconfigured Retell account becomes our reputation problem with none of our control.

### Trade-offs accepted

- **Infrastructure risk concentrates on AMP.** A Retell outage becomes an AMP outage from the customer's perspective. We manage this through Constitution Section 3.2 (adapter pattern, multiple providers per category) and Section 6.4 (graceful degradation).
- **Infrastructure costs scale with usage.** Margin pressure increases as customers scale. We manage this through Constitution Section 8 (cost discipline) and through pricing tier design that reflects actual usage costs.
- **We are on the hook for every external service we depend on.** This is the price of the moat. We accept it.

### What would change this decision

We would revisit Option A if:

1. A horizontal platform (OpenAI, Anthropic, Google) ships an agent orchestration product so good and so cheap that our infrastructure ownership becomes a cost burden without a corresponding moat benefit
2. The infrastructure costs of running customer agents exceed 50% of revenue per customer at scale, and we cannot find a path to reduce them
3. A specific customer segment we want to serve (enterprise, technical buyers) genuinely prefers Option B and represents enough revenue to justify a parallel offering

None of these are likely in the next 18 months. The decision stands.

### Implementation implications

This decision drives the following architectural commitments, which will appear in the Technical Constitution v1 and the Runtime Architecture document:

- All agent execution runs on AMP-controlled infrastructure (Vercel, Supabase, plus the adapter layer to Retell/ElevenLabs/Twilio)
- A shared context layer (database + memory) is mandatory — all of a customer's agents read from and write to it
- An orchestration engine decides routing, handoffs, and escalation between agents
- Customer-facing surfaces (dashboard, configuration, billing) treat the underlying services as implementation details, never exposed to the customer
- The adapter pattern (Section 3.2) becomes load-bearing — service replacement must be possible without customer impact

---

## ADR-002 — AMP Owns Its Own Supabase Project; Drop the `amp_` Prefix and the `providers` FK

**Date:** 2026-05-13
**Status:** Accepted
**Decided by:** CEO (Josh) with PM/Architect recommendation
**Supersedes:** None
**Superseded by:** None

### Context

The first project inventory (Session 001, `docs/PROJECT_INVENTORY.md`) surfaced two Claire-era vestiges in the schema:

1. Every AMP-owned table carries an `amp_` prefix (`amp_organizations`, `amp_agents`, `amp_calls`, `amp_appointments`, `amp_alerts`, `amp_templates`, `amp_weekly_reports`). This prefix only makes sense if AMP shares a Postgres instance with ProScore.
2. `amp_organizations.proscore_provider_id` declares a foreign key to a `providers` table that does not exist in this repo. The `providers` table belongs to ProScore.

These artifacts predate the Constitution and predate the multi-agent platform clarification from ADR-001. They were drafted when shared infrastructure between Claire OS, ProScore, and AMP was under active consideration.

### Decision

AMP's database is its own Supabase project (`yxuhjxxbgbuznpoekwpj`), fully separate from ProScore. There are no shared tables, no cross-database foreign keys, and no shared schemas. The `amp_` prefix on every table is dropped. The `providers` foreign key is removed.

The Vercel project `claire-ai-beta.vercel.app` is decommissioned; the canonical AMP URL is `amp-beta-one.vercel.app`.

### Alternatives considered

**Option B: Keep `amp_` prefix and maintain shared infrastructure with ProScore.** Rejected. ProScore and AMP serve different customers, have different security postures (AMP handles call recordings and end-user PII at higher volume), and have different operational tempos. Coupling their databases means a ProScore migration risks taking AMP down and vice versa. The `amp_` prefix would also need to be amended into Constitution Section 1.3, which only makes sense as a co-existence strategy — and we are choosing not to co-exist.

**Option C: Soft-deprecate `amp_` prefix (alias new tables, leave old ones for compatibility).** Rejected. There is no production data to preserve. A destructive rename is cheaper now than aliases compounding over time.

### Reasoning

1. **AMP's success is measured by the other 99% of its customers who have no connection to ProScore** (per North Star). Coupling the two databases at the schema level contradicts that strategic stance.
2. **Constitution Section 1.3 is unambiguous** about the locked terms. The `amp_` prefix violates it. Co-existence amendment was a possible path but only if shared infrastructure was happening. It isn't.
3. **The data currently in `amp_*` tables is throwaway.** No customer is reading from these rows. The cost of a destructive rename is the time to write the migration, not lost customer value.

### Trade-offs accepted

- **The webhook is live and ingesting Retell traffic into `amp_calls`.** A destructive rename means downtime on the ingestion path during the migration window. Mitigation: schedule the cutover during a window with no active testing; land the webhook URL change and the table rename in the same deploy.
- **The Vercel project decommission is operational, not just architectural.** We must verify `claire-ai-beta.vercel.app` is taken offline (or transferred) before the cleanup is complete. Added as a verification step in the cleanup plan (ADR-003).
- **Claire-era external resources persist in third-party accounts.** The Retell agent (`agent_58fbaa9f9eb2e1f6698e54bedd`), the Retell LLM (`llm_2387332d2303961cb4d67d815d9e`), and the Twilio number (`+12494448711`) are kept — they are the active AMP plumber testbed. They will be repointed at the renamed schema, not torn down.

### What would change this decision

We would revisit this decision if:

1. A future product decision genuinely requires AMP and ProScore to share customer records (unlikely — both are independent businesses).
2. Operating two Supabase projects produces cost or complexity that exceeds the value of separation (unlikely at our scale).

### Implementation implications

This decision is the foundation for the Constitutional cleanup planned in ADR-003 (next session). Specifically:

- **Schema rename:** `amp_organizations` → `customers`, `amp_agents` → `agents`, `amp_calls` → `conversations`, `amp_templates` → `agent_templates` (AMP-specific extension), `amp_appointments` → `appointments` (AMP-specific extension), `amp_alerts` → `alerts` (AMP-specific extension), `amp_weekly_reports` → `weekly_reports` (AMP-specific extension).
- **Enum rename:** every `amp_*` enum drops the prefix and is renamed per Constitution Section 1.1 (`{table_singular}_{column_singular}_type`).
- **FK removal:** `amp_organizations.proscore_provider_id` and its FK are dropped.
- **Vercel:** `claire-ai-beta.vercel.app` decommissioned. Verification added to the cleanup plan.
- **Codebase:** every reference to `amp_*` table or column names in `app/`, `lib/`, `scripts/` is renamed in the same atomic change.
- **Constitutional extensions:** `appointments`, `alerts`, `agent_templates`, `weekly_reports` are AMP-specific extensions on top of the Section 1.3 locked terms. Not violations. Logged here for clarity so the Reviewer does not flag them under T-003.

### Related decisions made this session (feed into ADR-003)

Four tactical answers Josh gave alongside this decision, captured here so they can be referenced by the cleanup plan:

- **Q4:** `amp_calls` renames to `conversations`, not to `calls`. Honor Section 1.3.
- **Q6:** Keep `appointments` and `alerts` as AMP-specific extensions (rename, do not drop). Same for `agent_templates` and `weekly_reports`.
- **Q7:** Move the Retell webhook to `/api/webhooks/retell/v1/` during the cleanup. Update the URL in the Retell dashboard at the same time.
- **Q8:** Preserve the Claire-era Retell agent, Retell LLM, and Twilio number. They are the active AMP plumber testbed. Repoint them at the renamed schema; do not tear down.

### Note on ADR numbering

`docs/NORTH_STAR.md` placeholder-reserves ADR-002 for the wedge decision. That reservation is now overwritten — today's decision claims ADR-002. The wedge ADR will receive the next available number after ADR-003. NORTH_STAR.md will be updated when the document is next revised; do not edit it as part of this session.

---

*Future decisions append below this line. Decisions are numbered sequentially (ADR-002, ADR-003, etc.) and never renumbered.*
