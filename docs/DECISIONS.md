# AMP — Decisions

This is the append-only Architecture Decision Record (ADR) log for AMP. Every load-bearing decision is recorded here with date, context, alternatives considered, reasoning, and what would change the decision. Decisions are not edited after being recorded — they are superseded by new decisions that reference them.

---

## ADR-001 — Orchestration Model: AMP as the Orchestration Brain

**Date:** 2026-05-12
**Status:** Accepted
**Decided by:** CEO (Josh) with PM/Architect recommendation
**Supersedes:** None
**Superseded by:** None

### Context

AMP is positioned as a multi-agent management platform for professional service businesses. The fundamental architectural question is who owns and runs the underlying agent infrastructure: AMP, or the customer.

### Decision

AMP owns and runs the underlying agent infrastructure. Customers configure their agents through the AMP dashboard but do not interact directly with the underlying services (Retell, ElevenLabs, Twilio, etc.). One signup, one bill, one dashboard, one support contact. The orchestration logic, the shared context layer, and the agent execution all live on AMP-controlled infrastructure.

### Alternatives considered

**Option B: AMP as the orchestration framework.** Customers bring their own infrastructure (their own Retell account, their own ElevenLabs account, etc.) and AMP coordinates them. Rejected because the target customer is a non-technical owner-operator who will not sign up for five separate services. The UX burden alone disqualifies this for our segment, and the defensibility is significantly weaker.

### Reasoning

Three reasons drove this decision:

1. **The target customer's buying behavior demands it.** Owner-operators of $500K-$5M service businesses decide and configure in one session with one credit card. Option B's "sign up for five services and configure each" flow is incompatible with this. We do not get to choose a customer who behaves differently than they do.

2. **Defensibility.** Option A creates a moat through accumulated customer data, agent performance learnings, and platform-wide improvements that compound. Option B is a thin coordination layer customers can route around as the underlying services become more capable. The companies that win this category (Sierra, Decagon, the eventual winner) are all Option A.

3. **Quality control.** Voice agent quality is the product (per North Star). Option A gives us full control over the execution path, the observability, and the iteration loop. Option B introduces variability we cannot manage — a customer's misconfigured Retell account becomes our reputation problem with none of our control.

### Trade-offs accepted

- **Infrastructure risk concentrates on AMP.** A Retell outage becomes an AMP outage from the customer's perspective. We manage this through Constitution Section 3.2 (adapter pattern, multiple providers per category) and Section 6.4 (graceful degradation).
- **Infrastructure costs scale with usage.** Margin pressure increases as customers scale. We manage this through Constitution Section 8 (cost discipline) and through pricing tier design that reflects actual usage costs.
- **We are on the hook for every external service we depend on.** This is the price of the moat. We accept it.

### What would change this decision

We would revisit Option A if:

1. A horizontal platform (OpenAI, Anthropic, Google) ships an agent orchestration product so good and so cheap that our infrastructure ownership becomes a cost burden without a corresponding moat benefit
2. The infrastructure costs of running customer agents exceed 50% of revenue per customer at scale, and we cannot find a path to reduce them
3. A specific customer segment we want to serve (enterprise, technical buyers) genuinely prefers Option B and represents enough revenue to justify a parallel offering

None of these are likely in the next 18 months. The decision stands.

### Implementation implications

This decision drives the following architectural commitments, which will appear in the Technical Constitution v1 and the Runtime Architecture document:

- All agent execution runs on AMP-controlled infrastructure (Vercel, Supabase, plus the adapter layer to Retell/ElevenLabs/Twilio)
- A shared context layer (database + memory) is mandatory — all of a customer's agents read from and write to it
- An orchestration engine decides routing, handoffs, and escalation between agents
- Customer-facing surfaces (dashboard, configuration, billing) treat the underlying services as implementation details, never exposed to the customer
- The adapter pattern (Section 3.2) becomes load-bearing — service replacement must be possible without customer impact

---

*Future decisions append below this line. Decisions are numbered sequentially (ADR-002, ADR-003, etc.) and never renumbered.*
