# AMP — Runtime Architecture

**Version:** v1
**Author:** Senior Lead Architect (with C-suite review)
**Last updated:** 2026-05-12
**Status:** Architectural design document. Implementation details may evolve; the architectural principles in this document are constitutional and require amendment to change.
**Next review:** Quarterly, or upon any architectural inflection point

---

## Purpose

This document defines how AMP operates at runtime — how a customer's multi-agent team is orchestrated, how agents communicate, how shared context works, how failures are handled, and how the system scales. It expands on Section 10 of the Technical Constitution.

The North Star defines *what* we are building. The Constitution defines *how we build*. This document defines *how the product runs once built*.

---

## Section 1 — The mental model

AMP is best understood by analogy. Imagine a small business that hires five employees: a receptionist who answers the phone, a chat representative who handles the website, an SMS coordinator who follows up on leads, an email assistant who manages quote requests, and a calendar coordinator who books appointments.

These five employees do not work in isolation. They share information. When the receptionist takes a call from a customer named Sarah who wants a quote for a kitchen renovation, she does not just hang up — she tells the email assistant to follow up with a quote, tells the calendar coordinator that Sarah is available Tuesday afternoon, and adds Sarah to the SMS coordinator's list for a reminder the day before the appointment. The receptionist is not doing all of this work — she is *routing* it to the right colleague.

The five employees are managed by an office manager who decides who does what, watches the queue, makes sure nothing falls through the cracks, and escalates to the business owner when something exceeds the team's authority.

AMP is this small business in software form.

- The **agents** are the employees. Each one has a narrow, well-defined role.
- The **orchestration layer** is the office manager. It routes work, manages handoffs, watches the queue, and escalates.
- The **shared context store** is the team's collective memory. Every employee has access to what the others have learned.
- The **dashboard** is the business owner's window into the team. They see what's happening without having to micromanage.
- The **customer's configuration** is the team's playbook. The owner defines the business rules, the hours, the services, the escalation policies — and the team follows them.

The product is not "we sell you a voice agent." The product is "we run your customer-facing AI workforce, and we give you the dashboard to manage it."

---

## Section 2 — The three layers

### 2.1 The Agent Layer

Individual agents that execute specific roles. Each agent has a single channel (voice, chat, SMS, email, etc.) and a single, narrow responsibility within that channel.

**Properties of the agent layer:**

- Agents do not make routing decisions. They execute their role.
- Agents have access to shared context but cannot directly modify another agent's configuration or state.
- Agents emit structured events that the orchestration layer consumes.
- Agents conform to the Agent Contract (Constitution Section 10.4).
- Agents are versioned and have changelogs.

**The agent types in v1:**

| Agent Type | Channel | Primary Role | Typical Latency Budget |
|---|---|---|---|
| Receptionist | Voice | Inbound call handling, qualification, routing | <500ms time-to-first-audio |
| Chat | Web chat | Inbound chat handling, qualification, routing | <2s |
| SMS Responder | SMS | Inbound SMS, follow-up sequences | <5s |
| Email Assistant | Email | Inbound email triage, quote requests | <60s |
| Booking | Multi-channel | Calendar coordination across all channels | <2s |

**The agent types in v2 (planned, not in initial build):**

- Outbound caller (proactive lead callback)
- Knowledge base curator (ingests customer documents to inform other agents)
- Performance analyst (reads conversation outcomes and surfaces patterns)

### 2.2 The Orchestration Layer

The brain. Decides routing, manages handoffs, maintains shared context, escalates to humans when needed.

**Properties of the orchestration layer:**

- Single source of truth for "what is happening in this workspace right now"
- Receives all agent events
- Owns the handoff protocol
- Enforces business rules defined by the customer
- Surfaces real-time state to the dashboard
- Records everything for observability and learning

**Components of the orchestration layer:**

- **Router:** Decides which agent handles a new interaction based on channel, end-user history, and customer rules
- **Handoff Manager:** Coordinates transitions between agents
- **Context Broker:** Reads and writes shared context with proper access control
- **Escalation Engine:** Detects when human intervention is required and routes to the customer's defined escalation paths
- **Event Bus:** Internal message system carrying events between components

The orchestration layer is the moat. Single-agent voice products do not have this layer. Building it correctly is the central engineering challenge.

### 2.3 The Surface Layer

Customer-facing interfaces. Dashboard, configuration, billing, marketing.

**Properties of the surface layer:**

- Read-mostly relationship with the orchestration layer
- Configuration changes go through a deploy gate (draft → review → activate)
- No direct database writes outside of the documented APIs
- Optimized for the non-technical operator

**Surfaces in v1:**

