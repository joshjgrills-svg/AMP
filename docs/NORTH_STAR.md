# AMP — North Star

**Version:** v1
**Author:** PM / Senior Lead Architect (with C-suite review)
**Last updated:** 2026-05-12
**Supersedes:** v0 (drafted earlier same day; rewritten after the multi-agent platform clarification and the parallel-then-primary commitment from CEO)
**Next review:** Quarterly, or upon any pivot of the wedge, business model, or commitment level

---

## What AMP is

AMP is the platform that runs a professional service business's AI workforce.

A small business — a contractor, a dental practice, a law office, a real estate brokerage — signs up for AMP and deploys a coordinated team of AI agents that handle their customer-facing work. A voice agent answers their phone. A chat agent handles their website visitors. An SMS agent follows up on leads. An email agent manages quote requests. The agents share context with each other and with the business owner. They hand off work between themselves intelligently. They learn from every conversation. They operate as a unified team, not as five disconnected tools.

The business owner sees one dashboard. Receives one bill. Has one support contact. Configures their agent team in under thirty minutes the first time, and rarely touches it again. Their agents work twenty-four hours a day, never call in sick, never quit, and produce better results than the human staff they would have otherwise hired — at roughly one-tenth the cost.

AMP is not a tool. AMP is the system of record for how AI does work inside a small business. The agents are the visible product. The platform underneath — orchestration, shared context, quality controls, observability, billing, the coordination logic that makes the agents work as a team rather than as a collection — is the actual business.

## Who AMP is for

**Primary buyer (first 100 customers):** Owner-operators of professional service businesses doing $500K to $5M in annual revenue. They are the receptionist, the salesperson, the marketer, and the operator — usually all at once. They lose money every week to missed calls, slow response times, and after-hours leads that go to a competitor before they can call back. They have tried hiring help. They could not find good people, could not afford them, or could not keep them. They are technology-curious but not technology-fluent. They will buy a product that demonstrably solves their problem in under thirty minutes. They will not buy a product that requires technical configuration, a sales call, or a procurement process.

**The vertical wedge:** To be determined by the Architect after analysis. The candidates are home services contractors, dental practices, law firms (specifically personal injury and family law intake), and real estate brokerages. The decision will be made as ADR-002 with full reasoning. Home services was the convenience answer from CEO's adjacent work on ProScore. Better analysis is required before committing.

**Not the buyer:** Enterprise companies. Fortune 500 customers. Anyone with an existing call center, an in-house customer success team, or a procurement process. Anyone whose buying decision requires a committee. Anyone who wants an API and the ability to write custom integrations. AMP serves the operator who needs the problem solved, not the buyer who needs to evaluate vendors.

## Why now

Three conditions converged in the last eighteen months that make AMP both possible and necessary.

**Voice AI crossed the line from obvious-robot to indistinguishable-from-human** for short structured conversations. Retell, ElevenLabs, and the underlying models from Anthropic and OpenAI now produce voice interactions that book appointments, qualify leads, and handle objections at human-or-better quality for the specific domains AMP serves. Two years ago this was a research demo. Today it is a deployable product. AMP would have been impossible to build in 2023. By 2027 the window for an independent platform like AMP will be narrower because the giants will have caught up.

**The cost structure inverted.** An AI agent handling 100 customer interactions per month costs roughly thirty dollars in underlying API spend. A human receptionist doing the same costs twenty-five hundred dollars. Even after AMP's platform margin, the value proposition for the business owner is no longer "AI is cheaper than humans" — it is "AI is so much cheaper that not using it is a strategic mistake." Small businesses that adopt AMP-equivalent platforms outcompete the ones that do not. This is no longer a debate. It is a force.

**The agent orchestration category is forming but not yet won.** Sierra and Decagon have raised significant capital but are focused on the enterprise segment. Salesforce Agentforce, Microsoft Copilot Studio, and OpenAI's Assistants API serve developers and large companies. The under-$10M-revenue segment — small businesses without technical staff who need a productized solution — is currently underserved. The category is moving fast and the window to establish a defensible position in this segment closes in twelve to twenty-four months. AMP exists to win that window.

