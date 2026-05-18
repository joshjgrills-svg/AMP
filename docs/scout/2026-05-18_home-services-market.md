---
date: 2026-05-18
source-of-task: Architect / Josh, per ADR-004 follow-up
purpose: Customer-side market validation of the home services voice agent wedge. NOT competitive analysis; this brief asks whether the customer pain, math, and willingness-to-pay actually support the wedge AMP just committed to. Negative verdict permitted and explicitly invited.
author: AMP Ecosystem Scout
confidence: **High** on the directional shape of the missed-call problem (corroborated across ServiceTitan, Housecall Pro, Invoca, NRCA, multiple aggregators). **Medium** on specific dollar-cost-per-missed-call figures (vendor-source bias is heavy; numbers should be treated as order-of-magnitude). **Medium-low** on after-hours percentages (sources contradict each other; the 40-73% range is wide enough to flag). **High** on the existence and pricing of the answering-service market. **High** on competitive intensity in AI voice for trades (Avoca alone is a category-shaping data point).
---

# Scout Customer Brief: Home Services Voice Agent Market

## What we asked

ADR-004 (2026-05-17) committed AMP to home services — HVAC, plumbing, electrical, roofing, and general contracting — as the first vertical, with the inbound voice agent as the lead capability. That decision was made on competitive grounds (against Claude for Small Business). It was NOT made on customer-grounds. This brief asks: does the customer-side data support the wedge? Are the calls real, is the missed-call cost real, is the existing-solution dissatisfaction real, and is there room to charge?

Six questions follow. The verdict is at the bottom; readers in a hurry can jump there.

---

## 1. Call volume

**Headline:** A typical small home-services contractor (under ~$5M revenue, 3-8 trucks) handles 100-200 inbound calls per week, with roughly 20-25 calls per day on a peak day. Volume varies sharply by trade and season.

**By trade:**

