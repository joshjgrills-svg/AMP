# AMP — Technical Constitution

**Version:** v1.1
**Author:** Senior Lead Architect (with C-suite review)
**Last updated:** 2026-05-17
**Supersedes:** v1 (2026-05-12; amended per ADR-005 to add Section 7.5 — documentation-only changes may commit directly to main without a pull request)
**Status:** This document is policy, not suggestion. Once ratified, the agent team enforces it without exception. Changes require explicit amendment via the procedure in Section 9.
**Next review:** Quarterly, or upon any architectural inflection point

---

## Preamble — Why this document exists

ProScore taught us what undisciplined foundations cost. Schema renames mid-project. Naming drift across phases. Connection strings hardcoded. Migrations applied manually. Data quality issues surfacing at scale instead of at creation. The cleanup is consuming weeks of founder time that should be going to growth.

AMP starts with a different premise: every convention is decided once, written down, and enforced by the agent team on every commit. The Constitution is the source of truth for *how* we build. The North Star is the source of truth for *what* we build. The Runtime Architecture document is the source of truth for *how the product operates at runtime*. Together they form the operating rules for the entire project.

The discipline this document encodes is not Fortune 500 process for its own sake. Each rule traces to a specific pain we have already paid for on ProScore, a specific pain a peer company has paid for, or a specific risk the C-suite review surfaced. Nothing is here for ceremony.

---

## Section 1 — Database and schema

### 1.1 Schema conventions

**Tables:** plural, snake_case. `agents`, `conversations`, `subscriptions`.

**Columns:** singular, snake_case. `created_at`, `phone_number`, `business_name`.

**Primary keys:** every table has a column named `id` of type `uuid`, defaulted to `gen_random_uuid()`, declared `not null` and as the primary key. No `bigserial`, no composite primary keys without explicit architectural justification. UUIDs are mandatory: they are non-enumerable (security), merge-safe (multi-environment), and portable (no sequence collisions on import/export).

**Foreign keys:** named `{referenced_table_singular}_id`. Every foreign key column has a corresponding `foreign key` constraint with explicit `on delete` behavior. No implicit relationships through naming convention alone.

**Timestamps:** every table has `created_at timestamptz not null default now()` and `updated_at timestamptz not null default now()`. The `updated_at` column is maintained by a trigger, not by application code. The trigger is part of the migration that creates the table.

**Soft delete:** when needed, use `deleted_at timestamptz null`. Never a `deleted` boolean. Soft-deleted rows are filtered by RLS or explicit query — never relied upon to be hidden by application logic.

**Enums:** any column with a constrained set of values uses a Postgres `enum` type or a `check` constraint. Never a free-text column managed by convention. Enums are named `{table_singular}_{column_singular}_type`. Values are lowercase snake_case strings.

**JSON columns:** `jsonb`, not `json`. Used only when the shape is genuinely variable across rows. Every `jsonb` column has a documented schema in code (Zod schema in TypeScript) validated at the application boundary.

**Indexes:** declared in the same migration as the column they index. Naming: `idx_{table}_{column(s)}`. Composite indexes are explicitly ordered for the queries they serve.

**Row-Level Security:** mandatory on every table from the migration that creates it. Default deny. Explicit allow policies for each access pattern. No exceptions. This is the single biggest lesson from ProScore's April 2026 security work.

### 1.2 Migration discipline

Every schema change is a numbered migration file in `supabase/migrations/`. Migration files are append-only — never edited after being committed to the main branch. A mistake in a migration is corrected by a subsequent migration.

Migration files are named `{timestamp}_{verb}_{object}.sql`. The verb is one of: `create`, `add`, `modify`, `drop`, `rename`, `populate`, `backfill`.

Every migration includes a comment at the top with: the date, the author, the reason, and the rollback procedure. If a migration cannot be safely rolled back, the comment must state this explicitly and the migration requires CEO sign-off before deployment.

The Supabase MCP is the sanctioned way to apply migrations to development and staging. Production migrations require CEO approval and run through a deploy gate (Section 6).

