# AMP — Operating Rhythm

**Version:** v1
**Author:** PM / Senior Lead Architect
**Last updated:** 2026-05-12
**Status:** Operational policy. Codifies when each function in the AMP system runs.

---

## Why this document exists

Engineering organizations succeed or fail on rhythm. Without it, work happens in bursts of activity followed by long silences, important reviews get skipped because no one remembers to do them, and the system slowly drifts away from its standards. With it, the right work happens at the right time, automatically.

This document defines the cadence for every operational function in AMP. Some functions run every session. Some run weekly. Some run on events. All of them are documented here so nothing falls through the cracks.

---

## Per-session cadence (whenever Josh sits down to work)

The atomic unit of work in AMP is a session, bounded by `/session-start` and `/session-end`.

**Every session starts with:**
1. `/session-start` — reads state, surfaces open items from last session, asks what we're working on
2. Josh names the work
3. `/plan {task}` — invokes the Architect to produce a plan with C-suite review
4. Josh approves, modifies, or rejects the plan
5. `/build` — invokes the Builder to execute the approved plan
6. `/review` — invokes the Reviewer to audit the diff
7. Josh approves the PR (or sends it back for fixes)
8. `/session-end` — updates state documents, commits, pushes, surfaces open items

**Mandatory parts of every session:**
- `/session-start` and `/session-end` always happen
- No work goes to main without going through `/review`
- State documents (SESSION_LOG, DECISIONS where applicable, TRIPWIRES where applicable) update at session end

**Optional parts (invoked as needed):**
- Researcher, Scout, Customer Success — invoked when a brief is needed
- Designer — invoked when UI work is in scope
- Marketing — invoked when customer-facing copy is in scope
- Security — invoked when security-relevant surfaces are touched
- Voice QA — invoked when voice agent work is in scope or call review is needed

---

## Daily cadence (when AMP is in active production)

These run automatically when AMP has customers and operations matter.

**Every morning (10-15 minutes):**
- Architect produces a one-paragraph status: what's open, what's at risk, what needs decisions today
- Customer Success surfaces overnight churn signals or incidents
- Scout surfaces any high-priority ecosystem moves that warrant attention this week

**Every evening:**
- Sentry digest reviewed for new error patterns
- P0 and P1 incidents from the day reviewed and either resolved or queued for next session

These are not founder ceremonies. They are automated reports the founder reads in five minutes.

---

## Weekly cadence (one fixed day, default Friday)

The week's pattern review. Reserved for synthesis, not execution.

**Weekly outputs (in order):**

1. **Scout Weekly Brief** — Ecosystem scan, what's new, what should we consider adopting. Format defined in `.claude/agents/scout.md`.
2. **Voice QA Pattern Review** — Patterns from the week's calls. Common failure modes. Suggested prompt improvements. Format defined in `.claude/agents/voice-qa.md`.
3. **Customer Success Weekly Brief** — Activation funnel, engagement patterns, churn signals, feature request patterns. Format defined in `.claude/agents/customer-success.md`.
4. **Architect Weekly Summary** — One page. What got shipped, what's in flight, what's blocked, decisions made, decisions pending. The founder's snapshot.

**Time investment for Josh:** 30-45 minutes reading. No mandatory output.

**Acts taken on the briefs:**
- Items flagged "worth adopting now" by Scout go into the next session's planning queue
- Failure patterns surfaced by Voice QA generate new regression scenarios
- Churn signals from Customer Success trigger investigation
- The Architect Weekly Summary is committed to `docs/weekly/{date}.md` for the record

---

## Monthly cadence (first Monday of each month)

The month's audit. Reserved for systemic review, not feature work.

**Monthly outputs (in order):**

1. **Security Monthly Audit** — Auth flows, RLS policies, PII handling, secrets rotation status, webhook security, external service security. Format defined in `.claude/agents/security.md`.
2. **Tripwire Audit** — Walk `TRIPWIRES.md`. Anything older than 90 days flagged. Anything stale removed. Anything missing added.
3. **Constitution Compliance Sweep** — Reviewer sub-agent runs a broad sweep checking the codebase against the Constitution. Surfaces drift.
4. **Cost Review** — CFO chair. API spend, infrastructure costs, vendor spend. Per-customer unit economics. Flagged if margin is degrading.
5. **Customer Retention Review** — Customer Success synthesizes the month's churn, activation, expansion, contraction. Reports on net dollar retention.

**Time investment for Josh:** 1-2 hours reading and discussing. May trigger plans for the following week.

---

## Quarterly cadence (first week of January, April, July, October)

The quarter's strategic review. Reserved for vision and direction, not execution.

**Quarterly outputs (in order):**

