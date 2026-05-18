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

---

## Session 002 — Security incident cleanup
**Date:** 2026-05-15
**Duration:** ~30 minutes
**Participants:** Main-thread Claude, CEO (Josh)

### What happened
- `/session-start` opened the session; orientation surfaced that Session 001's commit `64ef65d` had been blocked by GitHub Push Protection and was sitting locally unpushed.
- Josh identified the cause: the Architect-generated `docs/PROJECT_INVENTORY.md` from Session 001 reproduced five live secret values it had read from `.env.local` (Retell API key, Twilio auth token, Twilio account SID, Supabase anon key, Supabase service role key). All five were rotated externally before this session began, so the exposed values are dead.
- `.env.local` confirmed not tracked (gitignored at `.gitignore:34` via `.env*`).
- Five lines (`docs/PROJECT_INVENTORY.md` lines 160–164) replaced with redacted markers; non-secret env entries (`TWILIO_PHONE_NUMBER`, `NEXT_PUBLIC_APP_URL`, `AMP_PLUMBER_AGENT_ID`, `AMP_PLUMBER_LLM_ID`, `AMP_INTERNAL_TEST_ORG_ID`) preserved.
- Repo-wide credential-pattern scan against all tracked files came back clean across five patterns (`key_…`, `sk_(live|test)_…`, `pk_(live|test)_…`, `AC[hex]{32}`, `eyJ…` JWTs).
- First amend attempt (`git add -A`) overreached and pulled in `.claude/settings.local.json` and `scripts/check-calls.ts` — both flagged in Session 001's "let ADR-003 decide" directive. Rolled back via `git rm --cached` + re-amend.
- `.claude/settings.local.json` added to `.gitignore` so it stops re-appearing in `git status`. `scripts/check-calls.ts` left untracked, fate still deferred to ADR-003.
- Postmortem appended to Session 001 entry above.
- Final amended commit `f24c2f5` contains exactly four files: `.gitignore`, `docs/DECISIONS.md` (ADR-002, original Session 001 content), `docs/PROJECT_INVENTORY.md` (scrubbed), `docs/SESSION_LOG.md` (postmortem).
- Session 001's blocked commit `64ef65d` orphaned in reflog.

### What got decided
- `.claude/settings.local.json` is per-machine config and gitignored permanently. Recorded in `.gitignore` and the Session 001 postmortem. Not a full ADR — too narrow.

### What got deferred
- **T-006 and T-007** (the new tripwires this incident exposes) to be drafted next session. Covers: (a) prohibition on reproducing `.env` contents in agent output, and (b) Architect inventory output must redact secret values by default.
- All Session 001 open items remain open (ADR-003, the wedge ADR, etc.) — this session diverted to incident response and did not advance them.

### What got blocked
- `git push origin main` from inside the session intercepted by Claude Code's auto-mode guardrail (blocks direct push to default branch). Josh ran the push manually mid-session; `origin/main` is now at `f24c2f5`. The Session 002 entry commit (`07abdc6`, this commit) is the one remaining unpushed at session-end.

### What's open for next session
- **Verify push landed** on `origin/main` (commit `f24c2f5` on top of `d98c799`, with `64ef65d` orphaned).
- **Draft T-006 and T-007** in `docs/TRIPWIRES.md` per the Session 001 postmortem follow-up. T-006: prohibit any reproduction of `.env*` contents in agent output. T-007: Architect inventories that read secret-bearing files must redact values by default and emit only key names + presence/rotation status.
- **ADR-003 (Constitutional cleanup plan)** — still the load-bearing deliverable Session 001 queued.
- All other Session 001 open items remain open (cleanup-PR strategy decision, cutover window for the destructive rename, NORTH_STAR.md ADR-placeholder numbering refresh).

### What needs Josh
- Run `git push origin main` once more to land the Session 002 entry commit (`07abdc6`). The rewritten Session 001 commit (`f24c2f5`) is already on the remote.
- Approve ADR-003 at the start of next session before any cleanup code is touched (carryover from Session 001).

### Tripwires fired
- **T-004 (Constitution violations)** — retroactively, Session 001's `PROJECT_INVENTORY.md` violated Constitution §4.1 ("Secrets… Never in committed files") and §6.1 ("We do not log… secrets"). The violation was not detected by the agent at write-time; it was caught by GitHub Push Protection at the network boundary. This is the failure mode T-006 and T-007 are designed to prevent.

### Constitution version at session start: v1
### Constitution version at session end: v1 (no amendments)

