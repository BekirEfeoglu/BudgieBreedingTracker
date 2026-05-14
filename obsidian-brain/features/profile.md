# Feature: profile

**Purpose**: User profile editing — display name, avatar, notification preferences, language.

## Key Screens

- Profile view
- Profile edit form
- Avatar picker (with photo upload pipeline)

## Key Providers

- `currentUserProfileProvider` — StreamProvider
- `profileNotifier` — AsyncNotifier for edits

## Avatar Upload

- `bird-photos` bucket (private)
- 10MB guard + `scan-image-safety` Edge Function check
- Cache invalidated after successful upload

## Language Setting

Language selector updates `easy_localization` locale. All 3 supported: `tr`, `en`, `de`.

## Developer Menu

Hidden 5-tap Easter egg on Settings header to access experimental flags (production users cannot see it). See [[patterns/feature-flags]].

## See Also

- [[features/settings]]
- [[features/_features-index]]