### 1.3 Naming taxonomy locks

These names are decided and never change:

- **Customer** — a paying business that uses AMP. The variable name is `customer`. The table is `customers`.
- **Agent** — an AI agent deployed by a customer. The variable name is `agent`. The table is `agents`.
- **Agent Type** — the category of an agent (voice, chat, sms, email). The variable name is `agent_type`. Stored as enum on the `agents` table.
- **Conversation** — a single interaction between an agent and an end-user. The variable name is `conversation`. The table is `conversations`.
- **End-user** — the person an agent talks to (the contact who calls, chats with, or emails the customer's business). The variable name is `end_user`. Stored on conversations by identity (phone, email, etc.); a future `end_users` table may exist when cross-conversation identity becomes valuable.
- **Subscription** — the billing relationship between AMP and a customer. The variable name is `subscription`. The table is `subscriptions`.
- **Workspace** — a customer's deployment of agents. One customer has one workspace (today). Future expansion may allow multiple. The variable name is `workspace`. The table is `workspaces`.
- **Handoff** — the act of one agent transferring a conversation to another agent. The variable name is `handoff`. The table is `handoffs`.

If a future feature creates ambiguity, we add a new term — we do not overload an existing term.

### 1.4 What the agents check on every database PR

The reviewer sub-agent halts and surfaces, for any PR touching the schema:

- Any new column without documented type and nullability rationale
- Any new table without RLS policies in the same migration
- Any new foreign key without explicit `on delete` clause
- Any new `jsonb` column without a documented schema
- Any free-text column that should be an enum
- Any migration that edits a previously-committed migration
- Any naming that violates the conventions above

---

## Section 2 — Code organization

### 2.1 Repository structure

```
amp/
├── apps/
│   ├── web/                  # Next.js customer-facing app
│   └── marketing/            # Next.js marketing site (separate deploy)
├── packages/
│   ├── ui/                   # Shared React components
│   ├── db/                   # Database types and Zod schemas
│   ├── agents/               # Agent definitions, prompts, configs
│   ├── orchestration/        # Runtime orchestration engine
│   └── shared/               # Shared utilities, constants
├── supabase/
│   ├── migrations/
│   └── functions/
├── docs/
│   ├── NORTH_STAR.md
│   ├── CONSTITUTION.md
│   ├── RUNTIME_ARCHITECTURE.md
│   ├── DECISIONS.md
│   ├── TRIPWIRES.md
│   └── SESSION_LOG.md
└── .claude/
    ├── agents/
    └── commands/
```

Monorepo with workspaces. Separate apps for the customer-facing product and the marketing site, deploying independently.

### 2.2 TypeScript discipline

Strict mode enabled. `noImplicitAny`, `strictNullChecks`, `noUnusedLocals`. The use of `any` is prohibited except in the narrowest possible scope with a comment explaining why. The use of `as` casts is prohibited except when converting between Zod-validated shapes.

All inputs at system boundaries (API requests, database reads, external API responses, environment variables, webhooks) are validated by Zod schemas. Never trust data that came from outside the type system without parsing it.

The `packages/db` package generates TypeScript types from the Supabase schema and exports them as the canonical source of truth for database shapes. Application code imports these types rather than re-declaring them.

### 2.3 File and module conventions

Files use kebab-case: `agent-detail-page.tsx`, `create-agent.ts`. React components are PascalCase exports from kebab-case files. One primary export per file.

API route handlers in Next.js follow the App Router convention. Every route under `app/api/` has a `route.ts` exporting the HTTP method handlers. Every API route that touches the database imports from `packages/db`.

### 2.4 What the agents check on every code PR

- Use of `any` without justification comment
- Use of `as` casts outside Zod boundaries
- Database queries constructed inline instead of through `packages/db`
- Components defined in files that do not match their name
- API routes that do not validate input with Zod
- New files violating the kebab-case convention

---

## Section 3 — API contracts and external integrations

### 3.1 API design

Internal APIs use REST conventions over Next.js API routes. JSON request and response bodies. Errors return: `{ error: { code: string, message: string, details?: object } }`. HTTP status codes mean what they mean. No "always return 200 with an error object."

External APIs (the public AMP API for customers, if and when it exists) follow the same conventions plus versioning. First public API is `v1` in the URL path. Breaking changes require a new version. Deprecation requires a 6-month notice in response headers.

### 3.2 External service integrations

Every external service (Retell, ElevenLabs, Twilio, Stripe, Resend, Supabase) is wrapped in a thin adapter in `packages/shared/integrations/{service}/`. Application code never calls the external SDK directly. The adapter handles authentication, retries, timeouts, and error normalization.

Every adapter exposes a typed interface validated by Zod. Every adapter logs structured events to Sentry and structured console logs on every external call. Every adapter has a documented timeout, retry policy, and failure mode.

**Multi-provider mandate:** For every category of external service where AMP's product would fail if the provider went down, the adapter is designed to support at least two providers, with the active provider configurable per workspace. The first version may ship with one provider, but the adapter shape must not preclude adding a second. Voice (Retell + a backup), TTS (ElevenLabs + a backup), and telephony (Twilio + a backup) are the categories where this matters most.

### 3.3 Webhook handling

Webhooks from external services are received at versioned endpoints (`/api/webhooks/{service}/v1`). Every webhook handler:

1. Validates the signature using the service's documented signing mechanism
2. Returns 200 within 1 second of receipt — long processing is deferred to a background job
3. Logs the raw payload before any processing
4. Is idempotent — receiving the same webhook twice produces the same outcome as receiving it once

Webhook secrets are stored in environment variables. Webhook endpoints are protected by signature verification, not IP whitelisting.

### 3.4 Dependency contingency

Every external service AMP depends on has a documented contingency:

- **Retell down:** Voice agents fall back to a configured Twilio voicemail with a custom message; calls are not lost
- **ElevenLabs down:** Voice agents fall back to a secondary TTS provider; voice quality may degrade temporarily but agents remain functional
- **Twilio down:** No fallback possible for telephony; documented as accepted risk; status page communicates outage to customers
- **Stripe down:** No new signups; existing customers continue to operate; billing reconciles when Stripe recovers
- **Supabase down:** Total platform outage; documented as accepted risk; service is restored when Supabase recovers
- **Resend down:** Emails queue and retry; non-blocking for product operation

Contingencies are revisited annually or after any incident exposes a gap.

---

## Section 4 — Security defaults

### 4.1 Secrets and credentials

All secrets live in environment variables. Never in code. Never in committed files. Never in client-side bundles. The `.env.example` file lists every required environment variable with a comment explaining what it is and where to get it.

Secrets are rotated on a documented schedule. Production API keys rotated every 90 days. Webhook signing secrets rotated every 90 days. Compromised secrets are rotated immediately and the incident logged in DECISIONS.md.

Vercel and Supabase environments use separate secrets for development, staging, and production. Compromise of one environment must not compromise others.

### 4.2 Authentication

Customer authentication is handled by Supabase Auth. Email-based magic links for primary flow, with OTP as fallback for environments where magic links fail (the ProScore Gmail prefetch issue is documented; OTP is the solution).

Admin authentication (for AMP internal tooling) is separate from customer authentication. Admin sessions cannot be obtained through the customer flow. Admin actions are logged with identity in an append-only audit log.

### 4.3 PII, call recording, and consent

Customer data and end-user data are stored separately. End-user phone numbers, names, conversation transcripts, and call recordings are PII.

- All PII is encrypted at rest by Supabase's default mechanism
- All PII is accessed through RLS policies restricting to the owning customer
- PII is never logged in application logs, error tracking, or analytics
- Call recordings are stored in private Supabase Storage buckets with signed URLs, never public URLs
- PII retention follows a documented policy: conversation transcripts retained for 90 days by default, configurable per customer, deleted automatically after retention

**Call recording consent (legal requirement):** AMP operates in two-party-consent jurisdictions where call recording requires the end-user's consent. Every voice agent's opening line includes mandatory consent disclosure language. The exact language is approved by counsel and is not customizable by the customer — customers can add to it but cannot remove or weaken it. This requirement is hard-coded into the agent template system.

### 4.4 Customer data rights

Every customer has the right to:

- Export all of their data in a machine-readable format (CSV/JSON), including conversations, agent configurations, and billing history
- Delete their account and all associated data, with confirmation flow; deletion is permanent after a 30-day recovery window
- Receive a copy of every conversation involving their workspace, including audio recordings where applicable

These rights are implemented before any customer pays. They are not features — they are foundational requirements.

### 4.5 What the agents check on every PR

- Any new secret being added without going through environment variables
- Any logging of PII fields
- Any new endpoint without authentication
- Any database query that bypasses RLS without explicit justification
- Any webhook endpoint without signature verification
- Any voice agent template missing consent language

---

## Section 5 — Testing and quality

### 5.1 What must be tested

Tests are a tax — they cost time to write and maintain. The Constitution requires tests for load-bearing paths only:

- Every API route that writes to the database
- **Every code path that determines whether a customer gets billed, in what amount, or whether they have access to features** (CFO requirement from C-suite review)
- Every webhook handler
- Every adapter to an external service
- Every Zod schema used at a system boundary
- The orchestration engine (Section 10) — handoff logic, context sharing, failure handling
- Authentication and authorization flows

Tests are not required for: pure UI components (manual review and visual regression cover these), straightforward database reads, internal utility functions, marketing site code.

100% test coverage produces brittle test suites that slow development. Coverage on critical paths produces a safety net for bugs that cost real money.

### 5.2 Voice agent quality

Voice agent quality is the product. It cannot be tested by traditional unit tests. The Constitution requires a separate quality pipeline:

- Every prompt change to a production agent triggers a regression test suite of pre-recorded scenarios
- Initial scenario count: 30 per agent type, growing as real calls expose failure modes
- Regression scenarios are added every time a real call exposes a failure mode
- The Voice QA sub-agent reviews call transcripts weekly and surfaces conversational failures
- A documented "agent quality score" is tracked over time as a leading indicator of customer satisfaction

### 5.3 Pre-flight checks before production deploys

Before any deploy to production:

1. All tests pass on staging
2. Database migration (if any) applied to staging and staging is healthy
3. Reviewer sub-agent has produced a clean review of the diff
4. Sentry shows no new error patterns in staging from past 24 hours
5. Deploy window is not during peak customer activity
6. Documented rollback procedure exists for the change

CEO approval is required for any deploy touching: Stripe code paths, RLS policies, schema migrations, webhook signing, authentication, voice agent prompts for production agents.

---

## Section 6 — Observability and incident response

### 6.1 What we log

Structured logs (JSON) for: every API request (method, path, status, duration, customer_id, workspace_id), every external service call (service, operation, duration, success/failure), every webhook received (service, type, signature verification result), every billing event (customer_id, event type, amount, Stripe event id), every agent invocation (agent_id, conversation_id, latency, outcome).

We do not log: PII (phone numbers, names, transcript content), secrets, full request/response bodies (which often contain PII).

Logs go to Vercel logging for the web app and Sentry for errors. Critical events (signups, first calls, billing failures, agent failures during live calls) go to a Slack channel for real-time founder awareness.

### 6.2 Error monitoring

Sentry is installed in every deployable environment from day one. Every error captured with context: stack trace, request ID, customer ID, environment, agent state (where applicable).

Errors categorized:
- **P0:** customer-facing breakage during a live conversation. Alert immediately.
- **P1:** degraded experience, no direct customer call impact. Daily review.
- **P2:** internal failure, no customer impact. Weekly review.

### 6.3 Incident response

When something breaks in production:

1. Acknowledge in project Slack within 15 minutes during waking hours
2. Determine scope: customers affected, what is broken
3. Restore service first (rollback, feature flag, hot fix), root-cause later
4. Within 24 hours of resolution, write a postmortem in `docs/postmortems/{date}_{title}.md`
5. Postmortem covers: what happened, why, how we restored, what we change so it doesn't happen again
6. "What we change" goes into the Constitution as a new rule or into TRIPWIRES.md as a new check

This is non-negotiable. Postmortems are how the system gets stronger over time.

### 6.4 Graceful degradation

Every customer-facing failure mode has a defined non-broken outcome:

- Voice agent fails mid-call: escalates to configured voicemail or human fallback; call is not lost
- Orchestration engine cannot route a handoff: end-user is told a human will follow up; lead is captured and surfaced to customer
- Dashboard cannot load: customer sees a clear error message with status page link
- Billing fails for a subscription: customer notified with 7-day grace period
- External service down: adapter returns typed error, application surfaces meaningfully

No silent failures. Every failure produces a signal the customer can understand and act on.

---

## Section 7 — Agent team operating model

### 7.1 The sub-agents

AMP development is conducted by a team of sub-agents:

- **Architect:** Plans. Reads current state. Produces numbered execution plans. Cannot write code. Runs C-suite review on non-trivial plans.
- **Builder:** Executes the architect's plans. Cannot deviate. Updates state documents on completion.
- **Reviewer:** Audits diffs against plan and Constitution. Can refuse to ship. Produces at least one specific finding per review.
- **Voice QA:** Reviews voice agent call transcripts. Surfaces conversational failures. Proposes prompt improvements.
- **Researcher:** Web research, competitive analysis, customer feedback synthesis. Runs async.

Each sub-agent has its own prompt file in `.claude/agents/` referencing this Constitution. The Constitution is source of truth; sub-agent prompts are thin wrappers enforcing role-specific protocols.

### 7.2 The slash commands

- `/session-start` — Reads state, surfaces open items from last session, asks what we're working on
- `/plan {task}` — Invokes the architect to produce a plan
- `/build` — Invokes the builder to execute the approved plan
- `/review` — Invokes the reviewer to audit the current diff
- `/session-end` — Updates state documents, commits, pushes

Sessions are bounded by `/session-start` and `/session-end`. Orphaned sessions are detected and reconciled by the next `/session-start`.

### 7.3 The state documents

- `NORTH_STAR.md` — What we're building
- `CONSTITUTION.md` — How we build
- `RUNTIME_ARCHITECTURE.md` — How the product operates at runtime
- `DECISIONS.md` — Append-only architecture decision records
- `TRIPWIRES.md` — Known failure modes and detection
- `SESSION_LOG.md` — Rolling log of last 10 sessions
- `PROJECT_INVENTORY.md` — Generated on demand by the architect; never edited by hand

Sub-agents read from these at start of every invocation and write at the end. Continuity is enforced structurally.

### 7.4 Tiered confidence model

Decisions are categorized:

- **Foundational (99% confidence required):** Schema, naming, security model, wedge, pricing structure. Hard to reverse. Get scrutiny.
- **Build (95% confidence required):** Library choices, file structure, API shape. Reversible. Move with reasonable confidence.
- **Exploratory (80% confidence required):** UI, copy, onboarding flow. Deploy, learn, iterate.

When the architect brings a decision to Josh, it includes the category, the confidence level, and what would change the confidence.

### 7.5 PR discipline and the documentation carve-out

All work touching application code, schema, configuration, `.claude/` agent definitions, or any path outside `docs/` requires a feature branch, a pull request, a Reviewer audit, and Josh's explicit merge approval. This is the human gate that protects the runtime from unreviewed risk.

**Documentation-only carve-out:** Changes confined to the `docs/` directory — `NORTH_STAR.md`, `CONSTITUTION.md`, `RUNTIME_ARCHITECTURE.md`, `OPERATING_RHYTHM.md`, `DECISIONS.md`, `TRIPWIRES.md`, `SESSION_LOG.md`, `README.md`, and any files under `docs/scout/` or `docs/research/` — may be committed directly to `main` by the Builder without a pull request.

The distinction is risk: documentation carries no runtime or security risk; code does. A typo fix in `NORTH_STAR.md` should not consume a merge cycle. A line-change in `app/api/webhooks/retell/route.ts` must.

The carve-out is **path-scoped, not intent-scoped**. A "documentation" change that also touches `.claude/agents/builder.md`, `package.json`, or any other non-`docs/` file is NOT documentation-only — the entire change goes through the standard PR flow. There is no "mostly docs" exception.

Sessions that produce only `docs/` changes commit those changes directly to `main` at `/session-end` and do not open a PR. Sessions that produce any non-`docs/` change open a PR for the entire session's work.

Constitutional amendments themselves still follow Section 9 (proposal, C-suite review, CEO approval, DECISIONS.md entry, version bump). The carve-out lowers merge friction; it does not lower the amendment bar. A Section 9 amendment that touches only `CONSTITUTION.md` and `DECISIONS.md` may commit directly to `main`; one that also rewires agent files goes through a PR (this is exactly how ADR-005 itself landed).

Amendments to this carve-out require a Constitutional amendment per Section 9.

---

## Section 8 — Architectural negative space

These are anti-patterns we commit to never adopting:

- **No hardcoded values for environment-specific config.** If it differs between dev and prod, it goes in env vars.
- **No `// TODO: fix this later` without a tracked issue.** Untracked TODOs become permanent.
- **No "we'll add tests later"** for critical paths.
- **No skipping migrations.** Schema changes go through migrations.
- **No direct edits to production data.** Production data changes go through scripts that are version-controlled.
- **No `console.log` in production code paths.** Use the structured logger.
- **No mixing of customer data across customers in the same query.** RLS or explicit customer_id filtering, always.
- **No new external dependencies without justification.** Every npm package is a future security incident or maintenance burden.
- **No paid external dependencies without CEO approval.** Any package with a monthly subscription or per-call pricing requires explicit sign-off regardless of cost. Cost discipline at this stage compounds.
- **No frameworks added to "solve" a problem that doesn't exist yet.** No Redux until state management is painful. No microservices until the monolith is a problem. No GraphQL until REST is limiting us. No parallel-agent orchestrators until parallel workstreams exist.
- **No backwards-incompatible API changes without a versioning strategy.**
- **No silent failures** anywhere in the system.

---

## Section 9 — Amendment procedure

This Constitution is not immutable. It evolves as we learn. But changes happen deliberately, not incidentally.

To amend:

1. Proposed amendment written as a discrete change with reasoning
2. Reviewed by relevant C-suite perspectives
3. CEO approves or rejects
4. Approved amendments appended to DECISIONS.md with date, change, reasoning
5. Constitution updated with version bump

Amendments cannot be made silently. An agent that wants to violate a Constitutional rule must propose an amendment, get it approved, and then act.

---

## Section 10 — Multi-agent runtime architecture

This section governs the runtime behavior of AMP — how the product itself operates. Detailed design lives in `RUNTIME_ARCHITECTURE.md`; this section establishes the constitutional rules that document must respect.

### 10.1 The orchestration model

Per ADR-001, AMP owns the orchestration infrastructure. All agent execution happens on AMP-controlled systems. Customers configure agents through the dashboard; they do not directly interact with underlying services.

Three architectural layers exist:

**The Agent Layer** — Individual agents (voice, chat, SMS, email). Each agent has a single, narrow responsibility. Agents do not make routing decisions; they execute their role and report outcomes.

**The Orchestration Layer** — The brain. Receives end-user interactions, decides which agent handles them, manages handoffs, maintains shared context, escalates when needed. The orchestration layer is the platform's defensibility.

**The Surface Layer** — Dashboard, configuration, billing, customer-facing communication. The customer's view into their agent team and its performance.

The three layers communicate through well-defined contracts. Agents do not call other agents directly. Surfaces do not call agents directly. All inter-layer communication routes through the orchestration layer or through documented APIs.

### 10.2 The shared context model

Every customer has one workspace. Within a workspace, there is a single shared context store that all of the workspace's agents read from and write to. Context includes:

- End-user identity and history (when the same person interacts via multiple channels)
- Active conversation state (so a handoff from voice to SMS preserves the thread)
- Customer business rules (hours, services, pricing, knowledge base)
- Agent-specific state and learnings

The shared context is the substrate that makes "multi-agent" mean something. Without it, AMP would be a dashboard that aggregates five separate tools. With it, AMP is a coordinated team.

Constitutional rules for shared context:

- The schema for shared context is versioned. Breaking changes require migrations.
- Context is workspace-scoped. RLS enforces this. No accidental cross-workspace leakage.
- Context writes are append-only where possible (conversation events) and revision-tracked where mutation is required (agent configurations).
- Context size is bounded per workspace; old or stale context is archived, not deleted, with documented retention policy.

### 10.3 The handoff protocol

When one agent transfers a conversation to another, the handoff goes through the orchestration layer, never directly. The orchestration layer:

1. Captures the current agent's state and conversation summary
2. Selects the destination agent based on routing rules and end-user context
3. Briefs the destination agent with the captured context
4. Notifies the end-user of the transition if appropriate
5. Logs the handoff for observability and learning

Constitutional rules for handoffs:

- Every handoff produces a `handoffs` table record with: source agent, destination agent, conversation, reason, success/failure, latency
- A failed handoff has a defined fallback: the conversation routes to a human escalation path defined by the customer
- Handoffs are observable in real time on the customer dashboard
- The destination agent receives a structured brief, not a raw transcript dump — brief format is governed by a versioned schema

### 10.4 The agent contract

Every agent in AMP, regardless of type, conforms to a contract:

- Receives a structured input (channel-specific: voice call, chat message, SMS, email)
- Has access to the workspace's shared context
- Executes its role within a documented latency budget
- Emits structured events (conversation started, response generated, handoff requested, completed)
- Reports outcomes in a documented format

Constitutional rules for agents:

- Agent definitions are versioned. Production agents have a version number and a changelog.
- Agent prompts and configurations are stored in `packages/agents/` under version control. Never edited in production through the dashboard alone — dashboard edits create draft versions that go through a deploy gate.
- Every agent has a documented latency budget appropriate to its channel (voice: <500ms time-to-first-audio; chat: <2s; SMS: <5s; email: <60s).
- Every agent has a documented failure mode that does not lose the customer interaction.

### 10.5 The observability requirement

The orchestration layer is opaque by default — agents handle interactions in the background. The customer needs visibility into what their agents are doing without being overwhelmed.

Constitutional rules for runtime observability:

- Every conversation produces a real-time event stream visible on the customer dashboard
- Every conversation produces a structured summary readable in under 10 seconds
- Every conversation produces a quality signal (resolved, escalated, abandoned, error)
- The customer can drill from summary to full transcript without leaving the dashboard
- Aggregated metrics (conversations per day, handoff rate, escalation rate, quality score) are visible per-agent and per-workspace

### 10.6 What the agents check on runtime architecture PRs

- Any new agent that does not conform to the agent contract
- Any code that allows direct agent-to-agent communication
- Any code that reads or writes shared context without RLS enforcement
- Any handoff path without a defined fallback
- Any agent template without a documented failure mode
- Any change to the shared context schema without a migration

---

## What happens next

Josh reviews this Constitution at v1. We discuss any disagreement. We land on v1 ratified.

Once v1 is ratified, the next work is:

1. The Runtime Architecture document (`RUNTIME_ARCHITECTURE.md`) gets written, expanding Section 10 into a detailed design
2. The sub-agent prompts get written, each referencing the Constitution
3. The slash commands get implemented
4. Inventory of `congenial-halibut` runs against the Constitution, surfacing what exists and what needs cleanup
5. ADR-002 (the wedge decision) gets researched and recorded

The Constitution is the longest document we will ever write. Everything downstream is execution against it. Get this right and the next twelve months are easier. Get it wrong and we pay for it the way ProScore is paying for its founding decisions now.

This is v1. v2 will exist when reality teaches us something this document got wrong.
