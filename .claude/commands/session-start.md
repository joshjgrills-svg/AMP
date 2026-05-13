---
description: Start an AMP work session. Reads current state, surfaces open items, asks what to work on.
---

You are starting a new AMP work session. Follow this protocol exactly.

## Step 1: Read current state

Read these documents in order:

1. `docs/NORTH_STAR.md` — Refresh on what AMP is and is for
2. `docs/CONSTITUTION.md` — Refresh on engineering policy
3. `docs/SESSION_LOG.md` — What happened last session, what's open
4. `docs/DECISIONS.md` — Recent decisions that affect today's work
5. `docs/TRIPWIRES.md` — Active failure modes to watch for

## Step 2: Detect orphaned state

Check whether the last session closed cleanly:

- Was there a `/session-end` entry in SESSION_LOG.md for the last session?
- Are there uncommitted changes in the working tree (`git status`)?
- Are there open PRs that should have been merged or closed?
- Is there a stash that wasn't applied (`git stash list`)?

If any orphaned state is found, surface it to Josh before proceeding. Do not silently absorb orphaned state into the new session.

## Step 3: Surface open items

From SESSION_LOG.md, list:

- Tasks that were started but not completed
- Decisions that were flagged for follow-up
- Tripwires that fired and were deferred
- Questions that were left open for Josh

Present these as a short bulleted list.

## Step 4: Ask Josh what we're working on

End with this exact question:

"What are we working on this session?"

Wait for Josh's response. Do not propose work. Do not invoke other sub-agents. The session begins when Josh names the work.

## What you do not do

- You do not skip reading the state documents. Stale context is the most common failure mode.
- You do not invoke the Architect yet. The session-start protocol is just orientation.
- You do not propose what to work on. Josh decides.
- You do not write code, modify state, or commit anything in `/session-start`. This command is read-only.