## What "won" looks like

The timeline assumes ProScore launches in the next two to four weeks. Until ProScore is live, AMP is in foundation mode. The targets below count from the date AMP receives full founder attention, not from today.

**12 months after AMP goes primary (estimated mid-2027):** 100-300 paying customers across the chosen vertical wedge. $750K to $1.5M ARR run rate, with $1M as the working target. 85%+ gross retention. Demonstrable proof that the multi-agent platform thesis works for at least one customer segment. At least three agent types in production (voice, chat, SMS at minimum). A clear path to a second vertical based on what we learn from the first.

**24 months (mid-2028):** 1,500-3,000 paying customers. $10M to $20M ARR. The platform has crossed the threshold where the network effects start mattering — agent performance is measurably better than what any single customer could achieve alone, because the platform learns from every conversation across the customer base. Acquisition cost is dropping, not rising. AMP is recognized as the default answer in the verticals we have entered.

**36 months (mid-2029):** $40M to $60M ARR. Three to five verticals served. Series A or Series B decision based on whether we want to compound capital or compound revenue. Multiple competitive moats compounding simultaneously: customer data, agent performance, brand recognition, switching costs. AMP is acquired or independent with a credible path to $100M ARR.

**The deeper bet:** Every professional service business in North America — somewhere between five and ten million businesses — will operate an AI agent team within five to seven years. The platform that becomes the default system of record for that team in the under-$10M-revenue segment is worth fifteen to thirty billion dollars at scale. That is the prize. AMP is built to win it.

## What AMP is explicitly not

**Not a developer tool.** Vapi, Bland, Retell, the Twilio voice ecosystem, and the general "build your own agent" category serve technical builders. AMP serves the non-technical operator. The dashboard, the configuration flow, the language we use, the support we offer, the documentation we write — all of it assumes the buyer cannot read code and does not want to. The day we ship an API as a primary product is the day we have lost our positioning.

**Not enterprise software.** No SSO requirements for the first hundred customers. No procurement cycles. No custom contracts. No sales engineers. No "let's set up a discovery call." If a customer needs more than thirty minutes to decide, they are not our customer. AMP grows by serving the underserved many, not by chasing the lucrative few. Enterprise can come later if the unit economics work. It is not the wedge.

**Not a horizontal platform.** AMP will never try to be everything for every business. The bet is that vertical-specific agents (a voice agent designed specifically for plumbers, with knowledge of permits and rough-ins and emergency dispatch) outperform generic agents by enough to justify a vertical-specific platform around each one. We will say no to opportunities that pull us toward horizontal. Going wide is how startups die. Going deep in one vertical, then deep in the next, is how platforms get built.

**Not a single-agent product.** AMP could ship faster as "we sell you a voice agent" and the market would buy it. We are choosing not to. A single-agent product is a feature, not a company. The defensibility, the customer value, and the eventual outcome require the multi-agent platform. We are taking the harder road deliberately.

**Not ProScore's child.** AMP is a standalone company with a standalone customer base, a standalone product, and a standalone strategic identity. ProScore may eventually become an AMP customer, and that integration will be interesting. But AMP's success is measured by the other 99% of its customers who have no connection to ProScore. We do not architect AMP for ProScore's needs. We architect AMP for AMP's customers.

**Not a partnership.** AMP is solely Josh's company. No partners, no co-founders, no equity splits, no shared decision rights. This is a strategic simplification that enables faster iteration and a cleaner cap table.

## The constraint that defines us

Josh is the sole operator. There is no engineering team, no sales team, no support team, no executives. There is one founder, AI tooling, and time.

Until ProScore launches (estimated two to four weeks from this document), AMP receives partial attention — perhaps ten to fifteen hours per week, focused on foundation work (documents, architecture, agent team setup, inventory, wedge decision). Active product development does not begin until ProScore is live and stable.

After ProScore launches, Josh's available time for AMP rises to thirty-five to forty-five hours per week. This is the operating reality the build plan must respect. A feature that requires three people to operate is not a feature we ship. A sales motion that requires founder-led demos at scale is not a sales motion we run. A customer who needs hand-holding to onboard is not a customer we serve.

