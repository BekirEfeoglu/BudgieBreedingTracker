# Budgie Breeding Tracker Store And YouTube Video Package Design

Date: 2026-05-14

## Goal

Create a complete video package for Budgie Breeding Tracker for Apple App Store, Google Play, YouTube, and short-form channels.

The package uses real simulator and emulator screen recordings as the main proof of product value. Motion graphics, localized copy, transitions, and cover artwork are added around the recordings so each platform receives a channel-appropriate version.

## Approved Direction

The approved direction is the hybrid package:

- Real iOS and Android app recordings are the main visual source.
- App Store and Google Play versions stay store-safe and product-focused.
- YouTube and Shorts versions use stronger pacing, headline overlays, and a clearer call to action.
- Turkish and English are produced as separate localized versions.

Rejected directions:

- Store-only cut: lower production risk but weaker YouTube presence.
- Cinematic story cut: stronger brand storytelling but higher App Store adaptation risk.

## Outputs

Produce these outputs:

- Apple App Store app preview: portrait iPhone video, 15-30 seconds, app-recording led, minimal promotional framing.
- Google Play preview video: YouTube-uploadable video for the Play Console store listing, Android recording led.
- YouTube promo: 45-60 seconds, Turkish and English versions.
- Shorts/Reels promo: vertical 9:16, 20-30 seconds, Turkish and English versions.
- YouTube cover artwork: Turkish and English variants.

## Platform Constraints

Apple App Store preview:

- Follow Apple App Preview specifications.
- Keep duration between 15 and 30 seconds.
- Use supported video formats and resolution for portrait iPhone preview.
- Keep the content focused on actual app experience.

Google Play:

- Use a YouTube-hosted preview video suitable for Play Console store listing assets.
- Keep the preview accurate to the app experience and avoid misleading claims.
- Prefer Android screen recordings for the Google Play version.

Reference docs:

- Apple App Preview specifications: https://developer.apple.com/help/app-store-connect/reference/app-preview-specifications
- Google Play preview assets: https://support.google.com/googleplay/android-developer/answer/9866151

## Narrative

Main message: Budgie Breeding Tracker helps breeders manage the full breeding workflow and daily flock records in one place.

Core scene order:

1. Brand/logo and promise.
2. Breeding pair and incubation tracking.
3. Egg and chick lifecycle tracking.
4. Calendar and reminders.
5. Statistics and reporting.
6. Sync, backup, or premium value where visible in the app.
7. Store or YouTube call to action.

The first 5-7 seconds should make the breeding value obvious. Later scenes can broaden into inventory, calendar, statistics, and synchronization.

## Localization

Create Turkish and English versions as separate renders. The underlying screen recording sequence can be shared when text content does not conflict, but all overlays, captions, voiceover scripts, and cover artwork text must be localized per version.

Turkish tone:

- Direct, practical, breeder-focused.
- Example message style: "Uretim takibini tek yerden yonetin."

English tone:

- Clear, app-store friendly, practical.
- Example message style: "Track breeding, eggs, chicks, and flock records in one place."

## Capture Plan

Use simulator and emulator captures with clean demo data.

iOS capture:

- Target portrait iPhone recording for App Store and YouTube iOS shots.
- Capture stable flows for breeding pair, incubation, eggs, chicks, calendar, and stats.

Android capture:

- Target portrait Android recording for Google Play and YouTube Android shots.
- Capture matching flows where possible so the package feels consistent across platforms.

Demo data requirements:

- At least one active breeding pair.
- At least one incubation/clutch with eggs in different states where the app supports it.
- At least one chick or growth-related screen if available.
- Calendar/reminder entries.
- Statistics or reporting screens with meaningful non-empty data.

Sensitive data must not be shown. Use fictional names and records only.

## Visual Identity

Use the existing app identity and assets:

- App logo and icon assets from `assets/images/`.
- Domain icons from `assets/icons/` where needed.
- A clean, calm visual system suitable for a breeder productivity app.

Visual direction:

- Product-first.
- Light, clear backgrounds for store previews.
- Stronger motion and headline treatment for YouTube and Shorts.
- Avoid generic stock-like visuals when real app screens can show the value.

## Production Workflow

1. Confirm app runs locally on iOS simulator and Android emulator.
2. Prepare or seed clean demo data.
3. Record iOS and Android flows.
4. Build HyperFrames compositions for store, YouTube, Shorts, and cover variants.
5. Render Turkish and English versions.
6. Verify duration, resolution, readability, and platform suitability.
7. Provide final video and cover files with a short upload checklist.

## Verification

Before handoff:

- Confirm every requested output exists.
- Confirm App Store preview duration is within 15-30 seconds.
- Confirm YouTube promo duration is within 45-60 seconds.
- Confirm Shorts/Reels duration is within 20-30 seconds.
- Confirm Turkish and English text are not mixed in the same render.
- Check all overlays for mobile readability.
- Check video files play from start to finish.
- Check no secrets, personal data, debug banners, or test-only UI are visible.

## Open Follow-Up Before Implementation

The implementation plan should still decide:

- Whether voiceover is required or text-only is preferred.
- Whether final renders should include background music.
- Exact demo data names and records.
- Exact output file naming convention.
