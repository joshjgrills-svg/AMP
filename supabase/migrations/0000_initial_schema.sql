-- ============================================================================
-- 0000_initial_schema.sql — AMP canonical schema baseline
-- ----------------------------------------------------------------------------
-- Date:      2026-05-23
-- Author:    Architect (Claude); execution by Builder per ADR-003
-- Reason:    Phase 2 (Redrafted) per ADR-003 — "Claire is dead, AMP is fresh
--            build" operating principle (ADR-007, Session 007).
--
--            Drops the seven zero-row legacy amp_* tables, the
--            amp_set_updated_at() trigger function, and the ten amp_* enum
--            types. Creates the six canonical Constitution §1.3 tables —
--            customers, agent_templates, agents, conversations, appointments,
--            alerts — each with uuid PK, created_at / updated_at + trigger,
--            RLS enabled, and inline idx_* indexes.
--
--            Preserved by intent: the ensure_rls event trigger and its
--            backing function public.rls_auto_enable(). Both are already
--            ADR-008-compliant in name and provide defense-in-depth RLS
--            auto-enable on any new table in schema public.
--
-- Rollback:  ONE-WAY MIGRATION. The drops are CASCADE and destroy the legacy
--            amp_* tables, their indexes, triggers, and the related enum
--            types irrecoverably. Rollback path requires restoring from a
--            Supabase point-in-time backup taken BEFORE this migration is
--            applied. Pre-write audit (Session 012, 2026-05-23) confirmed
--            all seven legacy tables are zero-row, so the destructive surface
--            carries no production data loss; the migration is destructive
--            of schema only.
--
-- References:
--   docs/DECISIONS.md           — ADR-003 Phase 2 + Phase 4 Redraft (2026-05-23)
--   docs/DECISIONS.md           — ADR-002 line 98 (existing Supabase data is throwaway)
--   docs/DECISIONS.md           — ADR-007 ("Claire is dead, AMP is fresh build")
--   docs/DECISIONS.md           — ADR-008 (three-layer naming convention)
--   docs/CONSTITUTION.md §1.1   — schema conventions (uuid, timestamps, RLS, naming)
--   docs/CONSTITUTION.md §1.2   — migration discipline (this header)
--   docs/CONSTITUTION.md §1.3   — locked terms (customer, agent, conversation, ...)
--   docs/CONSTITUTION.md §4.5   — RLS posture (default deny)
--
-- RLS note:  Every table created here is `enable row level security`. No allow
--            policies are declared in this migration, per the execution spec.
--            Default-deny posture holds for the anon and authenticated roles;
--            the only access path today is the Retell webhook handler via the
--            service-role client (which bypasses RLS by design). Allow
--            policies arrive in a later migration when authenticated/anon
--            access patterns become load-bearing.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1. Drop legacy amp_* tables (CASCADE; all confirmed zero-row in pre-audit)
-- ----------------------------------------------------------------------------

drop table if exists public.amp_weekly_reports cascade;
drop table if exists public.amp_alerts         cascade;
drop table if exists public.amp_appointments   cascade;
drop table if exists public.amp_calls          cascade;
drop table if exists public.amp_agents         cascade;
drop table if exists public.amp_templates      cascade;
drop table if exists public.amp_organizations  cascade;

-- ----------------------------------------------------------------------------
-- 2. Drop legacy amp_* enum types (CASCADE)
-- ----------------------------------------------------------------------------

drop type if exists public.amp_org_status         cascade;
drop type if exists public.amp_org_tier           cascade;
drop type if exists public.amp_agent_status       cascade;
drop type if exists public.amp_call_direction     cascade;
drop type if exists public.amp_call_status        cascade;
drop type if exists public.amp_call_outcome       cascade;
drop type if exists public.amp_sentiment          cascade;
drop type if exists public.amp_appointment_status cascade;
drop type if exists public.amp_alert_type         cascade;
drop type if exists public.amp_alert_severity     cascade;

-- ----------------------------------------------------------------------------
-- 3. Drop legacy amp_set_updated_at() trigger function (CASCADE)
--    NOT dropped: rls_auto_enable() and the ensure_rls event trigger.
-- ----------------------------------------------------------------------------

drop function if exists public.amp_set_updated_at() cascade;

-- ----------------------------------------------------------------------------
-- 4. Extensions
-- ----------------------------------------------------------------------------

create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- 5. Shared trigger function (canonical, no amp_ prefix)
-- ----------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- 6. Enum types
--    Naming per Constitution §1.1: {table_singular}_{column_singular}_type.
--    Values lowercase snake_case.
-- ----------------------------------------------------------------------------

create type public.customer_status_type        as enum ('trial', 'active', 'paused', 'churned');
create type public.customer_tier_type          as enum ('starter', 'growth', 'scale', 'enterprise');
create type public.agent_status_type           as enum ('draft', 'active', 'paused', 'archived');
create type public.conversation_direction_type as enum ('inbound', 'outbound');
create type public.conversation_status_type    as enum ('queued', 'in_progress', 'completed', 'missed', 'voicemail', 'failed');
create type public.conversation_outcome_type   as enum ('booked', 'info_provided', 'transferred', 'voicemail', 'hangup', 'spam', 'unresolved');
create type public.conversation_sentiment_type as enum ('positive', 'neutral', 'negative');
create type public.appointment_status_type     as enum ('scheduled', 'confirmed', 'completed', 'canceled', 'no_show', 'rescheduled');
create type public.alert_severity_type         as enum ('low', 'medium', 'high', 'critical');
create type public.alert_kind_type             as enum ('system_error', 'payment_failed', 'missed_call');

