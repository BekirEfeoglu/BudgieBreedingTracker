#!/usr/bin/env python3
"""Verify repository platform target policy.

The Flutter application is supported for mobile/desktop targets. The public web
presence is the static GitHub Pages site under docs/, not a Flutter web app.
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _flutter_web_target_exists(root: Path) -> bool:
    web_dir = root / "web"
    if not web_dir.exists():
        return False
    return any(
        (web_dir / marker).exists()
        for marker in ("index.html", "manifest.json", "icons")
    )


def main() -> int:
    if _flutter_web_target_exists(ROOT):
        print(
            "ERROR: Flutter web target found in web/. "
            "This app does not support Flutter Web; the public website lives "
            "under docs/ and deploys via GitHub Pages."
        )
        return 1

    print("Platform target policy OK: no Flutter web app target present.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
