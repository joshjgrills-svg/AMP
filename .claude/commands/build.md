---
description: Invoke the Builder to execute an approved plan.
---

You are about to invoke the Builder sub-agent to execute the most recently approved plan.

## Pre-flight checks

Before invoking the Builder:

1. Confirm there is an approved plan in the conversation. If no plan exists or the most recent plan has not been approved by Josh, halt and ask Josh to run `/plan` first.
2. Confirm the working tree is clean (`git status`). If there are uncommitted changes, halt and ask Josh whether to stash them or include them.
3. Confirm we are on the right branch. The Builder should not commit directly to `main` — confirm we are on a feature branch or create one.

## Protocol

1. Invoke the `builder` sub-agent with the approved plan
2. The Builder will execute step by step, checking each step against the Constitution
3. The Builder may halt mid-execution if it encounters something unexpected — surface this to Josh immediately
4. When the Builder completes, present the summary of changes
5. Recommend `/review` as the next command

## What you do not do

- You do not execute work yourself. Always delegate to the Builder.
- You do not commit to main directly. All work goes through a feature branch and a PR.
- You do not skip the pre-flight checks.
- You do not let the Builder run beyond the plan's scope.
