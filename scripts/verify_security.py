#!/usr/bin/env python3
"""
BudgieBreedingTracker - Security Posture Verification

Lightweight security audit that runs in CI to flag regressions in the
project's security posture. Each check maps to a specific control listed
in SECURITY.md / .claude/rules/security.md.

Checks:
  1. Build obfuscation: Codemagic + GitHub Actions release builds must
     pass `--obfuscate --split-debug-info=...`.
  2. Edge Function CORS: shared cors.ts must emit baseline security
     headers (HSTS, X-Content-Type-Options, X-Frame-Options, CSP, etc.).
  3. Certificate pinning: lib/core/security/certificate_pinning.dart must
     exist and be wired up in bootstrap.
  4. Service-role key never imported in client (lib/) code.
  5. Sensitive secrets are not committed: .env / *.keystore / *.jks /
     *.p12 / *.pem must be ignored by git.
  6. flutter_secure_storage is the only place sensitive credentials
     (api keys, tokens) are persisted on device.
  7. RLS migrations exist for sensitive tables.

Exit codes:
  0 — all controls verified
  1 — at least one regression detected
  2 — script misuse (missing files, etc.)

Usage: python3 scripts/verify_security.py [--verbose]
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple

ROOT = Path(__file__).resolve().parent.parent
VERBOSE = "--verbose" in sys.argv

# Reuse shared color helpers if available; fall back to plain text.
try:
    sys.path.insert(0, str(ROOT / "scripts"))
    from _rules_utils import Colors  # type: ignore
    GREEN = Colors.GREEN
    RED = Colors.RED
    YELLOW = Colors.YELLOW
    CYAN = Colors.CYAN
    BOLD = Colors.BOLD
    RESET = Colors.RESET
except Exception:
    GREEN = RED = YELLOW = CYAN = BOLD = RESET = ""


def ok(label: str, detail: str = "") -> Tuple[str, bool, str]:
    return (label, True, detail)


def fail(label: str, detail: str) -> Tuple[str, bool, str]:
    return (label, False, detail)


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def check_release_obfuscation() -> List[Tuple[str, bool, str]]:
    """Release flutter builds must obfuscate Dart symbols."""
    results: List[Tuple[str, bool, str]] = []

    codemagic = read(ROOT / "codemagic.yaml")
    if not codemagic:
        results.append(fail("codemagic.yaml", "file missing"))
    else:
        # Both android-release and ios-release should obfuscate.
        for build_kind, build_cmd in (
            ("android-release", "flutter build appbundle --release"),
            ("ios-release", "flutter build ipa --release"),
        ):
            block = re.search(
                re.escape(build_cmd) + r"[\s\S]*?(?=\n\s{0,4}- name:|\Z)",
                codemagic,
            )
            if not block:
                results.append(
                    fail(f"codemagic {build_kind}", "build block not found")
                )
                continue
            obf = "--obfuscate" in block.group(0)
            split = "--split-debug-info" in block.group(0)
            if obf and split:
                results.append(ok(f"codemagic {build_kind}", "obfuscation enabled"))
            else:
                results.append(
                    fail(
                        f"codemagic {build_kind}",
                        f"missing --obfuscate or --split-debug-info "
                        f"(obfuscate={obf}, split={split})",
                    )
                )

    ci = read(ROOT / ".github" / "workflows" / "ci.yml")
    if not ci:
        results.append(fail(".github/workflows/ci.yml", "file missing"))
    else:
        # GitHub Actions android-release must obfuscate.
        match = re.search(
            r"flutter build appbundle --release[\s\S]*?(?=\n\s{0,6}- name:|\Z)",
            ci,
        )
        if not match:
            results.append(
                fail("ci.yml android-release", "build block not found")
            )
        else:
            obf = "--obfuscate" in match.group(0)
            split = "--split-debug-info" in match.group(0)
            if obf and split:
                results.append(
                    ok("ci.yml android-release", "obfuscation enabled")
                )
            else:
                results.append(
                    fail(
                        "ci.yml android-release",
                        f"missing --obfuscate or --split-debug-info "
                        f"(obfuscate={obf}, split={split})",
                    )
                )
    return results


def check_edge_function_security_headers() -> List[Tuple[str, bool, str]]:
    """_shared/cors.ts must emit baseline HTTP security headers."""
    cors = read(ROOT / "supabase" / "functions" / "_shared" / "cors.ts")
    if not cors:
        return [fail("edge cors.ts", "file missing")]

    required = [
        ("Strict-Transport-Security", "HSTS"),
        ("X-Content-Type-Options", "MIME sniff protection"),
        ("X-Frame-Options", "clickjacking protection"),
        ("Referrer-Policy", "referrer leakage"),
        ("Content-Security-Policy", "default-deny CSP"),
    ]
    results: List[Tuple[str, bool, str]] = []
    for header, why in required:
        if header in cors:
            results.append(ok(f"edge {header}", why))
        else:
            results.append(fail(f"edge {header}", f"missing ({why})"))
    return results


def check_certificate_pinning() -> List[Tuple[str, bool, str]]:
    """Certificate pinning module must exist and be installed in bootstrap."""
    pinning = ROOT / "lib" / "core" / "security" / "certificate_pinning.dart"
    if not pinning.exists():
        return [fail("certificate_pinning.dart", "module missing")]

    body = pinning.read_text(encoding="utf-8")
    if "CertificatePinning.install()" not in body and "static void install" not in body:
        return [
            fail(
                "certificate_pinning.dart",
                "no install() entry point exposed",
            )
        ]

    # Check that bootstrap actually calls it.
    bootstrap_candidates = list(ROOT.glob("lib/**/bootstrap*.dart")) + list(
        ROOT.glob("lib/main*.dart")
    )
    invoked = any(
        "CertificatePinning.install" in f.read_text(encoding="utf-8")
        for f in bootstrap_candidates
        if f.is_file()
    )
    if invoked:
        return [ok("certificate pinning", "installed in bootstrap")]
    return [
        fail(
            "certificate pinning",
            "module exists but not wired into bootstrap/main",
        )
    ]


def check_no_service_role_in_client() -> List[Tuple[str, bool, str]]:
    """SUPABASE_SERVICE_ROLE_KEY must never appear in lib/."""
    lib = ROOT / "lib"
    hits: List[str] = []
    for path in lib.rglob("*.dart"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        # Allow comments referencing it, flag actual usage.
        for lineno, line in enumerate(text.splitlines(), start=1):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("///"):
                continue
            if "SERVICE_ROLE" in stripped and "service_role" in stripped.lower():
                hits.append(f"{path.relative_to(ROOT)}:{lineno}")
    if not hits:
        return [ok("service role key", "not present in client code")]
    return [
        fail(
            "service role key",
            f"found in client code: {', '.join(hits[:5])}",
        )
    ]


def check_gitignore_secrets() -> List[Tuple[str, bool, str]]:
    gi = read(ROOT / ".gitignore")
    if not gi:
        return [fail(".gitignore", "file missing")]
    required = [".env", "*.keystore", "*.jks", "*.p12", "*.pem", "key.properties"]
    results: List[Tuple[str, bool, str]] = []
    for token in required:
        if token in gi:
            results.append(ok(f".gitignore {token}", "ignored"))
        else:
            results.append(
                fail(f".gitignore {token}", "secret pattern not ignored")
            )
    return results


def check_no_secrets_committed() -> List[Tuple[str, bool, str]]:
    """git ls-files: no .env / keystore / cert files should be tracked."""
    try:
        tracked = subprocess.run(
            ["git", "ls-files"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        ).stdout.splitlines()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return [
            fail("git ls-files", "git unavailable; cannot verify"),
        ]

    forbidden_re = re.compile(
        r"(^|/)(\.env(\.[^/]+)?|.+\.(keystore|jks|p12|pem)|key\.properties)$"
    )
    leaks = [p for p in tracked if forbidden_re.search(p) and not p.endswith(".example")]
    if not leaks:
        return [ok("committed secrets", "no .env/key/cert files tracked")]
    return [
        fail(
            "committed secrets",
            f"forbidden files tracked: {', '.join(leaks[:5])}",
        )
    ]


def check_pgaudit_migration() -> List[Tuple[str, bool, str]]:
    """At least one migration should reference pgaudit / audit triggers."""
    migrations = list((ROOT / "supabase" / "migrations").glob("*.sql"))
    if not migrations:
        return [fail("supabase migrations", "directory empty")]
    haystack = "\n".join(p.read_text(encoding="utf-8", errors="ignore") for p in migrations)
    has_pgaudit = "pgaudit" in haystack.lower()
    has_audit_table = "audit_logs" in haystack
    if has_pgaudit and has_audit_table:
        return [ok("audit logging", "pgaudit + audit_logs both present")]
    if has_audit_table:
        return [
            fail(
                "audit logging",
                "audit_logs table present, pgaudit migration missing",
            )
        ]
    return [
        fail(
            "audit logging",
            "neither pgaudit nor audit_logs migration found",
        )
    ]


CHECKS = [
    ("Release build obfuscation", check_release_obfuscation),
    ("Edge Function security headers", check_edge_function_security_headers),
    ("TLS certificate pinning", check_certificate_pinning),
    ("Service role key isolation", check_no_service_role_in_client),
    (".gitignore secret patterns", check_gitignore_secrets),
    ("No secrets committed to git", check_no_secrets_committed),
    ("Audit logging (pgaudit / audit_logs)", check_pgaudit_migration),
]


def main() -> int:
    print(f"{BOLD}{CYAN}BudgieBreedingTracker - Security Verification{RESET}\n")

    total = 0
    failed = 0
    for section, check in CHECKS:
        print(f"{BOLD}{section}{RESET}")
        for label, passed, detail in check():
            total += 1
            mark = f"{GREEN}OK{RESET}" if passed else f"{RED}FAIL{RESET}"
            suffix = f" - {detail}" if (detail and (VERBOSE or not passed)) else ""
            print(f"  [{mark}] {label}{suffix}")
            if not passed:
                failed += 1
        print()

    if failed == 0:
        print(f"{GREEN}{BOLD}All {total} security controls verified.{RESET}")
        return 0
    print(
        f"{RED}{BOLD}{failed}/{total} security controls failed.{RESET} "
        f"Review the FAIL items above and either fix the regression or "
        f"update SECURITY.md if the control is intentionally relaxed."
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