- Dashboard (live conversation view, history, metrics, agent status)
- Configuration (business rules, hours, services, escalation paths, agent templates)
- Billing (subscription management, usage tracking, invoices)
- Onboarding (signup flow, initial agent setup, phone number provisioning)

**Surfaces in v2 (planned):**

- Analytics (deeper performance insights)
- Knowledge base manager (customer-uploaded documents that inform agents)
- Team management (multi-user access for businesses with staff)

---

## Section 3 — The shared context model

The shared context is the substrate that makes "multi-agent" mean something. Without it, AMP is a dashboard aggregating five separate tools. With it, AMP is a coordinated team.

### 3.1 What is in shared context

**End-user identity:** When the same person interacts via multiple channels, they should be recognized as one end-user. The identity layer maintains:

- Phone number(s)
- Email address(es)
- Names provided in any conversation
- A unified end-user record per workspace, with cross-channel identity resolution

**Conversation state:** The current state of any active or recent conversation, including:

- Channel
- Active agent
- Conversation summary
- Outcome (resolved, escalated, in progress, abandoned)
- Linked to end-user identity

**Customer business rules:** The customer's configuration that all agents respect:

- Hours of operation
- Services offered
- Pricing rules
- Escalation paths
- Knowledge base (documents, FAQs)
- Brand voice and tone

**Agent learnings:** Aggregated insights from past conversations that improve future agent performance:

- Frequently asked questions
- Successful resolution patterns
- Edge cases that required escalation
- Customer preferences (e.g., "always confirm appointment by SMS, not email")

### 3.2 Data model for shared context

The shared context is implemented as a set of Postgres tables in the customer's workspace, with RLS enforcing workspace isolation.

Tables involved:

- `workspaces` — One row per customer
- `agents` — Agents deployed in a workspace
- `agent_configurations` — Versioned configurations for each agent
- `end_users` — Identity records, one per unique end-user per workspace
- `conversations` — One row per conversation, with channel and outcome
- `conversation_events` — Append-only event stream within a conversation
- `handoffs` — Records of inter-agent transitions
- `escalations` — Records of human-required escalations
- `business_rules` — Customer's configuration (hours, services, etc.)
- `knowledge_base_items` — Customer-uploaded documents and FAQs
- `agent_learnings` — Aggregated insights surfaced over time

Detailed schemas for each table are produced during the build phase and tracked through `supabase/migrations/`.

### 3.3 Access patterns

- **Read by agents:** Agents read context relevant to their current conversation through the Context Broker
- **Write by agents:** Agents write conversation events and proposed identity updates; the Context Broker validates and persists
- **Read by orchestration:** The orchestration layer reads broadly to make routing decisions
- **Read by surfaces:** The dashboard reads aggregated views; configuration surfaces read business rules
- **Write by surfaces:** Customers write to configuration through the surface; surfaces never write to conversation state directly

### 3.4 Workspace isolation

Every read and write is workspace-scoped. RLS policies enforce this at the database level. No code path can accidentally read or write across workspaces.

This is the most important security property of the system. Violating it leaks customer A's customer data into customer B's view. The Constitution mandates RLS on every table and the reviewer sub-agent halts any PR that would weaken it.

---

## Section 4 — The handoff protocol

When one agent transfers a conversation to another, the handoff goes through the orchestration layer. Direct agent-to-agent communication is prohibited.

### 4.1 Handoff flow

1. **Source agent decides handoff is needed.** Triggers vary: end-user requests a different channel ("can you text me?"), conversation moves outside the source agent's competence (a quote request to a receptionist), end of conversation hands off to a follow-up agent (SMS reminder after a booking)
2. **Source agent emits a handoff event** to the orchestration layer with: conversation id, target agent type, structured brief, reason
3. **Orchestration layer validates the handoff** — does a target agent exist? Is the target agent available? Are there business rules that block this handoff?
4. **Orchestration layer creates a `handoffs` table record** with the full context
5. **Orchestration layer briefs the destination agent** with a structured payload (not a raw transcript)
6. **Destination agent acknowledges and takes over.** Conversation state is updated to reflect the new active agent
7. **End-user is notified if appropriate.** Some handoffs are invisible to the end-user (voice agent invoking the booking system in the background); others require disclosure ("I'm going to send you a text with the details")

### 4.2 The handoff brief format

The destination agent does not receive a raw transcript dump. It receives a structured brief:

```typescript
{
  conversation_id: uuid,
  source_agent: { id: uuid, type: agent_type },
  end_user: { id: uuid, name?: string, phone?: string, email?: string },
  summary: string,           // 2-3 sentence human-readable summary
  intent: enum,              // booking | quote | inquiry | complaint | other
  key_facts: object,         // Structured data extracted by source agent
  context_references: uuid[], // IDs of relevant past conversations or KB items
  urgency: enum,             // low | normal | high
  customer_preferences: object, // Communication preferences for this end-user
}
```

