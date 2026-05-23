# Phase 1.5 — Claire Decommission Audit

**Date:** 2026-05-23
**Session:** 009
**ADR:** ADR-003 Phase 1.5 (Decommission Claire-era surfaces, executed before Phase 4 bring-up)
**Triggering principle:** "Claire is dead, AMP is fresh build" (recorded in ADR-007 reasoning trail and SESSION_LOG.md Session 007 line 534)

This document records the full inventory of Claire-era resources as of 2026-05-23, the per-resource keep/delete/investigate decision, and the execution log of every destructive action with verification evidence. It is the source of truth for what was deleted on 2026-05-23 and what remains pending.

---

## Part A — Inventory (no deletions)

The audit covered the systems listed in the Phase 1.5 brief: Vercel, Retell, Twilio, Supabase, GitHub repos, Codespaces, and any other Claire-era artifact surfaced during the sweep.

### Retell

Direct API queries (`/list-agents`, `/list-retell-llms`, `/list-phone-numbers`) against the canonical AMP account.

**Agents — 3 found:**

| Agent ID | Display Name | Voice | LLM | Published | Webhook | Verdict |
|---|---|---|---|---|---|---|
| `agent_0e211c256211ef2ead23cc8375` | AMP - Plumbing - V1 | 11labs-Adrian | `llm_b440eb1b707430fc9aa4d8d0164d` | no | none | **KEEP** — canonical AMP, renamed Session 007 |
| `agent_ddd09f387dcccc43b0f24ea350` | Healthcare Check-In (from template) | retell-Cimo | `llm_b470ed9903fcd7c51980e31e3ac2` | no | none | **DELETE** — Retell template starter, zero references in repo |
| `agent_ceeab21fd886bdb7ea3bb46925` | Patient Screening (from template) | retell-Cimo | (conversation-flow type) | no | none | **DELETE** — Retell template starter, zero references in repo |

**LLMs — 2 found:**

| LLM ID | Model | Prompt subject | Used by | Verdict |
|---|---|---|---|---|
| `llm_b440eb1b707430fc9aa4d8d0164d` | claude-4.6-sonnet | Plumbing receptionist in Ontario, Canada | AMP - Plumbing - V1 | **KEEP** — canonical AMP |
| `llm_b470ed9903fcd7c51980e31e3ac2` | gpt-4.1 | Retell Health appointment screening | Healthcare Check-In (from template) | **DELETE** — orphaned once the Healthcare agent is deleted |

**Phone numbers in Retell registry:** 0. The Twilio number is not registered with Retell at this time.

### Twilio

Direct API queries against the single Twilio account (`AC8bd3c567...`, friendly name "My first Twilio account"). No subaccounts exist.

**Phone numbers — 1 found:**

| Number | voice_url | sms_url | trunk_sid | Verdict |
|---|---|---|---|---|
| `+12494448711` | `https://demo.twilio.com/welcome/voice/` (Twilio demo) | `https://demo.twilio.com/welcome/sms/reply` (Twilio demo) | `TK1be0c12fb9bfc4f7054fbde6b15885f2` (the Claire trunk, see below) | **KEEP** — leave for Phase 4 bring-up per CEO instruction; do not delete the number; trunk_sid will clear to null when the trunk below is deleted |

**SIP trunks — 1 found:**

| Trunk SID | friendly_name | domain_name | Origination URLs | Verdict |
|---|---|---|---|---|
| `TK1be0c12fb9bfc4f7054fbde6b15885f2` | **Claire Ai** | **claireai.pstn.twilio.com** | 1: `sip:sip.retellai.com` (priority 10, enabled) | **DELETE** — unambiguously Claire-branded routing infrastructure; deleting the trunk cascades to delete the origination URL and clears the `trunk_sid` on `+12494448711` without affecting the number itself |

**Cross-references in AMP code (out of Phase 1.5 deletion scope; documented for awareness):**

- `scripts/register-phone.ts:11` hardcodes `terminationUri = 'claireai.pstn.twilio.com'`
- `scripts/audit-trunk.ts:13` hardcodes `trunkSid = 'TK1be0c12fb9bfc4f7054fbde6b15885f2'`
- `scripts/attach-number-to-trunk.ts:13` hardcodes the same trunk SID

