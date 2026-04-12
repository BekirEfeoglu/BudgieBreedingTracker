# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in BudgieBreedingTracker, please report it responsibly.

### How to Report

1. **GitHub Private Vulnerability Reporting**: Use the [Security Advisories](https://github.com/BekirEfeoglu/BudgieBreedingTracker/security/advisories/new) feature to privately report the issue.
2. **Email**: Send details to **befeoglu016@gmail.com** with the subject line `[SECURITY] BudgieBreedingTracker`.

### What to Include

- A clear description of the vulnerability
- Steps to reproduce the issue
- Affected versions
- Any potential impact assessment

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 5 business days
- **Resolution**: Depending on severity, typically within 30 days

### Guidelines

- Please do **not** open public issues for security vulnerabilities
- Allow reasonable time for us to address the issue before public disclosure
- We will credit reporters in the fix announcement (unless anonymity is preferred)

### Scope

The following are in scope:

- Authentication and authorization bypasses
- Data exposure (user data, breeding records)
- SQL injection in Supabase queries
- RLS policy bypasses
- API key or secret exposure
- Encryption weaknesses (AES-256-CBC implementation)
- Certificate pinning bypasses

### Out of Scope

- Denial of service attacks
- Social engineering
- Physical security
- Third-party service infrastructure (Supabase, RevenueCat, Firebase)

## Security Measures

This application implements:

- **TLS Certificate Pinning** for Supabase connections
- **AES-256-CBC Encryption** with HMAC-SHA256 authentication for backups
- **Row-Level Security (RLS)** on all Supabase tables
- **Inactivity Guard** with automatic session timeout (30 min)
- **MFA Support** with brute-force lockout (Edge Function)
- **Input Validation** on all user inputs
- **Sentry Error Tracking** (no PII in reports)
- **File Magic Byte Validation** before storage uploads

## Security Best Practices for Users

- Keep the app updated to the latest version
- Use strong, unique passwords for your Supabase account
- Enable two-factor authentication (2FA) when available
- Do not share your `.env` file or API keys publicly
- Review app permissions periodically
