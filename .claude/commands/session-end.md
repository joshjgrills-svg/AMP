---
description: End an AMP work session. Updates state documents, commits, pushes, surfaces open items.
---

You are closing the current AMP work session. Follow this protocol exactly.

## Step 1: Summarize the session

Produce a session summary including:

- What got done (features, fixes, decisions)
- What got decided (any new entries that should go in DECISIONS.md)
- What got deferred (work that was started but not finished)
- What got blocked (work that hit a tripwire or required Josh input)
- What's open for the next session

## Step 2: Update state documents

Update the following:

1. **`docs/SESSION_LOG.md`** — Append a new session entry with date, duration, summary, open items
2. **`docs/DECISIONS.md`** — If any new ADRs were made this session, append them (numbered sequentially)
3. **`docs/TRIPWIRES.md`** — If any new tripwires were discovered, add them
4. **`docs/OpsCenter.tsx`** — If applicable, update task statuses to reflect what was completed

If SESSION_LOG.md has more than 10 entries, archive the oldest entries to `docs/archive/session-log/{year}-{month}.md` and keep only the last 10 in the active file.

## Step 3: Commit and push

First determine whether this session's changes are **documentation-only** or **mixed** (per Constitution §7.5):

- **Documentation-only:** every staged path is confined to `docs/` (`NORTH_STAR.md`, `CONSTITUTION.md`, `RUNTIME_ARCHITECTURE.md`, `OPERATING_RHYTHM.md`, `DECISIONS.md`, `TRIPWIRES.md`, `SESSION_LOG.md`, `README.md`, `docs/scout/*`, `docs/research/*`).
- **Mixed:** any staged path touches application code, schema, configuration, `.claude/` agent definitions, or any path outside `docs/`. The carve-out is path-scoped, not intent-scoped — a "mostly docs" change with one `.claude/` file is mixed, not documentation-only.

### If documentation-only (Constitution §7.5 carve-out):

1. Stage the state document updates by file name (never `git add -A` — see T-008)
2. Commit with a descriptive message
3. Push directly to `main` — no PR required, no feature branch required
4. Do not open a PR

### If mixed:

1. Stage the state document updates by file name (never `git add -A` — see T-008)
2. Commit on the current feature branch
3. Push to the feature branch
4. If a PR is not yet open, open one for Josh's review
5. Do NOT push to `main` directly — the PR is the gate

## Step 4: Surface what needs Josh

End with a clear list of:

- PRs open and awaiting Josh's approval
- Decisions that need Josh's input before the next session
- Tripwires that fired and need attention
- Anything else Josh should know before the next session starts

## What you do not do

- You do not merge PRs without Josh's explicit approval
- You do not skip state document updates because the session was short
- You do not skip the commit and push step
- You do not leave the session in a partially-closed state — either it closes cleanly or it doesn't close

## If something prevents clean closure

If you cannot close the session cleanly (e.g., merge conflicts, uncommitted work that requires decisions, etc.), surface this to Josh and explicitly note that the session is closing with orphaned state. The next `/session-start` will detect and reconcile it.
