# AMP — The System

This directory contains the operating system for how AMP is built. If you are reading this for the first time — whether you're Josh, a future contributor, or a Claude Code session — read this document first. Everything else makes sense in light of it.

---

## What this system is

AMP is built by a team of AI agents coordinated by a structured workflow. There is one human (Josh, CEO) and ten specialized AI agents that handle planning, execution, review, research, design, customer analysis, branding, and security. The team is bound together by:

- **Foundation documents** that define what AMP is, how it's built, how it operates at runtime, and what decisions have been made
- **Sub-agents** with narrow specialties and clear handoff protocols
- **Slash commands** that enforce the workflow at every step
- **Operating rhythms** that ensure the right work happens at the right time

The result is a small team that operates with the discipline of a large engineering organization, without the overhead of one.

---

## The foundation documents (read in this order)

### 1. `NORTH_STAR.md`
What AMP is, who it serves, why now, what "won" looks like, what AMP is explicitly not, the kill criteria. This is the test every consequential decision is checked against.

### 2. `CONSTITUTION.md`
How we build. Database conventions, naming policy, code organization, API contracts, security defaults, testing standards, observability requirements, agent operating model, architectural negative space. Policy, not suggestion.

### 3. `RUNTIME_ARCHITECTURE.md`
How AMP operates at runtime. The three layers (agent, orchestration, surface), the shared context model, the handoff protocol, the agent contract, failure handling, scale considerations.

### 4. `OPERATING_RHYTHM.md`
When things happen. Per-session, daily, weekly, monthly, quarterly, and on-event cadences. The schedule that prevents drift.

### 5. `DECISIONS.md`
Why we made the choices we made. Append-only ADR log. Numbered sequentially. Never edited after commit — superseded by new entries.

### 6. `TRIPWIRES.md`
Known failure modes. Hard tripwires (halt and surface) and soft tripwires (flag and proceed). Each tripwire has a last-reviewed date.

### 7. `SESSION_LOG.md`
Rolling log of the last 10 sessions. What happened, what got decided, what's open. The `/session-start` command reads this to surface context for the new session.

---

## The ten sub-agents

Each agent has its own definition file in `.claude/agents/`. Each one is a thin protocol wrapper that reads the foundation documents and executes a specific role.

### Core build team

- **`architect`** — Plans. Reads state. Runs C-suite review. Produces numbered execution plans. Cannot write code.
- **`builder`** — Executes plans with discipline. Cannot deviate. Updates state on completion.
- **`reviewer`** — Audits diffs against the plan, the Constitution, and the tripwires. Can refuse to ship.

### Specialists

- **`voice-qa`** — Reviews voice agent call transcripts. Surfaces failures. Proposes prompt improvements.
- **`researcher`** — Reads broadly, produces briefs. Async research, competitive analysis, customer feedback synthesis.
- **`scout`** — Scans the AI ecosystem weekly. Surfaces what's worth adopting to keep AMP ahead.
- **`designer`** — UI/UX specifications. Holds the bar on the "intuitive for non-technical operator" standard.
- **`customer-success`** — Voice of the customer. Reads behavior and feedback, surfaces patterns.
- **`marketing`** — Brand voice and customer-facing copy. Reviews everything customers see.
- **`security`** — Auth, RLS, PII, webhooks, credentials. The CSO chair as a continuously available auditor.

---

## The five slash commands

Each command has its own definition file in `.claude/commands/`. The commands are the only interface Josh uses to drive the system.

- **`/session-start`** — Reads state. Surfaces open items. Asks what we're working on.
- **`/plan {task}`** — Invokes the Architect to produce a plan.
- **`/build`** — Invokes the Builder to execute the approved plan.
- **`/review`** — Invokes the Reviewer to audit the current diff.
- **`/session-end`** — Updates state. Commits. Pushes. Closes the session.

---

## How a session actually flows

```
Josh: /session-start
Claude Code: [reads NORTH_STAR, CONSTITUTION, SESSION_LOG, TRIPWIRES]
              [surfaces open items from last session]
              "What are we working on this session?"

Josh: "I want to build the agent configuration UI."

Josh: /plan build the agent configuration UI
Claude Code: [invokes architect sub-agent]
              architect: [reads state, checks North Star alignment, runs tripwire check,
                         runs C-suite review with Designer + Marketing + Security chairs,
                         produces numbered plan with confidence level]
              [presents plan to Josh]

Josh: [approves plan, or asks for changes]

Josh: /build
Claude Code: [invokes builder sub-agent]
              builder: [reads plan, reads Constitution,
                       executes step by step, checking each step against the Constitution,
                       produces diff, opens PR on feature branch]

Josh: /review
Claude Code: [invokes reviewer sub-agent]
              reviewer: [reads plan, reads diff, reads Constitution, walks tripwires,
                        produces verdict: SHIP / FIX-BEFORE-SHIP / HALT-AND-DISCUSS,
                        with at least one specific finding]

Josh: [approves PR, or sends back for fixes]

Josh: /session-end
Claude Code: [appends to SESSION_LOG, updates DECISIONS if applicable,
              updates TRIPWIRES if applicable, commits state docs, pushes]
              [surfaces what needs Josh's attention before next session]
```

---

## What makes this different

Most AI-assisted development is a single agent making decisions and writing code in one continuous loop. AMP's system separates concerns:

- **Planning is structurally separate from execution.** The Architect cannot write code. This forces deliberate thought before action.
- **Review is structurally separate from execution.** The Reviewer is a different chair. It cannot just rubber-stamp its own work because it didn't do the work.
- **Specialized expertise is on tap.** When UI matters, the Designer chair speaks. When security matters, the Security chair speaks. When the broader ecosystem matters, the Scout speaks.
- **Continuity is enforced structurally.** State documents are read at session start and written at session end. The system has memory across sessions even though individual Claude Code sessions don't.
- **Decisions are remembered.** ADRs are append-only. Tripwires are persistent. The system gets stronger over time, not weaker.

The result: development that has the discipline of a serious engineering organization, executed by one human and a team of specialized agents.

---

## What to do if you're new here

If you are starting your first session in this repository:

1. Read this file (you're doing it)
2. Read `NORTH_STAR.md`
3. Read `CONSTITUTION.md`
4. Skim `RUNTIME_ARCHITECTURE.md` (you'll come back to it)
5. Skim `OPERATING_RHYTHM.md`
6. Run `/session-start`

That's it. The system takes you from there.

---

## What to do if something is broken

If a sub-agent produces output that violates the Constitution, the Constitution wins. The sub-agent is wrong.

If the foundation documents contradict each other, surface it to Josh. The system needs to be consistent to work.

If the workflow feels heavy and unnecessary for a specific task, that's worth surfacing but not skipping. Skipped discipline compounds.

If something genuinely needs to change in the foundation documents, that's an amendment per Constitution Section 9. Propose it, get it approved, log it in DECISIONS.md, then act on it.

---

## Final note

This system is itself a product. It will evolve. v1 will become v2 as we learn what works. The fact that it's well-documented doesn't make it correct — only experience can do that.

But the alternative — building without discipline, hoping it works out — is how startups become ProScore's debt-cleanup project. The discipline is what makes the ambition achievable.

Read the documents. Use the commands. Trust the agents to do their specialized work. Push back when something feels wrong. Build something that lasts.
