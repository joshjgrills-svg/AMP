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

---

## ADR-004 — Vertical Wedge and Product-Category Commitment: Customer-Facing Channels, Home Services First

**Date:** 2026-05-17
**Status:** Accepted
**Decided by:** CEO (Josh) with PM/Architect recommendation, informed by AMP Ecosystem Scout brief
**Supersedes:** None (overwrites the NORTH_STAR.md v1 placeholder reservation of ADR-002 for the wedge decision; the wedge ADR receives the next number after ADR-003 per the note at the end of ADR-002)
**Superseded by:** None

### Context

On 2026-05-13, Anthropic launched [Claude for Small Business](https://www.anthropic.com/news/claude-for-small-business) (CSB): a packaged set of 15 agentic workflows, 15 reusable skills, and connectors to 8 back-office SaaS tools (Intuit QuickBooks, PayPal, HubSpot, Canva, Docusign, Google Workspace, Microsoft 365, and one further unnamed connector), delivered as a plugin inside Claude Cowork to Pro, Max, and Teams plan users. The named example customers — a 15-person HVAC, a 30-person landscaping company, a 50-person real estate brokerage — overlap directly with AMP's North Star wedge candidates.

The scout brief (`docs/scout/2026-05-17_claude-for-small-business.md`) establishes one load-bearing fact: across every primary source verified, CSB has no voice, no telephony, no PSTN, no SMS, no autonomous after-hours customer-facing channel, and no end-user identity model. CSB is owner-initiated, human-in-the-loop, and operates inside Claude Desktop. It is back-office automation for the operator. AMP's wedge — customer-facing operational agents in place of the missing receptionist — is structurally untouched.

This is the strategic inflection point the North Star always anticipated. A horizontal platform has entered the SMB segment AMP targets. The wedge ADR can no longer be deferred. Three things must be decided now and recorded so they are not re-litigated next quarter: (1) what category AMP commits to, (2) which vertical leads, and (3) how CSB is evaluated against North Star kill-criterion #4.

### Decision

AMP makes the following six commitments:

1. **AMP's wedge is customer-facing channels, voice first.** AMP will not build back-office automation. The surface AMP owns is the phone, the website chat, the SMS thread, and the lead email — not QuickBooks, HubSpot, or Docusign. CSB owns back-office; AMP owns the real-time customer-facing layer CSB structurally cannot reach (no PSTN, no live channel, no autonomous after-hours mode).

2. **AMP will not become a Claude Cowork or Claude for Small Business plugin.** AMP is a standalone platform with its own dashboard, billing, and brand. AMP will not deliver through Claude Desktop. Building inside Cowork would surrender distribution, pricing ceiling, and category position to Anthropic. This commitment is consistent with ADR-001 and is made explicit here so the temptation cannot be re-introduced silently.

3. **First vertical: home services.** Specifically HVAC, plumbing, electrical, roofing, and general contracting. The lead capability is the inbound voice agent. Home services has the loudest after-hours pain, the cleanest missed-call-equals-lost-revenue math, the largest underserved population, and a warm-channel asset through ProScore (per North Star). CSB naming HVAC in Anthropic's own example list strengthens — does not weaken — this choice.

4. **AMP will not build horizontal back-office capabilities for at least 12 months.** No invoice chasers, no payroll workflows, no QuickBooks integrations, no contract reviewers. CSB exists for that. AMP's job is what CSB cannot do. Re-evaluation date: 2027-05-17.

5. **A new predictive tripwire is added: T-205.** If Anthropic ships any real-time, customer-facing, autonomous capability for Claude for Small Business or Claude Cowork — voice connector, live chat agent, autonomous after-hours customer mode — the Architect re-evaluates AMP's wedge against North Star kill-criterion #4. The trigger is the category boundary (autonomous customer-facing real-time interaction), not back-office connectors. Adding a Stripe or Slack connector to CSB does not fire T-205. Adding a Twilio or Retell connector does.

6. **North Star kill-criterion #4 is evaluated and not triggered as of 2026-05-17.** Claude for Small Business does not make AMP's value proposition redundant. AMP's promise to a contractor — "never miss a call again" — is not addressed by CSB at all. CSB validates the segment and warms AMP's funnel by educating SMB owners on agentic workflows. This evaluation is recorded so the question is not re-litigated next quarter.

### Alternatives considered

**Option B: Become a Claude for Small Business plugin or Cowork extension.** Rejected. Trades AMP's category position, pricing ceiling, and brand for short-term distribution. The North Star is explicit that AMP's buyer "will not buy a product that requires technical configuration"; CSB requires the operator to live inside Claude Desktop and learn its plugin model. ADR-001's Option B reasoning applies: a thin coordination layer on top of a horizontal platform is not defensible.

**Option C: Lead with dental, legal intake, or real estate instead of home services.** Rejected. Dental is more competitive (Weave, NexHealth, Dental Intelligence already entrenched). Legal intake is high-value but slow-cycle and consent-heavy in a way that complicates Constitution §4.3. Real estate is fragmented across IDX/CRM stacks and the buyer is less time-squeezed than a contractor. Home services wins on after-hours pain, missed-call math, addressable population, and warm-channel access through ProScore.

**Option D: Build back-office workflows alongside customer-facing agents to broaden surface area.** Rejected. Violates Constitution §8 ("No frameworks added to solve a problem that doesn't exist yet" — extended here to product scope) and contradicts North Star ("Not a horizontal platform"). CSB now occupies that space; competing horizontally with Anthropic is a losing posture. AMP wins by going deep on what CSB cannot do.

### Reasoning

1. **CSB is a tailwind, not a threat, because the jobs-to-be-done do not overlap.** CSB is owner-initiated, in-app, business-hours, back-office. AMP is autonomous, customer-facing, twenty-four-hour, voice-first. The HVAC owner who deploys CSB this month still loses the same calls to voicemail they lost last month. The two products are adjacent, not competitive.

2. **The architectural posture mismatch is not a feature gap Anthropic can close with a connector.** CSB is structurally a 9-to-5 product because it requires human-in-the-loop activation. A voice agent at the end of a phone line is structurally a 24-hour product. Closing that gap would require Anthropic to rebuild CSB around a multi-channel orchestration substrate with end-user identity — precisely the substrate ADR-001 commits AMP to owning. That is a roadmap commitment Anthropic has not made and would take engineering quarters to make.

3. **Anthropic is paying to educate AMP's buyer.** The 10-city in-person fluency tour (Chicago, Tulsa, Dallas, NJ, Baton Rouge, Birmingham, Salt Lake City, Baltimore, San Jose, Indianapolis) is market education AMP would otherwise have to fund. The owner who has spent a half-day with Claude understanding "agentic workflow" is dramatically easier to close on AMP than a cold prospect.

4. **Voice quality is a vertical-specific defensibility play, not a horizontal Anthropic product.** A voice agent that knows what a "rough-in" is, what a "P-trap" is, what the seasonal demand pattern is, and what the local permit office requires is depth Anthropic's 36M-business framing cannot economically build. AMP wins by going deep where Anthropic must stay shallow.

### Trade-offs accepted

- **AMP forgoes the back-office surface area entirely for at least 12 months.** Customers will ask for it. We say no and point them at CSB. The 2027-05-17 re-evaluation date is the only window where this commitment is revisited.
- **Home-services dependency.** If the home-services thesis is wrong, AMP loses 12 months. Mitigation: the kill-criteria in the North Star are dated; we measure at the 12-month-after-primary mark, not after the first quarter.
- **Anthropic gatekeeper risk persists.** Anthropic could ship a voice connector at any time. T-205 is the detection mechanism. The Constitution §3.2 multi-provider mandate already ensures AMP can swap Retell/ElevenLabs/Twilio if needed; the relevant exposure is competitive, not infrastructural.
- **The defensible adjacency ordering is implicit but not pre-committed.** Once voice ships, the natural extensions are SMS, chat, and email — all customer-facing channels per Constitution §10.4. The order in which these ship after voice is a Build Phase decision, not a Foundational one, and is deliberately left out of this ADR.

### Kill-criterion #4 evaluation (2026-05-17)

North Star kill-criterion #4: "A horizontal platform ships an offering that makes AMP's value proposition redundant for our target customer, and we cannot find a defensible differentiator within ninety days."

**Verdict: Not triggered.**

Claude for Small Business does not make AMP's value proposition redundant. AMP's value proposition to a home-services contractor is "never miss a call again, including at 11pm on Saturday, including when you're on a roof." CSB has no phone, no SMS, no autonomous after-hours mode, and no end-user identity layer. There is no overlap on the customer-facing job-to-be-done. The differentiator is not a feature AMP must scramble to build within 90 days; it is the category boundary CSB has not crossed and shows no roadmap intent to cross.

This evaluation is recorded with a date so the next quarter's review can pick it up where this one left off. The trigger for re-evaluation is T-205 firing or a material change in Anthropic's published roadmap, not the calendar.

### What would change this decision

We would revisit ADR-004 if:

1. T-205 fires (Anthropic ships a voice, real-time chat, or autonomous after-hours capability for CSB or Cowork).
2. The home-services thesis fails the 12-month-after-primary kill-criteria check (per North Star).
3. A different vertical produces faster traction in early customer development than home services, and the difference is large enough to overcome switching cost (unlikely; recorded for completeness).
4. The 2027-05-17 back-office embargo review concludes that horizontal expansion is now defensible against CSB's by-then-known surface area.

### References

- [Introducing Claude for Small Business — Anthropic](https://www.anthropic.com/news/claude-for-small-business) (announcement, 2026-05-13; verified by CEO against official source)
- `docs/scout/2026-05-17_claude-for-small-business.md` — full ecosystem scout brief informing this decision
- ADR-001 — Orchestration Model: AMP as the Orchestration Brain (the architectural commitment this wedge decision extends)
- ADR-002 — AMP-Supabase separation (the operational independence this wedge decision compounds)
- Constitution §3.2 — Multi-provider mandate (the infrastructural commitment that makes wedge-defensible voice possible)
- Constitution §10 — Multi-agent runtime architecture (the substrate the customer-facing wedge runs on)
- North Star — "Who AMP is for," "What AMP is explicitly not," kill-criterion #4
- TRIPWIRES.md — T-205 added in the same change as this ADR

---

## ADR-005 — Constitutional Amendment: Documentation-Only Changes Skip the PR Gate

**Date:** 2026-05-17
**Status:** Accepted
**Decided by:** CEO (Josh) with PM/Architect recommendation
**Supersedes:** None (amends Constitution v1 → v1.1, adding Section 7.5)
**Superseded by:** None

### Context

Until now, every change to the AMP repository — including pure documentation edits to `docs/NORTH_STAR.md`, `docs/CONSTITUTION.md`, `docs/SESSION_LOG.md`, and the like — required a feature branch, a pull request, and Josh's manual merge. This was a deliberate choice for the foundation phase: a uniform discipline is easier to enforce than a tiered one while the project is still finding its rhythm.

Three sessions in, the friction is asymmetric. Documentation PRs (PR #2 for the Session 001 tripwire follow-up, PR #3 for ADR-004 and SESSION_LOG appendage) consume founder attention but carry no runtime or security risk. Code PRs — none yet, since the ADR-003 cleanup has not begun — will consume the same attention but carry actual exposure. Treating both the same dilutes the signal of "this PR needs Josh's eyes" exactly when code work is about to begin.

### Decision

Amend Constitution v1 to v1.1 by adding Section 7.5 ("PR discipline and the documentation carve-out"). The rule:

- Changes confined to the `docs/` directory may be committed directly to `main` by the Builder without a pull request. Covered paths: `NORTH_STAR.md`, `CONSTITUTION.md`, `RUNTIME_ARCHITECTURE.md`, `OPERATING_RHYTHM.md`, `DECISIONS.md`, `TRIPWIRES.md`, `SESSION_LOG.md`, `README.md`, plus anything under `docs/scout/` or `docs/research/`.
- All other changes — application code, schema, configuration, `.claude/` agent definitions, or any path outside `docs/` — still require a feature branch, a PR, a Reviewer audit, and Josh's explicit merge approval.
- The carve-out is **path-scoped, not intent-scoped**: a change that touches both `docs/` and any non-`docs/` file is NOT documentation-only; the entire change goes through the standard PR flow.

### Alternatives considered

**Option B: Keep the uniform PR gate for all changes.** Rejected. The friction tax falls disproportionately on documentation, where risk is zero, and dulls Josh's attention for code PRs where risk is real.

**Option C: Tier by file count or diff size, not by path.** Rejected. "Small enough to commit direct" is subjective and erodes the policy bar. Path is mechanically checkable; line count is not.

**Option D: Intent-based carve-out ("if it's just docs in spirit").** Rejected. Mixed changes are exactly the dangerous case — a small `.claude/` agent update bundled with a `docs/` edit would slip through without review. Path-scoped enforcement is the safer default.

**Option E: Auto-merge PRs on a docs-only label via GitHub Actions.** Rejected as premature infrastructure. The same outcome (no Josh review for docs) can be achieved with a one-line Constitutional rule and zero CI to maintain.

### Reasoning

1. **Risk asymmetry is real and growing.** As ADR-003 (Constitutional cleanup) and subsequent code work begin, Josh's PR review attention becomes a load-bearing resource. Spending it on `SESSION_LOG.md` appendages is misallocation.
2. **`docs/` is genuinely runtime-safe.** Nothing under `docs/` is read at runtime by the application. The worst-case impact of a bad docs commit is a confused future agent, fixed by a follow-up docs commit. No customer-facing impact, no security exposure.
3. **`.claude/` is excluded by design.** Agent definitions, slash commands, and `settings.local.json` are not "documentation" — they configure the agent system's behavior. A bad change there can cause the next session to misbehave in ways that DO touch code. Hence the explicit exclusion in Section 7.5.
4. **Path-scoped enforcement is auditable.** A future Reviewer (or a human spot-checking) can verify any direct-to-main commit was docs-only by checking the file paths alone. No semantic interpretation required.

### Trade-offs accepted

- **Documentation drift risk increases.** Without a PR, there is no second pair of eyes on docs changes. Mitigation: the Reviewer agent can still be invoked on a docs commit; this is recommended for any change to `NORTH_STAR.md`, `CONSTITUTION.md`, or `DECISIONS.md` (the load-bearing trio). The carve-out permits direct commit; it does not require it.
- **The Constitution itself can be edited and pushed without a PR going forward.** Mitigation: Constitutional amendments still require the Section 9 procedure (proposal, C-suite review, CEO approval, DECISIONS.md entry, version bump). The carve-out lowers merge friction; it does not lower the amendment bar.
- **"Mostly docs" PRs disappear as a category.** A change that needs to update both Constitution and a builder.md (like this very change) goes through the full PR flow. This is the intended behavior — it is the safer default.

### What would change this decision

We would revisit ADR-005 if:

1. A documentation drift incident demonstrates that direct-to-main docs commits are corrupting the foundation faster than they save founder time.
2. Josh decides he wants visibility into every doc change as a discipline signal, independent of risk.
3. The team grows beyond Josh + agents, and "documentation reviewed by another human" becomes valuable in itself.

### Implementation implications

This amendment touches:

- `docs/CONSTITUTION.md` — version bumped to v1.1, Section 7.5 added
- `docs/DECISIONS.md` — this ADR appended
- `.claude/commands/session-end.md` — Step 3 updated to branch on session type (docs-only vs. mixed)
- `.claude/agents/builder.md` — "no direct push to main" rule amended to reflect the carve-out
- `.claude/agents/reviewer.md` — special case added: docs-only changes may arrive on main without a prior Reviewer audit

Because this change touches both `docs/` and `.claude/`, it is itself NOT eligible for the new carve-out — it goes through the standard PR flow. The next docs-only session (e.g., a `SESSION_LOG.md` append with no code) is the first one that benefits from the new rule.

**Open follow-up:** `docs/OPERATING_RHYTHM.md` (lines 22-30) describes the standard session flow including "Josh approves the PR" as a mandatory step. This line is now stale for docs-only sessions. It is intentionally not updated in this change — that update is itself docs-only and can be made directly to `main` after ADR-005 lands, as the first exercise of the new carve-out. Flagged for the next session.

**Numbering note:** ADR-004 (the wedge decision) is currently in flight in PR #3 and is not yet on `main`. ADR-005 is appended here on its own branch; the file will show ADR-001, ADR-002, ADR-005 until PR #3 merges, after which ADR-004 slots in by date order between ADR-002 and ADR-005. The ADRs are numbered sequentially; they are not required to appear in numeric order in the file once both PRs land.

### References

- Constitution v1.1, Section 7.5 (the rule this ADR establishes)
- Constitution Section 9 (the amendment procedure followed to land this change)
- Prior friction examples: PR #2 (Session 001 tripwire additions), PR #3 (ADR-004 + SESSION_LOG)
