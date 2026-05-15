# AMP — Tripwires

This document is the active list of known failure modes the Reviewer sub-agent checks for on every PR. Tripwires are added when postmortems reveal new failure modes. Tripwires are removed (or downgraded) when they are obsolete.

Each tripwire has a last-reviewed date. The Reviewer flags any tripwire older than 90 days as needing audit.

---

## Hard tripwires — Halt and surface to Josh

These tripwires require Josh's explicit acknowledgment to proceed. They cannot be silently overridden.

### T-001: Stripe production code changes
**Source:** Constitutional default (Section 5.3)
**Last reviewed:** 2026-05-12
**Detection:** Any change in `apps/web/api/stripe/*`, `apps/web/api/webhooks/stripe/*`, billing-related code, subscription state writes
**Rationale:** Stripe is or will be processing real customer money. Mistakes here erode trust faster than any other bug and may be financially material.
**Action when fired:** Halt. Surface to Josh. Require explicit "Stripe approved" before proceeding.

### T-002: RLS policy changes
**Source:** ProScore April 2026 security work, Constitution Section 4
**Last reviewed:** 2026-05-12
**Detection:** Any migration that creates, drops, or alters RLS policies; any code that uses `auth.role()` overrides
**Rationale:** RLS is the primary mechanism enforcing workspace isolation. A regression here leaks customer data across workspaces. This is a P0 security failure.
**Action when fired:** Halt. Surface to Josh. Require Reviewer sub-agent to specifically audit the RLS implications.

### T-003: Schema rename of locked terms
**Source:** ProScore schema drift lessons (business_name, business_type, trust_snapshots)
**Last reviewed:** 2026-05-12
**Detection:** Any migration that renames a column or table matching the Constitution's Section 1.3 taxonomy locks (customer, agent, conversation, end_user, subscription, workspace, handoff)
**Rationale:** These names are decided and never change. Renaming them mid-project causes cascading drift across every layer.
**Action when fired:** Halt. Surface to Josh. Require an explicit amendment to Constitution Section 1.3 before proceeding.

### T-004: Constitution violations
**Source:** Constitutional default (Section 9)
**Last reviewed:** 2026-05-12
**Detection:** Any code, migration, or configuration that violates a rule in CONSTITUTION.md
**Rationale:** The Constitution is policy, not suggestion. Violations require amendment, not exception.
**Action when fired:** Halt. Surface to Josh. Require Constitutional amendment (per Section 9) before proceeding.

### T-005: Direct production data edits
**Source:** Constitutional default (Section 8)
**Last reviewed:** 2026-05-12
**Detection:** Any SQL run directly against production, any dashboard-level data edit not version-controlled, any "let me just fix this real quick" attempt
**Rationale:** Production data changes that aren't version-controlled are invisible to the rest of the system and cannot be reproduced or rolled back.
**Action when fired:** Halt. Surface to Josh. Require the change to be expressed as a version-controlled migration or script.

### T-006: Agent output containing credential values
**Source:** Session 001 security incident postmortem (2026-05-13)
**Last reviewed:** 2026-05-13
**Detection:** Any agent-produced document, code, or output containing strings matching: API key prefixes (`sk_`, `pk_`, `key_`, `AC` followed by 32 hex chars), JWT patterns (`eyJ` followed by base64), high-entropy strings adjacent to `key=`/`token=`/`secret=`/`password=` patterns.
**Rationale:** The Architect produced PROJECT_INVENTORY.md containing five live secrets read from `.env.local`. GitHub push protection blocked the leak, but the prompt-level rule was missing.
**Action when fired:** Halt, redact the values, surface to Josh before any commit.

### T-007: Agents reading .env* file contents
**Source:** Session 001 security incident postmortem (2026-05-13)
**Last reviewed:** 2026-05-13
**Detection:** Any agent that reads `.env.local`, `.env.production`, or any `.env*` file beyond verifying its existence (via `ls` or `git status`).
**Rationale:** Reading secret values into context creates exposure risk even when the values aren't immediately written to output.
**Action when fired:** Halt. Verify the agent only needs to confirm existence, not read contents.

### T-008: Broad git staging commands
**Source:** Session 001 incident cleanup (2026-05-13)
**Last reviewed:** 2026-05-13
**Detection:** Any use of `git add -A`, `git add .`, or `git add *` by an agent.
**Rationale:** Broad staging swept in orphaned files (`.claude/settings.local.json` and `scripts/check-calls.ts`) that violated the session plan. Agents must stage specific files only.
**Action when fired:** Halt. Replace with targeted `git add <file>` commands listing exactly the intended files.

---

## Soft tripwires — Flag and proceed with caution

These tripwires require the Reviewer to flag the issue in the review output, but the diff can proceed if Josh is informed.

### T-101: New external dependencies
**Source:** Constitution Section 8
**Last reviewed:** 2026-05-12
**Detection:** Any `package.json` change adding a new dependency
**Rationale:** Every npm package is a future security incident or maintenance burden.
**Action when fired:** Flag in review. Reviewer must verify the dependency is justified.