### Notes for future-Claude
The Architect sub-agent has Read access to the working tree and will read `.env.local` if asked to inventory environment configuration. Until T-006 and T-007 are codified, the main thread is the only check against secret reproduction in Architect output. Josh's external rotation of all five exposed secrets is what made this incident recoverable; the next one may not be.

The post-incident commit hash is `f24c2f5`. The blocked, orphaned commit was `64ef65d`. If anyone is reading this and sees `64ef65d` referenced anywhere, it never reached the remote and was rewritten — do not try to recover it; it carries the leak.

---

## Session 003 — ADR-004 wedge decision + T-205 tripwire
**Date:** 2026-05-17
**Duration:** ~30 minutes
**Participants:** Main-thread Claude, CEO (Josh)

### What happened
- Verified that ADR-004, T-205, and the Scout brief (`docs/scout/2026-05-17_claude-for-small-business.md`) had been drafted in a prior pass and were sitting uncommitted on the stale `session-001-tripwires-followup` branch.
- Confirmed ADR-004 covers all six commitments Josh specified: (1) wedge = customer-facing channels, voice first; (2) AMP is not a Cowork/CSB plugin; (3) first vertical = home services (HVAC, plumbing, electrical, roofing, GC) with voice agent lead; (4) no horizontal back-office for ≥12 months (re-evaluate 2027-05-17); (5) T-205 predictive tripwire scoped to the customer-facing real-time category boundary; (6) kill-criterion #4 explicitly NOT triggered as of 2026-05-17.
- Confirmed Anthropic announcement URL (`https://www.anthropic.com/news/claude-for-small-business`) and Scout brief path are both cited in the ADR.
- Created new branch `session-002-wedge-adr-004` off `origin/main` (which was at `5efad18` — Session 001 follow-up PR #2 had already merged).
- Staged exactly 3 files by name per T-008 discipline: `docs/DECISIONS.md`, `docs/TRIPWIRES.md`, `docs/scout/2026-05-17_claude-for-small-business.md`. `scripts/check-calls.ts` left untracked — exactly the situation T-008 was created to prevent.
- Committed (`44a8103`) and pushed.
- Opened PR #3: https://github.com/joshjgrills-svg/AMP/pull/3

### What got decided
- **ADR-004** (now committed, awaiting Josh merge): see DECISIONS.md lines 143-228. Vertical wedge, product-category commitment, and 12-month back-office embargo recorded.

### What got deferred
- **ADR-003 (Constitutional cleanup plan)** — still the load-bearing deliverable; carried over from Sessions 001 and 002.
- **`scripts/check-calls.ts` fate** (commit or delete) — explicitly deferred to ADR-003. Still untracked.
- **NORTH_STAR.md placeholder ADR-number refresh** — still stale; the ADR-002 reservation note in DECISIONS.md is the authoritative correction until NORTH_STAR.md is next revised.

### What got blocked
- Nothing.

### What's open for next session
- Josh reviews and merges PR #3.
- ADR-003 (Constitutional cleanup plan) drafted and approved before any cleanup code is touched.
- All Session 001/002 carryover (cleanup PR strategy, cutover window for the destructive rename, NORTH_STAR.md numbering refresh).

### What needs Josh
- **Review and merge PR #3**: https://github.com/joshjgrills-svg/AMP/pull/3 (3 files, +247 lines).
- Approve ADR-003 at the start of next session.

### Tripwires fired
- **T-008 (preventive)** — the temptation to use `git add -A` to sweep the working tree was avoided by staging the three intended files by name. `scripts/check-calls.ts` correctly stayed out of the commit. The tripwire functioned as designed.

### Constitution version at session start: v1
### Constitution version at session end: v1 (no amendments)

### Notes for future-Claude
The branch is `session-002-wedge-adr-004` (Josh's naming) but this is the **third** SESSION_LOG entry — Sessions 000, 001, 002 already exist. The "Session 002" branch and commit naming reflects Josh's view that the 2026-05-15 security-cleanup entry (currently logged as Session 002) was really Session 001 incident response, not a fresh session of new work. The SESSION_LOG stays append-only; the branch name is the historical record. Do not retroactively renumber.

ADR-004 was drafted in a prior pass (already in the working tree before this session opened); this session's role was to (a) verify its content, (b) move it onto a clean branch, (c) commit exactly the intended 3 files, (d) push, (e) open the PR. The drafting work is preserved in the file itself.

`scripts/check-calls.ts` remains untracked at session end. Do not commit it ad hoc; let ADR-003 decide.

---

## Session 004 — Workflow amendment (Constitution v1.1, ADR-005)
**Date:** 2026-05-17
**Duration:** ~30 minutes
**Participants:** Main-thread Claude, CEO (Josh)

### What happened
- Josh asked to amend the workflow so documentation-only changes stop going through PRs while code changes keep the human gate.
- Constitution amended **v1 → v1.1** per the Section 9 procedure: new **Section 7.5 ("PR discipline and the documentation carve-out")** added.
- The rule: changes confined to `docs/` may commit directly to `main` without a PR; any change touching application code, schema, configuration, `.claude/`, or anything outside `docs/` still requires a feature branch, PR, Reviewer audit, and Josh's merge approval. **Path-scoped, not intent-scoped** — a single non-`docs/` file makes the entire change mixed.
- **ADR-005** recorded in `docs/DECISIONS.md` per Section 9.
- `.claude/commands/session-end.md` Step 3 rewritten to branch on session type.
- `.claude/agents/builder.md` "no direct push to main" rule amended.
- `.claude/agents/reviewer.md` special case added: docs-only direct commits are advisory-only for the Reviewer.
- Branch `session-004-workflow-amendment` created off `origin/main` (independent of PR #3). 5 files staged by name (T-008), committed (`fc0efff`), pushed.
- **PR #4 opened:** https://github.com/joshjgrills-svg/AMP/pull/4

### What got decided
- **ADR-005:** Documentation-only changes skip the PR gate. See DECISIONS.md for full rationale, alternatives, trade-offs, and what-would-change criteria.

### What got deferred
- **`docs/OPERATING_RHYTHM.md` update** — lines 22-30 list "Josh approves the PR" as a mandatory session step. This is now stale for docs-only sessions but intentionally NOT fixed in PR #4. After PR #4 merges, the OPERATING_RHYTHM fix is itself docs-only and becomes the **first exercise of the new §7.5 carve-out** — committed directly to main, no PR. Flagged in ADR-005.
- All prior carryover: **ADR-003 (Constitutional cleanup plan)** remains the load-bearing next deliverable; the 27 inventory issues from Session 001 remain open until ADR-003 lands.

### What got blocked
- Nothing at write-time. PR #4 hit a trivial merge conflict with `main` after PR #3 merged (both PRs append to `docs/SESSION_LOG.md` and `docs/DECISIONS.md`); resolved by rebasing PR #4 onto the post-PR-#3 main and keeping both sets of entries in chronological order.

### What's open for next session
- **Update `docs/OPERATING_RHYTHM.md`** as the first §7.5 direct-to-main commit.
- **ADR-003 (Constitutional cleanup plan)** drafted and approved before any cleanup code is touched.

### What needs Josh
- **Review and merge PR #4** (this session): https://github.com/joshjgrills-svg/AMP/pull/4 — 6 files (post-rebase), Constitution amendment + ADR-005 + agent file updates + SESSION_LOG entry
- Approve ADR-003 at the start of the next session

### Tripwires fired
- **T-008 (preventive, functioned as designed)** — file staging during the rebase resolution was per-file (`git add docs/DECISIONS.md`, `git add docs/SESSION_LOG.md`); `scripts/check-calls.ts` still correctly untracked, still deferred to ADR-003.

### Constitution version at session start: v1
### Constitution version at session end: v1.1 (Section 7.5 added per ADR-005)

### Notes for future-Claude
The branch naming this session (`session-004-workflow-amendment`) coincidentally matches the SESSION_LOG entry number (Session 004), unlike the earlier session today (`session-002-wedge-adr-004` → Session 003 in the log). Do not try to enforce a convention here. Josh names branches by intent; the SESSION_LOG numbers sequentially. The two systems are independent.

This is the **second session of 2026-05-17**. Two sessions in one day is fine when each closes cleanly; the SESSION_LOG entries make the boundary clear.

The §7.5 carve-out is a **one-way unlock** — it permits direct-to-main commits for docs but does not require them. The Reviewer can still be invoked on a docs commit, and should be for any change to the load-bearing trio (NORTH_STAR, CONSTITUTION, DECISIONS). The carve-out reduces friction; it does not require lower discipline.

ADR-005 itself was NOT eligible for the carve-out it establishes, because the change touched `.claude/` files. That's the path-scoped rule working as designed.

The "Numbering note" inside ADR-005 says "ADR-004 is currently in flight in PR #3 and is not yet on `main`." That sentence was historically true at write-time and is preserved per the DECISIONS.md append-only policy — ADRs are not edited after being recorded. By the time you read this, both ADR-004 and ADR-005 are on main and the file shows them in chronological order (ADR-004 above ADR-005).
