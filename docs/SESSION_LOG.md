# AMP — Session Log

Rolling log of the last 10 AMP work sessions. The `/session-start` command reads this file to surface open items from previous sessions. The `/session-end` command appends to this file.

When this file exceeds 10 entries, the oldest entries are archived to `docs/archive/session-log/{year}-{month}.md` and removed from this file.

---

## Session 000 — Foundation Phase complete
**Date:** 2026-05-12
**Duration:** Multi-hour PM/Architect session with CEO
**Participants:** PM/Architect (Claude), CEO (Josh)

### What happened
- AMP product vision clarified as multi-agent platform serving any professional business
- Orchestration model decided: AMP owns the brain (Option A) — logged as ADR-001
- Foundation documents drafted and ratified:
  - NORTH_STAR.md (v1)
  - CONSTITUTION.md (v1)
  - RUNTIME_ARCHITECTURE.md (v1)
  - OPERATING_RHYTHM.md (v1)
  - DECISIONS.md (ADR-001 logged)
  - TRIPWIRES.md (14 starter + 4 predictive tripwires)
  - SESSION_LOG.md (this file)
  - README.md (system orientation document)
- Ten sub-agents installed in `.claude/agents/`:
  - Core team: architect, builder, reviewer
  - Specialists: voice-qa, researcher, scout, designer, customer-success, marketing, security
- Five slash commands installed in `.claude/commands/`:
  - session-start, plan, build, review, session-end

### What got decided
- AMP is solely Josh's company (no partners)
- $1M ARR target in 12 months after AMP becomes primary (post-ProScore launch)
- Parallel-then-primary commitment: AMP in foundation mode until ProScore launches, full focus after
- Wedge decision deferred to ADR-002 with full market analysis
- Orchestration architecture: AMP-owned brain (Option A, ADR-001)

