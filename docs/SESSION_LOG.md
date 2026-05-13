# AMP — Session Log

Rolling log of the last 10 AMP work sessions. The `/session-start` command reads this file to surface open items from previous sessions. The `/session-end` command appends to this file.

When this file exceeds 10 entries, the oldest entries are archived to `docs/archive/session-log/{year}-{month}.md` and removed from this file.

---

## Session 000 — Foundation Phase complete
**Date:** 2026-05-12
**Duration:** Multi-hour PM/Architect session with CEO
**Participants:** PM/Architect (Claude), CEO (Josh)

### What happened
- AMP product vision clarified as multi-agent platform serving any professional business
- Orchestration model decided: AMP owns the brain (Option A) — logged as ADR-001
- Foundation documents drafted and ratified:
  - NORTH_STAR.md (v1)
  - CONSTITUTION.md (v1)
  - RUNTIME_ARCHITECTURE.md (v1)
  - OPERATING_RHYTHM.md (v1)
  - DECISIONS.md (ADR-001 logged)
  - TRIPWIRES.md (14 starter + 4 predictive tripwires)
  - SESSION_LOG.md (this file)
  - README.md (system orientation document)
- Ten sub-agents installed in `.claude/agents/`:
  - Core team: architect, builder, reviewer
  - Specialists: voice-qa, researcher, scout, designer, customer-success, marketing, security
- Five slash commands installed in `.claude/commands/`:
  - session-start, plan, build, review, session-end

### What got decided
- AMP is solely Josh's company (no partners)
- $1M ARR target in 12 months after AMP becomes primary (post-ProScore launch)
- Parallel-then-primary commitment: AMP in foundation mode until ProScore launches, full focus after
- Wedge decision deferred to ADR-002 with full market analysis
- Orchestration architecture: AMP-owned brain (Option A, ADR-001)

### What's open for next session
- Run inventory on `congenial-halibut` Codespace to surface what exists in `app/`, `lib/`, `scripts/`, `supabase/`
- Document inventory findings in `docs/PROJECT_INVENTORY.md`
- Update foundation docs to v1.1 based on inventory reality
- Begin ADR-002 research (wedge selection)
- Begin thinking about ADR-003 (integration architecture — how agents plug into customers' digital assets)

### What needs Josh
- Eventually: read the four foundation documents and gut-check for anything that feels off
- Eventually: input on Runtime Architecture Section 9 open questions (orchestration framework choice, model selection per agent)
- Active focus on ProScore launch in the next 2-4 weeks; AMP foundation work continues in the gaps

### Tripwires fired
None — this was a foundation session, no code touched

### Constitution version at session start: N/A (didn't exist)
### Constitution version at session end: v1

### Notes for future-Claude
The repo (`congenial-halibut`) starts with minimal scaffolding — CLAUDE.md is 11 bytes (just a pointer to AGENTS.md), AGENTS.md is 327 bytes (a generic Next.js 15 warning). No inherited assumptions to fight. The `app/`, `lib/`, `scripts/`, and `supabase/` folders contain "feat: initial AMP scaffold" commits but the contents have not been audited. The Vercel deployment at `claire-ai-beta.vercel.app` is inherited from the Claire OS era and its current state is unknown — this is part of what the inventory will surface.
