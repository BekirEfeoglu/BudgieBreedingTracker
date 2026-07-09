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

`FeedbackCategory` enum (`feedback_providers.dart`): `bug`, `feature`,
`general` — three values only. Each carries a label, description, `LucideIcons`
icon, and colour.

## Statuses

`FeedbackStatus` (feature enum, `feedback_providers.dart`): `open`,
`inProgress`, `resolved`, `closed` (+ `unknown` fallback). A separate
`FeedbackStatus` lives in `core/enums/admin_enums.dart` for the admin queue.
Status changes happen admin-side via `/admin/feedback`.

## Key Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `feedbackFormStateProvider` | `NotifierProvider` | Form field state + submission |
| `feedbackHistoryProvider(userId)` | `FutureProvider.family` | User's past submissions |
| `feedbackServiceProvider` | `Provider<FeedbackRemoteService>` | Online-only service (`feedbackRepositoryProvider` is a back-compat alias) |

## Widgets

| Widget | Role |
|--------|------|
| `FeedbackCategorySelector` | Category chip picker |
| `FeedbackFormWidgets` | Subject + message inputs + email opt-in |
| `FeedbackDeviceInfoSection` | OS + app version + locale (bug category only) |
| `FeedbackHistoryTab` | List of `feedbackHistoryProvider` results |
| `FeedbackHistoryCard` | Individual submission tile with status badge |
| `FeedbackInfoBanner` | Top-of-screen disclaimer + privacy hint |

## Online-Only

Feedback is **online-only** — submission requires connectivity, history fetch
hits Supabase, no local Drift mirror. The class is `FeedbackRemoteService`
(correctly named per [[architecture/online-first-exemption]] — a single-user
remote resource, NOT a cross-user-feed `*Repository` exemption). The file is
still `feedback_repository.dart` and the test `feedback_repository_test.dart` for
legacy reasons; class + provider (`feedbackServiceProvider`) carry the correct
name.

## Admin Flow

Admins access submissions via `/admin/feedback` (see [[features/admin]]).
Status transitions and replies are admin-only and gated by `AdminGuard`.
User history surfaces admin replies in both `FeedbackHistoryCard` (reply
indicator) and `FeedbackDetailSheet` (full response body).

## L10n

Keys under `feedback.*` namespace. Submission success toast surfaces
`feedback.submitted_success`; rejection (network, validation) follows
the [[patterns/error-handling]] flow.

## See Also

- [[features/admin]] — admin feedback triage
- [[features/_features-index]]
- [[patterns/forms-validation]]
