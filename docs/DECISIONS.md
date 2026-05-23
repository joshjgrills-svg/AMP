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

### Status (appended 2026-05-23, Session 009 — Phase 1.5 execution)

ADR-002's full decommission commitment is **executed** as of 2026-05-23. Detail:

- **Retell — DONE (Session 009).** Two Claire-era "from template" agents (`agent_ddd09f387dcccc43b0f24ea350` "Healthcare Check-In", `agent_ceeab21fd886bdb7ea3bb46925` "Patient Screening") and one orphaned LLM (`llm_b470ed9903fcd7c51980e31e3ac2`) deleted via Retell API; verified gone via 404 GETs. Canonical AMP agent `agent_0e211c256211ef2ead23cc8375` ("AMP - Plumbing - V1") and its LLM `llm_b440eb1b707430fc9aa4d8d0164d` remain. Note: this ADR's "Trade-offs accepted" line about preserving `agent_58fbaa9f9eb2e1f6698e54bedd` and `llm_2387332d2303961cb4d67d815d9e` as "the active AMP plumber testbed" was already invalidated by Session 007's drift investigation — those IDs were deleted upstream of ADR-002 by an unrecorded action; their current live replacements are the IDs above.
- **Twilio — DONE (Session 009).** The Claire-era SIP trunk `TK1be0c12fb9bfc4f7054fbde6b15885f2` (friendly_name "Claire Ai", domain `claireai.pstn.twilio.com`) deleted; verified gone via 404 GET. Phone number `+12494448711` preserved (per Phase 1.5 brief; Phase 4 brings it up) with `trunk_sid` now `null`, voice_url and sms_url still the inert Twilio demo URLs.
- **Vercel — DONE (pre-audit).** CEO dashboard check on 2026-05-23 confirmed `claire-ai-beta` no longer exists as a Vercel project. The team contains only `amp` (canonical), `finder-hub` (ProScore, unrelated), and `combinecrush` (unrelated). The Claire Vercel project was deleted at an unrecorded date prior to the 2026-05-23 audit. No destructive Vercel action was needed in Phase 1.5; this portion of ADR-002 was already complete before this session began.
- **Supabase — DEFERRED (separate decision queued).** A Claire-era project (`mnsclowesetxpwpukohx` "ClaireAi", INACTIVE) was discovered in the same Supabase org as the canonical AMP project during the audit. Per CEO instruction, it is NOT touched in Phase 1.5. This is the only remaining Claire-adjacent resource on the AMP infrastructure surface; it is flagged for a separate decision session and is not load-bearing on any current AMP system.

ADR-002 is now closed. Full audit + execution log lives at `docs/PHASE_1_5_AUDIT.md`. Session 009 narrative at SESSION_LOG.md.

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

---

## ADR-004 Amendment (2026-05-22): Wedge sharpening following Scout deep-dive on Avoca and CEO strategic input

**Date:** 2026-05-22
**Status:** Accepted; amends ADR-004 (does not supersede — ADR-004 remains in force as amended below)
**Decided by:** CEO (Josh) with PM/Architect recommendation, informed by two AMP Ecosystem Scout briefs
**Supersedes:** None (amends ADR-004)
**Superseded by:** None

### Context

ADR-004 (2026-05-17) was decided primarily on competitive grounds against Claude for Small Business. Two follow-on Scout briefs over the past week surfaced material new information that the original decision did not have:

1. The home-services customer-validation brief (`docs/scout/2026-05-18_home-services-market.md`) confirmed the wedge thesis (real pain, favorable math, open pricing window) but flagged that ADR-004 had evaluated the wrong competitor: **Avoca AI** — $1B valuation, $125M raised April 2026, ServiceTitan Gold Partner — was not assessed in ADR-004 and is the actual category-leading competitor in trades voice AI.

2. The Avoca competitive deep-dive (`docs/scout/2026-05-22_avoca-competitive-deep-dive.md`) established that Avoca's 70+ integrations and enterprise sales motion make it dominant at the $10M+ tier but structurally exclude the sub-$5M owner-operator segment — and clarified that AMP's defensible territory is narrower than ADR-004 articulated.

CEO direction following the two briefs is to sharpen the wedge along five axes — geography, verticals, segment, GTM, and competitive posture — before any further wedge execution. This amendment records those refinements. ADR-004's six original commitments remain in force; this amendment narrows and operationalizes them.

### Amendments

**1. Geographic scope.** V1 is Canada-only. United States opens as Phase 2 after the Canadian wedge proves. Rationale: ProScore's coverage is Ontario / Canada; AMP launches leveraging ProScore as a springboard; Canadian-first execution avoids splitting limited founder attention across two markets with different telecom regulation, different two-party consent rules, and different SMB software ecosystems.

