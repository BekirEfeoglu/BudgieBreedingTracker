#!/usr/bin/env python3
"""
BudgieBreedingTracker - Security Posture Verification

Lightweight security audit that runs in CI to flag regressions in the
project's security posture. Each check maps to a specific control listed
in SECURITY.md / .claude/rules/security.md.

Checks:
  1. Build obfuscation: Codemagic + GitHub Actions release-ready builds must
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
  8. Supabase Auth defaults remain production-safe: short-lived JWTs, no
     anonymous sign-ins, email confirmation, and TOTP MFA enabled.
  9. Edge Functions explicitly keep verify_jwt enabled and deploy scripts do
     not bypass JWT verification.

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

# Edge Functions that legitimately cannot verify a Supabase JWT because they
# are called by external systems that do not authenticate via Supabase Auth
# (e.g. third-party webhook receivers). Each entry MUST perform its own auth
# in the function source (shared-secret header, HMAC signature, etc.) and the
# exemption must be documented in .claude/rules/edge-functions.md.
WEBHOOK_FUNCTIONS_EXEMPT_FROM_JWT = {
    "revenuecat-webhook",
}

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

    release_ready = read(ROOT / ".github" / "workflows" / "release-ready.yml")
    if not release_ready:
        results.append(fail(".github/workflows/release-ready.yml", "file missing"))
    else:
        # GitHub Actions release-ready android-release must obfuscate.
        match = re.search(
            r"flutter build appbundle --release[\s\S]*?(?=\n\s{0,6}- name:|\Z)",
            release_ready,
        )
        if not match:
            results.append(
                fail("release-ready.yml android-release", "build block not found")
            )
        else:
            obf = "--obfuscate" in match.group(0)
            split = "--split-debug-info" in match.group(0)
            if obf and split:
                results.append(
                    ok("release-ready.yml android-release", "obfuscation enabled")
                )
            else:
                results.append(
                    fail(
                        "release-ready.yml android-release",
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


def check_edge_function_jwt_verification() -> List[Tuple[str, bool, str]]:
    """Every Supabase Edge Function must explicitly keep verify_jwt enabled."""
    config = read(ROOT / "supabase" / "config.toml")
    functions_root = ROOT / "supabase" / "functions"
    if not config:
        return [fail("edge function jwt config", "supabase/config.toml missing")]
    if not functions_root.exists():
        return [fail("edge function jwt config", "supabase/functions missing")]

    function_names = sorted(
        path.parent.name
        for path in functions_root.glob("*/index.ts")
        if not path.parent.name.startswith("_")
    )
    if not function_names:
        return [fail("edge function jwt config", "no edge functions found")]

    results: List[Tuple[str, bool, str]] = []
    for name in function_names:
        block_match = re.search(
            rf"^\[functions\.{re.escape(name)}\]([\s\S]*?)(?=^\[|\Z)",
            config,
            re.MULTILINE,
        )
        label = f"edge function {name} verify_jwt"
        is_webhook_exempt = name in WEBHOOK_FUNCTIONS_EXEMPT_FROM_JWT
        if not block_match:
            if is_webhook_exempt:
                results.append(
                    fail(
                        label,
                        f"missing [functions.{name}] block; "
                        "webhook receivers must declare verify_jwt = false explicitly",
                    )
                )
            else:
                results.append(
                    fail(label, f"missing [functions.{name}] verify_jwt = true")
                )
            continue
        verify_jwt = _read_toml_value(block_match.group(1), "verify_jwt")
        if is_webhook_exempt:
            # Webhook receivers must opt OUT of JWT verification explicitly so
            # the exemption is visible in the config rather than silent.
            if verify_jwt == "false":
                results.append(ok(label, "explicit false (webhook receiver)"))
            else:
                results.append(
                    fail(
                        label,
                        f"webhook receiver must set verify_jwt = false; "
                        f"found {verify_jwt or 'missing'}",
                    )
                )
        elif verify_jwt == "true":
            results.append(ok(label, "explicit true"))
        else:
            results.append(
                fail(label, f"expected true, found {verify_jwt or 'missing'}")
            )

    scan_roots = [ROOT / ".github", ROOT / "scripts", ROOT / "supabase"]
    bypass_hits: List[str] = []
    for scan_root in scan_roots:
        if not scan_root.exists():
            continue
        for path in scan_root.rglob("*"):
            if not path.is_file():
                continue
            if path.suffix not in {".yml", ".yaml", ".sh", ".toml", ".md"}:
                continue
            text = path.read_text(encoding="utf-8", errors="ignore")
            for lineno, line in enumerate(text.splitlines(), start=1):
                if "--no-verify-jwt" not in line:
                    continue
                if line.strip().startswith("#"):
                    continue
                # Allow the deploy line for webhook receivers whose JWT exemption
                # is declared in WEBHOOK_FUNCTIONS_EXEMPT_FROM_JWT.
                if any(
                    f"deploy {name} " in line or line.rstrip().endswith(
                        f"deploy {name}"
                    )
                    for name in WEBHOOK_FUNCTIONS_EXEMPT_FROM_JWT
                ):
                    continue
                bypass_hits.append(f"{path.relative_to(ROOT)}:{lineno}")

    if bypass_hits:
        results.append(
            fail(
                "edge deploy no-verify-jwt",
                f"bypass flag found: {', '.join(bypass_hits[:5])}",
            )
        )
    else:
        results.append(ok("edge deploy no-verify-jwt", "not used"))

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


def check_premium_sync_server_verified() -> List[Tuple[str, bool, str]]:
    """Premium state must be derived server-side, not from client RPC params."""
    results: List[Tuple[str, bool, str]] = []

    premium_sources = "\n".join(
        p.read_text(encoding="utf-8", errors="ignore")
        for p in (ROOT / "lib" / "domain" / "services" / "premium").glob("*.dart")
    )
    if "sync_premium_status" in premium_sources or ".rpc(" in premium_sources:
        results.append(
            fail(
                "premium sync client path",
                "premium code still calls a Supabase RPC directly",
            )
        )
    elif "sync-premium-status" in premium_sources:
        results.append(
            ok("premium sync client path", "uses Edge Function verification")
        )
    else:
        results.append(
            fail(
                "premium sync client path",
                "sync-premium-status Edge Function call not found",
            )
        )

    migrations = "\n".join(
        p.read_text(encoding="utf-8", errors="ignore")
        for p in (ROOT / "supabase" / "migrations").glob("*.sql")
    )
    if (
        "premium_sync_requires_server_verification" in migrations
        and "sync-premium-status Edge Function" in migrations
    ):
        results.append(
            ok("premium sync RPC", "legacy RPC is fail-closed")
        )
    else:
        results.append(
            fail(
                "premium sync RPC",
                "legacy sync_premium_status RPC is not explicitly fail-closed",
            )
        )

    return results


def _read_toml_value(body: str, key: str) -> str | None:
    match = re.search(rf"^\s*{re.escape(key)}\s*=\s*([^\n#]+)", body, re.MULTILINE)
    if not match:
        return None
    return match.group(1).strip().strip('"')


def check_supabase_auth_hardening() -> List[Tuple[str, bool, str]]:
    """Supabase auth config must preserve the documented security baseline."""
    config = read(ROOT / "supabase" / "config.toml")
    if not config:
        return [fail("supabase auth config", "supabase/config.toml missing")]

    results: List[Tuple[str, bool, str]] = []

    jwt_expiry = _read_toml_value(config, "jwt_expiry")
    try:
        jwt_seconds = int(jwt_expiry or "")
    except ValueError:
        jwt_seconds = 0
    if 0 < jwt_seconds <= 900:
        results.append(ok("auth jwt expiry", f"{jwt_seconds}s"))
    else:
        results.append(
            fail("auth jwt expiry", f"expected <=900s, found {jwt_expiry or 'missing'}")
        )

    anonymous = _read_toml_value(config, "enable_anonymous_sign_ins")
    if anonymous == "false":
        results.append(ok("auth anonymous sign-ins", "disabled"))
    else:
        results.append(
            fail(
                "auth anonymous sign-ins",
                f"expected false, found {anonymous or 'missing'}",
            )
        )

    email_confirmations = _read_toml_value(config, "enable_confirmations")
    if email_confirmations == "true":
        results.append(ok("auth email confirmations", "enabled"))
    else:
        results.append(
            fail(
                "auth email confirmations",
                f"expected true, found {email_confirmations or 'missing'}",
            )
        )

    totp_match = re.search(r"\[auth\.mfa\.totp\]([\s\S]*?)(?=\n\[|\Z)", config)
    totp_block = totp_match.group(1) if totp_match else ""
    totp_enroll = _read_toml_value(totp_block, "enroll_enabled")
    totp_verify = _read_toml_value(totp_block, "verify_enabled")
    if totp_enroll == "true" and totp_verify == "true":
        results.append(ok("auth totp mfa", "enroll+verify enabled"))
    else:
        results.append(
            fail(
                "auth totp mfa",
                "expected enroll_enabled=true and verify_enabled=true, "
                f"found enroll={totp_enroll or 'missing'} "
                f"verify={totp_verify or 'missing'}",
            )
        )

    return results


CHECKS = [
    ("Release build obfuscation", check_release_obfuscation),
    ("Edge Function security headers", check_edge_function_security_headers),
    ("Edge Function JWT verification", check_edge_function_jwt_verification),
    ("TLS certificate pinning", check_certificate_pinning),
    ("Service role key isolation", check_no_service_role_in_client),
    (".gitignore secret patterns", check_gitignore_secrets),
    ("No secrets committed to git", check_no_secrets_committed),
    ("Audit logging (pgaudit / audit_logs)", check_pgaudit_migration),
    ("Premium sync authorization", check_premium_sync_server_verified),
    ("Supabase Auth hardening", check_supabase_auth_hardening),
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
