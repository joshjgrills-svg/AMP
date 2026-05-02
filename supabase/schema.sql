-- AMP database schema
-- All AMP-owned tables use the `amp_` prefix to coexist with the existing
-- `providers` table (ProScore) that AMP organizations link back to.

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

create type amp_organization_status as enum ('trial', 'active', 'paused', 'churned');
create type amp_organization_tier   as enum ('starter', 'growth', 'scale', 'enterprise');

create type amp_agent_status as enum ('draft', 'active', 'paused', 'archived');

create type amp_call_direction as enum ('inbound', 'outbound');
create type amp_call_status    as enum ('queued', 'in_progress', 'completed', 'missed', 'failed', 'voicemail');
create type amp_call_outcome   as enum ('booked', 'info_only', 'transferred', 'voicemail', 'hangup', 'spam', 'unresolved');
create type amp_sentiment      as enum ('positive', 'neutral', 'negative');

create type amp_appointment_status as enum ('scheduled', 'confirmed', 'completed', 'canceled', 'no_show', 'rescheduled');

create type amp_alert_type     as enum (
  'missed_call',
  'low_sentiment',
  'no_booking',
  'booking_failed',
  'system_error',
  'payment_failed',
  'phone_number_issue',
  'integration_error'
);
create type amp_alert_severity as enum ('low', 'medium', 'high', 'critical');

-- ---------------------------------------------------------------------------
-- updated_at trigger helper
-- ---------------------------------------------------------------------------

create or replace function amp_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- amp_organizations: contractor accounts (AMP clients)
-- ---------------------------------------------------------------------------