-- ----------------------------------------------------------------------------
-- 7. customers — Constitution §1.3 locked term (replaces amp_organizations)
-- ----------------------------------------------------------------------------

create table public.customers (
  id                          uuid                  primary key default gen_random_uuid() not null,
  name                        text                  not null,
  slug                        text                  not null,
  contact_email               text,
  contact_phone               text,
  timezone                    text                  not null default 'America/Toronto',
  status                      customer_status_type  not null default 'trial',
  tier                        customer_tier_type    not null default 'starter',
  stripe_customer_id          text,
  stripe_subscription_id      text,
  stripe_price_id             text,
  stripe_subscription_status  text,
  trial_ends_at               timestamptz,
  created_at                  timestamptz           not null default now(),
  updated_at                  timestamptz           not null default now()
);

create trigger customers_set_updated_at
  before update on public.customers
  for each row execute function public.set_updated_at();

alter table public.customers enable row level security;

create unique index idx_customers_slug                   on public.customers (slug);
create unique index idx_customers_stripe_customer_id     on public.customers (stripe_customer_id);
create unique index idx_customers_stripe_subscription_id on public.customers (stripe_subscription_id);
create index        idx_customers_status                 on public.customers (status);
create index        idx_customers_tier                   on public.customers (tier);

-- ----------------------------------------------------------------------------
-- 8. agent_templates — ADR-002 Q6 AMP-specific extension (replaces amp_templates)
-- ----------------------------------------------------------------------------

create table public.agent_templates (
  id             uuid         primary key default gen_random_uuid() not null,
  slug           text         not null,
  name           text         not null,
  industry       text         not null,
  description    text,
  greeting       text         not null,
  system_prompt  text         not null,
  faqs           jsonb        not null default '[]'::jsonb,
  voice_id       text,
  is_active      boolean      not null default true,
  created_at     timestamptz  not null default now(),
  updated_at     timestamptz  not null default now()
);

create trigger agent_templates_set_updated_at
  before update on public.agent_templates
  for each row execute function public.set_updated_at();

alter table public.agent_templates enable row level security;

create unique index idx_agent_templates_slug      on public.agent_templates (slug);
create index        idx_agent_templates_industry  on public.agent_templates (industry);
create index        idx_agent_templates_is_active on public.agent_templates (is_active);

-- ----------------------------------------------------------------------------
-- 9. agents — Constitution §1.3 locked term (replaces amp_agents)
-- ----------------------------------------------------------------------------

create table public.agents (
  id                 uuid               primary key default gen_random_uuid() not null,
  customer_id        uuid               not null references public.customers(id)        on delete cascade,
  agent_template_id  uuid                        references public.agent_templates(id) on delete set null,
  name               text               not null,
  retell_agent_id    text,
  retell_llm_id      text,
  greeting           text,
  system_prompt      text,
  voice_id           text,
  business_hours     jsonb              not null default '{
    "monday":    {"open": "08:00", "close": "18:00", "enabled": true},
    "tuesday":   {"open": "08:00", "close": "18:00", "enabled": true},
    "wednesday": {"open": "08:00", "close": "18:00", "enabled": true},
    "thursday":  {"open": "08:00", "close": "18:00", "enabled": true},
    "friday":    {"open": "08:00", "close": "18:00", "enabled": true},
    "saturday":  {"open": "09:00", "close": "14:00", "enabled": false},
    "sunday":    {"open": "09:00", "close": "14:00", "enabled": false}
  }'::jsonb,
  booking_config     jsonb              not null default '{
    "enabled": true,
    "calendar_provider": "google",
    "calendar_id": null,
    "slot_duration_minutes": 60,
    "buffer_minutes": 15,
    "max_advance_days": 30,
    "min_lead_hours": 2,
    "service_area_zip_codes": [],
    "deposit_required": false
  }'::jsonb,
  status             agent_status_type  not null default 'draft',
  created_at         timestamptz        not null default now(),
  updated_at         timestamptz        not null default now()
);

create trigger agents_set_updated_at
  before update on public.agents
  for each row execute function public.set_updated_at();

alter table public.agents enable row level security;

create unique index idx_agents_retell_agent_id    on public.agents (retell_agent_id);
create index        idx_agents_customer_id        on public.agents (customer_id);
create index        idx_agents_agent_template_id  on public.agents (agent_template_id);
create index        idx_agents_status             on public.agents (status);

-- ----------------------------------------------------------------------------
-- 10. conversations — Constitution §1.3 locked term (replaces amp_calls)
-- ----------------------------------------------------------------------------