### What's open for next session
- Run inventory on `congenial-halibut` Codespace to surface what exists in `app/`, `lib/`, `scripts/`, `supabase/`
- Document inventory findings in `docs/PROJECT_INVENTORY.md`
- Update foundation docs to v1.1 based on inventory reality
- Begin ADR-002 research (wedge selection)
- Begin thinking about ADR-003 (integration architecture — how agents plug into customers' digital assets)

### What needs Josh
- Eventually: read the four foundation documents and gut-check for anything that feels off
- Eventually: input on Runtime Architecture Section 9 open questions (orchestration framework choice, model selection per agent)
- Active focus on ProScore launch in the next 2-4 weeks; AMP foundation work continues in the gaps

### Tripwires fired
None — this was a foundation session, no code touched

### Constitution version at session start: N/A (didn't exist)
### Constitution version at session end: v1

### Notes for future-Claude
The repo (`congenial-halibut`) starts with minimal scaffolding — CLAUDE.md is 11 bytes (just a pointer to AGENTS.md), AGENTS.md is 327 bytes (a generic Next.js 15 warning). No inherited assumptions to fight. The `app/`, `lib/`, `scripts/`, and `supabase/` folders contain "feat: initial AMP scaffold" commits but the contents have not been audited. The Vercel deployment at `claire-ai-beta.vercel.app` is inherited from the Claire OS era and its current state is unknown — this is part of what the inventory will surface.

---

## Session 001 — Codespace inventory + ADR-002
**Date:** 2026-05-13
**Duration:** ~60 minutes
**Participants:** Architect (Claude), CEO (Josh)

### What happened
- Architect produced `docs/PROJECT_INVENTORY.md` — first-ever inventory of the AMP repo
- 27 compliance issues catalogued against the Constitution (4 BLOCKING, 9 HIGH, 7 MEDIUM, 7 LOW)
- Josh answered all 8 open questions surfaced by the inventory
- ADR-002 logged: AMP owns its own Supabase project (`yxuhjxxbgbuznpoekwpj`); `amp_` prefix and `proscore_provider_id` FK to be removed; `claire-ai-beta.vercel.app` decommissioned

### What got decided
- **ADR-002:** AMP-Supabase separation from ProScore. Destructive rename (no copy-and-migrate). Decommission `claire-ai-beta.vercel.app`.
- **Q4 (feeds ADR-003):** rename `amp_calls` to `conversations` per Section 1.3
- **Q6 (feeds ADR-003):** keep `appointments` and `alerts` as AMP-specific extensions (rename, don't drop)
- **Q7 (feeds ADR-003):** version Retell webhook to `/api/webhooks/retell/v1/` during the cleanup; update Retell dashboard URL at the same time
- **Q8 (feeds ADR-003):** preserve the Claire-era Retell agent, Retell LLM, and Twilio number — they are the active AMP plumber testbed

### What got deferred
- The cleanup execution itself — ADR-003 will plan it next session
- All 27 compliance items from the inventory remain open until ADR-003 lands and execution begins
- Wedge selection (previously slotted as ADR-002 in NORTH_STAR.md) bumps to whatever number is next after ADR-003
- NORTH_STAR.md still lists deferred ADR placeholders (ADR-002 wedge, ADR-003 pricing, etc.) that are now stale — not corrected this session; will refresh when NORTH_STAR.md is next revised

### What got blocked
- Nothing. Discovery/decision session; no code touched.

### What's open for next session
- **ADR-003 (Constitutional cleanup plan):** the work plan for executing the inventory's remediation. Must cover at minimum: (a) schema rename + FK drop per ADR-002, (b) migrations baseline (Section 1.2), (c) RLS policies for every table (Section 4.5), (d) `.env.example` (Section 4.1), (e) webhook to `/v1/`, (f) decision on monorepo restructure timing, (g) Vercel decommission verification step, (h) handling of `scripts/check-calls.ts` (untracked) and `.claude/settings.local.json` (untracked, not gitignored — should be added to `.gitignore`).
- Begin executing the cleanup once ADR-003 is approved

### What needs Josh
- Approve ADR-003 at the start of next session before any code is touched
- Decide cleanup PR strategy (one atomic PR vs. staged) — recommendation will come with ADR-003
- Confirm acceptable cutover window for the destructive rename (the Retell webhook is live and will have downtime during the rename + URL change)

### Tripwires fired
None — discovery/decision session, no code touched

### Constitution version at session start: v1
### Constitution version at session end: v1 (no amendments)

### Notes for future-Claude
The `docs/PROJECT_INVENTORY.md` file is the architect's snapshot at 2026-05-13. Per Constitution Section 7.3, it is generated-on-demand and never edited by hand. Re-generate (overwriting) only when materially out of date with reality. The 27 compliance issues catalogued there are the input to ADR-003.

The Architect sub-agent does not have the Write tool; for documents the Architect "generates on demand," the main thread is the scribe. Today's flow worked: Architect produced the inventory body in its response, main thread committed it via Write.

`scripts/check-calls.ts` and `.claude/settings.local.json` are still untracked from Session 000. Both are flagged in the inventory and handled in ADR-003 (commit-or-delete decision plus gitignore fix). Do not commit them ad hoc; let ADR-003 decide.

The `amp_` prefix and `proscore_provider_id` FK survive in the repo until ADR-003 executes. Any new code that touches the schema before then must reference the existing `amp_*` names — not the planned post-rename names — to avoid creating broken references mid-cleanup.

### Postmortem (appended 2026-05-15)

SECURITY INCIDENT (resolved): PROJECT_INVENTORY.md included five live secrets read from .env.local. GitHub push protection blocked the leak before it reached the remote. All five secrets rotated externally; exposed values are dead. File scrubbed, commit amended, pushed clean. ROOT CAUSE: no prompt-level rule prohibited agents from reproducing .env contents in output. FOLLOW-UP: add T-006 and T-007 to TRIPWIRES.md next session. NOTE: .claude/settings.local.json added to .gitignore during cleanup. scripts/check-calls.ts remains untracked, deferred to ADR-003.