- **HVAC.** ~24 calls per day during peak (summer cooling / winter heating) per [ServiceTitan / industry aggregator data via AgentZap](https://agentzap.ai/blog/hvac-phone-statistics). Summer call volume runs 340% above spring per ACHR News (cited in the same source). The 3-to-8-truck shop fields "100 to 200 inbound calls per week" while dispatchers can physically answer 60-80, per [callbirdai.com summary of contractor data](https://www.callbirdai.com/blog-contractors-lose-money-missed-calls). 73% of annual HVAC revenue compresses into June-August and December-February (IBISWorld, cited via AgentZap).
- **Plumbing.** Less seasonal than HVAC but spike-driven (burst pipes, water heater failures, sewer backups). [ServiceTitan benchmark data](https://www.servicetitan.com/blog/data-call-booking-rates) puts plumbing at the highest booking rate of any trade at 43%, suggesting high-intent inbound. Specific call-volume counts are not published as cleanly as HVAC; the contractor-aggregator literature treats plumbing call volume as comparable to HVAC on a day-to-day basis but smoother across the year.
- **Electrical.** [AgentZap's electrical-trade compilation](https://agentzap.ai/blog/electrician-phone-statistics) cites that 58% of calls to electrical contractors arrive outside 9-5 (NECA-sourced per their citation; I could not independently verify on the NECA site). 67% of electrical service customers prefer phone over online booking. Daily volume estimates are thinner; the industry literature implies lower call volume per business than HVAC but higher average ticket.
- **Roofing.** Bursty and storm-driven. Off-peak: 5-10 calls per day. Storm-peak: 50-100+ within hours, per [Perceptionist's roofing storm analysis](https://myperceptionist.com/blog-roofing-storm-season-call-surge/). Florida contractor cited 200+ inbound calls in one week after Hurricane Ian. [NRCA Member Business Operations Survey 2025](https://agentzap.ai/blog/roofing-phone-statistics) (cited by AgentZap) reports the average roofing company misses 62% of incoming calls during peak business hours.
- **General contracting.** Lower call volume than the named trades; demand is more project-driven and slower-cycle. Reliable per-day call data for the residential GC segment is genuinely thin in primary sources. **Flag this gap.**

**By business size** (cross-trade, from [ServiceTitan's call-booking benchmark](https://www.servicetitan.com/blog/data-call-booking-rates)):
- 25+ technicians: 59% call booking rate
- <5 technicians: 24% call booking rate
- The bottom half of the market is structurally losing 70%+ of calls to either missed answers or failed conversion. This is AMP's segment per North Star.

**What this means for AMP:** The call volumes are real and the wedge's target segment (sub-$5M, under-5-tech operators) is exactly the segment with the worst capture rates. Volume per business is enough that an AI agent has work to do daily, but small enough that one customer's traffic is not infrastructurally heavy. Confidence on the overall shape: **high**. Confidence on per-trade specifics: **medium** — the same handful of aggregator articles are recycling each other's numbers, and only ServiceTitan's booking-rate data appears to come from a sufficiently large primary sample to trust without hedge.

---

## 2. Cost of a missed call

**Headline:** Per-missed-call cost estimates span $275 to $2,500 across trades, with HVAC commonly cited at $350+, plumbing at $300-$500, and roofing at $2,500+. The aggregate annual loss for a typical small contractor is $45K-$120K — a number that recurs consistently across multiple independent compilations.

**Per-call cost by trade:**
- **HVAC:** Each missed call ≈ $350 in lost revenue per [Contractor Magazine via AgentZap](https://agentzap.ai/blog/hvac-phone-statistics); customer lifetime value $12K-$15K per the same compilation. Emergency calls 2-3× regular service value.
- **Plumbing:** Per-missed-call cost commonly cited at $300-$500 (standard service) and $850-$1,500 (emergency water heater / leak) per the [SkipCalls plumber analysis](https://skipcalls.com/plumber/how-much-money-am-i-losing-from-missed-calls-on-weekend-emergency-plumbing-jobs-). [Housecall Pro research aggregated by leadfixai](https://leadfixai.com/blog/missed-calls-cost-contractors/) puts the cross-trade per-missed-call cost at $1,200 — biased toward the higher end because it includes lifetime value.
- **Roofing:** $2,500+ per missed call ([AgentZap roofing compilation](https://agentzap.ai/blog/roofing-phone-statistics) citing NRCA 2025 survey). Single replacement jobs at $8,000+ make the per-call expected value the highest of any trade.
- **Electrical:** No clean per-call dollar figure in the sources I verified. Inferred from booking rates and average ticket: $300-$600 per missed call is consistent with the math but should be treated as a model, not a measurement.

**Aggregate annual loss:** Multiple independent sources converge on **$45K-$120K per year** in lost revenue for the typical small contractor missing 5-10 calls per week ([callbirdai](https://www.callbirdai.com/blog-contractors-lose-money-missed-calls), [instantbusinesspro](https://instantbusinesspro.ai/post/cost-of-missed-calls)). Housecall Pro's "miss one call per day = $438K/year" figure is the high-water-mark estimate and likely overstated for the AMP target segment (it assumes high LTV across all calls; in the AMP segment, a substantial fraction of inbound is sales inquiries that wouldn't have converted anyway).

**The conversion math the customer already does in their head:**
- 78% of callers who reach voicemail hang up and call the next contractor ([Invoca / multiple aggregators](https://www.invoca.com/blog/how-much-missed-sales-calls-cost-home-services-businesses)). 85% in the HVAC-specific data per AgentZap.
- The first contractor to answer wins the job 50-78% of the time depending on call type ([NextPhone analysis](https://www.getnextphone.com/blog/call-booking-conversion-rate-optimization)).
- Average HVAC contractor misses 22-27% of inbound calls; spikes to 35%+ in peak season ([IBISWorld via AgentZap](https://agentzap.ai/blog/hvac-phone-statistics)).

**Bias warning on the dollar figures.** Every primary-feeling source on missed-call cost is published by a vendor selling answering services or AI voice. There is no independent academic study I could find. The directional finding (missed calls cost real money, lots of it) is uncontested across vendor and non-vendor sources. The specific dollar amounts should be treated as marketing-massaged.

**What this means for AMP:** The pitch ROI math is sound. Even at the conservative end — $45K/year in lost revenue, 30-50% recoverable with a competent voice agent — recovered revenue is $15K-$25K/year per customer. A $200-$500/month subscription ($2.4K-$6K/year) clears the ROI bar by 3-10×. Confidence: **high on directional**, **medium on precision**.

---

## 3. After-hours reality

**Headline:** 40-73% of home-services calls arrive outside 9-5 business hours, depending on source. After-hours coverage today is a hodgepodge: voicemail (most common, worst-converting), the owner's personal cell (common, owner-unsustainable), a human answering service ($199-$800/mo, see Question 4), or nothing. This is the rawest pain in the market.

**Sources, ranked by my confidence:**
- 58% of electrical contractor calls arrive outside 9-5, per NECA cited via [AgentZap](https://agentzap.ai/blog/electrician-phone-statistics). The NECA primary source I could not independently verify, but the figure is repeated across multiple downstream compilations.
- 62% of HVAC calls come outside regular business hours, per ACHR News cited via [AgentZap](https://agentzap.ai/blog/hvac-phone-statistics).
- 73% of home-services calls "come outside standard 9-5 hours" with 31% being after-hours emergencies, per [Perceptionist's contractor analysis](https://perceptionist.com/after-hours-answering-service-for-contractors/) — but this is a vendor source.
- "Roughly 40% of home service inquiries come in after 5 PM or on weekends" per multiple aggregator pieces — a more conservative figure that I trust slightly more.

**Range to use in customer conversations:** 40-60% of inbound calls arrive after hours for a typical home-services contractor. The 62%+ figures from HVAC-specific and electrical-specific sources are plausible but should be sourced before quoting in marketing.

**What contractors do today (qualitative, from aggregator and forum analysis — primary forum sources blocked by Reddit's fetch restriction):**
- **Voicemail.** The default. 78-85% of after-hours callers don't leave a message — they call the next contractor. So "we have voicemail" is functionally equivalent to "we don't answer."
- **Personal cell forwarding.** The owner picks up nights and weekends. Sustainable for a sole-prop; corrosive for owner mental health and rate-limited by sleep.
- **Human answering service.** $199-$800/month (Q4 below). Reliable for message-taking; weak at actually booking jobs because the human at the call center does not have access to the CRM or schedule.
- **AI voice receptionist.** Adoption growing but still <10% of the segment (inferred; I do not have a clean adoption number — flag as gap).
- **Nothing.** Genuinely common in the under-$1M-revenue tier. The owner accepts the lost revenue as a cost of being small.

**What this means for AMP:** The after-hours pain is structurally bigger than the missed-during-hours pain. ADR-004's "never miss a call, including 11pm Saturday" framing maps directly onto this. AMP's wedge surface is the highest-leverage hours of the missed-call problem. Confidence: **high on directional**, **medium on specific percentages**.

---

## 4. Existing solutions

**Headline:** The answering-service market for contractors is large, mature, and openly priced — but the products are message-takers, not bookers. The AI-voice category is rapidly forming, with one breakout (Avoca) at $1B valuation and a long tail of $49-$249/mo competitors. The customer is dissatisfied with both: human services take messages instead of booking jobs; AI services struggle with trade-specific vocabulary and CRM integration.

**Human answering services (priced and verified):**
- **PATLive:** $199/mo base, popular plan at $460/mo for 200 minutes, $2.60/min overage on pay-as-you-go ([source via Smith.ai comparison](https://smith.ai/virtual-receptionist-service-comparison/smith-ai-vs-patlive)).
- **Smith.ai:** Plans start ~$290/mo for 30 calls; ~$293/mo for 75 calls ([Smith.ai pricing](https://smith.ai/pricing/receptionists)).
- **AnswerForce:** Starts ~$389/mo with $99 setup fee, 90-day commitment. Specifically positions on contractor / trades vertical ([AnswerForce contractors page](https://www.answerforce.com/contractors-answering-service)).
- **MAP Communications:** Pricing not published; positioned at the contractor vertical.
- **Ruby Receptionists, AnswerConnect, Centratel, Dexcomm:** All in the $250-$800/mo zone for contractor accounts based on aggregator surveys.

**Common dissatisfaction pattern with human services** (synthesized from vendor-comparison content, since primary forum sources were inaccessible): the human takes a message, the contractor calls back, the customer has already booked elsewhere. The service is rated on call answer rate, not on jobs booked. The fundamental product mismatch is that the receptionist is judged on the wrong outcome.

**AI voice tools — the competitive landscape (priced):**
- **Avoca AI** — $125M raised April 2026, $1B valuation, ServiceTitan Gold Partner, Nexstar Network partnership, named customers include 1-800-GOT-JUNK, Goettl, Turnpoint Services. Estimated $1,000-$3,000/mo for mid-market HVAC operations; $1,500-$2,500/mo for a $5M HVAC with 6 CSRs and 800-1,500 calls/mo ([Avoca / AI Automation Global](https://aiautomationglobal.com/blog/avoca-ai-voice-agent-trades-unicorn-2026)). **This is the dominant competitive signal in the space.**
- **Sameday:** Trades-built. Launch plan $449/mo for mid-size HVAC ([Sameday pricing post](https://www.gosameday.com/post/ai-answering-service-pricing-what-to-expect-in-2026)).
- **Rosie AI:** Starts $49/mo; positioned specifically at home services per multiple aggregators.
- **Goodcall:** $79/mo Starter, $129/mo Growth, $249/mo Scale. **Key complaint surfaced repeatedly: "Goodcall takes a message while contractor-specific AI dispatches a tech, which is a $600-800 in revenue difference on a single call"** ([Dialora's honest Goodcall review](https://www.dialora.ai/blog/goodcall-reviews)). Latency ~600ms, retains "slightly robotic feel," outgrown quickly by serious contractors.
- **Numa:** $49/mo unlimited usage.
- **Hatch, Trillet, Marlie, Dialzara, Allo, AgentZap, Welco, NextPhone, Solvea:** Long tail of $49-$299/mo AI receptionists, most generic, some vertical-positioned. None at Avoca's scale.

**Pricing range to anchor on:** AI receptionist services cluster at **$49-$299/mo for non-vertical solutions** and **$449-$2,500/mo for trade-specific solutions with CRM integration**. The Avoca pricing data point is the most important — it shows that contractors will pay $1.5K-$2.5K/month for a vertical, integrated, "actually books jobs" product.

**Dissatisfaction signals (where AMP can win):**
- Goodcall's "takes a message vs. dispatches a tech" complaint is the single clearest articulation of where current AI receptionists fall short. AMP's multi-agent design — voice agent that hands off to a scheduling agent that writes back to the CRM — is structurally the right answer to this complaint.
- Latency complaints (600ms+ on Goodcall) — Constitution §10.4 commits AMP to <500ms time-to-first-audio. If AMP hits that bar, it's a published-spec advantage.
- "Outgrown quickly" — the lighter tier ($49-$129/mo) products plateau as the business scales. AMP can position itself as the product that grows with the contractor.
- Owner-set-up burden — most current solutions require the owner to write call scripts and configure flows. AMP's 30-minute onboarding (North Star) is the unfair advantage here, if it can be delivered.

**What this means for AMP:** The existing-solution dissatisfaction is real and concentrated in known failure modes. The pricing ceiling is established by Avoca at the high end and the long tail at the low end — AMP can credibly price in the $200-$600/mo zone for the first wedge product and have room. Confidence: **high**.

---

## 5. Willingness to pay

**Headline:** A typical sub-$5M home-services contractor is already spending **$1,500-$5,000/month** on call handling and lead capture across Google LSAs, Angi/HomeAdvisor, Yelp, and an answering service. Adding $200-$500/mo for an AI voice agent that captures the leads they're already paying to generate is well within the budget envelope.

**The customer's current monthly spend (composite, verified ranges):**
- **Google Local Service Ads:** $25-$300/lead depending on trade and metro. HVAC $45-$120/lead; plumbing $40-$90/lead. Mid-size contractors spend $1,000-$3,000/mo here. ([Pipeline On budget guide](https://pipelineon.com/blog/google-lsa-budget-home-service/), [Searchlight Digital HVAC CPL](https://searchlightdigital.io/what-is-a-good-cost-per-lead-for-hvac-google-ads/))
- **Angi / HomeAdvisor:** $25-$120/lead, effective cost-per-acquired-customer $600-$1,400. Most contractors spend $300-$2,500/mo here. ([Hook Agency Angi review](https://hookagency.com/blog/angi-leads-reviews/), [7ten Marketing](https://7ten.marketing/how-much-does-angi-angies-list-cost-for-contractors/))
- **Yelp:** $300-$1,000+/mo on advertising.
- **Answering service:** $199-$800/mo if they have one (only ~30-40% of the segment does, per industry estimate I should source more cleanly — flag).
- **Aggregate marketing-and-call-handling spend:** $2,000-$4,000/mo for a $500K-$2M revenue contractor (5-10% of revenue benchmark per [Contracting Empire](https://contractingempire.com/cost-of-marketing-for-construction-companies/)). $3,000-$8,000/mo for the $2M-$5M tier.

**The willingness-to-pay argument:** A contractor paying $69 per LSA lead has every reason to pay $300/mo to ensure those leads — already paid for — actually get answered. The marginal ROI on lead capture beats the marginal ROI on lead generation, because the lead is already there. This is the cleanest pitch in the wedge.

**The pricing ceiling:**
- **Floor:** $49/mo (Numa, Rosie entry-tier). At this price, the customer assumes the product is a toy.
- **Realistic AMP entry:** $200-$500/mo for the inbound voice agent alone. Maps to <2% of revenue for a $500K contractor and <0.5% for a $2M contractor.
- **Multi-agent platform ceiling:** $500-$1,500/mo once voice + SMS + chat + email are bundled. Maps to Avoca's pricing zone and is defensible by integration depth.
- **Ceiling above which procurement friction begins:** ~$2,500/mo for the under-$5M segment. Above this, the buyer wants a demo, a contract, and a vendor evaluation — outside AMP's "configure in 30 minutes, one credit card" model.

**What this means for AMP:** The market is already pre-paying for the problem AMP solves. The pricing window of $200-$1,500/mo per customer is open, comfortable, and uncrowded above the $49-$129 toy tier and below the Avoca enterprise tier. The unit economics in the North Star ($1M ARR from 100-300 customers = $3K-$10K ACV/year) are achievable inside this range without aggressive pricing. Confidence: **high**.

---

## 6. The verdict

**The data supports home services as AMP's first wedge — but the verdict is qualified, and the qualifications matter.**

### What's strong (the wedge holds):

1. **The pain is real, measurable, and acknowledged by the customer.** Contractors already know they're losing $45K-$120K/year to missed calls. They don't need to be educated on the problem; they need a product that fixes it. This is the cleanest jobs-to-be-done in the SMB segment.
2. **The math is favorable at any reasonable pricing.** Recovering even 30% of lost revenue ($13K-$36K/year) makes a $300-$500/mo AMP subscription clear ROI by 3-10×. The pitch doesn't require fancy storytelling.
3. **After-hours is the highest-leverage surface.** 40-60% of calls arrive after hours; current solutions (voicemail, owner's cell, human answering service) all fail in known ways. AMP's 24-hour autonomous voice agent maps directly to this gap.
4. **The customer is already paying.** $2K-$5K/mo on marketing and call-handling for the target segment. Adding $300-$500/mo for actual answer-and-book is a budget-line move, not a budget-line addition.
5. **Pricing window is open.** The $200-$600/mo zone is uncrowded; Goodcall ($79-$249) sits below it, Avoca ($1,500+) sits above it. AMP can enter this zone defensibly.

### What's worrying (the qualifications):

1. **Avoca is real and large.** $1B valuation, $125M raised, ServiceTitan Gold Partner, named Nexstar partnership, $1B in jobs booked in 2026. They are not a vaporware competitor; they are a category leader with a head start. **ADR-004 considered Claude for Small Business as the competitive threat and concluded "not triggered." Avoca is a different competitor with a different positioning, and the ADR did not evaluate it.** Avoca targets larger trades operators ($5M+ with 6+ CSRs, per the cited pricing example) — which leaves AMP's North Star segment (under $5M, owner-operator) technically open. But Avoca will move downmarket. The 12-18 month window in the North Star may compress against Avoca specifically.
2. **The dollar-cost-of-missed-call literature is vendor-funded.** Every primary source on missed-call cost is published by a vendor selling answering services or AI voice. The direction is uncontested; the precise dollar figures should not be quoted in customer-facing materials without a hedge or an independent citation.
3. **The under-$1M-revenue tier is the hardest sell.** They have the loudest pain but the smallest budget. Many in this tier currently use "nothing" or "voicemail" — they accept the lost revenue. Convincing the sub-$1M contractor to spend $300/mo on AI voice when they already declined to spend $400/mo on a human answering service is a real sales challenge that the data does not yet address.
4. **General contracting is the weakest of the five trades.** Lower call volume, longer sales cycles, less obvious missed-call math. The data I could verify on GCs was thin and qualitative. **Recommendation: drop GC from the initial wedge naming, or relegate it to "phase 2" in vertical messaging. HVAC, plumbing, electrical, roofing carry the wedge. GC is a hedge that adds positioning complexity without obvious payoff.**
5. **Roofing is structurally different from the other three core trades.** Storm-driven, bursty (50-100 calls in hours, then quiet for months), heavily contested by storm-chasers, high lead cost ($100+/lead in metros). The product requirements for roofing voice are different (massive elasticity, weather-event detection, lead-qualification depth) from steady-demand trades. **Recommendation: lead with HVAC + plumbing for V1; add roofing as a focused V2 once storm-event handling is proven.**

### If one trade is dramatically stronger:

**HVAC and plumbing are tied for first.** HVAC has the cleanest seasonal data, the most established missed-call literature, and the most concentrated demand surface (June-August + December-February). Plumbing has the highest call-booking rate of any trade (43% per ServiceTitan), suggesting the inbound caller intent is unusually high. Either is defensible as the lead vertical. Pick HVAC if the seasonal compounding matters more (a customer who installs in May has the entire summer to validate ROI); pick plumbing if smoother demand makes the pilot cleaner to instrument.

**Electrical is third.** Strong after-hours signal (58% per NECA) and good ticket sizes, but lower call volume per business and fewer published benchmarks. Worth a vertical-3 slot, not vertical-1.

**Roofing and general contracting are weaker for V1** for the reasons above.

### If a different vertical would be better:

I was asked to flag this honestly. **No vertical visible in the public data is a stronger first wedge than HVAC+plumbing for AMP specifically.** Dental has lower after-hours pain (people don't have toothache emergencies at the rate they have AC failures); legal intake has consent-and-compliance complexity that violates Constitution §4.3; real estate is fragmented across IDX/CRM stacks. The home-services answer holds.

The honest caveat: **landscaping** showed up several times in Anthropic's Claude for Small Business example list and in AnswerForce's vertical pages. I did not deeply research landscaping in this brief. If a Phase-2 vertical is being considered, landscaping is worth a dedicated brief; the customer profile (owner-operator, after-hours quote requests, seasonal demand) maps closely to the wedge thesis. Flagging for follow-up, not as a competitor to HVAC/plumbing for V1.

### Net verdict

**Proceed with the home-services wedge. Narrow the initial trade list from five to two (HVAC, plumbing). Treat electrical as a fast-follow. Treat roofing and general contracting as Phase 2.** The wedge holds on customer pain, math, willingness to pay, and competitive whitespace at the under-$5M segment. The single most important risk surface added by this brief is **Avoca** — it warrants a dedicated competitive deep-dive that ADR-004 did not perform, because ADR-004 was scoped to Claude for Small Business.

---

## Confidence and data quality

**High confidence:**
- The shape of the missed-call problem (volume, after-hours skew, voicemail abandonment, first-responder-wins dynamic) is corroborated across enough independent sources to treat as established.
- The existence and pricing of the human answering-service market.
- The pricing structure of the AI receptionist market, both budget tier ($49-$249/mo) and trades-specific tier ($449-$2,500/mo).
- The Avoca data points (funding, valuation, partners, customer examples) — multiple primary sources align.

**Medium confidence:**
- Specific per-trade dollar costs of missed calls. Direction is solid; precision is vendor-massaged.
- After-hours call percentages (40% vs. 58% vs. 62% vs. 73% depending on source and trade). The directional finding (substantial after-hours volume) is robust; the specific percentage to quote in marketing is not.
- ServiceTitan booking-rate data is high-quality but is itself a snapshot of ServiceTitan-using businesses, which skew larger and more sophisticated than the AMP target segment. The numbers likely understate the booking-rate gap in the true bottom of the market.

**Low confidence / flagged gaps:**
- Per-day inbound call data for general contractors. Genuinely thin in published sources.
- Adoption rate of AI voice in the AMP target segment. I do not have a credible "what percentage of sub-$5M contractors currently use any AI voice tool" number. This is the most important market-sizing gap and would meaningfully change the urgency math if obtained.
- Independent (non-vendor) academic or government data on missed-call cost. I could not find one. This is the single biggest credibility gap in the wedge's quantitative pitch.
- Reddit, r/HVAC, r/Plumbing, r/Electricians primary forum content. The fetch tooling could not access Reddit directly in this run. The qualitative complaint patterns synthesized in Question 4 are extracted from vendor-comparison articles that themselves cite forum sentiment, not from primary forum analysis. A follow-up brief with direct forum reading would strengthen the dissatisfaction signals.
- Landscaping as a possible Phase-2 vertical was flagged but not researched.

## Sources

- [ServiceTitan — Average Call Booking Rates](https://www.servicetitan.com/blog/data-call-booking-rates)
- [ServiceTitan — HVAC Statistics for 2026](https://www.servicetitan.com/blog/hvac-statistics)
- [ServiceTitan — Consumer Trends in the Trades 2025](https://www.servicetitan.com/guides/consumer-trends-in-the-trades-2025)
- [AgentZap — HVAC Industry Phone Statistics](https://agentzap.ai/blog/hvac-phone-statistics)
- [AgentZap — Electrical Contractor Phone Statistics](https://agentzap.ai/blog/electrician-phone-statistics)
- [AgentZap — Roofing Industry Phone Statistics](https://agentzap.ai/blog/roofing-phone-statistics)
- [Callbird AI — How Contractors Lose $45K-$120K Per Year to Missed Calls](https://www.callbirdai.com/blog-contractors-lose-money-missed-calls)
- [SkipCalls — Money Lost From Weekend Emergency Plumbing Calls](https://skipcalls.com/plumber/how-much-money-am-i-losing-from-missed-calls-on-weekend-emergency-plumbing-jobs-)
- [Instant Business Pro — Real Cost of Missed Calls for Contractors 2026](https://instantbusinesspro.ai/post/cost-of-missed-calls)
- [Housecall Pro — Hidden Costs of Missed Calls](https://www.housecallpro.com/resources/missed-calls/)
- [Invoca — How Much Missed Sales Calls Cost Home Services Businesses](https://www.invoca.com/blog/how-much-missed-sales-calls-cost-home-services-businesses)
- [Perceptionist — After-Hours Answering Service for Contractors](https://perceptionist.com/after-hours-answering-service-for-contractors/)
- [Perceptionist — Roofing Storm Season Call Surge](https://myperceptionist.com/blog-roofing-storm-season-call-surge/)
- [Smith.ai vs PATLive Comparison](https://smith.ai/virtual-receptionist-service-comparison/smith-ai-vs-patlive)
- [Smith.ai Pricing](https://smith.ai/pricing/receptionists)
- [AnswerForce — Contractors Answering Service](https://www.answerforce.com/contractors-answering-service)
- [Avoca AI — Home Services AI Platform](https://www.avoca.ai/)
- [PR Newswire — Avoca Raises $125M at $1B Valuation](https://www.prnewswire.com/news-releases/avoca-raises-125m-at-1b-valuation-to-power-americas-services-economy-with-ai-302753962.html)
- [AI Automation Global — Avoca Hits $1B](https://aiautomationglobal.com/blog/avoca-ai-voice-agent-trades-unicorn-2026)
- [Sameday — AI Answering Service Pricing 2026](https://www.gosameday.com/post/ai-answering-service-pricing-what-to-expect-in-2026)
- [Dialora — Honest Goodcall Reviews 2026](https://www.dialora.ai/blog/goodcall-reviews)
- [Ringly — AI Virtual Receptionist Cost Guide](https://www.ringly.io/blog/how-much-does-an-ai-virtual-receptionist-cost-in-2025)
- [Hook Agency — Angi Leads Reviews From Contractors 2025](https://hookagency.com/blog/angi-leads-reviews/)
- [7ten Marketing — How Much Does Angi Cost for Contractors](https://7ten.marketing/how-much-does-angi-angies-list-cost-for-contractors/)
- [Pipeline On — Google LSA Budget Benchmarks by Trade](https://pipelineon.com/blog/google-lsa-budget-home-service/)
- [Searchlight Digital — HVAC Google Ads CPL 2026](https://searchlightdigital.io/what-is-a-good-cost-per-lead-for-hvac-google-ads/)
- [Contracting Empire — Cost of Marketing for Construction Companies](https://contractingempire.com/cost-of-marketing-for-construction-companies/)
- [LocaliQ — Home Services Advertising Benchmarks](https://localiq.com/blog/home-services-advertising-benchmarks/)
- [NextPhone — Call-to-Booking Conversion 2026](https://www.getnextphone.com/blog/call-booking-conversion-rate-optimization)
- [NextPhone — Home Services Answering Service](https://www.getnextphone.com/blog/home-services-answering-service)
- [LeadFix AI — How Much Do Missed Calls Cost Contractors](https://leadfixai.com/blog/missed-calls-cost-contractors/)
- [Statista — Number of Plumbing & HVAC Contractor SMBs by Firm Size U.S. 2020](https://www.statista.com/statistics/1122362/number-plumbing-hvac-contractor-smbs-firm-size-us/)
- [BLS — Plumbing, Heating, and Air-Conditioning Contractors OEWS](https://www.bls.gov/oes/2023/may/naics5_238220.htm)
- [NAICS / Census — Plumbing, Heating, and Air-Conditioning Contractors](https://www.census.gov/naics/?input=2382&year=2022&details=2382)