### T-102: New paid external services
**Source:** Constitution Section 8, CFO feedback
**Last reviewed:** 2026-05-12
**Detection:** Any new service with subscription pricing or per-call pricing being added to AMP
**Rationale:** Cost discipline at this stage compounds.
**Action when fired:** Flag in review. Require explicit Josh approval regardless of cost magnitude.

### T-103: Missing tests on critical paths
**Source:** Constitution Section 5.1
**Last reviewed:** 2026-05-12
**Detection:** New API routes, billing code, webhook handlers, external adapters, or Zod boundary schemas without corresponding tests
**Rationale:** Critical paths must have tests. The Constitution mandates this.
**Action when fired:** Verdict is FIX-BEFORE-SHIP. Tests must accompany the code, not follow later.

### T-104: console.log in production paths
**Source:** Constitution Section 6.1
**Last reviewed:** 2026-05-12
**Detection:** Any `console.log`, `console.warn`, `console.error` in code that runs in production
**Rationale:** Unstructured logs are useless at scale and can leak PII.
**Action when fired:** Verdict is FIX-BEFORE-SHIP. Replace with structured logger.

### T-105: Hardcoded environment-specific values
**Source:** Constitution Section 8
**Last reviewed:** 2026-05-12
**Detection:** URLs, API endpoints, feature flags, or other values that differ between dev/staging/prod hardcoded in source
**Rationale:** Hardcoded values cause production-only bugs and deployment failures.
**Action when fired:** Verdict is FIX-BEFORE-SHIP. Move to environment variables.

### T-106: Untracked TODOs
**Source:** Constitution Section 8
**Last reviewed:** 2026-05-12
**Detection:** Any `// TODO:`, `// FIXME:`, `// HACK:` comment without a tracked issue reference
**Rationale:** Untracked TODOs become permanent.
**Action when fired:** Flag in review. Either remove or add an issue reference.

### T-107: PII in logs
**Source:** Constitution Section 4.3
**Last reviewed:** 2026-05-12
**Detection:** Logging statements that include `phone_number`, `email`, `name`, transcript content, or recording URLs
**Rationale:** PII in logs is a privacy violation and a security risk.
**Action when fired:** Verdict is FIX-BEFORE-SHIP.

### T-108: Webhook handlers without signature verification
**Source:** Constitution Section 3.3
**Last reviewed:** 2026-05-12
**Detection:** Any route under `/api/webhooks/*` that does not validate the request signature
**Rationale:** Unsigned webhooks allow attackers to inject malicious events.
**Action when fired:** Verdict is FIX-BEFORE-SHIP.

### T-109: Direct agent-to-agent communication
**Source:** Runtime Architecture Section 4
**Last reviewed:** 2026-05-12
**Detection:** Agent code that calls another agent's API directly instead of routing through the orchestration layer
**Rationale:** Direct agent communication bypasses the orchestration layer that is AMP's moat.
**Action when fired:** Verdict is FIX-BEFORE-SHIP. Route through the orchestration layer.

### T-110: Missing graceful degradation
**Source:** Runtime Architecture Section 6.2, Constitution Section 6.4
**Last reviewed:** 2026-05-12
**Detection:** New failure mode introduced without a defined non-broken outcome
**Rationale:** Silent failures compound. Every failure must produce a signal.
**Action when fired:** Verdict is FIX-BEFORE-SHIP.

---

## Predictive tripwires — Watch for these

These tripwires have not bitten us yet but are predicted based on the architecture and the experience of peer companies. They are upgraded to active tripwires once they fire.

### T-201: Voice agent latency regression
**Source:** Runtime Architecture Section 5.2
**Last reviewed:** 2026-05-12
**Detection:** Voice agent time-to-first-audio exceeds 500ms in production
**Rationale:** Voice agents that feel slow feel robotic, which is the product's existential failure mode.

### T-202: Cross-workspace data leak
**Source:** Runtime Architecture Section 3.4
**Last reviewed:** 2026-05-12
**Detection:** Any query returning rows from multiple workspaces in a context where one was expected
**Rationale:** The most catastrophic possible failure. Customer A sees Customer B's data.

### T-203: Handoff failure without fallback
**Source:** Runtime Architecture Section 4.3
**Last reviewed:** 2026-05-12
**Detection:** A handoff fails and no escalation path triggers
**Rationale:** A failed handoff that goes nowhere means a lost customer interaction.

### T-204: Consent disclosure missing or modified
**Source:** Constitution Section 4.3
**Last reviewed:** 2026-05-12
**Detection:** Voice agent template deployed without approved consent language, or consent language modified by customer in a way that weakens it
**Rationale:** Legal exposure in two-party consent jurisdictions.

---

## Audit schedule

Tripwires are reviewed quarterly. The Reviewer sub-agent flags any tripwire older than 90 days for re-evaluation. Tripwires that are no longer relevant are removed with a note in DECISIONS.md.

New tripwires are added by:

1. A postmortem identifying a new failure mode
2. A C-suite review surfacing a risk that warrants codification
3. A pattern of similar issues being caught manually

New tripwires include: source, detection method, rationale, action when fired, and last-reviewed date.
