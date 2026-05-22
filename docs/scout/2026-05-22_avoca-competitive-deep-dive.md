---
date: 2026-05-22
source-of-task: Architect / Josh, follow-up to home-services brief 2026-05-18
purpose: Competitive deep-dive on Avoca AI. This is the input ADR-004 was missing — ADR-004 evaluated Claude for Small Business as the competitive threat and did not assess Avoca, which the home-services customer brief flagged as the actual category-leading competitor in trades voice AI. Negative verdict permitted and explicitly invited — if Avoca structurally threatens AMP's home-services wedge, say so with evidence.
author: AMP Ecosystem Scout
confidence: **High** on Avoca's funding, customer count, scale, and segment (multiple aligned primary sources — Fortune, PR Newswire, the founders' own statements, third-party reviews, and customer-page evidence). **High** on Avoca's integration breadth (their own integrations page lists 70+ platforms including Housecall Pro, Jobber, FieldEdge — this is a significant correction from the home-services brief's working assumption that Avoca was ServiceTitan-locked). **Medium** on pricing specifics ($1K-$3K/mo range is corroborated by three independent third-party sources but Avoca has no public pricing; treat as estimate). **Medium** on Avoca's downmarket trajectory (hiring signals are mixed; no PLG product visible; the New Verticals Lead role signals horizontal expansion rather than downmarket). **Low** on Avoca's product weaknesses — almost all complaint signals come from competitor-authored comparison content and should be treated as biased; I could not find independent forum or G2/Capterra reviews. **High** on the strategic implication: AMP's wedge as written in ADR-004 is more threatened than the home-services brief suggested.
---

# Scout Competitive Deep-Dive: Avoca AI

## 1. What Avoca actually does

Avoca markets itself as the "AI Workforce for Service Businesses" — a multi-product platform organized around the contractor's full inbound and outbound communication stack, not a single voice agent.

