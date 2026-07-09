---
name: screenshot-debug
description: Debug a bug reported via a simulator/device screenshot — the user's standard bug-report channel (see memory: feedback_screenshot_debugging). Identifies the on-screen surface, traces the UI → Provider → Repository → DAO/Remote data flow to the root cause, then hunts sibling paths before fixing. Use when the user sends a screenshot of a broken screen, or describes a visual/behavioral bug in the running app.
allowed-tools: Read, Grep, Glob, Bash, Edit, Task
---

# Screenshot-Driven Debugging

> The user reports bugs by sending simulator screenshots and expects immediate investigation (memory: feedback_screenshot_debugging). Wrap the standard `systematic-debugging` discipline around a screenshot-to-source workflow.

## When to use
The user attaches a screenshot of a broken screen, or describes something visually wrong / misbehaving in the running app. If the report is an exception/stack trace with no visual, use `systematic-debugging` directly.

## Step 1 — Read the screenshot precisely
- Identify the exact screen (AppBar title, tab, visible widgets, empty/error/loading state, language). Read on-screen text literally — l10n keys leaking raw (e.g. `title_beginner` instead of the translated string) is itself a class of bug seen before.
- Note what is WRONG vs expected: wrong data, missing widget, overflow (German/Turkish text), wrong color/dark-mode, frozen spinner, wrong navigation.
- Do NOT assume the cause. State the observed symptom in one sentence.

## Step 2 — Locate the surface in source
1. Map the screen to its feature: `lib/features/<name>/screens/`. Grep visible l10n keys or literal strings to pin the exact widget.
2. Identify the providers the widget watches (`ref.watch`) — that is the data source to trace.

## Step 3 — Trace the data flow (the canonical chain)
Follow `UI → Provider → Repository → DAO / RemoteSource`, reading each hop:
- **UI**: is the AsyncValue `loading/error/data` mapped correctly? Empty vs filter-empty confusion? `.select()` scope wrong?
- **Provider**: race condition (missing `_requestId`), stale cache, wrong `keepAlive`, error swallowed instead of surfaced via AsyncValue.
- **Repository**: offline-first read from Drift vs online-first, sync/conflict handling, `ValidatedSyncMixin` FK gaps.
- **DAO / Remote**: `.equalsValue()` for enums, `SupabaseConstants` usage, `.toSupabase()`, timezone/UTC math (datetime-format.md), encryption decrypt-failure returning null.

Regenerate first if the symptom smells like stale generated code: `dart run build_runner build --delete-conflicting-outputs`.

## Step 4 — Confirm root cause, then reproduce
- Form a single hypothesis and confirm it in code (or with a temporary `AppLogger.debug`, removed before commit).
- Where the change is previewable, drive it with the preview tools to observe the fix — don't rely on the screenshot alone. Prefer a failing test that captures the bug (test-driven-development) before the fix.

## Step 5 — Fix + sibling hunt
- Apply the minimal root-cause fix. No drive-by refactoring.
- Launch `sibling-path-hunter` for the defect class — a visual bug in one form/list/screen usually has twins (the whole ConsumerStatefulWidget form family, every AsyncValue mapping, etc.).

## Step 6 — Verify + gates
- Add/update the test for the fixed behavior.
- `flutter analyze --no-fatal-infos` + the relevant `flutter test test/path/...`, then the local quality gate if the surface is broad.
- If previewable, capture proof (screenshot/console/network) rather than asking the user to re-check.

## Handoff
State the root cause in one sentence (not just the symptom), the fix, any siblings found and fixed, the verification evidence, and `git status`. Respond in Turkish per chat.md.
