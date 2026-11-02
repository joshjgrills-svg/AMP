# ProScore Front Desk — session handoff (2026-11-02)

**Read this first in any new session working on Front Desk.** Full plan: https://claude.ai/artifact/BQwzcKNLL58awAS8KqBxMM (copy of v4 in `docs/front-desk/plan-v4.html`).

## What Front Desk is
An AI receptionist for ProScore pros (Ontario trades): answers missed / after-hours / overflow calls, captures the job with trade-specific questions, routes emergencies to the pro's cell, books, follows up, in English and French. Goal: revenue for ProScore; must beat every competitor (Jobber Receptionist, Housecall Pro CSR AI, Workiz Genius, Avoca, Hatch, Sameday, Rosie, Dialbox, Smith.ai) on product and price.

## Decisions by Josh (CEO) — settled
- Order: Front Desk first, then ProScore-in-Claude connector (bookable by AI assistants).
- Pricing (LOCKED): Growth + Starter add-on C$69/mo (60 calls); Premium INCLUDES Starter; Pro add-on +C$79 (150 calls) and Max add-on +C$199 (400 calls) on Premium only; every feature in every plan; C$0.90 per extra call; annual = 2 months free.
- Trial: card taken at signup. 14-day standard; 30-day launch offer with a deadline (recommendation, confirm).
- Inbound calls only; outbound only to people who asked (incl. instant follow-up on web leads with consent checkbox).
- Review requests go to EVERY completed job, never selective. Front Desk never feeds the ProScore score (rule P3).
- No lawyer for now: ship safe defaults (AI + recording disclosure, consent ledger, STOP everywhere, 90-day transcript deletion).
- Calendar: ProScore keeps the booking; .ics invite to any calendar day 1; Google + Outlook two-way sync; Jobber next.
- Twilio: separate sub-account "ProScore Front Desk" (ID starts AC2d9be5d5ead…). Never touch the main account or ProScore's live number +1 365 825 4776.
- Josh has an Apple developer account; App Store Connect API key needed only at the phone-app milestone. Google Play account still needed (US$25).

## Architecture (from the integration plan)
- Build INSIDE the finderhub (ProScore) repo + ProScore Supabase; port AMP code (lib/retell.ts, lib/twilio.ts, webhook) by hand and harden it. AMP's own DB untouched.
- Tables `front_desk_*`, service-role only (RLS on, REVOKE from PUBLIC/anon/authenticated). Keyed on provider_id (location).
- CRITICAL: separate Stripe subscription + `metadata.product=front_desk`; webhook branch BEFORE plan routing; `event-account.ts` must ignore FD subscriptions — otherwise `priceIdToTier` returns 'claimed' and a Front Desk purchase downgrades a paying pro's membership.
- Retell: native Claude model (keep Retell batch testing), one template agent + per-call dynamic variables via the Inbound Call Webhook; Conversation Flow for the safety-triage opening; post-call analysis for the job ticket; warm transfer with whisper. Multi-prompt agents and legacy Cal.com tools are deprecated; legacy SIP endpoint removed 2026-09-30 (verify trunk origination); list agents is `POST /v2/list-agents`.
- Twilio: one sub-account for all pros, one number per pro tagged in DB; SIP trunk to Retell with Disaster Recovery URL → fallback TwiML (ring pro's cell, then voicemail + transcript by SMS). Canadian inventory: only 249 and 289 had numbers (none in 705/416/647/905/613/519/437) — buy local code first, then overlay code.
- Phone app: web app in a thin native shell (Expo/Capacitor) for Time-Sensitive push + action buttons; emergencies also by SMS.

## Done so far
- Stripe TEST: product `prod_VYW8dN2glFTr69` "ProScore Front Desk", prices by lookup_key: fd_starter_monthly 6900, fd_starter_annual 69000, fd_pro_monthly 7900, fd_pro_annual 79000, fd_max_monthly 19900, fd_max_annual 199000 (CAD cents).
- Retell: key works (`FD_RETELL_API_KEY`), workspace empty.
- Env vars in the cloud environment: FD_TWILIO_ACCOUNT_SID, FD_TWILIO_API_KEY_SID, FD_TWILIO_API_KEY_SECRET, FD_RETELL_API_KEY, STRIPE_TEST_SECRET_KEY (sk_test).

## Next steps (M0)
1. Verify Twilio: `GET /2010-04-01/Accounts/$FD_TWILIO_ACCOUNT_SID/IncomingPhoneNumbers.json` must return 200 (SID must start AC2d9be5d5ead).
2. ADR in finderhub: `docs/architecture/ADR-0NN-front-desk.md`; AMP ADR noting Front Desk is ProScore-owned.
3. SIP trunk + DR URL in the sub-account; buy one test number (249/289).
4. Retell template agent (safety triage first), Claude Haiku-class; measure p95 turn latency < 0.8–1.0 s on real calls.
5. Trade packs (11 trades; plumbing, HVAC, electrical first) with 4-check verification; Josh to approve top-scored pros as reviewers (3 free months).
6. Open Josh decisions: v1 additions list (lead follow-up, photo intake, landline handling, self-reschedule, VIP/block lists, extra languages, AI-agent callers, "Booked via ProScore" with off switch, terms of service) and whether Booking/Follow-up/Brings-Customers upgrades move launch to ~14–15 weeks or ship after an ~11–12 week launch.