create table public.conversations (
  id                uuid                            primary key default gen_random_uuid() not null,
  customer_id       uuid                            not null references public.customers(id) on delete cascade,
  agent_id          uuid                                     references public.agents(id)    on delete set null,
  retell_call_id    text,
  twilio_call_sid   text,
  caller_name       text,
  caller_phone      text,
  caller_email      text,
  direction         conversation_direction_type     not null default 'inbound',
  status            conversation_status_type        not null default 'queued',
  outcome           conversation_outcome_type,
  sentiment         conversation_sentiment_type,
  started_at        timestamptz,
  ended_at          timestamptz,
  duration_seconds  integer,
  transcript        jsonb,
  summary           text,
  recording_url     text,
  flagged           boolean                         not null default false,
  flag_reason       text,
  metadata          jsonb                           not null default '{}'::jsonb,
  created_at        timestamptz                     not null default now(),
  updated_at        timestamptz                     not null default now()
);

create trigger conversations_set_updated_at
  before update on public.conversations
  for each row execute function public.set_updated_at();

alter table public.conversations enable row level security;

create unique index idx_conversations_retell_call_id          on public.conversations (retell_call_id);
create unique index idx_conversations_twilio_call_sid         on public.conversations (twilio_call_sid);
create index        idx_conversations_customer_id             on public.conversations (customer_id);
create index        idx_conversations_agent_id                on public.conversations (agent_id);
create index        idx_conversations_status                  on public.conversations (status);
create index        idx_conversations_outcome                 on public.conversations (outcome);
create index        idx_conversations_started_at              on public.conversations (started_at desc);
create index        idx_conversations_caller_phone            on public.conversations (caller_phone);
create index        idx_conversations_customer_id_started_at  on public.conversations (customer_id, started_at desc);
create index        idx_conversations_flagged                 on public.conversations (flagged) where flagged = true;

-- ----------------------------------------------------------------------------
-- 11. appointments — ADR-002 Q6 AMP-specific extension (replaces amp_appointments)
-- ----------------------------------------------------------------------------

create table public.appointments (
  id                    uuid                      primary key default gen_random_uuid() not null,
  customer_id           uuid                      not null references public.customers(id)     on delete cascade,
  agent_id              uuid                               references public.agents(id)        on delete set null,
  conversation_id       uuid                               references public.conversations(id) on delete set null,
  end_user_name         text                      not null,
  end_user_phone        text,
  end_user_email        text,
  end_user_address      text,
  service_type          text,
  notes                 text,
  scheduled_at          timestamptz               not null,
  duration_minutes      integer                   not null default 60,
  calendar_provider     text,
  calendar_event_id     text,
  confirmation_sent     boolean                   not null default false,
  confirmation_sent_at  timestamptz,
  reminder_sent         boolean                   not null default false,
  reminder_sent_at      timestamptz,
  status                appointment_status_type   not null default 'scheduled',
  created_at            timestamptz               not null default now(),
  updated_at            timestamptz               not null default now()
);

create trigger appointments_set_updated_at
  before update on public.appointments
  for each row execute function public.set_updated_at();

alter table public.appointments enable row level security;

create index idx_appointments_customer_id              on public.appointments (customer_id);
create index idx_appointments_agent_id                 on public.appointments (agent_id);
create index idx_appointments_conversation_id          on public.appointments (conversation_id);
create index idx_appointments_scheduled_at             on public.appointments (scheduled_at);
create index idx_appointments_status                   on public.appointments (status);
create index idx_appointments_calendar_event_id        on public.appointments (calendar_event_id);
create index idx_appointments_customer_id_scheduled_at on public.appointments (customer_id, scheduled_at);

-- ----------------------------------------------------------------------------
-- 12. alerts — ADR-002 Q6 AMP-specific extension (replaces amp_alerts)
-- ----------------------------------------------------------------------------

create table public.alerts (
  id                uuid                  primary key default gen_random_uuid() not null,
  customer_id       uuid                  not null references public.customers(id)     on delete cascade,
  agent_id          uuid                           references public.agents(id)        on delete set null,
  conversation_id   uuid                           references public.conversations(id) on delete set null,
  kind              alert_kind_type       not null,
  severity          alert_severity_type   not null default 'medium',
  title             text                  not null,
  message           text,
  context           jsonb                 not null default '{}'::jsonb,
  resolved          boolean               not null default false,
  resolved_at       timestamptz,
  resolved_by       uuid,
  resolution_notes  text,
  created_at        timestamptz           not null default now(),
  updated_at        timestamptz           not null default now()
);

create trigger alerts_set_updated_at
  before update on public.alerts
  for each row execute function public.set_updated_at();

alter table public.alerts enable row level security;

create index idx_alerts_customer_id            on public.alerts (customer_id);
create index idx_alerts_agent_id               on public.alerts (agent_id);
create index idx_alerts_conversation_id        on public.alerts (conversation_id);
create index idx_alerts_kind                   on public.alerts (kind);
create index idx_alerts_severity               on public.alerts (severity);
create index idx_alerts_resolved               on public.alerts (resolved) where resolved = false;
create index idx_alerts_customer_id_created_at on public.alerts (customer_id, created_at desc);

commit;