This constraint is not a limitation. It is the strategic advantage. The competitors building AMP-equivalent products with venture funding and fifty-person teams are slower than us, more expensive than us, and structurally unable to serve the customer segment we are designed for. We win by being the version of this product that one motivated operator with AI tooling can actually build and run — and we make that limitation invisible to the customer.

## The two phases

**Foundation Phase (now until ProScore launches, ~2-4 weeks):**

The goal of this phase is to land all of the substrate that makes the build phase fast and disciplined. No customer-facing features are built. The deliverables are:

- North Star (this document) at v1, ratified
- Technical Constitution at v1, ratified
- Runtime Architecture document at v1, defining the multi-agent orchestration design
- Five sub-agents installed in `.claude/agents/`: Architect, Builder, Reviewer, Voice QA, Researcher
- Five slash commands installed in `.claude/commands/`: session-start, plan, build, review, session-end
- Inventory of the `congenial-halibut` Codespace, surfacing what already exists and what compliance gaps need cleanup
- Wedge decision logged as ADR-002 with full analysis
- Project Roadmap document defining the work breakdown for the Build Phase

The Foundation Phase succeeds when, on the day ProScore launches, AMP can start building product within the first hour with full clarity on what to build, how to build it, and against what standards.

**Build Phase (begins on ProScore launch, lasts 9-12 months to first revenue):**

The goal of this phase is to ship the minimum charge-able multi-agent product to the chosen wedge vertical and reach $1M ARR within twelve months of the phase starting. The deliverables are the actual product, the marketing site, the onboarding flow, the billing system, the customer support apparatus, and the first hundred paying customers.

The Build Phase will be broken into milestones in the Project Roadmap document. The milestones will be reviewed against this North Star at each transition.

## The kill criteria

We stop building AMP if any of the following are true at the twelve-month-after-primary mark (estimated mid-2027):

1. Fewer than fifty paying customers and the curve is not bending upward
2. Customer acquisition cost exceeds two thousand dollars per customer with no path to reduce it
3. Net dollar retention falls below seventy-five percent after the first ninety days
4. A horizontal platform ships an offering that makes AMP's value proposition redundant for our target customer, and we cannot find a defensible differentiator within ninety days
5. Founder bandwidth across personal obligations and AMP becomes structurally insufficient to give AMP what it needs to win

We do not pivot AMP into something else. We either ship it as designed or shut it down cleanly. Half-measures kill startups slower than failure does, and the founder time invested in a slow death is more valuable spent on something with a real path to winning.

## The future decisions this document leaves open

These are explicitly deferred to future ADRs. They are not gaps — they are decisions that should be made with more information than we have today.

- **ADR-002:** Vertical wedge selection (home services / legal intake / dental / real estate). To be decided by Architect after market analysis, before any product development begins.
- **ADR-003:** Pricing structure and tier design. To be decided after wedge selection, before any customer-facing surface is built.
- **ADR-004:** Company name and brand. AMP is the working name. Real brand work happens in the Build Phase.
- **ADR-005:** Funding strategy. Bootstrap to $1M ARR is the default. Capital raise becomes a decision at $1M ARR or upon competitive pressure.
- **ADR-006:** Acquisition vs. IPO orientation. Premature to decide. Revisit at $10M ARR.

## How this document is used

The North Star is the test we apply to every consequential decision in AMP. Before any plan ships, before any architecture is finalized, before any feature is built, the test is: does this move us toward what this document describes?

If the answer is yes, we proceed. If the answer is no, we either revise the plan or revise the North Star — but we never proceed in contradiction with it silently. The sub-agents will check plans against this document. The reviewer will check diffs against it. The C-suite reviews will pressure-test against it.

The North Star is not a marketing document. It is the operating system for strategic alignment between the founder, the agent team, and any future humans who join AMP. Its job is to outlive any individual conversation and any individual decision, so that when we are deep in execution and the path forks, we have something to navigate by.

This is v1. v2 will exist when reality teaches us something this document got wrong.
