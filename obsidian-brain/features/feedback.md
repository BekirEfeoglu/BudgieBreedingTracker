# Feature: feedback

**Purpose**: In-app feedback submission with submission history and admin
triage. Replaces email round-trips and lets users see status updates on
their submitted feedback.

## Key Screens

| Screen | Route |
|--------|-------|
| `FeedbackScreen` | `AppRoutes.feedback` (two tabs: new submission + history) |
| Detail sheet (`FeedbackDetailSheet`) | Bottom sheet from history list |

## Categories

`FeedbackCategory` enum: `general`, `bug`, `feature_request`, `complaint`,
`praise`. Categories drive the submission form layout (e.g. bug adds
device info section).

## Statuses

`FeedbackStatus` enum: lifecycle from `submitted` → `triaged` → `responded` /
`resolved` / `closed`. Status changes happen admin-side via
`/admin/feedback`.

## Key Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `feedbackFormStateProvider` | `NotifierProvider` | Form field state + submission |
| `feedbackHistoryProvider(userId)` | `FutureProvider.family` | User's past submissions |
| `feedbackRepositoryProvider` | `Provider` | Online-first repository |

## Widgets

| Widget | Role |
|--------|------|
| `FeedbackCategorySelector` | Category chip picker |
| `FeedbackFormWidgets` | Subject + message inputs + email opt-in |
| `FeedbackDeviceInfoSection` | OS + app version + locale (bug category only) |
| `FeedbackHistoryTab` | List of `feedbackHistoryProvider` results |
| `FeedbackHistoryCard` | Individual submission tile with status badge |
| `FeedbackInfoBanner` | Top-of-screen disclaimer + privacy hint |

## Online-First

Feedback is **online-first** — submission requires connectivity, history
fetch hits Supabase. Local mirror would offer no UX value (user can't
respond offline). `feedbackRepositoryProvider` follows the
`*Repository` exception path documented in
[[architecture/online-first-exemption]].

## Admin Flow

Admins access submissions via `/admin/feedback` (see [[features/admin]]).
Status transitions and replies are admin-only and gated by `AdminGuard`.

## L10n

Keys under `feedback.*` namespace. Submission success toast surfaces
`feedback.submitted_success`; rejection (network, validation) follows
the [[patterns/error-handling]] flow.

## See Also

- [[features/admin]] — admin feedback triage
- [[features/_features-index]]
- [[patterns/forms-validation]]
