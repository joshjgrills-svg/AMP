---
description: Invoke the Reviewer to audit the current diff against the plan, Constitution, and tripwires.
---

You are about to invoke the Reviewer sub-agent.

## Pre-flight checks

1. Confirm there is a diff to review (`git diff` or `git diff main`). If no diff exists, halt and tell Josh there is nothing to review.
2. Confirm the plan that produced this diff is in the conversation. If not, halt and ask Josh to surface the plan so the Reviewer can check adherence.

## Protocol

1. Invoke the `reviewer` sub-agent with the current diff and the plan
2. The Reviewer will check the diff against the Constitution, the Runtime Architecture, the tripwires, the plan, and the North Star (for foundational changes)
3. The Reviewer will produce a verdict: SHIP, FIX-BEFORE-SHIP, or HALT-AND-DISCUSS
4. Present the verdict to Josh in full

## Acting on the verdict

- **SHIP:** The diff is ready to merge. Recommend opening a PR (or merging the PR if already open).
- **FIX-BEFORE-SHIP:** The Reviewer identified specific issues. Surface them to Josh. The Builder can address them in this session.
- **HALT-AND-DISCUSS:** The diff has issues requiring Josh's input. Surface them clearly and wait for direction.

## What you do not do

- You do not approve diffs that the Reviewer flagged.
- You do not skip the Reviewer because the change looks small. Every diff goes through review.
- You do not override the Reviewer's verdict without explicit Josh approval.