**2. First verticals (narrowed from ADR-004's five trades).** Launch verticals: **plumbing, electrical, HVAC.** Fast-follow: **roofing.** Deprioritized for the initial wedge: general contracting, kitchen remodeling, bathroom remodeling, pest control, tree service, drywall, landscaping. Rationale: these three trades have the highest published call-volume metrics and the most acute missed-call cost. Plumbing carries the highest call-booking rate in published trade data (43% per ServiceTitan); HVAC carries the strongest seasonal compounding (73% of revenue in 4 months); electrical has the highest customer phone-preference rate (67%). Roofing is structurally different (storm-bursty) and deferred to fast-follow once steady-demand trades are proven. General contracting is dropped from the initial naming per the home-services brief's "weakest of the five" finding.

**3. Customer segment (narrowed from ADR-004's "$500K to $5M").** Primary target: **sub-$2M revenue, 1–5 truck owner-operator.** Secondary target: **$2M–$5M** (contested middle ground; serveable while Avoca remains upmarket). Explicitly excluded: **$5M+ operators, multi-location chains, PE-backed roll-ups** — these are Avoca's segment and AMP will not compete there. Rationale: the Avoca brief established that Avoca's $1K–$3K/month price point and sales-led GTM motion structurally exclude the sub-$2M tier. This is AMP's defensible structural opening, not a marketing positioning.

**4. ProScore relationship.** AMP is a standalone product and standalone business. **ProScore is a launch springboard, not a parent product.** At launch, AMP leverages ProScore for: (a) marketing reach into ProScore's contractor base, (b) a natural early-customer cohort of ProScore-verified contractors, (c) a two-way value loop (AMP improves call handling, which generates better-handled jobs, which feed back into ProScore's trust signals). AMP sells to any Canadian contractor or professional service business, not only ProScore-verified contractors. **Honest timing note:** ProScore is not yet live as of 2026-05-22. Until ProScore launches, AMP cannot lean on the ProScore warm channel. Pre-ProScore-launch GTM is direct outreach to Ontario plumbing, electrical, and HVAC contractors plus word of mouth.

**5. Positioning against Avoca.** AMP does not compete with Avoca head-to-head on features, integration breadth, or enterprise customer references — AMP will lose all three. When a buyer asks about Avoca, the answer is:

> "Avoca is built for $10M+ trades operators with 20+ CSRs. AMP is built for the 1–5 truck owner-operator who wants the phone answered without a sales call."

AMP differentiates on **segment economics, not product capability.**

**6. Load-bearing commitments.** The following commitments are now strategic infrastructure, not stylistic preferences. Any future product decision that erodes any of them is a concession to Avoca and triggers re-review under this amendment:

- 30-minute self-serve onboarding (no sales call required to deploy)
- Transparent published pricing (no demos required to learn the price)
- $200–$500/month entry tier; $800/month bundle ceiling for 2026
- No procurement process required to start
- Lead with Housecall Pro and Jobber integrations (not ServiceTitan — that is Avoca's stronghold)

**7. Competitive monitoring posture: monitor, do not match.** The Scout monitors Avoca quarterly. Specific re-evaluation triggers:

- Avoca publishes a "starting at $X" pricing page
- Avoca launches a self-serve or "Lite" SKU
- Avoca hires SMB AEs, SDRs, or PLG product roles
- Avoca announces a partnership with a sub-$2M-focused tool or community

Scout briefs go to the Architect, not directly to execution. **AMP's strategy is NOT "match whatever Avoca does."** AMP's strategy is to own the Canadian owner-operator wedge that Avoca structurally cannot serve profitably.

**8. Kill criteria shift.** North Star kill-criterion #4 ("a horizontal platform makes AMP redundant") needs updating. The real near-term threat is not a horizontal platform — it is a **vertical-native competitor moving downmarket.** Specifically: if Avoca ships a self-serve SKU at <$500/month with <30-minute onboarding, AMP's defensible territory closes within a quarter and kill-criterion #4 is triggered. This scenario is added to TRIPWIRES.md as predictive tripwire **T-206** in the same change as this amendment. (NORTH_STAR.md kill-criterion #4 itself is not rewritten here; the amendment narrows its operational meaning, and a v2 NORTH_STAR.md will codify it when the document is next revised.)

### Reasoning

The two Scout briefs together produce one consolidated finding: **ADR-004's wedge is correct in shape but too generous in size.** Three sources of generosity:

1. **Segment generosity.** ADR-004 named "$500K to $5M" inherited from NORTH_STAR.md. The Avoca brief showed Avoca contests the upper half of that range today and could contest the middle with one strategic decision. AMP's defensible territory is sub-$2M; planning the wedge around the wider range invites a competitive collision AMP cannot win.

2. **Vertical generosity.** ADR-004 named five trades. The home-services brief established that the call-volume and missed-call-cost evidence is strong for HVAC and plumbing, decent for electrical, structurally different for roofing, and thin for general contracting. Five trades dilute focus without strengthening the wedge.

3. **Positioning generosity.** ADR-004 left positioning against AI voice competitors undefined because the original brief did not surface Avoca. The Avoca brief made clear that AMP cannot compete on product breadth and must compete on segment economics. Codifying this prevents future product decisions from drifting toward feature parity (which AMP cannot afford and does not need).

The amendment is conservative on what AMP keeps from ADR-004 (customer-facing channels, voice first, home services, no back-office for 12 months) and aggressive on what AMP narrows (geography, trade count, segment, GTM posture). The combined effect is a sharper wedge that is easier to execute against, easier to message, and harder for Avoca to attack from above.

### Trade-offs accepted

- **Canada-only V1 forgoes the larger US market for the wedge period.** Accepted: the founder-attention math does not support two markets, and ProScore's Ontario footprint is the warm channel.
- **Dropping kitchen/bath remodel, pest, tree, drywall, landscaping from the initial naming forgoes positioning surface area.** Accepted: focused HVAC + plumbing + electrical is a stronger market position than a long list, and the deprioritized verticals can be added as expansion once the wedge proves.
- **Excluding $5M+ operators forgoes the easier-to-close logo accounts.** Accepted: those accounts are Avoca's; chasing them is a losing posture and a distraction from the defensible segment.
- **The "lead with Housecall Pro and Jobber, not ServiceTitan" commitment is counter to the conventional wisdom that ServiceTitan is the entry point to trades software.** Accepted: for AMP specifically, ServiceTitan is the segment Avoca owns. AMP's customers are mostly not on ServiceTitan; AMP's roadmap should reflect that.
- **"Monitor, do not match" leaves AMP perpetually one feature behind Avoca's published product surface.** Accepted: feature parity with a $125M-funded competitor is not a winnable game; segment-economics differentiation is.

### What would change this amendment

We would revisit this amendment if:

1. **T-206 fires** (Avoca ships self-serve SKU under $500/mo with under-30-min onboarding).
2. **T-205 fires** (Anthropic ships a customer-facing real-time capability — original ADR-004 trigger, still active).
3. The Canadian wedge proves and US expansion becomes the load-bearing decision.
4. ProScore launches and the warm-channel assumption is validated or invalidated by early customer-acquisition data.
5. A second competitive deep-dive surfaces a new credible threat the Avoca brief did not consider (e.g., a Housecall Pro or Jobber acquisition of an AI voice player, which would compress AMP's wedge faster than Avoca going downmarket).

### References

- `docs/scout/2026-05-18_home-services-market.md` — customer-validation brief
- `docs/scout/2026-05-22_avoca-competitive-deep-dive.md` — Avoca competitive deep-dive (the load-bearing input ADR-004 was missing)
- ADR-001 — Orchestration Model (the architectural foundation this amendment compounds)
- ADR-002 — Supabase separation (the operational independence this amendment compounds)
- ADR-004 — original wedge decision (amended, not superseded, by this entry)
- ADR-005 — §7.5 documentation carve-out (the procedural mechanism that allowed this amendment to ship as docs-only)
- TRIPWIRES.md — T-206 added in the same change as this amendment
- NORTH_STAR.md — kill-criterion #4 operational meaning narrowed by this amendment; full v2 revision deferred

---

## ADR-003 — Constitutional Cleanup Execution Plan

**Date:** 2026-05-22
**Status:** Approved with modifications (pending Phase 0 verification spike before any execution begins)
**Decided by:** PM/Architect recommendation; CEO (Josh) approved with modifications 2026-05-22 (Session 006)
**Supersedes:** None
**Superseded by:** None

### Context

`docs/PROJECT_INVENTORY.md` (2026-05-13) catalogued 27 Constitutional compliance issues in the inherited Claire-era scaffold. ADR-002 (2026-05-13) ratified the destructive-rename approach: AMP owns its own Supabase project, the `amp_` prefix is dropped, the `providers` FK is removed, and `claire-ai-beta.vercel.app` is decommissioned. Four sessions of carryover have queued the execution plan as the load-bearing next deliverable. This ADR is that plan.

The four BLOCKING violations that gate the Build Phase:

1. Every locked-term table name violates Constitution §1.3 (`amp_organizations`, `amp_agents`, `amp_calls`, `amp_templates`, `amp_appointments`, `amp_alerts`, `amp_weekly_reports`).
2. RLS is enabled on every table with **zero policies defined** (§1.1, §4.3, §4.5). The webhook works only because it uses the service-role client.
3. No `.env.example` (§4.1), no `supabase/migrations/` directory (§1.2), no tests (§5.1), no Sentry (§6.2), no structured logger (§6.1).
4. Repo is flat, not the §2.1-mandated monorepo.

Three deferred items also belong in this plan: `scripts/check-calls.ts` (untracked since Session 001), `claire-ai-beta.vercel.app` decommissioning (ADR-002 commitment never executed), and the Retell webhook move to `/api/webhooks/retell/v1/` (Session 001 Q7 decision never executed).

The wedge has sharpened since ADR-002 (Canadian sub-$2M plumbing/electrical/HVAC owner-operators per ADR-004 + 2026-05-22 amendment). The cleanup must be Constitutional and unblock the Build Phase for this sharpened wedge — it does not have to support every theoretical future product.

### Decision

Execute the cleanup in **eight sequenced phases**, each a discrete commit (or PR) with explicit verification. Monorepo restructure is **deferred to a separate ADR (ADR-006 placeholder)**, not included in this plan — reasoning below.

The phases (modified 2026-05-22 per CEO approval — Phase 0 added; old Phase 6 moved to Phase 1.5; old Phases 7/8 renumbered to 6/7):

0. **Verification spike** (no committed code unless Sentry install is verified clean) — Builder verifies (a) Sentry-on-Next-16 compatibility and (b) Retell dashboard URL change behavior in a scratch context. Either lifts overall plan confidence to 99% target or surfaces a concrete blocker that triggers an ADR-003 amendment before Phase 1 begins.
1. **Repo hygiene + Vercel env-var unblock** (PR) — `.env.example`, `scripts/check-calls.ts` deletion, `.gitignore` audit, AND Vercel Preview/Development env-var configuration (HIGH PRIORITY carryover from Session 003) to unblock PR checks for all subsequent phases.
1.5. **Decommission Claire-era surfaces** (Vercel dashboard + SESSION_LOG direct to main per §7.5) — verify and remove `claire-ai-beta.vercel.app`; reconcile Retell/Twilio resource inventory. Done BEFORE the cutover (not after, as originally planned) to eliminate one possible source of interference during the Phase 4 destructive rename.
2. **Migrations baseline** (PR) — capture the live Supabase schema as `0000_baseline.sql` with proper header per §1.2; no functional change.
3. **Pre-flight infrastructure** (PR) — Vitest + first webhook test, structured logger, Sentry install, env-var validation at boundary. Lands before the destructive rename so the rename has a safety net.
4. **Cutover migration** (PR + Supabase apply + Vercel deploy + Retell dashboard change, executed in a bounded window) — schema rename + enum rename + FK drop + RLS policies + webhook URL versioning, all in one atomic deploy.
5. **Scripts reconciliation** (PR) — update or delete the ten one-off scripts that reference `amp_*` names; resolve the `create-amp-agent.ts` schema drift; remove Claire-era hardcoded values.
6. **`jsonb` Zod schemas + adapter pattern Phase 1** (PR) — Zod schemas for the seven `jsonb` columns; wrap Retell client first (it is on the live call path).
7. **Index rename + enum rename + secondary cleanup** (PR) — non-load-bearing naming compliance items grouped because they share a migration shape.

Monorepo restructure is **out of scope** for this ADR and tracked as ADR-006 (proposed). The restructure has the highest blast radius of any item in the inventory and gains nothing for the wedge (one app, no marketing site yet, no second customer surface). Doing it now compounds the cutover risk for zero customer value. Doing it before the marketing site or a second app is built is the right inflection point.

### Alternatives considered

**Option B: One giant atomic PR covering all 27 inventory items.** Rejected. Cutover risk is bounded by phase size; an eight-step plan with eight verifications produces eight chances to detect a regression and eight clean rollback points. A single PR produces one regression surface and one rollback that throws away all the good work along with the bad.

**Option C: Defer RLS policies to a later phase ("the webhook is service-role, we don't need them yet").** Rejected. Constitution §1.1 mandates RLS on every table from the migration that creates them, and §4.5 explicitly forbids merging tables without policies. The renamed tables ARE new tables from the migration's perspective. Skipping policies would create a window where any future code path using the anon client reads nothing — silently — exactly the failure mode §4.5 was written to prevent. Policies and the rename land together.

**Option D: Include the monorepo restructure as the final phase.** Rejected for this ADR. See reasoning in §6 below.

**Option E: Copy-and-migrate instead of destructive rename.** Already rejected by ADR-002. Not re-litigated.

**Option F: Move the webhook URL change to a separate cutover from the schema rename.** Rejected. Both require Retell dashboard work and a brief data-flow interruption. Two cutovers is two windows of risk; one cutover is one. Per ADR-002 trade-off note, "land the webhook URL change and the table rename in the same deploy."

### Sequenced execution steps

Each phase is one commit/PR (where applicable) with explicit verification. Where-it-happens annotation is **bold** at the start of each phase.

---

**Phase 0 — Verification Spike** (no committed code unless Sentry install is verified clean)

*Where:* **Codespace** for the Sentry check; **Retell dashboard** for the URL behavior check (against a scratch test agent, NOT the production plumber testbed).
*Estimated time:* 30 minutes.

Steps:
1. **Sentry-on-Next-16 compatibility:** check `npm view @sentry/nextjs versions` for the latest version; check the Sentry changelog or release notes for Next.js 16 support; in a scratch branch, run `npm i @sentry/nextjs` followed by `npm run build`. Verify the build succeeds with no Sentry-related errors. Record the version installed and any wizard prompts that diverge from documented setup.
2. **Retell dashboard URL change behavior:** in the Retell dashboard, create or use a scratch test agent (NOT the production plumber testbed agent `agent_58fbaa9f9eb2e1f6698e54bedd`). Change its webhook URL to a benign endpoint (e.g., a Vercel route that just logs the receipt). Observe: does the change take effect immediately? Does it require agent republish? Is there a propagation delay? Place a test call; verify which URL receives the webhook.
3. Record findings as a brief paragraph appended to the Phase 0 session's SESSION_LOG entry (or as a dedicated note under `docs/research/` if findings are substantial).

*Verification:*
- **Pass condition:** Sentry installs and builds cleanly on Next.js 16.2.4; Retell URL change is a one-field edit that takes effect within seconds of dashboard save. Plan confidence lifts to 99% target; proceed to Phase 1.
- **Blocker condition:** Sentry incompatible (or requires non-trivial workaround beyond the documented fallback); OR Retell URL change requires agent republish (which introduces its own downtime implications). Either triggers an ADR-003 amendment before Phase 1 begins.

*Commit boundary:* Phase 0 produces no committed code unless the Sentry install on the scratch branch is rolled forward into Phase 3 (no need to throw away verified work). Findings are recorded via SESSION_LOG entry. If a blocker is surfaced, the ADR-003 amendment is itself a docs-only commit per §7.5.

*Critical:* This phase MUST complete before Phase 1 begins. If a blocker is surfaced, the cleanup pauses until the amendment lands.

---

**Phase 1 — Repo hygiene + Vercel env-var unblock** (PR)

*Where:* **Codespace** for file changes; **Vercel dashboard** for Preview/Development env-var configuration.
*Estimated time:* 1 hour (30 min file changes + 30 min Vercel dashboard work).

Steps:
1. Create `.env.example` at repo root listing every variable currently in `.env.local` with a one-line comment per variable explaining what it is and where to obtain it. Use placeholder values; never copy real secrets (T-006, T-007).
2. `git rm scripts/check-calls.ts` per the decision section below. (Decision: delete.)
3. Verify `.gitignore` covers `.env*` (already confirmed; line 28).
4. Audit `.gitignore` once more for any new gaps surfaced since Session 002 (e.g., `.next/`, `coverage/`, `*.tsbuildinfo` — all already present).
5. **Vercel Preview/Development env-var unblock (HIGH PRIORITY carryover from Session 003):** add `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` to Vercel's Preview and Development environments for the AMP project (use the same values currently in Production). This unblocks PR checks for all subsequent phases — without it, every PR (starting with Phase 2) will fail the Vercel build with `Missing required env var: NEXT_PUBLIC_SUPABASE_URL`. Dashboard work, not code; goes in the Phase 1 PR description as a checkbox.

*Verification:*
- `git status` shows `.env.example` tracked, `.env.local` untracked.
- `scripts/check-calls.ts` is no longer untracked (deleted in step 2).
- `cat .env.example` shows every variable; no real secrets are present.
- A test PR against main (the Phase 2 PR is the natural validator) passes the Vercel build without missing-env-var errors on both Preview and Development.

*Commit boundary:* one PR for file changes. Vercel dashboard env-var configuration is manual work that does not produce a commit but does need a checkbox in the Phase 1 PR description.

---

**Phase 1.5 — Decommission Claire-era surfaces** (Vercel dashboard + SESSION_LOG)

*Where:* **Vercel dashboard** (manual), **Codespace** for the SESSION_LOG note.
*Estimated time:* 30 minutes.

**Position rationale (added 2026-05-22 per CEO approval):** Removing the Claire-era Vercel project BEFORE the Phase 4 cutover (rather than after, as originally planned) eliminates a possible source of interference during the destructive rename. If `claire-ai-beta.vercel.app` still serves traffic (or holds DNS, or has any webhook pointed at it), it is one more thing that could mask or compound a Phase 4 failure mode. Decommissioning first means Phase 4's cutover blast radius is bounded to a single Vercel project.

Steps:
1. In the Vercel dashboard, verify `claire-ai-beta.vercel.app` status. If it serves traffic, take it offline (or delete the project entirely if Josh confirms it is no longer needed for any purpose). Record the action.
2. Audit Retell dashboard for any other webhook URLs pointing at `claire-ai-beta.vercel.app` (paranoid check — should be none).
3. Audit Twilio dashboard for the phone number `+12494448711` configuration — confirm it routes to Retell agent `agent_58fbaa9f9eb2e1f6698e54bedd`, not to a Claire-era endpoint.
4. Append a SESSION_LOG entry recording the decommission with timestamp and what was done.

*Verification:*
- `curl -I https://claire-ai-beta.vercel.app/` returns 404 or DNS NXDOMAIN.
- No Retell webhook points at the Claire URL.
- Twilio number routing confirmed correct.

*Commit boundary:* docs-only SESSION_LOG append, direct to main per §7.5.

---

**Phase 2 — Migrations baseline** (PR)

*Where:* **Codespace** for file creation; **Supabase dashboard** for verification that baseline matches live schema before applying anything to the live project.
*Estimated time:* 2 hours including Supabase introspection.

Steps:
1. Create `supabase/migrations/` directory.
2. Use the Supabase MCP `list_tables` against the live project (`yxuhjxxbgbuznpoekwpj`) to confirm the live schema matches `supabase/schema.sql`. Reconcile any drift surfaced by `scripts/create-amp-agent.ts` (it references `amp_templates.type`, `amp_organizations.type`, `amp_agents.retell_llm_id` which may exist in live but not in committed schema, per Inventory item #15).
3. Create `supabase/migrations/20260522000000_baseline.sql` containing the **reconciled** current schema (post-drift-resolution). Header comment per §1.2 must include: date (2026-05-22), author, reason ("Capture current schema as numbered baseline; no functional change."), rollback procedure ("This is a baseline capture. Rollback is `drop schema public cascade; create schema public;` followed by re-applying the prior `supabase/schema.sql`. Destructive — only for a fresh environment.").
4. Delete `supabase/schema.sql` (now superseded by the migration).
5. Add `db:migrate` script to `package.json` invoking the Supabase MCP or CLI workflow Josh prefers.

*Verification:*
- `supabase/migrations/20260522000000_baseline.sql` exists with proper header.
- Applying the baseline to a clean Supabase project produces a schema identical to the live project (test via Supabase MCP `apply_migration` to a scratch branch if available, or via dry-run + diff).
- `supabase/schema.sql` is deleted.
- The Reviewer audit confirms no functional change to the live schema.

*Commit boundary:* one PR. No live-schema change — this is a structural capture only.

*Critical:* This phase MUST complete and merge before Phase 4 can run. Phase 4 depends on having a numbered migrations chain.

---

**Phase 3 — Pre-flight infrastructure** (PR)

*Where:* **Codespace.**
*Estimated time:* 4-6 hours.

Steps:
1. Install Vitest: `npm i -D vitest @vitest/coverage-v8`. Add `test` and `test:watch` scripts to `package.json`.
2. Write the first test: `app/api/webhooks/retell/route.test.ts` — covers signature verification (happy path, bad signature), and the upsert path with a mocked `supabaseAdmin`. This is the minimum to satisfy §5.1 ("every webhook handler" must be tested).
3. Install Sentry: `npm i @sentry/nextjs`. Run `npx @sentry/wizard@latest -i nextjs` or wire manually. Configure DSN per environment.
4. Add structured logger module at `lib/log.ts` (kept flat for now since monorepo restructure is deferred). Use `pino` (small, fast, no deps that matter): `npm i pino`. Export a singleton with `info`, `warn`, `error` methods that emit JSON.
5. Replace every `console.*` call in `app/api/webhooks/retell/route.ts` (lines 168, 173, 185, 252, 260 per inventory) with the structured logger. **Do not log raw Supabase error objects** — extract `message` and `code` only (PII guard per §6.1).
6. Add a Zod schema for environment variables at `lib/env.ts`, parsed once at module load. Throws on missing required vars.

*Verification:*
- `npm test` runs and passes Vitest with the webhook test.
- `npm run build` succeeds with Sentry wired.
- A deliberate uncaught error in a local route reaches Sentry's dashboard (or a Sentry test event does).
- The webhook route no longer contains `console.*` calls.
- Starting the app with a missing env var throws a clear error at boot, not a silent runtime failure.

*Commit boundary:* one PR. Reviewer must approve before Phase 4.

*Note on confidence:* Sentry wiring on Next.js 16 + React 19 is the part with the most uncertainty here — the Sentry wizard's Next.js support has historically lagged Next.js majors. Per `AGENTS.md`, the Builder reads `node_modules/next/dist/docs/` before wiring. Flagged for execution.

---

**Phase 4 — Cutover migration** (PR + bounded execution window)

*Where:* **Codespace** for the migration file + code rename; **Supabase dashboard/MCP** to apply migration; **Vercel** for redeploy; **Retell dashboard** for webhook URL update.
*Estimated time:* PR review separate; execution window is 30 minutes (see "Cutover window" section below).

Steps (PR contents, all in one commit on the PR branch):

1. Create `supabase/migrations/20260522000100_rename_amp_tables_and_add_rls.sql`. The migration:
   - Drops the `amp_organizations.proscore_provider_id` FK and column (ADR-002 commitment).
   - Renames tables: `amp_organizations` → `customers`, `amp_agents` → `agents`, `amp_calls` → `conversations`, `amp_templates` → `agent_templates`, `amp_appointments` → `appointments`, `amp_alerts` → `alerts`, `amp_weekly_reports` → `weekly_reports`.
   - Renames every enum per §1.1 (`amp_organization_status` → `customer_status_type`, `amp_agent_status` → `agent_status_type`, `amp_call_direction` → `conversation_direction_type`, `amp_call_status` → `conversation_status_type`, `amp_call_outcome` → `conversation_outcome_type`, `amp_sentiment` → `conversation_sentiment_type`, `amp_appointment_status` → `appointment_status_type`, `amp_alert_type` → `alert_type_type` [or `alert_kind_type` — see open question below], `amp_alert_severity` → `alert_severity_type`, `amp_organization_tier` → `customer_tier_type`).
   - Adds default-deny + explicit-allow RLS policies per table. Policy shape: `customer_id`-scoped allow for `authenticated` role; service-role bypass implicit. Policies cover SELECT, INSERT, UPDATE, DELETE explicitly per §4.5.
   - Header comment per §1.2 including rollback procedure: "Rename tables back to `amp_*`, restore `proscore_provider_id` column + FK, drop all policies." Note: rollback is theoretically possible but should not be required because cutover window data is throwaway.

2. Update all 17 `amp_*` references in code:
   - `app/api/webhooks/retell/route.ts`: lines 162 (`amp_agents` → `agents`), 179, 248, 257 (`amp_calls` → `conversations`). Move the route file from `app/api/webhooks/retell/route.ts` to `app/api/webhooks/retell/v1/route.ts` (Session 001 Q7, ADR-002 commitment).
   - `lib/supabase.ts`: no table refs, no change.
   - `scripts/*.ts`: update or defer to Phase 5. Recommend update inline in this PR for the scripts that will survive (most updates are mechanical `amp_X` → `X` find-replace).
3. Update `package.json` if any script names reference `amp_*`.

*Cutover execution sequence (run in this order during the bounded window):*

a. Merge the PR to main. Vercel auto-deploys the new code (which references the renamed tables — it will 500 against the un-migrated live DB until step b).
b. Apply the migration to the live Supabase project via MCP `apply_migration`.
c. Update the Retell dashboard webhook URL from `https://amp-beta-one.vercel.app/api/webhooks/retell` to `https://amp-beta-one.vercel.app/api/webhooks/retell/v1`. (**Manual Retell dashboard work** — single field change.)
d. Place a test call to the AMP plumber agent (`agent_58fbaa9f9eb2e1f6698e54bedd`, Twilio `+12494448711`). Verify the webhook fires, a row appears in `conversations`, no errors in Sentry, no 4xx/5xx in Vercel logs.

*Verification:*
- All seven renamed tables exist with new names; `amp_*` tables do not exist.
- `proscore_provider_id` column and FK do not exist.
- Every renamed table has at least one SELECT, INSERT, UPDATE, DELETE policy defined (`select policyname from pg_policies` returns ≥4 rows per table).
- Test call lands a row in `conversations`, not `amp_calls`.
- Webhook URL change in Retell dashboard takes effect (verify by webhook receipt logged in Sentry within 5 seconds of test-call hangup).
- No 500s in Vercel logs in the 10 minutes following cutover.

*Commit boundary:* one PR for the code+migration; manual dashboard steps documented in the PR description as a checklist Josh runs at merge time.

---

**Phase 5 — Scripts reconciliation** (PR)

*Where:* **Codespace.**
*Estimated time:* 3-4 hours.

Steps:
1. For each script under `scripts/`, decide: keep (and update to new names) / delete / move to `scripts/archive/`. Default decision per script:
   - `create-amp-agent.ts` → **keep**, update to new names, rename to `create-agent.ts`, resolve schema drift surfaced by Inventory item #15.
   - `check-schema.ts`, `probe-schema.ts`, `check-template.ts` → **keep**, update table names. These are introspection helpers useful during Build Phase.
   - `audit-retell.ts`, `audit-retell-numbers.ts`, `audit-trunk.ts` → **keep**, remove hardcoded Claire-era `trunkSid` (move to env var or delete the script).
   - `bind-phone.ts`, `register-phone.ts`, `attach-number-to-trunk.ts` → **archive** to `scripts/archive/`. These are one-shot setup tooling, already run.
2. Remove `terminationUri = 'claireai.pstn.twilio.com'` hardcoding from `register-phone.ts` if archived this is moot; otherwise move to env var.
3. Include `scripts/` in typecheck by removing the `"scripts/**"` exclude from `tsconfig.json` (Inventory item #20). Fix any newly-surfaced type errors.

*Verification:*
- `npx tsc --noEmit` passes including scripts.
- No script references any `amp_*` name.
- No Claire-era hardcoded values remain in tracked scripts.

*Commit boundary:* one PR. Lower risk because no live system touched.

---

**Phase 6 — Zod schemas for `jsonb` columns + Retell adapter** (PR)

*Where:* **Codespace.**
*Estimated time:* 1 day.

Steps:
1. Install Zod if not present: `npm i zod`.
2. Create `lib/schemas/` (kept flat pending monorepo) with one file per `jsonb` column:
   - `agent-templates-faqs.ts`, `agents-business-hours.ts`, `agents-booking-config.ts`, `conversations-transcript.ts`, `conversations-metadata.ts`, `alerts-context.ts`, `weekly-reports-metrics.ts`.
3. Validate at the application boundary: every write into a `jsonb` column passes through `Schema.parse()`; every read out of one passes through `Schema.safeParse()` with a logged warning on failure.
4. Wrap the Retell SDK in an adapter at `lib/integrations/retell/index.ts`. Adapter exposes typed `createAgent`, `getCall`, `registerPhoneNumber` with retry (max 2), 10-second timeout, Sentry instrumentation per §3.2. Multi-provider design hook: adapter takes an interface, current implementation is Retell-only, but the interface allows a second provider to be added later.
5. Update the webhook route and `lib/retell.ts` callers to use the adapter.

*Verification:*
- `npm test` includes a Zod-validation test for at least the `conversations.transcript` schema.
- The webhook route does not import `retell-sdk` directly.
- A simulated Retell timeout produces a typed error reaching Sentry, not an uncaught exception.

*Commit boundary:* one PR.

---

**Phase 7 — Index rename + remaining cleanup** (PR)

*Where:* **Codespace** + **Supabase MCP** for the index rename migration.
*Estimated time:* 2-3 hours.

Steps:
1. Create `supabase/migrations/20260522010000_rename_indexes.sql` renaming every index from `{table}_{column}_idx` to `idx_{table}_{column}` per §1.1. 26 indexes per inventory.
2. Update `app/layout.tsx` metadata title from `"Create Next App"` to `"AMP"` (cosmetic; Inventory item #22).
3. Replace `app/page.tsx` with a minimal holding page (Inventory item #23). One sentence: "AMP — coming soon." Defer marketing copy to a separate session.
4. Add `engines` field to `package.json` pinning Node version (Inventory item #25). Node 20 is the Vercel default; pin to `>=20.0.0 <23.0.0`.
5. Fix `app/globals.css` `font-family` override that defeats the Geist wiring (Inventory item #24). One-line CSS fix.

*Verification:*
- `select indexname from pg_indexes where schemaname = 'public'` shows all indexes use the `idx_` prefix.
- `https://amp-beta-one.vercel.app/` no longer serves the create-next-app placeholder.
- `npm install` succeeds on a Node 20 environment.

*Commit boundary:* one PR. Lowest risk in the plan.

---

### Cutover window

**Planned window:** Sunday, 2026-05-31, 09:00–09:30 ET (06:00–06:30 PT).

**Why this window:**
- Sunday morning is the lowest-traffic time for inbound calls to home-services contractors. The plumber testbed is the only live agent today; even so, a Sunday-morning miss is the minimum-cost miss.
- 30-minute bound is generous for a 4-step cutover. Steps are: (a) merge PR (~2 min auto-deploy), (b) apply migration (~10 sec), (c) update Retell URL (~1 min manual click), (d) test call (~2 min). Buffer is for unforeseen issues.
- If the window blows past 30 minutes, rollback procedure is documented in the migration header: restore prior tables, restore Retell URL to `/api/webhooks/retell` (no `/v1`), revert the PR. The 30-minute bound is a forcing function; if rollback is needed it happens at minute 30, not minute 60.

**Pre-window checklist Josh runs:**
1. Confirm no active inbound traffic in Retell dashboard's call log for the prior 2 hours.
2. Confirm Vercel deployments queue is empty.
3. Confirm Supabase status page is green.
4. Have the rollback procedure file open in another window.

**During-window communication:** Josh runs the cutover; the SESSION_LOG entry for the cutover session records start time, end time, and any deviations from the checklist. If anything material happens (rollback needed, errors observed, dashboard work surfaces an unknown), a postmortem follows per §6.3 regardless of whether the cutover ultimately succeeded.

### `scripts/check-calls.ts` decision

**Decision: Delete.**

**Reasoning:**
1. The script is 36 lines of one-off introspection. It queries the most recent 5 rows from `amp_calls` and prints them. It is not load-bearing.
2. Rewriting it for `conversations` is trivial (one-line change) but adds a tracked artifact that has been used zero times in the four months since it was written.
3. Archiving in `scripts/archive/` is dead weight for an item that has never been re-run.
4. If the same introspection is needed in the Build Phase, recreating it takes 5 minutes — and by then the right tool is a Supabase MCP query, not a tracked TS script.
5. Most importantly: this script is the canonical example of "untracked work" T-008 was created to catch. Deleting it closes the loop on the original Session 001 finding rather than re-litigating it. Every future session has been carrying it as open work for zero benefit.

Execution: `git rm scripts/check-calls.ts` happens in Phase 1.

### Pre-mortem

The five most likely failure modes:

**1. The migrations baseline does not faithfully capture the live schema.**
The inventory flagged that `scripts/create-amp-agent.ts` references columns (`amp_templates.type`, `amp_organizations.type`, `amp_agents.retell_llm_id`) that may exist in the live Supabase project but not in committed `schema.sql`. If Phase 2 captures only what is in `schema.sql`, the baseline does not match reality, and Phase 4's rename migration will fail on tables/columns it does not expect — or worse, silently succeed while leaving stranded columns the application then references and the typecheck does not catch (because the renamed table no longer has the column the script expects).

*How detected:* Phase 2 includes a Supabase MCP `list_tables` introspection step that compares live to committed. The diff IS the detection.
*How recovered:* Reconcile within Phase 2 by adding the drift to the baseline migration. Do not move to Phase 4 until the diff is zero.
*Mitigation in plan:* Phase 2 explicitly calls for reconciliation before baseline lock-in. Verification criterion includes "Applying the baseline to a clean Supabase project produces a schema identical to the live project."

**2. RLS policies are written but lock out the service-role webhook.**
The webhook today works because `supabaseAdmin` uses the service role, which bypasses RLS by default. But the wrong policy shape (e.g., an `authenticated`-only INSERT policy without a service-role bypass) could break the webhook silently — the call lands, the upsert fails, Sentry catches it, but the row is lost.

*How detected:* The test call in Phase 4 step (d) is the detection. A failed upsert produces no row in `conversations` and a Sentry error within seconds.
*How recovered:* Revert the migration (rollback procedure documented in header), revisit policies, re-cut. The 30-minute window makes this a 5-minute reversal.
*Mitigation in plan:* Phase 3's webhook test runs against a mocked `supabaseAdmin` and will exercise the upsert code path; the policy interaction is only testable in the live DB. Add an explicit "service-role can do everything" policy as a belt-and-suspenders measure on the renamed tables — service role bypasses RLS regardless, but the explicit policy makes the intent visible and protects against a future Supabase change to default behavior.

**3. The Retell dashboard URL change does not take effect, or takes effect late.**
Retell's webhook URL is a single field but it is unknown (per Inventory and not verified for this ADR) whether Retell caches the URL, requires republishing the agent, or whether a propagation delay exists between dashboard save and live routing.

*How detected:* Phase 4 step (d) test call. If the call lands but no webhook arrives, the URL did not propagate. If the call lands AND a webhook arrives at the old URL (which still exists on the deployed app since file moves do not auto-redirect), the URL was never updated.
*How recovered:* If propagation is the issue, wait 5 minutes and re-test. If propagation requires agent republish, do that in the dashboard. If old-URL webhooks are arriving, keep the old route file in place temporarily with a structured-log warning so we capture the data while we debug the dashboard.
*Mitigation in plan:* This is the highest-uncertainty item in the cutover. **Flagged for verification during execution: the Builder should test the URL change against a staging or scratch Retell agent first if one is available before doing it on the production plumber testbed.** Confidence on Retell behavior here is 80%, not 99%. If the URL change is more involved than a one-field edit, Phase 4 may need to split the URL move from the schema rename.

**4. The cutover succeeds but a script in `scripts/` references `amp_*` and breaks the next time it is run.**
There are 13+ references to `amp_*` table names across `scripts/`. Phase 4 moves the live database; Phase 5 cleans up the scripts. Between merge of Phase 4 and merge of Phase 5, any script run against the live DB will throw "relation does not exist."

*How detected:* The script fails immediately on run.
*How recovered:* Phase 5 fixes it. Until then, do not run any `scripts/*.ts` between Phase 4 and Phase 5 merge.
*Mitigation in plan:* Phase 4's PR description includes "Do not run any operational scripts until Phase 5 merges." Phase 5 should be opened as a draft PR before Phase 4 merges so the gap is minimized to hours, not days.

**5. Sentry wiring on Next.js 16 + React 19 produces build failures or runtime breakage.**
Per `AGENTS.md`, Next.js 16 has breaking changes from training-data conventions. The Sentry Next.js SDK has historically lagged Next.js majors. If `@sentry/nextjs` is incompatible with Next 16, Phase 3 stalls and the entire plan blocks behind it (because Phases 4+ depend on Sentry being installed for the observability gate per §6.2).

*How detected:* `npm run build` fails after Sentry install.
*How recovered:* Three options, in order: (a) check the Sentry changelog for a Next.js 16 compatible version (`npm view @sentry/nextjs versions`); (b) if unavailable, vendor Sentry's Node SDK (`@sentry/node`) and wire it manually without the Next.js plugin — gives error capture without the full Next.js integration; (c) defer Sentry to a post-cutover phase, but require Phase 3 to land structured logging at minimum.
*Mitigation in plan:* Per `AGENTS.md`, the Builder reads `node_modules/next/dist/docs/` before writing code. The Builder should verify Sentry compatibility BEFORE starting Phase 3 — that is a 5-minute version check. If incompatible, Phase 3 is restructured per option (b) above. Confidence on Sentry install: 85%.

### C-suite review

**CTO.** The plan's biggest risk is Phase 4's cutover. Two operations (schema rename + webhook URL change) in one window is a hard pattern to test in isolation. I want the Phase 3 pre-flight to include a test that exercises the webhook against a renamed-table fixture, not just the current-shape fixture, so the new code path is exercised before live cutover. The eight-phase sequencing is correct; the alternative (one giant PR) would be a worse risk than this plan accepts. I disagree with deferring the monorepo — short-term I agree, but I want it as ADR-006 proposed with a "no later than first marketing site or second customer surface" trigger so it does not get lost. **Resolution:** Phase 3 test fixture updated to exercise renamed-table shape; ADR-006 placeholder added to the open questions; CTO concerns addressed.

**CSO.** RLS policies and the rename landing together is non-negotiable and the plan respects this. I want explicit policy review in the Phase 4 PR: every table needs SELECT, INSERT, UPDATE, DELETE policies named, scoped to `customer_id` (the new table), with a documented service-role bypass. I also want the webhook route to NOT log raw Supabase error objects (the current code does this; §6.1 forbids it) — Phase 3 covers this but I am flagging it as a hard requirement, not nice-to-have. On Sentry: ensure no PII reaches it; the `beforeSend` filter must strip `caller_phone`, `caller_name`, `caller_email` per §4.3. **Resolution:** Phase 3 step 5 already covers PII guard in logging; Sentry `beforeSend` PII filter added as explicit verification in Phase 3.

**CFO.** I am chasing two costs. First, Sentry has a free tier (5K events/month); at AMP's current zero-traffic state we are well under. Confirm we are on the free tier and that the plan does not add a paid dependency — §8 requires my explicit sign-off for paid external deps and I have not given it. Second, the cutover window is bounded but if it slips and an inbound call is missed during the window, we burn customer trust we have not yet built. The trade-off is acceptable because the plumber testbed is an internal test agent today, not a paying customer — but the moment AMP has a paying Canadian plumber, this kind of cutover requires a different model (zero-downtime, blue-green, or scheduled per customer). Flag for the Build Phase. **Resolution:** Sentry free-tier confirmed as part of Phase 3 verification. Cutover model flagged in "What Josh will hit next" — future cutovers under paying-customer load require a different pattern.

**COO.** The manual surface in this plan is the part I worry about most. Four phases require dashboard work (Phase 1.5 Vercel, Phase 1.5 Retell/Twilio audit, Phase 4 Retell, Phase 4 Supabase apply via MCP). Each dashboard action is a place where the operating loop breaks — Josh does it once, no audit trail, no rollback automation. I want each manual dashboard step to be a single line in the PR description with a checkbox; Josh checks it as he goes; the SESSION_LOG entry for the cutover session preserves the record. I also want the Phase 4 cutover scheduled in advance (Sunday 09:00 ET is fine) and not slipped — slipping the window erodes the "bounded" property of the cutover. **Resolution:** Phase 4 PR description template includes a dashboard-step checklist; SESSION_LOG entry for the cutover session is mandatory; cutover window pinned to Sunday 2026-05-31 09:00-09:30 ET in this ADR.

**Real disagreement and resolution:** CTO wants the monorepo handled as a separate ADR (ADR-006); CSO is silent on the monorepo. CFO worries about the cutover-window risk for future paying customers; COO worries about the current cutover's manual surface. These are not in direct conflict — both COO and CFO want bounded, recorded cutover discipline; the difference is whether the discipline scales (CFO's concern). **Both resolved by** (a) recording the manual surface in PR checklists for THIS cutover, (b) flagging that future paying-customer cutovers require a different model (zero-downtime, scheduled per customer) as a Build Phase decision. CTO and the implicit "do not defer monorepo too long" position is resolved by promising an ADR-006 placeholder.

### Confidence levels (per Constitution §7.4)

This is a **Foundational decision (99% bar)** because it touches schema and security model — both explicitly named in §7.4 as Foundational.

Per-component confidence (updated 2026-05-22 per CEO approval — Phase 0 added, Phase 1.5 added, Phase numbering shifted):

- **Phase 0 (verification spike): 100% binary** — either passes (proceed to Phase 1) or surfaces a blocker (triggers ADR-003 amendment). Either way the plan moves forward in a known direction; there is no "Phase 0 fails ambiguously" outcome.
- **Phase 1 (repo hygiene + Vercel env-var unblock): 99%.** Trivial, well-understood, low blast radius. The added Vercel dashboard step is the same complexity as any other env-var configuration.
- **Phase 1.5 (decommission Claire surfaces): 95%.** Dashboard work; `claire-ai-beta.vercel.app` current state unknown carries 5% uncertainty until verified.
- **Phase 2 (migrations baseline): 95%.** Depends on faithful introspection of live schema. The drift between committed `schema.sql` and live DB is the unknown. Confidence rises to 99% after Phase 2 step 2 (the introspection step) completes.
- **Phase 3 (pre-flight infrastructure): 85% pre-spike, 99% post-spike.** Phase 0 resolves the Sentry-on-Next-16 uncertainty. Vitest + structured logger + env Zod are 99% on their own. Sentry alone is 80% pre-spike; post-spike either lifts to 99% or revises the plan via the `@sentry/node` fallback.
- **Phase 4 (cutover): 90% pre-spike, 99% post-spike.** Phase 0 resolves the Retell URL behavior uncertainty. Schema migration mechanics are 95%+. RLS policy shape is 95% (standard pattern).
- **Phase 5 (scripts reconciliation): 99%.** Pure code change, no live system touched.
- **Phase 6 (Zod + adapter): 95%.** Well-understood pattern; first adapter pattern in the repo means some shape decisions get made and may need iteration.
- **Phase 7 (index rename + cleanup): 99%.** Mechanical.

**Overall plan confidence: Pre-spike: 95%. Post-spike: 99% target, contingent on no blocker discovery.** The two named uncertainties (Sentry-on-Next-16 compatibility, Retell dashboard URL change behavior) are now resolved by Phase 0 before Phase 1 begins. If Phase 0 surfaces a blocker on either count, the plan triggers an ADR-003 amendment before any further execution. The plan no longer carries un-verified uncertainty into the cleanup.

### Trade-offs accepted

- **Eight phases means eight PRs and eight verifications across multiple sessions.** Faster than one mega-PR if anything breaks; slower if everything works. Accepted because the risk-bounded model produces eight rollback points and forces verification at each gate.
- **Monorepo restructure deferred.** Inventory item #5 (HIGH) is not addressed in this ADR. ADR-006 placeholder. Accepted because the wedge does not need it and including it doubles the blast radius of this cleanup for zero customer value.
- **Cutover window has a 30-minute customer-impact bound during which the plumber testbed is unreachable.** Acceptable because no paying customer exists yet. Not acceptable for future cutovers post-customer-acquisition; flagged for the Build Phase.
- **The plan accepts that the live Supabase project has drift from committed `schema.sql` and that drift is reconciled inside the baseline migration, not separately documented.** Accepted because the only audit trail anyone needs is "the renamed schema works"; pre-rename drift becomes irrelevant once Phase 4 ships.
- **Sentry-on-Next-16 carries the highest uncertainty in the plan and is not resolved before ADR approval.** Accepted because resolving it requires the Builder to run code; the architect cannot resolve it from inspection. Falling back to `@sentry/node` is a known-good escape valve.

### What would change this decision

This ADR would be revised before execution if:

1. The Phase 2 introspection step reveals the live Supabase schema drift is materially larger than the inventory anticipated (e.g., entire tables not in committed schema, or columns the application currently writes to that are not captured anywhere).
2. The Builder's pre-Phase-3 verification of Sentry-on-Next-16 surfaces a fundamental incompatibility that requires more than the documented fallback (e.g., `@sentry/node` itself broken on Node 20 + Next 16).
3. The Builder's pre-Phase-4 verification of Retell dashboard URL behavior surfaces that the change requires Retell agent republish (which has its own downtime implications and may require splitting Phase 4 into two windows).
4. Josh changes the cutover window or wants the plumber testbed paused entirely during cleanup (which would simplify Phase 4 by removing the "test call must succeed" gate).
5. A new ADR (e.g., a decision to launch with multiple environments — staging + prod — before the wedge ships) changes the substrate this cleanup runs against.

This ADR would be re-evaluated post-execution if any phase's verification fails in a way the plan did not anticipate. The post-failure response is a postmortem per §6.3 and a revised plan as ADR-003.1 or ADR-007 (whichever is more honest about what changed).

### Implementation implications

**Files created:**
- `.env.example` (Phase 1)
- `supabase/migrations/20260522000000_baseline.sql` (Phase 2)
- `supabase/migrations/20260522000100_rename_amp_tables_and_add_rls.sql` (Phase 4)
- `supabase/migrations/20260522010000_rename_indexes.sql` (Phase 7)
- `app/api/webhooks/retell/v1/route.ts` (Phase 4, replaces old location)
- `app/api/webhooks/retell/route.test.ts` or `app/api/webhooks/retell/v1/route.test.ts` (Phase 3)
- `lib/log.ts` (Phase 3)
- `lib/env.ts` (Phase 3)
- `lib/schemas/{seven-jsonb-schemas}.ts` (Phase 6)
- `lib/integrations/retell/index.ts` (Phase 6)
- `scripts/archive/{bind-phone,register-phone,attach-number-to-trunk}.ts` (Phase 5; existing files moved)
- Sentry config files generated by Sentry wizard (Phase 3; exact list depends on wizard output; Phase 0 may roll forward verified scratch install)

**Files modified:**
- `app/api/webhooks/retell/route.ts` → moved + table refs updated + console.* removed (Phase 3 + Phase 4)
- `scripts/{check-schema,probe-schema,check-template,create-amp-agent,audit-*}.ts` → table refs updated, Claire-era values removed (Phase 5)
- `package.json` → test scripts, db:migrate, engines field, new deps (Phases 3, 5, 6, 7)
- `tsconfig.json` → remove `"scripts/**"` exclude (Phase 5)
- `app/layout.tsx` → title metadata (Phase 7)
- `app/page.tsx` → holding page (Phase 7)
- `app/globals.css` → remove font-family override (Phase 7)
- `.gitignore` → no expected changes (Phase 1 verification only)

**Files deleted:**
- `supabase/schema.sql` (Phase 2; superseded by migrations)
- `scripts/check-calls.ts` (Phase 1)

**Live system changes (where executed):**
- **Supabase project `yxuhjxxbgbuznpoekwpj` (Phase 4 + Phase 7 via MCP `apply_migration`):** schema rename, FK drop, RLS policies, index rename.
- **Vercel project (Phase 1 manual for Preview/Development env vars; Phase 1.5 manual for Claire decommission; Phase 4 auto-deploy on PR merge):** Preview/Development env-var configuration, `claire-ai-beta` project deletion, new code deploy, env var addition for Sentry DSN (Phase 3).
- **Retell dashboard (Phase 0 manual scratch test; Phase 4 manual production update):** scratch-agent URL behavior verification, then production plumber-testbed URL update.
- **Twilio dashboard (Phase 1.5 audit only):** routing verification, no changes expected.

**State document updates:**
- `docs/DECISIONS.md` — this ADR appended on approval; potentially ADR-006 placeholder for monorepo deferral if Josh wants it tracked explicitly.
- `docs/TRIPWIRES.md` — likely a new tripwire after Phase 4 cutover (e.g., "destructive cutover under paying-customer load requires a different model"); add post-cutover, not now.
- `docs/SESSION_LOG.md` — one entry per phase-execution session (anticipated 3-5 sessions across the eight phases depending on session length).
- `docs/PROJECT_INVENTORY.md` — re-generated by Architect after Phase 8 lands; not edited by hand per §7.3.

### References

- Constitution §1.1 (schema conventions, RLS mandate)
- Constitution §1.2 (migration discipline)
- Constitution §1.3 (locked terms taxonomy)
- Constitution §2.1 (monorepo structure; deferred to ADR-006)
- Constitution §2.2 (TypeScript discipline; relevant for Phase 3 env Zod + Phase 7 Zod schemas)
- Constitution §3.2 (adapter pattern; Phase 7)
- Constitution §3.3 (webhook handling; Phase 4 URL versioning)
- Constitution §4.1 (secrets in env; Phase 1)
- Constitution §4.3 (PII, RLS, recordings; Phase 4 + Phase 3 logging guard)
- Constitution §4.5 (RLS policies in same migration as table; Phase 4 gating rule)
- Constitution §5.1 (webhook handler tests required; Phase 3)
- Constitution §6.1 (structured logging, no PII; Phase 3)
- Constitution §6.2 (Sentry; Phase 3)
- Constitution §6.3 (postmortems; required if any phase fails)
- Constitution §7.4 (tiered confidence; Foundational 99% bar)
- Constitution §7.5 (docs-only carve-out; relevant for SESSION_LOG entries during execution)
- Constitution §8 (negative space; CFO sign-off required for paid deps — Sentry is free-tier)
- ADR-001 — Orchestration model (the architectural commitment this cleanup unblocks)
- ADR-002 — AMP-Supabase separation + destructive rename ratification (the decision this ADR executes)
- ADR-004 — Wedge decision (the customer segment this cleanup unblocks the build for)
- ADR-004 Amendment (2026-05-22) — Canadian sub-$2M plumbing/electrical/HVAC sharpening
- ADR-005 — §7.5 docs-only carve-out (relevant for SESSION_LOG and Phase 6 commits)
- `docs/PROJECT_INVENTORY.md` (2026-05-13) — the source of the 27 compliance issues
- `docs/scout/2026-05-18_home-services-market.md` — customer-validation context for wedge scope
- `docs/scout/2026-05-22_avoca-competitive-deep-dive.md` — competitive context informing why cleanup speed matters

---

## ADR-006 — Monorepo Restructure (Deferred)

**Date:** 2026-05-22
**Status:** Proposed placeholder
**Decided by:** Reserved for future decision (placeholder created by ADR-003 with CEO approval, Session 006)
**Supersedes:** None
**Superseded by:** None

### Context

ADR-003 (Constitutional Cleanup Execution Plan, 2026-05-22) deferred the Constitution §2.1-mandated monorepo restructure (`apps/web`, `apps/marketing`, `packages/db`, `packages/ui`, `packages/agents`, `packages/orchestration`, `packages/shared`) to a future ADR. The deferral reasoning, recorded in ADR-003: the wedge does not need the monorepo today (one app, no marketing site yet, no second customer surface), and including the restructure in ADR-003 would have doubled the blast radius of the Constitutional cleanup for zero customer value.

This placeholder reserves the ADR-006 number and names the trigger condition so the deferral does not silently extend forever. The CTO chair in ADR-003's C-suite review specifically asked for this placeholder; this entry satisfies that ask.

### Trigger

Execute the monorepo restructure no later than the earlier of:

1. The first marketing site (`apps/marketing`) being built, OR
2. The first second customer surface (a second `apps/*` package — e.g., a customer-facing dashboard separate from the operator dashboard), OR
3. The first Build Phase milestone where adding a new package becomes load-bearing (e.g., an agent SDK that customers consume, a shared schema package that two apps depend on).

When any of these triggers fires, this ADR is upgraded from Proposed placeholder to Accepted, with a full Decision section detailing the restructure plan, sequencing, and cutover approach.

### Body

TBD when triggered. The full ADR will cover at minimum:

- Sequencing (which packages get carved out first; how the existing flat `app/`, `lib/`, `scripts/` get distributed)
- Tooling (npm workspaces vs pnpm vs Turborepo)
- Cutover approach (one PR or staged)
- TypeScript path mapping and build orchestration
- CI implications
- Per-package verification criteria
- Pre-mortem and C-suite review (per ADR-003's pattern)

### What would change this decision

This placeholder would be revised if:

1. A trigger fires (in which case the ADR is upgraded, not revised).
2. Constitution §2.1 itself is amended to drop or modify the monorepo requirement (would require a Section 9 amendment per CONSTITUTION.md).
3. A new architectural decision (e.g., splitting AMP into multiple repos rather than one monorepo) changes the substrate this ADR would operate on.

### References

- Constitution §2.1 (monorepo structure — the source of this requirement)
- ADR-003 (the cleanup plan that deferred this restructure and created this placeholder)
- `docs/PROJECT_INVENTORY.md` item #5 (HIGH compliance issue: flat repo violates §2.1)

---

## ADR-007 — Constitutional Amendment: Auto-Memory Store Discipline (Cache, Not Source of Truth)

**Date:** 2026-05-23
**Status:** Accepted
**Decided by:** CEO (Josh) directly, on the basis of the Session 008 status check audit
**Supersedes:** None (amends Constitution v1.1 → v1.2, adding Section 7.6)
**Superseded by:** None

### Context

Claude Code maintains a file-based auto-memory store at `/home/codespace/.claude/projects/-workspaces-amp/memory/`, outside the repo. The harness auto-loads `MEMORY.md` (the index) into every conversation's system context; individual memory files are read on demand. As of Session 008 the store contains four files: `MEMORY.md`, `adr_status.md`, `claire-is-dead.md`, and `claude-for-small-business.md`.

Session 008 surfaced a latent governance question: what is the relationship between this external store and the in-repo `docs/` system? Left undefined, the store can drift in either of two directions: (a) become a parallel knowledge base where principles, decisions, and project facts originate outside the repo and never get promoted in — a foundation-corroding pattern of the kind ProScore paid for, recurring in a new medium; or (b) become a stale snapshot the agent over-trusts when the repo has moved on, undermining the "the repo is the source of truth" discipline Constitution Section 7.3 already establishes for state documents.

The audit performed in Session 008 (covering all four current memory files against `docs/DECISIONS.md`, `docs/SESSION_LOG.md`, `docs/CONSTITUTION.md`, and `docs/scout/`) found zero auto-memory-only content. The store is functioning correctly as a cache today. This ADR formalizes that posture so the discipline does not depend on every future Session catching the drift in audit.

### Decision

Amend Constitution v1.1 to v1.2 by adding Section 7.6 ("Auto-memory store discipline"). The rule:

- The auto-memory store is allowed to mirror or summarize content from `docs/` for fast context loading.
- The auto-memory store is NOT a separate documentation system.
- Any operating principle, decision, or project fact that exists only in auto-memory and not in `docs/` is a drift bug to fix immediately by promoting the content into the relevant repo file (`DECISIONS.md`, `SESSION_LOG.md`, `CONSTITUTION.md`, or `TRIPWIRES.md`, as appropriate).
- The repo is the source of truth. Auto-memory is the cache. When the two disagree, the repo wins.
- New knowledge is written into `docs/` first; the auto-memory entry, if any, is a follow-on summary with a pointer back to the canonical source.

### Alternatives considered

**Option B: Treat auto-memory as a peer documentation system with its own scope.** Rejected. Two parallel doc systems means two places to keep in sync, two places to audit, and inevitable divergence. Constitution Section 7.3 already names the seven in-repo state documents as the canonical set; adding an off-repo eighth doc surface would silently weaken that.

**Option C: Ban auto-memory entirely.** Rejected. The store demonstrably saves context-loading time on every session start — `MEMORY.md` index auto-loads into system context, and three of the four current entries (`adr_status.md`, `claire-is-dead.md`, `claude-for-small-business.md`) compress multi-page repo content into a paragraph the agent can act on immediately. The cost of re-deriving that compression every session, from a docs tree that will only grow, is real. Cache-with-discipline beats no-cache.

**Option D: Allow auto-memory-only operating principles for "personal" or "session-scoped" notes.** Rejected. The category is undefined and self-expanding. Any principle the agent applies to future decisions is by definition load-bearing; "personal" is a backdoor that erases the audit boundary the rest of the Constitution depends on.

### Reasoning

1. **The "repo is source of truth" posture is non-negotiable for a system that depends on the next agent picking up coherent state.** Section 7.3 names the canonical documents; this amendment closes the off-repo loophole.
2. **Caches are useful; un-disciplined caches are foundation-corroding.** The pattern is identical to the ProScore lesson about hardcoded values and undocumented conventions — small, harmless-looking off-repo state that the team starts to rely on, that no one promotes back into the canonical record, and that diverges silently over months until the only authoritative source is whatever's loaded into someone's head.
3. **The audit in Session 008 was clean.** Formalizing the rule now, while there is zero drift, is cheap. Doing it after the first drift incident would mean recovering content from out-of-repo state under pressure — exactly the recovery work the Constitution exists to prevent.
4. **Memory entry expiration is now well-defined.** A memory entry that points at content removed from `docs/` is by definition stale and should be removed or updated. A memory entry that contains new content not in `docs/` is by definition a drift bug. Both states are mechanically detectable by future audits.

### Trade-offs accepted

- **The agent gives up the ability to record principles in memory-only form.** Mitigation: this is the point of the rule. Any principle worth applying is worth writing into `docs/`.
- **Memory authoring becomes a two-step write (docs first, then memory).** Mitigation: in practice the agent already writes the docs change as part of session work; the memory entry is a summary, not a duplicate authoring effort. The marginal cost is small.
- **Audits become a recurring operation.** Mitigation: built into `/session-start` and `/session-end` over time as a checklist item if drift recurs; for now, an on-demand audit (like the one performed in Session 008) suffices. If drift becomes a pattern, a follow-on ADR can codify the audit as a structural step.

### What would change this decision

We would revisit ADR-007 if:

1. The auto-memory mechanism itself materially changes (Anthropic ships a different memory model that, e.g., is no longer file-based or is no longer agent-visible the way it is today).
2. A genuine, repeatable category of "memory-only" content emerges that adds value without compromising the source-of-truth posture — e.g., transient per-session context that genuinely cannot live in `docs/`. The current four files do not exhibit this category.
3. Operating multiple agents (per Section 7.1) creates per-agent memory stores whose interaction with the shared repo needs explicit governance beyond what this rule provides.

### Implementation implications

This amendment touches:

- `docs/CONSTITUTION.md` — version bumped to v1.2, Section 7.6 added
- `docs/DECISIONS.md` — this ADR appended

Both files are under `docs/`, so this amendment is itself eligible for the Section 7.5 documentation-only carve-out and commits direct-to-main as a single docs-only commit.

The Session 008 audit confirming zero current drift is the inaugural exercise of the rule, performed before the rule landed. Future audits — whether on-demand, on session-start, or on session-end — follow the same shape: enumerate the memory files, confirm each claim is represented in `docs/`, promote anything that is not.

### References

- Constitution v1.2, Section 7.6 (the rule this ADR establishes)
- Constitution Section 7.3 (the canonical in-repo state documents)
- Constitution Section 9 (the amendment procedure followed to land this change)
- Session 008 audit (performed 2026-05-23; result: zero auto-memory-only content across all four files at the time of audit)

---

## ADR-008 — Naming Convention for AMP (Three Layers)

**Date:** 2026-05-23
**Status:** Accepted
**Decided by:** CEO (Josh), drafted by the Architect
**Supersedes:** None (extends Constitution §1.3 locked domain terms into a broader naming system; bumps Constitution v1.2 → v1.3)
**Superseded by:** None

### Context

Constitution §1.3 locks the eight domain terms that AMP uses for entities (customer, agent, agent_type, conversation, end-user, subscription, workspace, handoff). It is silent on the broader naming surface: environment variables, vendor credentials, app-level configuration, file paths, display names, branch names, PR titles, sub-agent names, slash command names. Without an explicit convention, names accrete in whatever shape the first commit happens to use, drift over time, and force later sessions to choose between rename sweeps (expensive) or living with inconsistency (foundation-corroding in the ProScore pattern).

Two specific drift incidents motivate this ADR:

1. **Session 007 Retell agent rename.** The live agent was named "AMP Plumber - Default" — a singular vertical ("Plumber") at a position in the namespace that will hold many verticals (per ADR-004 amendment: Plumbing + Electrical + HVAC; Roofing fast-follow). Session 007 renamed the agent to "AMP - Plumbing - V1," making vertical, intent, and version legible. But the env-var names (`AMP_PLUMBER_AGENT_ID`, `AMP_PLUMBER_LLM_ID`) still encode "Plumber" as a singular noun in AMP's identifier namespace, and `.env.local` still uses that shape.

2. **Mixed prefixing in `.env.local`.** Today the file contains both `AMP_PLUMBER_*` (AMP-owned identifier) and `TWILIO_PHONE_NUMBER` (which encodes AMP's own phone number under a vendor prefix as if Twilio issued it to us — it is in fact our number; Twilio is the provider). This mixed posture is benign at one variable but is the failure mode that will compound as the env-var surface grows.

The convention this ADR establishes is meta — it governs the names of names. Once locked, the Architect's plans, the Builder's commits, the Reviewer's audits, and every future ADR all enforce it.

### Decision

**The Convention — three layers.**

**Layer 1. Things that belong to AMP** (agents, customers, conversations, test resources, internal IDs).

- Format: `AMP_<THING>_<MODIFIER>_<VERSION>`
- Examples:
  - `AMP_AGENT_DEFAULT_V1`
  - `AMP_LLM_DEFAULT_V1`
  - `AMP_TEST_ORG_ID`
  - `AMP_PHONE_NUMBER`

**Layer 2. Vendor credentials** (API keys, tokens, secrets the vendor issued to us).

- Format: `<VENDOR>_<CREDENTIAL>`
- No `AMP_` prefix. These live in the vendor's namespace, not ours.
- Examples:
  - `RETELL_API_KEY`
  - `TWILIO_AUTH_TOKEN`
  - `TWILIO_ACCOUNT_SID`
  - `SUPABASE_SERVICE_ROLE_KEY`
  - `ANTHROPIC_API_KEY`

**Layer 3. App-level configuration** (URLs, public keys, environment switches).

- Format: `AMP_<CONFIG>` or framework-required (e.g., `NEXT_PUBLIC_*` for browser-exposed Next.js values).
- Examples:
  - `NEXT_PUBLIC_APP_URL`
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`

**Decision rule — which layer does a name belong in?**

Ask: is this a credential the vendor issued me, or is it an ID inside my own system?

- Vendor-issued credential → Layer 2.
- AMP's own identifier or resource → Layer 1.
- Application config or framework-required name → Layer 3.

**Enforcement — guideline-strength.**

- Default: every new name conforms to the convention.
- Deviation allowed when justified in a code comment or commit message explaining why the convention does not fit.
- Reviewer sub-agent must flag any non-conforming name in a PR and either accept the written justification or request a rename.
- Exceptions multiply silently if no justification is required, so the justification step is mandatory even when the deviation is small.

**Scope — what the convention governs.**

1. Environment variable names (`.env.local`, `.env.example`, Vercel env vars).
2. Database table names, column names, enum values (extends Constitution Section 1.3 locked terms).
3. Code file and folder names (`lib/integrations/<vendor>/` for Layer 2 adapters, `lib/agents/` and `lib/customers/` for Layer 1 domain code).
4. Document filenames (`docs/scout/YYYY-MM-DD_topic.md`, `docs/DECISIONS.md`, etc. — date-first when applicable).
5. Retell agent and LLM display names (e.g., "AMP - Plumbing - V1" — vertical name is descriptive content, not a variable name violation).
6. Sub-agent names in `.claude/agents/` and slash command names in `.claude/commands/`.
7. Branch names (`session-NNN-<topic>` or `phase-N-<topic>`).
8. PR titles, commit message conventions.

### Alternatives considered

**Option B: Defer the convention until the first vertical-multiplication forces it.** Rejected. ADR-004 amendment already commits AMP to plumbing + electrical + HVAC + roofing as parallel verticals; the singular "Plumber" in env vars is already obsolete. Deferring means the rename sweep grows by every variable added between now and the trigger, and the convention itself drifts further from "decide once" in the meantime.

**Option C: Single global prefix for everything (`AMP_*` for all variables including vendor credentials).** Rejected. Erases the conceptual boundary between "what the vendor issued to me" and "what I named." A future engineer reading `AMP_RETELL_API_KEY` cannot tell at a glance whether AMP minted that key or Retell did. The convention rule that "vendor names belong to vendors" preserves the audit boundary and is consistent with ADR-001 (AMP owns orchestration; vendors own their own surfaces).

**Option D: Strict enforcement with CI-level rejection of non-conforming names.** Rejected as premature. Constitution §8 ("No frameworks added to solve a problem that doesn't exist yet") applies. Reviewer-flagged-with-mandatory-justification gives 95% of the benefit at zero infrastructure cost. If the discipline degrades, a later ADR can codify CI enforcement.

**Option E: Use the convention only for env vars and leave the rest alone.** Rejected. The drift cost is structural; bounding the convention to env vars leaves seven other naming surfaces uncovered (table/column names, file paths, display names, sub-agent names, branch names, PR titles, commit messages). The convention is meta exactly because it must apply to all surfaces uniformly to be load-bearing.

### Reasoning

1. **Vendor names belong to vendors.** A credential `RETELL_API_KEY` is owned by Retell — they issued it. An identifier `AMP_AGENT_DEFAULT_V1` is owned by AMP — we minted it. Encoding that ownership in the prefix makes the namespace audit boundary mechanical instead of conceptual. This is consistent with ADR-001 (AMP owns the orchestration brain; vendor surfaces remain vendor surfaces).

2. **"Plumber" as a singular noun is wrong at the prefix slot.** Per ADR-004 amendment (2026-05-22), AMP's vertical scope is Plumbing + Electrical + HVAC + Roofing (fast-follow). Encoding a single vertical as a noun in AMP's identifier namespace (`AMP_PLUMBER_*`) is the kind of foundation-locking decision that costs weeks to undo later. The Session 007 Retell display name rename ("AMP - Plumbing - V1") already established the right shape: vertical as a descriptive modifier, not as a noun at the prefix slot.

3. **Three layers maps to a real distinction in the codebase.** `lib/integrations/<vendor>/` already exists as a Constitution §3.2 mandate; `lib/agents/` and `lib/customers/` will exist when the orchestration layer is built (Constitution §10.1). The three-layer naming convention falls out of the three-layer code architecture — they are the same partition.

4. **Guideline-strength enforcement with mandatory justification is the right default.** Strict enforcement creates fights over edge cases; no enforcement is no convention. Requiring a written reason for any deviation forces the deviation through conscious thought and into the git record, where it can be reviewed when the convention is next revised.

### Trade-offs accepted

- **Existing names that do not conform must be renamed.** Mitigation: the rename sweep is scoped, queued, and timed (see Pending follow-up appended to SESSION_LOG.md in the same commit as this ADR). It is one focused session, not an ongoing migration.
- **`NEXT_PUBLIC_*` framework names break the Layer 3 `AMP_<CONFIG>` shape.** Acceptable: the framework requires the `NEXT_PUBLIC_` prefix for browser-exposed values, and overriding the framework convention for purity is the kind of low-value rigidity Constitution §8 prohibits. Layer 3 explicitly allows framework-required names.
- **The Reviewer must hold the line on the justification step.** Without it, the convention degrades to "whatever shape the first commit happened to use" within a quarter. Mitigation: the Reviewer's job description (`.claude/agents/reviewer.md`) gets a checklist line on the next pass, and any non-conforming name in a PR without a written justification is grounds for refusal.

### What would change this decision

We would revisit ADR-008 if:

1. The three-layer split itself proves wrong — for example, a fourth load-bearing category emerges (today: AMP-owned, vendor-issued, app config; tomorrow: ?).
2. A future ADR formally restructures AMP into multiple repos or multiple Vercel projects, in which case the convention may need a project-scope dimension that today's single-repo posture does not have.
3. Strict CI-level enforcement becomes worth the infrastructure cost — e.g., after multiple rename sweeps motivated by guideline-strength enforcement failing in practice.
4. A vendor name itself collides with an AMP name in a way the prefix rule cannot disambiguate.

### Constitutional impact

Constitution §1.3 is extended to reference this ADR. Section 1.3's locked domain terms (customer, agent, conversation, etc.) are the Layer 1 vocabulary; this ADR governs the broader naming system that surrounds them. Constitution version bumped v1.2 → v1.3 in the same commit as this ADR.

### Implementation implications

This amendment touches:

- `docs/DECISIONS.md` — this ADR appended
- `docs/CONSTITUTION.md` — §1.3 updated with a reference sentence; version bumped v1.2 → v1.3
- `docs/SESSION_LOG.md` — Pending follow-up appended for the rename sweep

All three files are under `docs/`, so this amendment commits direct-to-main as a single docs-only commit per Section 7.5.

The rename sweep itself is NOT executed in this commit. The sweep touches code (`.env.local` is local-only but `.env.example` is committed; code references inside `lib/`, `app/`, `scripts/`), Vercel env vars, and Retell agent metadata — none of which fall under the §7.5 carve-out. The sweep is its own session, queued in SESSION_LOG.md and scheduled to run after ADR-003 Phase 1.5 (Claire decommission) and before ADR-003 Phase 4 (bring-up).

### References

- Constitution §1.3 (locked domain terms — the Layer 1 vocabulary this ADR extends)
- ADR-001 (AMP owns orchestration — vendor names belong to vendors, not AMP — the reasoning behind the Layer 2 / Layer 1 split)
- ADR-004 amendment (2026-05-22) — Plumbing + Electrical + HVAC as parallel verticals; the ADR that obsoletes "Plumber" as a singular noun in the prefix slot
- Session 007 (2026-05-22) — Retell agent rename from "AMP Plumber - Default" to "AMP - Plumbing - V1"; the inaugural exercise of the convention before the convention was written down
- Constitution Section 9 (the amendment procedure followed to land this change)

### Status (appended 2026-05-23, Session 010 — Rename sweep executed)

The rename sweep queued by this ADR is **executed** as of 2026-05-23. The three explicit renames specified in the body:

- `AMP_PLUMBER_AGENT_ID` → `AMP_AGENT_DEFAULT_V1` ✓
- `AMP_PLUMBER_LLM_ID` → **deleted** (not renamed; Phase 1 audit confirmed unused in code — see Session 010 entry for the reasoning)
- `TWILIO_PHONE_NUMBER` → `AMP_PHONE_NUMBER` ✓ (Layer 1 reclassification: it is AMP's number, Twilio is the provider)

Plus one display-name fix surfaced by the audit clause: `scripts/bind-phone.ts:17` nickname `'AMP Production - Plumber'` → `'AMP Production - Plumbing'` (singular-noun-as-vertical pattern fix per ADR-008 §5).

Three Claire-trunk scripts deleted as a side-effect of the rename sweep (`scripts/register-phone.ts`, `scripts/audit-trunk.ts`, `scripts/attach-number-to-trunk.ts`) — they hardcoded resources deleted in Phase 1.5 and would have returned Twilio 404 if executed.

Audit-clause findings recorded in Session 010 entry and the PR body: `lib/{twilio,retell,supabase}.ts` flat layout violates ADR-008 §3 (defer to a structural restructure); `scripts/create-amp-agent.ts` lines 9-11 hardcode vertical-scope choices (defer to Phase 4 redraft / ADR-004 amendment scope).

Branch: `rename-sweep-adr-008`. The `.env.example` rename is folded into PR #5 (Phase 1 repo hygiene) rather than this PR because PR #5 creates that file. Vercel dashboard work for the renamed env vars is pending CEO execution per the rename-sweep PR body.

Constitution v1.3 (the version bumped when this ADR landed) is unchanged by this status update; the rename sweep is an implementation of ADR-008, not an amendment to it.
