# Change Log Archive - 2026-06

Back to [[log]].

## [2026-06-13] automation | platform/wiki lint

- Removed unsupported Flutter web target files; GitHub Pages remains served from
  `docs/`.
- Added `check_platform_targets.py` and `check_obsidian_brain.py` to local and
  CI quality gates.

---

## [2026-06-13] sync | Rule metadata + wiki stat drift

Synced wiki summaries with current `CLAUDE.md` and `.claude/rules/` after the
rule metadata alignment commit.

- UUID guidance updated from `Uuid().v4()` to `const Uuid().v7()` for new entity
  creation paths in overview and sync/data-layer pages.
- Stat drift updated: source 983->987, tests 901/11,048->903/11,095, l10n
  2,992->2,995, migrations 160->174, Edge Functions 9->12, Supabase constants
  137->138, code-quality checker wording 28->27 checker categories.
- Edge Function inventory now includes `create-community-post`,
  `create-community-comment`, and `upload-community-photo`.
- Shared widget catalog corrected to 29 with 2 dialogs and 5 egg widgets.