These three scripts will return Twilio 404 if executed after the trunk deletion. They are already known to be hardcoded (PROJECT_INVENTORY.md item #16). Per CEO instruction, they are left alone in Phase 1.5; their cleanup falls to the rename sweep or Phase 4 bring-up.

### Supabase

MCP-authenticated queries (`list_organizations`, `list_projects`) against the org `Josh's projects` (`vercel_icfg_bvJnVhI1jinuTeRa8ld4YEpx`).

**Projects — 4 found on the org:**

| Project ID | Name | Status | Region | Created | Verdict |
|---|---|---|---|---|---|
| `yxuhjxxbgbuznpoekwpj` | AMP | ACTIVE_HEALTHY | ca-central-1 | 2026-04-30 | **KEEP** — canonical per ADR-002 |
| `mnsclowesetxpwpukohx` | **ClaireAi** | INACTIVE | ca-central-1 | 2026-04-08 | **INVESTIGATE / DEFER** — Claire-era; do not touch in Phase 1.5 per CEO instruction; separate decision queued |
| `olwbvghtptfabpseipaa` | FinderHub-v2 | ACTIVE_HEALTHY | ca-central-1 | 2026-02-10 | Out of scope — unrelated to Claire and AMP; noted for org-level awareness |
| `qdndcfsyrxxcxapovkso` | combinecrush | INACTIVE | us-west-2 | 2026-03-15 | Out of scope — unrelated; noted |

### GitHub repos

`gh api /user/repos --paginate` against the authenticated `joshjgrills-svg` account.

| Repo | Created | Visibility | Verdict |
|---|---|---|---|
| `joshjgrills-svg/AMP` | 2026-05-01 | public | **KEEP** — canonical |

No `claire-*` repo exists on this account. No additional repos.

### Codespaces

`gh codespace list`.

| Name | Repository | State | Verdict |
|---|---|---|---|
| `congenial-halibut-wrpp4974657p2gxrv` | `joshjgrills-svg/AMP` | Available | **KEEP** — current AMP dev environment; "congenial-halibut" is a cosmetic GitHub-generated codespace name, not a Claire reference |

### Vercel

**GAP at audit time.** The Vercel CLI is installed locally but unauthenticated. The audit could not enumerate Vercel projects or env vars directly. Pending CEO check of the Vercel dashboard for: (a) whether `claire-ai-beta` still exists as a project, (b) any other Claire-named projects, (c) env vars on any Claire-era project. The canonical AMP project (`prj_2AkzhMh9UmmxgA62b142dlEHEVkc`, team `team_X0fsBiUbRRvKH64giowgF67T`) is known from `.vercel/project.json` per PROJECT_INVENTORY.md line 173.

The Vercel decommission of `claire-ai-beta.vercel.app` is the remaining open ADR-002 commitment. It is queued as a follow-up to this PR.

---

## Part B — Decisions

CEO confirmed the following calls on 2026-05-23 in response to the Part A inventory:

1. **Delete the two Claire-era "from template" Retell agents** and the orphaned LLM. Three deletions: `agent_ddd09f387dcccc43b0f24ea350`, `agent_ceeab21fd886bdb7ea3bb46925`, `llm_b470ed9903fcd7c51980e31e3ac2`.
2. **Delete the Twilio SIP trunk** `TK1be0c12fb9bfc4f7054fbde6b15885f2` ("Claire Ai", domain `claireai.pstn.twilio.com`), including its origination URL. Phone number `+12494448711` is left alone — trunk deletion will clear its `trunk_sid` field to null without affecting the number itself. Pre-flight verification required: (a) confirm number's `voice_url` is still Twilio demo at the moment of deletion, (b) confirm no other phone numbers reference this trunk_sid. Halt and report if either check surfaces unexpected dependencies.
3. **Vercel decommission** pending CEO dashboard check; not executed in this session. Will be folded into this PR or a follow-up PR once the dashboard data is available.
4. **Hardcoded Claire references in three scripts** (`register-phone.ts`, `audit-trunk.ts`, `attach-number-to-trunk.ts`) are deferred to the rename sweep. They will return Twilio 404 if executed after this session; leave them alone for now.
5. **`ClaireAi` Supabase project** (`mnsclowesetxpwpukohx`) is deferred to a separate decision. Do not touch in Phase 1.5.

---

## Part C — Execution log

All four destructive actions executed in sequence with per-step verification. UTC timestamps captured at the moment of each `DELETE` call.

### Deletion 1 — Retell agent `agent_ddd09f387dcccc43b0f24ea350`

- **Action:** `DELETE https://api.retellai.com/delete-agent/agent_ddd09f387dcccc43b0f24ea350`
- **Timestamp:** 2026-05-23T03:44:05Z
- **Response:** HTTP 204 (no content)
- **Verification:** `GET /get-agent/agent_ddd09f387dcccc43b0f24ea350` returned HTTP 404 with body `{"status":"error","message":"Item agent_ddd09f387dcccc43b0f24ea350 not found from agent"}`. Confirmed gone.

### Deletion 2 — Retell agent `agent_ceeab21fd886bdb7ea3bb46925`

- **Action:** `DELETE https://api.retellai.com/delete-agent/agent_ceeab21fd886bdb7ea3bb46925`
- **Timestamp:** 2026-05-23T03:44:15Z
- **Response:** HTTP 204
- **Verification:** `GET /get-agent/agent_ceeab21fd886bdb7ea3bb46925` returned HTTP 404 with body `{"status":"error","message":"Item agent_ceeab21fd886bdb7ea3bb46925 not found from agent"}`. Confirmed gone.

### Deletion 3 — Retell LLM `llm_b470ed9903fcd7c51980e31e3ac2`

- **Action:** `DELETE https://api.retellai.com/delete-retell-llm/llm_b470ed9903fcd7c51980e31e3ac2`
- **Timestamp:** 2026-05-23T03:44:25Z
- **Response:** HTTP 204
- **Verification:** `GET /get-retell-llm/llm_b470ed9903fcd7c51980e31e3ac2` returned HTTP 404 with body `{"status":"error","message":"Not Found"}`. Confirmed gone.

**Retell post-deletion state — `/list-agents` and `/list-retell-llms`:**

- Agents: 1 — `agent_0e211c256211ef2ead23cc8375` "AMP - Plumbing - V1" (canonical AMP, untouched).
- LLMs: 1 — `llm_b440eb1b707430fc9aa4d8d0164d` (claude-4.6-sonnet, plumbing prompt; canonical AMP, untouched).

### Deletion 4 — Twilio SIP trunk `TK1be0c12fb9bfc4f7054fbde6b15885f2`

**Pre-flight verification (immediately before deletion):**

1. `+12494448711`'s `voice_url` confirmed as `https://demo.twilio.com/welcome/voice/` (unchanged from Part A; inert).
2. Listing all phone numbers on the account and filtering for `trunk_sid == "TK1be0c12fb9bfc4f7054fbde6b15885f2"` returned only `+12494448711`. No other numbers reference this trunk.

Both pre-flight checks passed. Proceeding with deletion.

- **Action:** `DELETE https://trunking.twilio.com/v1/Trunks/TK1be0c12fb9bfc4f7054fbde6b15885f2`
- **Timestamp:** 2026-05-23T03:45:02Z
- **Response:** HTTP 204
- **Verification:**
  - `GET /v1/Trunks/TK1be0c12fb9bfc4f7054fbde6b15885f2` returned HTTP 404 with body `{"code":20404,"message":"The requested resource /v1/Trunks/TK1be0c12fb9bfc4f7054fbde6b15885f2 was not found","more_info":"https://www.twilio.com/docs/errors/20404","status":404}`. Trunk confirmed gone.
  - Listing phone numbers confirms `+12494448711` is preserved with `voice_url` unchanged (Twilio demo), `sms_url` unchanged, and `trunk_sid: null` (was the deleted trunk's SID). Twilio cascade-deleted the origination URL with the trunk and cleared the phone number's `trunk_sid` field without affecting the number itself.

---

## Final state (after Part C execution)

**Deleted (4 resources):**

- Retell agent `agent_ddd09f387dcccc43b0f24ea350` ("Healthcare Check-In (from template)")
- Retell agent `agent_ceeab21fd886bdb7ea3bb46925` ("Patient Screening (from template)")
- Retell LLM `llm_b470ed9903fcd7c51980e31e3ac2` (gpt-4.1, Retell Health prompt)
- Twilio SIP trunk `TK1be0c12fb9bfc4f7054fbde6b15885f2` ("Claire Ai", domain `claireai.pstn.twilio.com`) including its `sip:sip.retellai.com` origination URL

**Preserved (canonical AMP):**

- Retell agent `agent_0e211c256211ef2ead23cc8375` ("AMP - Plumbing - V1")
- Retell LLM `llm_b440eb1b707430fc9aa4d8d0164d` (claude-4.6-sonnet, plumbing)
- Twilio phone number `+12494448711` (now with `trunk_sid: null`; voice_url + sms_url remain the inert Twilio demo URLs as before)
- Supabase project `yxuhjxxbgbuznpoekwpj` "AMP"
- GitHub repo `joshjgrills-svg/AMP`
- Codespace `congenial-halibut-wrpp4974657p2gxrv`

**Pending (queued as follow-ups, NOT executed in Phase 1.5):**

- **Vercel `claire-ai-beta.vercel.app` decommission** — awaiting CEO dashboard check; will be folded into this PR or a follow-up PR. This is the remaining open ADR-002 commitment.
- **Supabase project `ClaireAi` (`mnsclowesetxpwpukohx`)** — separate decision; not Phase 1.5 scope.
- **Hardcoded Claire references in `scripts/register-phone.ts`, `scripts/audit-trunk.ts`, `scripts/attach-number-to-trunk.ts`** — will return Twilio 404 if executed; cleanup deferred to the rename sweep (SESSION_LOG.md Pending follow-up #3) or to Phase 4 bring-up, whichever runs first.

---

## References

- ADR-002 (2026-05-13) — original decommission commitment for Claire-era artifacts; Retell and Twilio portions are now executed by this audit; Vercel portion pending
- ADR-003 (2026-05-22) — Constitutional Cleanup Execution Plan, Phase 1.5 entry at DECISIONS.md line 436
- Session 007 (2026-05-22) — Retell agent rename ("AMP Plumber - Default" → "AMP - Plumbing - V1") and drift investigation that surfaced the dead `agent_58fbaa9f9eb2e1f6698e54bedd`
- ADR-007 (2026-05-23) — recorded the "Claire is dead, AMP is fresh build" operating principle in the auto-memory governance ADR; reasoning trail applies to this decommission
- PROJECT_INVENTORY.md item #16 — the three hardcoded Claire-era references in `scripts/` (out of Phase 1.5 deletion scope; deferred to rename sweep)
