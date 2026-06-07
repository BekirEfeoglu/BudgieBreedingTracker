# Marketing Inbound Agent Design

## Goal

Create a practical marketing operations kit for Facebook and Instagram that grows BudgieBreedingTracker through compliant inbound lead capture, useful content, and human-approved replies. The system must avoid cold direct-message outreach, scraping, or unsolicited promotional messaging.

## Scope

This design covers:

- Meta lead generation campaign briefs.
- A 30-day social content calendar.
- A safe inbound inbox agent playbook.
- Message templates for comments, DMs, lead forms, and follow-ups.
- A CRM template for tracking opt-in status and lead stage.
- A measurement dashboard model for weekly optimization.

This design does not create an automated spam sender, account scraper, browser bot, or mass-DM tool.

## Audience

Primary audience:

- Budgie breeders and hobbyists.
- Pet shop owners who sell bird supplies.
- Bird-care content creators.
- Breeders managing eggs, incubation, chicks, pedigree, and health records.

Secondary audience:

- Turkish users first.
- English and German expansion after the first campaign data is available.

## Recommended Approach

Use an inbound-first funnel:

1. Content attracts relevant users.
2. Meta Lead Ads or click-to-message ads create explicit user intent.
3. The agent classifies inbound comments, DMs, and form submissions.
4. The agent drafts replies and records lead data.
5. A human approves outbound replies during the first operating phase.
6. Follow-up messages are sent only when the user has started the conversation or opted in.

This keeps growth aligned with platform rules, protects account reputation, and gives measurable campaign data.

## Components

Located under `docs/marketing/`:

- `README.md`: operating overview and weekly rhythm.
- `meta-campaign-briefs.md`: campaign objectives, audience, creative, budgets, and UTM rules.
- `content-calendar-30-days.csv`: ready-to-use daily content schedule.
- `inbound-agent-playbook.md`: agent policy, classification, reply workflow, escalation, and reporting.
- `agent-system-prompt.md`: copyable system prompt for an inbox assistant.
- `message-templates.md`: approved Turkish message templates for common inbound scenarios.
- `crm-template.csv`: importable CRM/Sheet columns and example rows.
- `weekly-dashboard-template.md`: weekly KPI report and decision template.
- `link-map.md`: canonical app, lead magnet, organic, DM, and paid UTM links.
- `launch-7-day-plan.md`: first-week Meta rollout plan and automation fixes.
- `assets/free-incubation-tracker-template.csv`: downloadable incubation tracker lead magnet.

## Agent Boundary

The agent can:

- Read inbound messages/comments exported or reviewed from Meta Business Suite.
- Draft replies.
- Classify user intent and lead stage.
- Write CRM notes.
- Recommend content topics and campaign changes.

The agent must not:

- Scrape followers, group members, or commenters for cold outreach.
- Send unsolicited DMs.
- Send messages without opt-in or inbound context.
- Make health, veterinary, or guaranteed breeding outcome claims.
- Target sensitive personal attributes.

## Data Flow

```text
Content / Ad / Lead Form
  -> User comment, DM, or form submission
  -> Agent classification
  -> Human-approved reply draft
  -> CRM row update
  -> Opt-in follow-up sequence
  -> Weekly KPI report
```

## Success Metrics

Track weekly:

- Content published.
- Profile visits.
- Link clicks.
- Store clicks by UTM source.
- Lead form submissions.
- DM conversations started.
- Reply rate.
- Cost per lead.
- App installs.
- Premium trials or purchases when attribution is available.

## Verification

This is a documentation and operations change. Verification is done by:

- Checking that the files exist and are internally consistent.
- Confirming the playbook bans cold DM automation.
- Confirming campaign links use UTM naming.
- Confirming CRM has opt-in and do-not-contact fields.

No Flutter runtime tests are required.