**The product surface** (per [avoca.ai](https://www.avoca.ai/) and the [ServiceTitan marketplace listing](https://marketplace.servicetitan.com/partner/Avoca-AI)):

- **Responder (AI CSR — the flagship).** 24/7 inbound voice agent that answers calls, qualifies the caller, books jobs directly into the CRM, handles objections, routes emergencies. Sub-2-second answer latency per the [AI Automation Global deep-dive](https://aiautomationglobal.com/blog/avoca-ai-voice-agent-trades-unicorn-2026).
- **Simple Scheduler.** Customer-facing self-service booking.
- **Web Chat.** Inbound chat channel.
- **SMS.** Two-way text.
- **Speed-to-Lead (outbound).** Multi-channel response to inbound web leads — claimed <15 second response time per the avoca.ai homepage.
- **Outbound Campaigns.** AI-driven outbound calling for re-engagement, estimate follow-up, board recovery. Sila Services case study reports [80,000+ autonomous outbound calls for board recovery](https://www.avoca.ai/customers/sila-services).
- **Google LSA integration.** Native ad-platform connection.
- **Coach.** Real-time call scoring and CSR performance analytics — Avoca scores both AI and human CSR calls. Wilson Companies case study claims [call quality up from 40% to 95%](https://www.avoca.ai/) since deployment.
- **Analytics.** Booking rate, revenue attribution, performance dashboards.

**Channels covered.** Voice, SMS, web chat, email, outbound calls. This is a four-channel platform, not a voice-only product.

**Workflows automated.** Inbound answer, lead qualification, job booking (with direct CRM write-back), after-hours coverage, dispatch handoff to humans for complex/emergency calls, outbound speed-to-lead, outbound re-engagement campaigns, CSR coaching, quality assurance.

**Table-stakes vs. distinctive.** Table-stakes: 24/7 answer, basic booking, SMS. Distinctive: (a) the multi-product Responder + Coach + Outbound platform, which is genuinely broader than the Goodcall/Rosie/Sameday tier; (b) deep two-way CRM write-back (not Zapier shims); (c) the Coach product specifically — Avoca is the only vendor in this category I found that scores both AI and human CSR performance in the same product.

**Modules/SKUs.** Avoca markets the platform with at least three named pillars — Responder, Coach, and Outbound — that customers appear to license separately or as a bundle. The [contractor-toolstack review](https://contractortoolstack.com/software/avoca-ai/) frames pricing as "depending on which of the three pillars you activate," supporting the modular model.

## 2. Technology and integrations

**Inferred stack** (the most rigorous public source is [AI Automation Global](https://aiautomationglobal.com/blog/avoca-ai-voice-agent-trades-unicorn-2026), which is unverified for primary-source provenance but the only public deep-dive on Avoca's architecture; flag as inference):

- **Voice infrastructure:** ElevenLabs (TTS), Deepgram (ASR), Sonic, and the open-source Voxtral model are named. No claim of a proprietary foundation model.
- **Posture vs. horizontal platforms:** Avoca explicitly positions itself against Vapi, Retell, and Bland — framing those as "infrastructure layers" and itself as the "vertical workflow layer." This is consistent with Avoca's own pitch in [Tyson Chen's podcast appearances](https://www.ownedandoperated.com/post/owned-and-operated-revolutionizing-call-centers-with-avoca-ai-and-tyson-chen) where he emphasizes that the trades-specific conversation logic and integration depth are the moat, not the voice stack.
- **LLM:** Not publicly disclosed. Almost certainly multi-model orchestration (Claude / GPT class for reasoning, smaller models for routing) but I cannot confirm. **Flag as unverified.**
- **Sub-2-second answer latency** is claimed per the same AI Automation Global piece — competitive with the Retell/Vapi tier and consistent with what's achievable on the inferred stack. AMP's Constitution §10.4 commits to <500ms time-to-first-audio; that gap, if delivered, is a published-spec edge.

**Multi-agent posture.** Avoca's surface suggests an orchestrated multi-agent system (separate agents for inbound voice, outbound campaigns, scheduling, quality scoring, all reading/writing the same CRM state) — but the public material does not describe the internal architecture. The "Responder + Coach + Outbound" product structure implies multi-agent; the public sales pitch does not lean on it.

**Integrations — the most important correction to the home-services brief.** The home-services brief implicitly treated Avoca as ServiceTitan-anchored. **That is wrong.** Avoca's [official integrations page](https://www.avoca.ai/integrations) lists **70+ platforms**, including:

- **CRM/FSM (the critical ones):** ServiceTitan, Housecall Pro, Jobber, FieldEdge, Service Fusion, ServicePro, ServiceMinder, Thryv, GorillaDesk, Job Nimbus, Workiz, Sera, BuildOps, AccuLynx, FieldRoutes, PestPac, RealGreen, Service Autopilot, Salesforce, HubSpot, Microsoft Dynamics, Zoho, Close, GoHighLevel.
- **Telephony/call routing:** CallRail, Ringba.
- **Marketing/lead:** Google LSA, LeadPerfection, Scorpion.
- **Photo/docs:** CompanyCam.

The [Housecall Pro integration page](https://www.avoca.ai/integrations/housecall-pro) explicitly markets "5 min" setup, direct job booking, automated outbound campaigns, and emergency routing — i.e., feature parity with the ServiceTitan integration, not a shallow shim. Third-party comparison sites that frame Avoca as "ServiceTitan lock-in" (e.g., [Claudessa's comparison page](https://claudessa.com/vs/avoca)) are competitor-authored and contradicted by Avoca's primary source.

**Bottom line on integrations:** Avoca's integration moat is broader and deeper than the home-services brief assumed. The "AMP wins on non-ServiceTitan operators" argument is materially weaker than I previously implied.

## 3. Pricing and customer segment

**Pricing.** No public pricing on avoca.ai. Three independent third-party sources estimate **$1,000-$3,000/month** for typical home-services accounts ([contractor-toolstack review](https://contractortoolstack.com/software/avoca-ai/), [AI Automation Global](https://aiautomationglobal.com/blog/avoca-ai-voice-agent-trades-unicorn-2026), [Solvea's competitor analysis](https://solvea.cx/blog/best-ai-receptionist-for-hvac)). Pricing scales by call volume, CSR team size, and the number of product pillars activated. **Treat as estimate** — Avoca has not confirmed.

**Procurement model.** Demo-required, sales-led, custom quote. No self-serve sign-up visible. Implementation handled by a dedicated Implementation Manager role per Avoca's own [job listing](https://jobs.ashbyhq.com/avoca). This is a sales-led, white-glove deployment motion — the opposite of AMP's North Star "30-minute self-serve onboarding."

**Customer count and growth.**
- **800+ customers** as of April 2026, per [Fortune](https://fortune.com/2026/04/27/avoca-ai-agents-missed-calls-hvac-plumbing-roofing-kleiner-perkins-chen-shrivastava-braswell/).
- **1,000+ service businesses** referenced on Avoca's [Nexstar partnership page](https://www.avoca.ai/partners/nexstar) (more recent claim than Fortune).
- **10x growth in 2025**, surpassed 8-figure ARR, on track for $1B in jobs booked in 2026 per the [PR Newswire announcement](https://www.prnewswire.com/news-releases/avoca-raises-125m-at-1b-valuation-to-power-americas-services-economy-with-ai-302753962.html).

**Customer segment — the load-bearing finding.** This is more nuanced than either the home-services brief or Avoca's own marketing implies. Three data points:

1. **The marquee enterprise accounts are massive.** Sila Services: [3,000+ employees, 1,200 technicians, 40+ brands, thousands of daily calls](https://www.avoca.ai/customers/sila-services). My Plumber Plus: [$129M revenue, 356 employees](https://www.avoca.ai/customers/my-plumber-plus). 1-800-GOT-JUNK?: national franchise. Goettl: ~$200M+ HVAC operator. This is enterprise/PE-rollup territory.

2. **The "small family-operated" testimonials are not actually that small.** [Reliable Comfort, marketed by Avoca as a "family-operated HVAC and plumbing company,"](https://www.avoca.ai/customers/reliable-comfort) has up to $10M revenue, multi-location Indiana operation, two decades of history per [LeadIQ](https://leadiq.com/c/reliable-comfort-heating--air/5a1dbf832300005900bf3dd8). This is at or above the upper edge of AMP's sub-$5M North Star. The smallest customer Avoca prominently markets is roughly 2x larger than AMP's largest target.

3. **The third-party reviewer consensus is explicit.** [Contractor Toolstack](https://contractortoolstack.com/software/avoca-ai/) and [Claudessa's comparison page](https://claudessa.com/vs/avoca) both state Avoca is "best for 20+ CSR operations" and "$10M+ revenue companies." Claudessa quotes: "If you're a 5-person HVAC shop doing $800K in revenue, Avoca isn't built for you." [Solvea](https://solvea.cx/blog/best-ai-receptionist-for-hvac) states Avoca's pricing is impractical for sub-$1M operators. These are competitor-authored sources, but the consistency is notable.

**Net:** The home-services brief's claim that Avoca currently targets $5M+ operators is **confirmed and arguably understated** — Avoca's actual customer center of gravity looks more like $10M-$200M+ HVAC/plumbing operators, often PE-backed roll-ups or franchise systems. **The sub-$5M owner-operator segment in AMP's North Star is genuinely uncontested by Avoca today.**

## 4. Strengths

**Why Meritech and General Catalyst wrote a $125M check at $1B** ([PR Newswire](https://www.prnewswire.com/news-releases/avoca-raises-125m-at-1b-valuation-to-power-americas-services-economy-with-ai-302753962.html), [Fortune](https://fortune.com/2026/04/27/avoca-ai-agents-missed-calls-hvac-plumbing-roofing-kleiner-perkins-chen-shrivastava-braswell/)):

1. **Distribution lock-in.** ServiceTitan Gold Partner + Nexstar Network preferred vendor. ServiceTitan is the system-of-record for ~60% of trades operators above $5M; Nexstar is the largest member-owned trade buying group. When the system of record and the buying group both ship the same vendor, the path to the buyer runs through those distribution surfaces — and Avoca already owns them. AMP cannot replicate this through any reasonable amount of marketing spend; it has to win on a different vector.

2. **Real revenue, real growth.** 8-figure ARR in 2025 with 10x growth, 800+ customers, on track for $1B in jobs booked in 2026. Investor quote from Alex Clayton (Meritech): "Three years ago, AI voice for home services wasn't a category. Avoca created it." This is not a fundraising story trying to pre-empt traction; the traction was real before the round.

3. **Product depth beyond a voice agent.** The Responder + Coach + Outbound + Web Chat + Scheduler bundle is structurally broader than the AI receptionist tier (Goodcall, Rosie, Numa). Buyers at the $10M+ tier want a platform; Avoca is the only category competitor shipping one at scale.

4. **Verified customer outcomes.** [Aire Serv Sevierville: after-hours bookings 58 → 208, 90% booking rate](https://www.avoca.ai/). [Sila Services: 90% of calls handled by AI, within 2% of top human CSR performance](https://www.avoca.ai/customers/sila-services). [Wilson Companies: call quality 40% → 95%, 85% booking rate, 400 calls/week](https://www.avoca.ai/). These are vendor-published, but the specificity and the named-company attribution makes them harder to dismiss than typical case-study marketing.

5. **Trades-native conversation training.** Avoca's positioning consistently emphasizes "trades vocabulary, trades workflows, trades pricing logic" — the founders learned the segment in person at Texas trade conferences (per the [Fortune piece](https://fortune.com/2026/04/27/avoca-ai-agents-missed-calls-hvac-plumbing-roofing-kleiner-perkins-chen-shrivastava-braswell/) detailing Tyson Chen's Rescue Air encounter). This is operational depth that takes time to acquire — AMP starts from zero here.

6. **Capital and team scale.** 85 employees, hiring aggressively (19+ open roles per [Ashby](https://jobs.ashbyhq.com/avoca)), Forward Deployed Engineer roles at $160-250K, dedicated Implementation Managers, GTM Recruiter, New Verticals Lead. The org is built for white-glove enterprise sales at scale and is hiring to compress the deployment cycle further.

## 5. Vulnerabilities

I want to be careful here. **Almost every "Avoca weakness" claim I found is in competitor-authored comparison content** (Leaping AI, Claudessa, Solvea, contractor-toolstack — most of these blogs exist to convert search traffic to a competitor's demo page). I could not find G2, Capterra, Trustpilot, or independent Reddit threads discussing Avoca. The absence of negative reviews is itself a signal — Avoca either has very few unhappy customers, or has very few customers small enough to leave public reviews (consistent with the enterprise segment finding).

With that caveat, the credible vulnerability surface is:

1. **Sub-$5M operator economics don't work.** Avoca's price point ($1K-$3K/mo, estimated) and white-glove sales motion are structurally incompatible with a $500K-$3M HVAC owner-operator. The contractor-toolstack review explicitly names this: ["overkill for 1-5 person shops"](https://contractortoolstack.com/software/avoca-ai/). This is not a fixable product gap — it's a deliberate segment choice driven by the unit economics of the sales motion. **This is the structural opening for AMP.**

2. **Sales-led procurement is a friction tax in the SMB segment.** Demo-required, custom quote, contract negotiation, dedicated Implementation Manager onboarding — that motion adds 30-90 days of sales cycle that an owner-operator running a $1M HVAC business with no procurement function doesn't want to absorb. The owner wants to swipe a card and have the agent live by Monday.

3. **Coach is a niche product for very small operators.** Avoca's CSR coaching/scoring module is high-leverage at 20+ CSR operations. At a 1-3 CSR owner-operator, the entire Coach product line is wasted spend. AMP doesn't need to compete on it.

4. **Voice latency, if Avoca is at ~2 seconds, is meaningfully worse than what's achievable.** Sub-2-second is the claim; the industry frontier (Retell with real-time interrupts) is ~600ms-1s. If AMP delivers on its <500ms Constitution commitment, it's a published-spec edge. This will matter to product-savvy buyers but probably not to the typical owner-operator who is comparing AI to "voicemail."

5. **Multi-vertical expansion risks vertical depth dilution.** Avoca is [actively expanding into moving, automotive, junk removal, property management](https://www.prnewswire.com/news-releases/avoca-raises-125m-at-1b-valuation-to-power-americas-services-economy-with-ai-302753962.html) with a dedicated New Verticals Lead hire. This is necessary for the $1B valuation thesis (trades alone won't support it) but creates internal competition for engineering and ops attention. **A pure-play home services competitor that doesn't expand horizontally could plausibly out-execute Avoca within trades.** This is the most credible product-strategy opening.

6. **Confidence-limited weakness areas.** Reviewers I could find name "limited to quick straightforward interactions," "lacks self-improving AI," and "no GDPR/HIPAA/SOC 2 mention" ([Leaping AI](https://leapingai.com/blog/voice-ai-platforms-compared-leaping-ai-vs-avoca)) — but the GDPR/HIPAA claim is wrong (Avoca's own homepage advertises SOC 2 Type 2 and GDPR compliance). Treat all competitor-authored weakness claims as suspect.

## 6. Downmarket signals

This is the question that most directly determines AMP's wedge timing. The evidence is mixed and, on balance, suggests Avoca is **not** prioritizing the sub-$5M segment in the near term — but is structurally positioned to enter it if it chooses.

**Signals that Avoca is moving downmarket:**

1. **70+ integrations including Housecall Pro, Jobber, Workiz** ([avoca.ai/integrations](https://www.avoca.ai/integrations)) — these are the FSMs used by sub-$5M operators. ServiceTitan customers skew >$2M; Housecall Pro and Jobber dominate <$2M. Building these integrations is the prerequisite for serving the segment, and Avoca has done the prerequisite work.

2. **Founder origin story is downmarket.** [Tyson Chen originally built for his mom's acupuncture clinic](https://servicebusinessmastery.com/how-ai-is-going-to-impact-the-customer-service-side-of-home-services/) and small businesses before pivoting to trades, and the [Fortune piece](https://fortune.com/2026/04/27/avoca-ai-agents-missed-calls-hvac-plumbing-roofing-kleiner-perkins-chen-shrivastava-braswell/) features Chen explicitly framing the mission as "the people who do that work" and "those who get left behind" — language oriented toward the smaller end of the segment, not enterprise.

3. **YC W23 origin and SMB positioning in YC profile.** Avoca's [Y Combinator company page](https://www.ycombinator.com/companies/avoca) describes the target customer as "service-based SMBs" — including dentists, massage therapists, law firms — not enterprise. The Series B narrative repositioned upward, but the founding DNA is SMB.

**Signals that Avoca is NOT moving downmarket in the near term:**

1. **Hiring posture is sales-led enterprise expansion, not PLG.** Per [Ashby jobs page](https://jobs.ashbyhq.com/avoca), open roles include Implementation Manager, GTM Recruiter, Forward Deployed Engineer ($160-250K), Agent Product Manager, Growth Manager, Business Operations Manager. **No PLG / self-serve PM / Developer Relations role.** No "SMB AE" or "SDR" type role visible. The org is being built for sales-led enterprise deployment.

2. **The New Verticals Lead role is horizontal expansion, not downmarket.** Avoca is going wide (moving, automotive, property management, junk removal) before going down (sub-$5M trades). This is the rational $1B-valuation play — horizontal expansion at the existing customer-size tier scales revenue faster than going smaller in the same vertical.

3. **No "starting at $X" pricing page.** Self-serve pricing is the cleanest downmarket signal a SaaS company emits. Avoca has none. Every customer goes through a demo and custom quote — a motion that doesn't scale to sub-$5M owner-operators because the CAC math doesn't work.

4. **Marquee customer-page emphasis is enterprise.** Sila Services (40+ brands), Wilson Companies (multi-state), Granite Comfort (9 brands), Authority Brands (franchise platform) — these are the lead testimonials. The "small family operation" framing is applied to companies (Reliable Comfort, up to $10M) that are well above the AMP target.

5. **Nexstar member skew is mid-market.** Nexstar's typical member is a $5M-$50M home services operator (the [Nexstar membership profile is published in their member materials](https://www.nexstarnetwork.com/blog/newsroom/jumpstart-your-business-with-win-win-win-vendor-partnerships/)) — meaningfully above AMP's target. The flagship distribution partnership is not pointed at AMP's segment.

**Net read.** Avoca has the integrations to serve the sub-$5M segment but is not building the GTM motion (PLG product, self-serve pricing, low-touch onboarding, SMB sales hires) required to actually capture it. The opportunity cost calculus for Avoca makes this rational: a single Sila Services account is worth more than 100 sub-$5M accounts at the same gross margin and a tenth of the operational complexity. **The 12-18 month window the home-services brief named for AMP probably holds at the floor end (sub-$2M owner-operators), is at risk at the mid range ($2M-$5M), and is closed at the top ($5M+).**

## 7. AMP differentiation

This is the section I owe Josh the most honesty on. The home-services brief read "Avoca is at $5M+, AMP can win sub-$5M." That framing is **directionally correct but too generous to AMP.** Here is the more honest framing.

**Where AMP has a genuine, defensible structural opening:**

1. **The sub-$2M owner-operator who cannot absorb $1K-$3K/mo and a 60-day sales cycle.** This is a real segment, it's underserved, and Avoca's economics structurally exclude it. AMP at $200-$500/mo with 30-minute self-serve onboarding is the natural fit. **This is the core AMP wedge and the honest answer to "why does AMP exist in a world with Avoca."**

2. **The "I don't have ServiceTitan, I won't pay for ServiceTitan, I want this to work with my Google Calendar and a CSV" segment.** Even with Avoca's 70 integrations, the deep configuration depth Avoca offers is wasted on a 1-3 person shop running on Housecall Pro Basic or no FSM at all. AMP's wedge here is "works without the implementation overhead Avoca's motion requires."

3. **Pricing transparency and self-serve as a positioning weapon.** Every Avoca buyer goes through a demo. AMP publishing prices and offering self-serve sign-up is a positioning advantage in a segment where the buyer hates sales calls. This is not a product moat, but it is a sales-motion moat — and Avoca's sales motion is expensive enough to fund AMP's marketing for the same revenue.

**Where the AMP differentiation pitch is weaker than the home-services brief implied:**

1. **"AMP wins on non-ServiceTitan customers" is partially wrong.** Avoca already integrates with Housecall Pro, Jobber, FieldEdge, ServiceFusion, Workiz, and 60+ others. The differentiation argument has to be about onboarding cost and price-point, not integration coverage.

2. **"AMP wins on multi-agent vs. single-channel" is also weaker than implied.** Avoca already ships voice + SMS + chat + outbound + scheduling + coaching as a platform. They are not a single-channel competitor. The multi-agent positioning has to specifically be about the orchestration model AMP is building (per Constitution) being more flexible/extensible — and that's a hard argument to make to a contractor who just wants their phone answered.

3. **"AMP wins on latency" is real but narrow.** Sub-500ms TTFB vs. ~2-second Avoca is a real spec advantage, and customers do feel it. But it's not a top-3 selling point to an owner-operator comparing AMP to "nothing" or "voicemail." It's a top-3 selling point against Avoca specifically — and a sub-$2M customer probably wasn't going to buy Avoca anyway.

4. **"AMP wins on vertical depth" is currently false.** Avoca has 800 home-services customers, four years of trades vocabulary tuning, and lives at trade conferences. AMP has zero customers. Vertical depth is something AMP can build, not something AMP has.

**The honest one-sentence answer.** AMP exists in a world with Avoca because Avoca's GTM motion structurally cannot serve the bottom half of the trades market profitably, and the bottom half is large enough (the sub-$5M tier is ~70% of trades businesses by count per the [Statista NAICS data](https://www.statista.com/statistics/1122362/number-plumbing-hvac-contractor-smbs-firm-size-us/) cited in the home-services brief) to support a viable company. The differentiation is segment economics, not product capability.

**The honest risk to this answer.** If Avoca launches a self-serve "Avoca Lite" SKU at $299/mo with a Housecall Pro 5-minute setup, the AMP segment closes within a quarter. They have everything they need to do this except the strategic decision to deprioritize enterprise expansion in favor of segment expansion. They will probably not make that decision in 2026 because the unit economics push them upmarket. But they could.

## 8. Strategic implications

### Wedge timing

The home-services brief named a 12-18 month window. **Refine to: 18-24 months for the sub-$2M floor, 9-12 months for the $2M-$5M mid range, and effectively closed today for $5M+.** Two reasons the window may compress faster than even those estimates:

- Avoca's [new verticals expansion](https://jobs.ashbyhq.com/avoca/73aa1239-2e2e-48a5-a455-4e544ece9c26) signals they will not prioritize sub-$5M trades in the near term, which is good for AMP — but the integration breadth (70+ platforms) means the prerequisite work to launch a downmarket SKU is already done. The strategic decision is the only barrier.
- The category is moving fast. Sameday at $449/mo, Rosie at $49/mo, Goodcall, Numa — there are at least 10 competitors at AMP's intended price point already. Avoca is not AMP's only competitor in the sub-$5M tier; it's the most credible threat from above.

### Pricing implications

- **AMP's $200-$500/mo entry tier is correctly positioned.** It sits below Avoca's floor and above the toy tier ($49-$129).
- **AMP should not price above $600/mo for the inbound voice agent alone.** That ceiling preserves the "Avoca is 3-5x our price" positioning. Above it, the buyer compares directly to Avoca and loses on product depth and customer references.
- **A multi-agent platform bundle (voice + SMS + chat + outbound) can credibly clear $1,000/mo** — but only if AMP has the integration depth and customer references to compete at that price level, which it does not yet. **For 2026, hold the bundle ceiling at ~$800/mo to stay clearly below Avoca's estimated floor.**
- **The single most important pricing decision** is whether to publish pricing publicly. Avoca's refusal to publish is its biggest GTM vulnerability with the AMP segment. Publishing pricing is a strategic differentiation lever, not a marketing tactic.

### Positioning against Avoca to a contractor

When the contractor asks "what about Avoca," the honest, defensible answer is:

> "Avoca is built for $10M+ HVAC operators with 20+ customer service reps. It's a serious product and they have great customers. If you're at that scale, you should evaluate them. AMP is built for the owner-operator running 1-5 trucks who needs the phone answered and the job booked tomorrow, without a sales call or a $1,500/mo invoice. Different segment, different product."

This is the only positioning that holds against a contractor who has actually evaluated Avoca. **Do not try to compete head-to-head on product features, customer references, or integration breadth — AMP will lose all three.** Compete on segment economics, deployment speed, and price.

### ADR-004 amendment recommendations

The home-services brief recommended narrowing to HVAC + plumbing and treating roofing/electrical/GC as later phases. This deep-dive supports that recommendation and adds:

1. **The North Star segment definition needs to be sharpened to "sub-$2M revenue, 1-5 truck owner-operator"** — not "sub-$5M." The $2M-$5M tier is now a contested middle ground where Avoca can move down faster than AMP can move up. AMP's defensible territory is below $2M; ambitions to grow accounts into the $2M-$5M tier are valid but should be planned as expansion revenue, not as the wedge.

2. **The "ServiceTitan-integrated" framing should be deprioritized in AMP's roadmap.** Avoca owns ServiceTitan distribution. AMP should treat ServiceTitan as a Phase-2 integration and lead with Housecall Pro, Jobber, and "works without an FSM" as the wedge. This inverts the conventional wisdom that ServiceTitan is the entry point to trades software — for AMP specifically, ServiceTitan is the segment where Avoca is strongest.

3. **The 30-minute self-serve onboarding commitment in the Constitution is now load-bearing competitive infrastructure, not a nice-to-have.** It is the single most important product differentiation lever AMP has against Avoca. Any product decision that erodes it (an enterprise SKU, a custom integration tier, a Salesforce-style implementation flow) is a competitive concession to Avoca. The Constitution's existing commitment here should be re-affirmed.

4. **AMP should stop framing Avoca as a "future competitor we'll worry about later."** Avoca is the dominant category competitor today, structurally walled off from AMP's segment by their own economics — but the segmentation is a Avoca strategic choice, not a structural moat. AMP should plan around the assumption that Avoca will launch a downmarket SKU sometime in the next 18 months and structure the wedge to be defensible by that point: customer references, organic GTM motion, distribution into Housecall Pro / Jobber communities, and a switching-cost moat (deep workflow customization that's painful to replicate).

5. **General contracting and roofing should be dropped from the initial wedge naming** — confirming the home-services brief recommendation. These trades are weak relative to HVAC/plumbing on Avoca-comparable metrics (call volume, after-hours pain, predictability of demand). Spreading thin across five trades is a positioning loss vs. focused HVAC+plumbing.

6. **Track Avoca quarterly, not weekly.** The watch trigger should be: (a) any "starting at $X/mo" public pricing, (b) any self-serve product launch, (c) any "Avoca Lite" SKU, (d) any SMB AE or SDR hire visible on Ashby, (e) any partnership with a sub-$2M-focused tool (Housecall Pro's lower tiers, Jobber's starter plan). Any of these is the trigger to compress AMP's roadmap urgency.

### Net verdict

**The home-services wedge holds — but narrower than ADR-004 articulated.** AMP's defensible segment is sub-$2M HVAC and plumbing owner-operators with no ServiceTitan, where Avoca's economics cannot follow. The 12-18 month window is real at that floor, narrower in the $2M-$5M middle, and closed above. The path forward is to (a) sharpen the wedge to the sub-$2M floor, (b) lead with Housecall Pro and Jobber integration, not ServiceTitan, (c) treat self-serve, transparent pricing, and 30-minute onboarding as load-bearing differentiation, and (d) plan the roadmap to be defensible by the time Avoca launches a downmarket SKU. **A re-amended ADR-004 that codifies these refinements is warranted before any further wedge execution.**

---

## Sources

- [Avoca AI homepage](https://www.avoca.ai/)
- [Avoca AI — Integrations page (70+ platforms listed)](https://www.avoca.ai/integrations)
- [Avoca AI — Housecall Pro integration](https://www.avoca.ai/integrations/housecall-pro)
- [Avoca AI — Nexstar partnership page](https://www.avoca.ai/partners/nexstar)
- [Avoca AI — Customer stories](https://www.avoca.ai/customers)
- [Avoca AI — Sila Services case study](https://www.avoca.ai/customers/sila-services)
- [Avoca AI — Reliable Comfort case study](https://www.avoca.ai/customers/reliable-comfort)
- [Avoca AI — My Plumber Plus case study](https://www.avoca.ai/customers/my-plumber-plus)
- [Avoca AI — Jobs (Ashby)](https://jobs.ashbyhq.com/avoca)
- [Avoca AI — Agent Product Manager job listing](https://jobs.ashbyhq.com/avoca/260e5ea9-87c2-4261-9fea-301f46578173)
- [Avoca AI — New Verticals Lead job listing](https://jobs.ashbyhq.com/avoca/73aa1239-2e2e-48a5-a455-4e544ece9c26)
- [PR Newswire — Avoca Raises $125M at $1B Valuation](https://www.prnewswire.com/news-releases/avoca-raises-125m-at-1b-valuation-to-power-americas-services-economy-with-ai-302753962.html)
- [Fortune — How a chance encounter in Texas sparked a $1B Kleiner Perkins-backed AI startup](https://fortune.com/2026/04/27/avoca-ai-agents-missed-calls-hvac-plumbing-roofing-kleiner-perkins-chen-shrivastava-braswell/)
- [The AI Insider — Avoca closes $125M at $1B valuation](https://theaiinsider.tech/2026/04/29/avoca-closes-125m-at-1b-valuation-to-power-americas-services-economy-with-ai/)
- [AI Automation Global — Avoca Hits $1B: AI Voice Agents Conquer the Trades](https://aiautomationglobal.com/blog/avoca-ai-voice-agent-trades-unicorn-2026)
- [Homepros — Home services startup Avoca lands investment, officially launches](https://homepros.news/home-services-startup-avoca-lands-investment-officially-launches/)
- [Y Combinator company page — Avoca (W23)](https://www.ycombinator.com/companies/avoca)
- [ServiceTitan Marketplace — Avoca AI partner listing](https://marketplace.servicetitan.com/partner/Avoca-AI)
- [Owned and Operated podcast #131 — Tyson Chen interview](https://www.ownedandoperated.com/post/owned-and-operated-revolutionizing-call-centers-with-avoca-ai-and-tyson-chen)
- [Service Business Mastery — Tyson Chen on AI in home services CSR](https://servicebusinessmastery.com/how-ai-is-going-to-impact-the-customer-service-side-of-home-services/)
- [Contractor Toolstack — Avoca AI Review 2026 (third-party)](https://contractortoolstack.com/software/avoca-ai/)
- [Claudessa — Avoca AI Review: Pricing, Features & Alternatives (competitor-authored)](https://claudessa.com/vs/avoca)
- [Leaping AI — Leaping AI vs Avoca comparison (competitor-authored)](https://leapingai.com/blog/voice-ai-platforms-compared-leaping-ai-vs-avoca)
- [Solvea — 7 Best AI Receptionists for HVAC (competitor-authored)](https://solvea.cx/blog/best-ai-receptionist-for-hvac)
- [LeadIQ — Reliable Comfort Heating & Air company profile](https://leadiq.com/c/reliable-comfort-heating--air/5a1dbf832300005900bf3dd8)
- [Nexstar Network — Strategic Partner program overview](https://www.nexstarnetwork.com/blog/newsroom/jumpstart-your-business-with-win-win-win-vendor-partnerships/)
- [FeaturedCustomers — Avoca customer references](https://www.featuredcustomers.com/vendor/avoca)
- [Pulse2 — Avoca $125M+ raise coverage](https://pulse2.com/avoca-125-million-raised-at-1-billion-valuation-to-power-services-economy-with-ai/)

---

## Confidence and gaps

**High confidence:**
- Avoca's funding, valuation, growth metrics (8-figure ARR, 10x in 2025, 800+ customers, $1B in jobs booked 2026 run rate). Multiple aligned primary sources.
- Avoca's integration breadth (70+ platforms including Housecall Pro, Jobber, FieldEdge, ServiceFusion). Primary source: Avoca's own integrations page. **This is a material correction to the home-services brief.**
- Avoca's actual customer segment center of gravity ($10M+ HVAC/plumbing operators, PE-rollup and franchise-platform skew). Confirmed across customer-page evidence, third-party reviewer consensus, and the Sila Services case study scale.
- Sales-led, demo-required procurement motion. Confirmed by absence of public pricing, presence of dedicated Implementation Manager hiring, and third-party reviewer consensus.
- Distribution lock-in via ServiceTitan Gold Partner + Nexstar preferred vendor.
- Founder backgrounds and YC W23 origin.

**Medium confidence:**
- Pricing specifics ($1,000-$3,000/mo). Three independent third-party sources converge but Avoca has not confirmed. Treat as estimate.
- Technology stack (ElevenLabs, Deepgram, Voxtral; no proprietary foundation model). One credible secondary source; not confirmed by Avoca directly.
- Sub-2-second answer latency claim. One source.
- Downmarket trajectory read. The signals are genuinely mixed — integrations and founder DNA point downmarket, hiring and product surface point upmarket. My read (Avoca will not prioritize sub-$5M in the next 12 months) is an inference, not a fact.

**Low confidence / explicit gaps:**
- Independent customer reviews. I could not find Avoca on G2 or Capterra with meaningful review volume. Reddit r/HVAC, r/Plumbing did not surface threads on Avoca specifically (or the fetch tooling could not reach them). The vulnerability section is therefore weakly evidenced; every "weakness" cited is from competitor-authored content and should be discounted.
- Avoca's actual contract structure (annual vs. monthly, minimum commitments, cancellation terms). Not visible publicly.
- Internal product roadmap and any planned downmarket SKU. No insider information; the "12-month window" estimate is a strategic inference from public signals, not a confirmed timeline.
- Avoca's LLM choice (Claude, GPT, multi-model). Not disclosed.
- Specific Nexstar member-tier penetration. Avoca claims partnership; the actual member-base capture rate is not published.
- Forward Deployed Engineer comp ($160-250K) and the team structure of the implementation org — would inform a precise estimate of Avoca's CAC and explain the segment economics more rigorously, but I do not have it.

**The single biggest gap that would change the recommendation if filled:** an actual Avoca pricing quote for a 5-truck, $2M HVAC operator. If the quote comes back at $400-$600/mo, the sub-$5M segment is contested today and AMP's wedge is materially weaker than this brief concludes. If it comes back at $1,500+/mo (consistent with the estimate), the wedge holds as analyzed. Closing this gap requires either a friendly contractor running a real demo or a competitive-intelligence purchase — both outside the Scout role's scope but worth flagging for follow-up.
