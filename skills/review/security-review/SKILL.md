---
id: security-review
name: Security Hygiene Review
domain: security
type: build-review
status: active
version: 1.0.0
standard: standards/security.md
script: scripts/maa-security-review.sh
template: skills/review/security-review/templates/review-report.md
---

# Security Hygiene Review

A Build Review skill that checks repository-level security hygiene signals.
It detects what is present (or absent) on the filesystem — it does not scan
for vulnerabilities, run SAST tooling, or perform runtime analysis.

## When to run

Run this review:
- Before opening a PR that ships to production
- When onboarding a new project into MAA
- After a security incident, to confirm baseline hygiene was in place

## What it checks

| # | Signal | Detection method |
|---|--------|-----------------|
| 1 | `.gitignore` present | `test -f .gitignore` |
| 2 | `.env*` entries in `.gitignore` | `grep -E '^\s*\.env'` |
| 3 | Sensitive env files at root | `test -f` for `.env`, `.env.local`, `.env.production`, `.env.development` |
| 4 | Private key/cert files at root | `test -f` for `id_rsa`, `id_ed25519`, `id_dsa`; `find -maxdepth 1` for `*.pem`, `*.key` |
| 5 | Dependency lock file | `test -f` for 9 known lock file names |
| 6 | `SECURITY.md` present | `test -f SECURITY.md` |
| 7 | Automated dep update config | `test -f` for Dependabot and Renovate config paths |
| 8 | Secret scanning config | `test -f` for `.gitleaks.toml`, `.secretlintrc`, `.trufflehog.yml` |
| 9 | Docker non-root USER | `grep` last `USER` instruction in Dockerfile |
| 10 | Environment template | `test -f` for `.env.example`, `.env.sample`, `example.env` |

## What it does NOT check

The following require manual review — they cannot be detected from the filesystem alone:

- Authentication and authorisation logic (JWT validation, RBAC, session handling)
- Input validation and parameterised queries
- HTTP security headers (Helmet, CSP, HSTS)
- TLS configuration
- Error message exposure to clients
- CORS origin allowlisting
- Secret rotation policies

These items appear as a manual findings section in the generated report.

## Usage

```bash
maa review security <project-path>
```

## Output

Writes a Markdown report to `reports/reviews/YYYY-MM-DD-<project>-security.md`.

The report contains:
- Automated signal results
- A manual findings checklist for items that cannot be auto-detected
- Recommendations keyed to `standards/security.md` section numbers

## Interpretation guide

| Result | Meaning |
|--------|---------|
| `detected` / `present` | Signal was found |
| `not detected` | Signal was not found — review whether it is needed |
| `found (...)` | One or more sensitive files were found — investigate |
| `not checked (...)` | Check was skipped because a prerequisite was absent |

A "not detected" result for check 3 (sensitive env files) is the **good** outcome.
A "found (...)" result for check 3 requires immediate investigation.