1. **North Star Review** — Read NORTH_STAR.md. Is what's written there still what we believe? What's been falsified by reality? What's been validated? Decision: version bump or no change.
2. **Constitution Review** — Same question for CONSTITUTION.md. Have we learned anything that should be codified? Have any rules become obsolete?
3. **C-suite Strategic Review** — Full eight-chair review of where AMP is, where it's going, what's working, what's not. CTO on architecture trajectory. CPO on product direction. CMO on positioning and brand. CFO on financial trajectory. CRO on sales motion. CSO on security posture. COO on operational readiness. General Counsel on legal exposure.
4. **Roadmap Reset** — Given everything above, what's the next 90 days of work? Updated `docs/ROADMAP.md`.
5. **Fundraising/Strategic Decision Check** — Should we raise capital? Should we sell? Should we hire? Should we kill anything? These decisions are surfaced quarterly so they don't get made under pressure.

**Time investment for Josh:** Half-day to one day per quarter. The most expensive ceremony, the most valuable one.

---

## On-event cadence (triggered by specific events, not the calendar)

These run when something happens, regardless of where in the calendar we are.

### On any P0 or P1 incident

Within 24 hours of incident resolution:
1. Postmortem written in `docs/postmortems/{date}_{title}.md`
2. Postmortem includes: what happened, why, how we restored service, what we change to prevent recurrence
3. The "what we change" goes into the Constitution as a new rule (if policy-level) or into TRIPWIRES.md as a new check (if detection-level)
4. The Architect Weekly Summary references the incident
5. If a customer was affected, customer-facing communication is reviewed by Marketing before sending

### On any foundational decision

Within the same session as the decision:
1. ADR drafted in DECISIONS.md
2. Includes: date, context, decision, alternatives considered, reasoning, what would change the decision
3. Numbered sequentially (ADR-002 follows ADR-001, etc.)
4. Never edited after committed — superseded by a new ADR if changed

### On any Constitutional amendment

Per Constitution Section 9:
1. Amendment proposed with reasoning
2. Reviewed by relevant C-suite perspectives
3. CEO approves or rejects
4. Approved amendments appended to DECISIONS.md
5. Constitution updated with version bump

### On any customer churn

Within 48 hours of churn:
1. Customer Success investigates with the data available
2. Investigation written in `docs/customer-success/churn/{date}_{anonymized}.md`
3. Pattern signal assessed (one-off vs. broader pattern)
4. If broader pattern, item added to the next session's planning queue

### On any competitor major announcement

Within 48 hours:
1. Scout produces a targeted deep-dive
2. Architect assesses strategic implications
3. If response is warranted, item added to the next session's planning queue

### On any external service outage affecting AMP

Real-time:
1. Status page updated
2. Customers notified per contingency plan in Constitution Section 3.4

Within 24 hours of resolution:
1. Postmortem written (even if AMP was not at fault — we own the customer experience)
2. Contingency procedure reviewed and updated if it failed

---

## Pre-launch gate (one-time event before first paying customer)

Before AMP accepts its first paying customer, all of the following must be true:

1. **Security:** Pre-launch security sign-off APPROVED by the Security sub-agent (per `.claude/agents/security.md`)
2. **Legal:** Terms of Service, Privacy Policy, Acceptable Use Policy live and linked
3. **Operational:** Status page operational, incident response plan documented
4. **Product:** Voice agent quality regression suite passing (30+ scenarios)
5. **Billing:** Stripe integration tested end-to-end with real cards (Josh's own card minimum)
6. **Onboarding:** A non-Josh non-developer can complete signup, configure an agent, and receive a real test call within 60 minutes
7. **Support:** Documented escalation path for customer issues
8. **Branding:** Marketing site live with no broken links, no Lorem ipsum, no placeholder copy

This is a checklist, not a vibe check. Each item is verified specifically.

---

## When the rhythm fails

If a scheduled cadence is skipped, the next occurrence of that cadence includes a "what we missed" section. The system absorbs the miss, doesn't pretend it didn't happen.

If a cadence is being skipped repeatedly, that's a signal to either change the cadence (it's too frequent) or change the system (it's not delivering value). Either action requires explicit decision-making, not silent drift.

The point of the rhythm is to make the right work happen at the right time without requiring willpower. If willpower is the only thing keeping a cadence going, the cadence is wrong.

---

## What's not in this rhythm yet

Some functions become rhythmic only when AMP has more scale than it does today. Listed here for future activation:

- **Daily standup** — When AMP has multiple humans working on it
- **Sprint planning** — When work is too large to plan session-by-session
- **Customer advisory board** — When AMP has 50+ customers and recurring strategic input is valuable
- **Investor update** — When AMP raises capital
- **All-hands** — When AMP has employees

These activate when their conditions are met, not on a schedule.

---

## Final note

The rhythm is the difference between a project that compounds and a project that drifts. Most of the cadences above feel slow to install — they take time the founder thinks should go to building. The trade-off is real and the trade-off is worth it. The founders who fail are the ones who treat operational rhythm as optional. The founders who win treat it as load-bearing.

This document is v1. It will evolve as we learn what works at AMP's scale and what doesn't. Drift in the cadences themselves is the leading indicator that the rhythm needs an update.