create table amp_organizations (
  id                      uuid primary key default gen_random_uuid(),
  proscore_provider_id    uuid unique references providers(id) on delete set null,
  name                    text not null,
  slug                    text unique not null,
  contact_email           text,
  contact_phone           text,
  timezone                text not null default 'America/New_York',

  status                  amp_organization_status not null default 'trial',
  tier                    amp_organization_tier   not null default 'starter',
  trust_score             numeric(5,2) not null default 0
                            check (trust_score >= 0 and trust_score <= 100),
  mrr                     numeric(10,2) not null default 0,

  stripe_customer_id      text unique,
  stripe_subscription_id  text unique,
  stripe_price_id         text,
  stripe_subscription_status text,
  trial_ends_at           timestamptz,

  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create index amp_organizations_status_idx          on amp_organizations(status);
create index amp_organizations_tier_idx            on amp_organizations(tier);
create index amp_organizations_proscore_idx        on amp_organizations(proscore_provider_id);
create index amp_organizations_stripe_customer_idx on amp_organizations(stripe_customer_id);

create trigger amp_organizations_set_updated_at
  before update on amp_organizations
  for each row execute function amp_set_updated_at();

-- ---------------------------------------------------------------------------
-- amp_templates: reusable agent personalities (plumber, electrician, ...)
-- ---------------------------------------------------------------------------

create table amp_templates (
  id              uuid primary key default gen_random_uuid(),
  slug            text unique not null,
  name            text not null,
  industry        text not null,
  description     text,
  greeting        text not null,
  system_prompt   text not null,
  faqs            jsonb not null default '[]'::jsonb,
  voice_id        text,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index amp_templates_industry_idx  on amp_templates(industry);
create index amp_templates_is_active_idx on amp_templates(is_active);

create trigger amp_templates_set_updated_at
  before update on amp_templates
  for each row execute function amp_set_updated_at();

-- ---------------------------------------------------------------------------
-- amp_agents: deployed agent instance per organization
-- ---------------------------------------------------------------------------

create table amp_agents (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null references amp_organizations(id) on delete cascade,
  template_id         uuid references amp_templates(id) on delete set null,

  name                text not null,
  retell_agent_id     text unique,
  twilio_phone_number text unique,

  greeting            text,
  system_prompt       text,
  voice_id            text,

  business_hours      jsonb not null default '{
    "monday":    {"open": "08:00", "close": "18:00", "enabled": true},
    "tuesday":   {"open": "08:00", "close": "18:00", "enabled": true},
    "wednesday": {"open": "08:00", "close": "18:00", "enabled": true},
    "thursday":  {"open": "08:00", "close": "18:00", "enabled": true},
    "friday":    {"open": "08:00", "close": "18:00", "enabled": true},
    "saturday":  {"open": "09:00", "close": "14:00", "enabled": false},
    "sunday":    {"open": "09:00", "close": "14:00", "enabled": false}
  }'::jsonb,

  booking_config      jsonb not null default '{
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

  status              amp_agent_status not null default 'draft',

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index amp_agents_organization_idx on amp_agents(organization_id);
create index amp_agents_template_idx     on amp_agents(template_id);
create index amp_agents_status_idx       on amp_agents(status);
create index amp_agents_retell_idx       on amp_agents(retell_agent_id);

create trigger amp_agents_set_updated_at
  before update on amp_agents
  for each row execute function amp_set_updated_at();

-- ---------------------------------------------------------------------------
-- amp_calls: call logs from Retell
-- ---------------------------------------------------------------------------

create table amp_calls (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null references amp_organizations(id) on delete cascade,
  agent_id            uuid references amp_agents(id) on delete set null,

  retell_call_id      text unique,
  twilio_call_sid     text unique,

  caller_name         text,
  caller_phone        text,
  caller_email        text,

  direction           amp_call_direction not null default 'inbound',
  status              amp_call_status    not null default 'queued',
  outcome             amp_call_outcome,
  sentiment           amp_sentiment,

  started_at          timestamptz,
  ended_at            timestamptz,
  duration_seconds    integer,

  transcript          jsonb,
  summary             text,
  recording_url       text,

  flagged             boolean not null default false,
  flag_reason         text,

  metadata            jsonb not null default '{}'::jsonb,

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index amp_calls_organization_idx        on amp_calls(organization_id);
create index amp_calls_agent_idx               on amp_calls(agent_id);
create index amp_calls_started_at_idx          on amp_calls(started_at desc);
create index amp_calls_status_idx              on amp_calls(status);
create index amp_calls_outcome_idx             on amp_calls(outcome);
create index amp_calls_flagged_idx             on amp_calls(flagged) where flagged = true;
create index amp_calls_caller_phone_idx        on amp_calls(caller_phone);
create index amp_calls_org_started_at_idx      on amp_calls(organization_id, started_at desc);

create trigger amp_calls_set_updated_at
  before update on amp_calls
  for each row execute function amp_set_updated_at();

-- ---------------------------------------------------------------------------
-- amp_appointments: bookings made by the agent
-- ---------------------------------------------------------------------------

create table amp_appointments (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null references amp_organizations(id) on delete cascade,
  agent_id            uuid references amp_agents(id) on delete set null,
  call_id             uuid references amp_calls(id) on delete set null,

  customer_name       text not null,
  customer_phone      text,
  customer_email      text,
  customer_address    text,

  service_type        text,
  notes               text,

  scheduled_at        timestamptz not null,
  duration_minutes    integer not null default 60,

  google_event_id     text,
  calendar_provider   text,

  confirmation_sent   boolean not null default false,
  confirmation_sent_at timestamptz,
  reminder_sent       boolean not null default false,
  reminder_sent_at    timestamptz,

  status              amp_appointment_status not null default 'scheduled',

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index amp_appointments_organization_idx       on amp_appointments(organization_id);
create index amp_appointments_agent_idx              on amp_appointments(agent_id);
create index amp_appointments_call_idx               on amp_appointments(call_id);
create index amp_appointments_scheduled_at_idx       on amp_appointments(scheduled_at);
create index amp_appointments_status_idx             on amp_appointments(status);
create index amp_appointments_org_scheduled_idx      on amp_appointments(organization_id, scheduled_at);
create index amp_appointments_google_event_idx       on amp_appointments(google_event_id);

create trigger amp_appointments_set_updated_at
  before update on amp_appointments
  for each row execute function amp_set_updated_at();

-- ---------------------------------------------------------------------------
-- amp_alerts: operational alerts surfaced to the dashboard
-- ---------------------------------------------------------------------------

create table amp_alerts (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null references amp_organizations(id) on delete cascade,
  agent_id            uuid references amp_agents(id) on delete set null,
  call_id             uuid references amp_calls(id) on delete set null,

  type                amp_alert_type     not null,
  severity            amp_alert_severity not null default 'medium',

  title               text not null,
  message             text,
  context             jsonb not null default '{}'::jsonb,

  resolved            boolean not null default false,
  resolved_at         timestamptz,
  resolved_by         uuid,
  resolution_notes    text,

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index amp_alerts_organization_idx     on amp_alerts(organization_id);
create index amp_alerts_type_idx             on amp_alerts(type);
create index amp_alerts_severity_idx         on amp_alerts(severity);
create index amp_alerts_resolved_idx         on amp_alerts(resolved) where resolved = false;
create index amp_alerts_org_created_idx      on amp_alerts(organization_id, created_at desc);

create trigger amp_alerts_set_updated_at
  before update on amp_alerts
  for each row execute function amp_set_updated_at();

-- ---------------------------------------------------------------------------
-- amp_weekly_reports: per-org aggregated weekly stats
-- ---------------------------------------------------------------------------

create table amp_weekly_reports (
  id                      uuid primary key default gen_random_uuid(),
  organization_id         uuid not null references amp_organizations(id) on delete cascade,

  week_start              date not null,
  week_end                date not null,

  total_calls             integer not null default 0,
  answered_calls          integer not null default 0,
  missed_calls            integer not null default 0,
  total_call_duration_seconds integer not null default 0,
  avg_call_duration_seconds   integer not null default 0,

  appointments_booked     integer not null default 0,
  appointments_completed  integer not null default 0,
  appointments_canceled   integer not null default 0,

  positive_sentiment_count integer not null default 0,
  neutral_sentiment_count  integer not null default 0,
  negative_sentiment_count integer not null default 0,

  flagged_calls           integer not null default 0,
  alerts_triggered        integer not null default 0,

  trust_score_start       numeric(5,2),
  trust_score_end         numeric(5,2),

  estimated_revenue       numeric(10,2) not null default 0,
  metrics                 jsonb not null default '{}'::jsonb,

  sent_at                 timestamptz,

  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),

  unique (organization_id, week_start)
);

create index amp_weekly_reports_org_week_idx on amp_weekly_reports(organization_id, week_start desc);
create index amp_weekly_reports_week_idx     on amp_weekly_reports(week_start desc);

create trigger amp_weekly_reports_set_updated_at
  before update on amp_weekly_reports
  for each row execute function amp_set_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
-- Enabled on every AMP table. Service role bypasses RLS, so the backend
-- continues to operate normally. Add per-tenant policies before exposing
-- these tables to anon/authenticated client keys.

alter table amp_organizations    enable row level security;
alter table amp_templates        enable row level security;
alter table amp_agents           enable row level security;
alter table amp_calls            enable row level security;
alter table amp_appointments     enable row level security;
alter table amp_alerts           enable row level security;
alter table amp_weekly_reports   enable row level security;

-- ---------------------------------------------------------------------------
-- Seed data: plumber + electrician templates
-- ---------------------------------------------------------------------------

insert into amp_templates (slug, name, industry, description, greeting, system_prompt, faqs)
values
(
  'plumber',
  'Plumber',
  'plumbing',
  'Default agent personality for residential and light-commercial plumbing contractors.',
  'Hi, thanks for calling. This is the virtual assistant for your local plumbing team — how can I help you today?',
  $$You are a friendly, professional virtual receptionist for a plumbing company.

Your job is to:
1. Greet the caller warmly and identify their need (emergency vs. routine).
2. For emergencies (active leak, no water, sewage backup, burst pipe, no hot water in winter), gather the address, a callback number, and a brief description, then offer the soonest available slot or escalate to the on-call technician.
3. For routine work (fixture install, slow drain, water heater quote, remodel), collect the customer's name, phone, address, service type, and book an appointment during business hours.
4. Quote service-call fees only if the contractor has explicitly listed them; otherwise say a technician will confirm pricing on-site.
5. Never diagnose over the phone or commit to a fixed total price.
6. Confirm the appointment time and let the caller know they'll receive a text confirmation.
7. Speak clearly, keep responses under 2 sentences when possible, and ask one question at a time.

If the caller is hostile, abusive, or clearly spam, politely end the call.$$,
  '[
    {"q": "Do you offer 24/7 emergency service?", "a": "Yes — for active leaks, burst pipes, no water, or sewage backups we dispatch on-call technicians around the clock. For non-emergencies we book during business hours."},
    {"q": "What is your service-call fee?", "a": "There is a standard service-call fee that covers diagnosis and the first 30 minutes on-site. The technician will confirm the exact amount before any work begins."},
    {"q": "Do you handle water heaters?", "a": "Yes — repair, replacement, and tankless conversions for both gas and electric units."},
    {"q": "Are you licensed and insured?", "a": "Yes, fully licensed, bonded, and insured. The technician can show credentials on arrival."},
    {"q": "Do you provide free estimates?", "a": "Estimates for replacement and remodel work are free. Diagnostic visits for active issues carry the standard service-call fee."},
    {"q": "What areas do you serve?", "a": "I''ll check the service area for your ZIP code right now — what ZIP are you calling from?"}
  ]'::jsonb
),
(
  'electrician',
  'Electrician',
  'electrical',
  'Default agent personality for residential and light-commercial electrical contractors.',
  'Hi, thanks for calling. This is the virtual assistant for your local electrical team — how can I help you today?',
  $$You are a friendly, professional virtual receptionist for an electrical contractor.

Your job is to:
1. Greet the caller and quickly determine if this is a safety emergency (sparks, burning smell, partial power loss, exposed wiring, panel issue, EV-charger fault).
2. For emergencies, advise the caller to keep the affected breaker off, gather address and callback number, and dispatch the on-call electrician.
3. For routine work (panel upgrade, EV charger install, lighting, ceiling fan, outlet add, generator, inspection), collect name, phone, address, service type, and book during business hours.
4. Never give specific code or amperage advice over the phone — defer to the licensed electrician on-site.
5. Confirm appointments verbally and tell the caller a text confirmation is on the way.
6. Speak clearly, keep responses short, and ask one question at a time.

If the caller is hostile, abusive, or clearly spam, politely end the call.$$,
  '[
    {"q": "Do you handle electrical emergencies?", "a": "Yes — for sparks, burning smells, partial power loss, or panel issues we dispatch around the clock. Please keep the affected breaker off until we arrive."},
    {"q": "Do you install EV chargers?", "a": "Yes — Level 2 home chargers including Tesla Wall Connector, ChargePoint, and most universal J1772/NACS units. We pull permits and handle panel upgrades if needed."},
    {"q": "Can you upgrade my electrical panel?", "a": "Yes — 100A, 200A, and 400A service upgrades, including meter base and grounding. The electrician will confirm scope and pricing on-site."},
    {"q": "Are you licensed and insured?", "a": "Yes, fully licensed, bonded, and insured. The electrician can show credentials on arrival."},
    {"q": "Do you offer free estimates?", "a": "Estimates for installs and upgrades are free. Diagnostic visits for active issues carry the standard service-call fee."},
    {"q": "What areas do you serve?", "a": "I''ll check the service area for your ZIP code right now — what ZIP are you calling from?"},
    {"q": "Do you pull permits?", "a": "Yes — we pull all required permits and handle inspection scheduling for any work that needs it."}
  ]'::jsonb
);