This format is versioned. Changes to it are migrations. Agents are built against a specific brief version.

### 4.3 Failed handoffs

If a handoff cannot be completed (target agent unavailable, end-user unreachable on target channel, business rules block it), the orchestration layer routes to the customer's defined escalation path:

- Default: notify customer via configured method (Slack, SMS, email) with conversation summary
- Customer can configure custom escalation paths per scenario
- The conversation is never lost — it always lands somewhere

### 4.4 Constitutional rules for handoffs

- Every handoff produces a `handoffs` table record
- A failed handoff has a defined fallback
- Handoffs are observable in real-time on the dashboard
- The destination agent receives a structured brief, not a raw transcript
- Brief format is versioned

---

## Section 5 — The agent contract

Every agent in AMP, regardless of type, conforms to a contract. This is what makes the system extensible — new agent types can be added without redesigning the orchestration.

### 5.1 The contract

```typescript
interface Agent {
  // Identity
  id: uuid;
  type: agent_type;
  version: string;
  workspace_id: uuid;

  // Lifecycle
  initialize(config: AgentConfiguration, context: SharedContext): Promise<void>;
  shutdown(): Promise<void>;

  // Operation
  handleInteraction(input: ChannelInput): Promise<AgentResult>;
  receiveHandoff(brief: HandoffBrief): Promise<void>;

  // Metadata
  latencyBudget: number; // milliseconds
  failureMode: FailureMode;
  capabilities: Capability[];
}
```

The contract defines the minimum interface. Individual agent types extend it with channel-specific methods (voice agents handle audio streams, chat agents handle text streams, etc.).

### 5.2 Agent definition

Agents are defined in `packages/agents/{type}/` with:

- `prompt.ts` — The prompt template
- `config.ts` — Default configuration and Zod schema for customer overrides
- `handlers.ts` — Channel-specific handlers
- `tests/` — Regression test scenarios
- `CHANGELOG.md` — Version history

Customer-specific configurations override the defaults through the dashboard. The merged configuration (default + customer overrides) is what the agent operates with.

### 5.3 Agent versioning

Agents are versioned independently. A customer's workspace pins specific versions of each agent. Updates roll out through the deploy gate:

1. New agent version is deployed to staging
2. Regression test suite runs
3. Reviewer sub-agent approves the diff
4. New version is deployed to production but not activated for any customer
5. Selected customers (initially: Josh, beta testers) opt in to the new version
6. After 7 days without incidents, version becomes the default for new customers
7. Existing customers can opt in or remain on their pinned version until they choose to upgrade

No silent agent updates. Customers see what version they are on and can roll back if they want to.

---

## Section 6 — Failure handling

Multi-agent systems fail in ways single-agent systems do not. We design for failure from day one.

### 6.1 Failure modes

**Single-agent failure:** One agent encounters an error during a conversation.

- Voice agent: graceful fallback to configured voicemail with custom message
- Chat agent: graceful fallback to "I'll have someone reach out to you shortly" + lead capture + customer notification
- SMS/Email: graceful fallback to manual customer review queue

**Orchestration failure:** The orchestration layer itself encounters an error.

- New conversations route to manual review queue with notification to customer
- Existing conversations continue with their current agent (degraded mode — no handoffs possible)
- Dashboard shows "platform issue, conversations being captured manually"

**External service failure:** Retell, ElevenLabs, Twilio, etc. fail.

- See Constitution Section 3.4 (Dependency contingency)

**Database failure:** Supabase fails.

- Total platform outage. Documented and accepted.
- Status page communicates outage to customers
- Postmortem after recovery

### 6.2 The "no silent failures" principle

Every failure must produce a signal:

- To the end-user, where appropriate (voice agent fallback message, chat fallback message)
- To the customer (dashboard notification, Slack/email alert)
- To the AMP team (Sentry, Slack channel)

A failure that goes unobserved is a failure that compounds. The Constitution requires graceful degradation, not silent recovery.

### 6.3 Recovery procedures

Every failure mode has a documented recovery procedure:

- **Conversation stuck in handoff:** Manual unstick via admin tool; root-cause investigated
- **Agent producing bad outputs:** Roll back to previous agent version
- **Context corruption:** Restore from append-only event stream
- **Workspace data leak (P0):** Immediate audit, customer notification, postmortem

---

## Section 7 — Scale considerations

We are not optimizing for scale at v1. We are designing for scale from the start so that v2 is not a rewrite.

### 7.1 What scales linearly with customers

