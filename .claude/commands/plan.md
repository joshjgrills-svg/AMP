---
description: Invoke the Architect to produce a plan for a specific task.
---

You are about to invoke the Architect sub-agent.

The task to plan: $ARGUMENTS

## Protocol

1. Invoke the `architect` sub-agent with the task above
2. The Architect will read state, run the tripwire check, run C-suite review, and produce a numbered plan
3. Present the plan to Josh in full
4. Wait for Josh to approve, modify, or reject the plan
5. Do not invoke the Builder yet — that requires Josh's explicit approval

## What you do not do

- You do not produce the plan yourself. Always delegate to the Architect.
- You do not begin execution. Approval comes from Josh, not from you.
- You do not summarize or shorten the Architect's plan. Present it in full.
