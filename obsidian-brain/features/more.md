# Feature: more

**Purpose**: Bottom-nav hub for secondary navigation — features and
account actions that don't fit on the primary tabs. Adapts to guest vs.
authenticated state and shows the in-app user guide.

## Key Screens

| Screen | Route |
|--------|-------|
| `MoreScreen` | `AppRoutes.more` — main hub |
| `UserGuideScreen` | `AppRoutes.userGuide` — searchable topic list |
| `GuideDetailScreen` | `AppRoutes.userGuideDetail` — single topic with rendered content |

## Sections

`more_screen_sections.dart` (part file) builds:

- **Features**: gamification, marketplace, statistics, genetics history,
  AI predictions, backup, calendar, health records, genealogy
- **Account**: profile, settings, notification settings, premium
- **Help & legal**: user guide, feedback, privacy policy, terms of
  service, community guidelines, about

Guest users see an inline "Log in" CTA in the app bar and a slimmed-down
list (no per-user features).

## User Guide

| Component | Source |
|-----------|--------|
| Topic list | `lib/features/more/widgets/guide_topics_data.dart` |
| Topic detail | `lib/features/more/widgets/guide_data.dart` + `guide_content_widgets.dart` |
| List item | `guide_topic_list_item.dart` |

Guide is fully **offline / local**, searchable in-screen. Adding a topic:
edit `guide_topics_data.dart` (metadata) + `guide_data.dart` (body) and
add the localized strings to `tr/en/de.json` under `user_guide.*`.

## Premium Hooks

Cross-feature import to `premium_providers.dart` gates entries like
"Backup" and "Genetics history" — locked items render a lock badge and
route to `AppRoutes.premium` on tap when entitlement is missing.

## Admin Entry

When `userRoleProvider` is `admin` or `founder`, an additional Admin link
appears at the bottom of the list, routing to `AppRoutes.admin`.

## L10n

Section labels live under `nav.*` and `more.*` namespaces. User guide
topics use `user_guide.*`.

## See Also

- [[features/admin]] — admin entry from More
- [[features/premium]] — entitlement gating
- [[features/feedback]] — feedback shortcut
- [[features/_features-index]]