- Database storage (each customer's context, conversations, recordings)
- API costs (each agent invocation costs API spend)
- Telephony costs (each voice call costs minutes)
- Sentry events, logs

These scale linearly and are priced into the customer tiers. Unit economics work as long as per-customer costs stay below per-customer revenue.

### 7.2 What does not scale linearly

- Orchestration layer compute (shared across all workspaces, scales with concurrent activity, not customer count)
- Web app serving (shared across all customers)
- Database connections (pool, shared)

These are the components that benefit from scale. As customer count grows, per-customer overhead decreases.

### 7.3 Architectural decisions that protect scale

- **Workspace isolation via RLS, not separate databases:** Single Supabase project, RLS-enforced isolation. Cheaper than multi-tenant database architecture; less performant at very large scale (10,000+ customers), but appropriate for our trajectory.
- **Adapter pattern for external services:** Allows provider replacement without rewriting application code.
- **Append-only event streams for context:** Allows efficient point-in-time queries and replay; expensive in storage, cheap in compute.
- **Background job queue for non-real-time work:** Long-running operations (transcription, learning extraction, batch updates) don't block real-time agent operation.

### 7.4 When to reconsider

If any of the following become true, we revisit the scale architecture:

- Customer count exceeds 5,000 and per-tenant performance degrades noticeably
- Concurrent conversation count exceeds 1,000 and the orchestration layer becomes a bottleneck
- Database storage exceeds Supabase's economical tier and a sharded approach becomes attractive
- A specific customer segment requires a dedicated infrastructure tier (rare, but possible)

None of these are near-term concerns. Documented for completeness.

---

## Section 8 — The observable customer experience

What does the customer see when AMP is running?

### 8.1 First impression (signup to first call)

1. Customer signs up at amp.app with email
2. Magic link to email, click to verify
3. Onboarding flow:
   - "What's your business name?"
   - "What industry?" (selects from predefined verticals)
   - "What hours are you open?"
   - "What services do you offer?" (free text or predefined options)
4. Phone number provisioning:
   - "We'll give you an AMP phone number you can forward your existing line to"
   - Number is allocated from Twilio inventory
   - Test call from AMP to verify the agent works
5. First call from a real customer:
   - Receptionist agent answers
   - Customer hears a natural human-like voice
   - Call is logged on the dashboard within 30 seconds of ending

Time from signup to first successful real call: target <60 minutes.

### 8.2 Ongoing experience (daily use)

The customer logs into AMP once a day, or doesn't log in at all. The product works in the background.

When they do log in, they see:

- **Today's activity:** conversations handled, by agent, with outcomes
- **What needs your attention:** escalations, missed handoffs, ambiguous outcomes
- **Trends:** week-over-week conversation volume, resolution rate, escalation rate
- **Top issues:** patterns surfaced by agent learnings ("you've had 12 questions about evening availability this week — want to update your hours?")

They can drill into any conversation, see the transcript or recording, and intervene if needed. Most days, they do not intervene. The product runs.

### 8.3 The success metric for customer experience

If a customer logs in less than once per week after the first month, the product is working. Reduced surface time is the goal, not increased engagement. AMP is not a social network. It is infrastructure.

---

## Section 9 — Open architecture questions

These are explicitly unresolved and will be decided during the build phase with more information than we have today.

1. **The framework choice for the orchestration engine.** Build from scratch (full control, more work) or build on top of a framework like LangGraph or Mastra (faster to first version, but adds a dependency and a learning curve). Recommendation lean: build from scratch, because the orchestration layer is the moat and dependencies on third-party agent frameworks create coupling.

2. **The model selection per agent.** Should every agent run on Claude? On a mix? On the cheapest capable model per task? Cost vs. quality vs. consistency tradeoff. To be benchmarked during build phase.

3. **The persistent memory mechanism.** Beyond conversation context, agents could have long-term memory of an end-user's history. Where does this live? How is it summarized? When does it get re-injected into prompts? Research required.

4. **The marketplace question.** Should third parties be able to build agents for AMP's platform? Eventually yes, almost certainly. Not in v1. The agent contract is designed to make this possible but the marketplace is a v2+ feature.

5. **The mobile experience.** The customer-facing dashboard is web-first. Do we need a mobile app? Push notifications via the web app may be sufficient for v1. Native app deferred until customer feedback demands it.

---

## What happens next

This document is v1. The orchestration design will get more specific as we build. The principles in this document are constitutional and require amendment to change. The implementation details will evolve.

Next concrete steps:

1. CEO reviews this document and the North Star v1 and Constitution v1
2. ADR-002 (the wedge decision) gets researched and recorded
3. The sub-agent prompts get written
4. The slash commands get implemented
5. The inventory of `congenial-halibut` runs and we see what already exists vs. what we're building from scratch
6. The build phase starts when ProScore launches

The orchestration layer is the most important thing AMP will ever build. This document is the start of getting it right.
