# Security Standards

**Version:** 1.0.0
**Last updated:** 2026-03-05
**Domain:** Security Hygiene
**Status:** Approved
**Origin:** seed
**Sources:** none

---

## Scope

This standard covers security hygiene practices observable from a repository's filesystem.
It does not cover vulnerability scanning, penetration testing, or runtime security analysis.
These checks are intended to be a baseline that any project should meet before shipping.

---

## 1. Secret and Credential Hygiene

- Never commit secrets, credentials, or private keys to the repository
- `.env` files and all environment-specific variants (`.env.local`, `.env.production`,
  `.env.development`, `.env.staging`) must be listed in `.gitignore`
- Private key files (`id_rsa`, `id_ed25519`, `id_dsa`, `*.pem`, `*.key`) must never appear at the
  repository root or in committed paths
- Provide an `.env.example`, `.env.sample`, or `example.env` so contributors know which variables
  are required — without including real values
- Secret scanning tooling (`.gitleaks.toml`, `.secretlintrc`, `.trufflehog.yml`) should be
  configured to prevent accidental secret commits

## 2. Dependency Management

- Every project must have a dependency lock file (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`,
  `Pipfile.lock`, `poetry.lock`, `uv.lock`, `Gemfile.lock`, `go.sum`, `Cargo.lock`)
- Lock files must be committed to the repository — do not `.gitignore` them
- Configure automated dependency update tooling (Dependabot via `.github/dependabot.yml`, or Renovate
  via `renovate.json` / `.renovaterc`) to receive security patches promptly
- Review automated dependency PRs promptly — stale PRs leave known vulnerabilities unpatched

## 3. Authentication and Authorization

- Never roll your own authentication — use a battle-tested library or service
- Validate all JWT tokens on every request: signature, expiry, issuer, and audience claims
- Store passwords using a modern adaptive hashing algorithm (bcrypt, Argon2, scrypt)
- Never store plaintext passwords or use MD5/SHA1 for password hashing
- Enforce least-privilege: API keys and service accounts should have only the permissions they need
- Rotate credentials that may have been exposed — never assume a leaked secret is safe to keep

## 4. Input Validation and Output Encoding

- Validate all untrusted input at system boundaries: request bodies, query parameters, headers,
  path parameters, file uploads
- Reject unexpected input rather than sanitising it — allowlists are safer than denylists
- Parameterise all database queries — never concatenate user input into SQL strings
- Encode output for the appropriate context (HTML, JSON, SQL, shell) to prevent injection attacks
- Validate Content-Type headers on inbound requests to prevent MIME-type confusion attacks

## 5. HTTP Security Headers

- Set `Strict-Transport-Security` on all production HTTPS services
- Set `X-Content-Type-Options: nosniff`
- Set `X-Frame-Options: DENY` or use `Content-Security-Policy: frame-ancestors 'none'`
- Set a restrictive `Content-Security-Policy`; avoid `unsafe-inline` and `unsafe-eval`
- Remove `X-Powered-By` headers to avoid advertising your stack
- Use a library such as Helmet (Node.js) or Django's `SECURE_*` settings to apply headers consistently

## 6. Transport Security

- Serve all production traffic over HTTPS — never HTTP
- Redirect HTTP to HTTPS at the infrastructure or application layer
- Do not disable TLS certificate verification in code, even for development
- Do not use TLS 1.0 or 1.1 — require TLS 1.2 minimum, prefer TLS 1.3

## 7. Error Handling and Logging

- Never expose stack traces, internal error messages, or database errors to API consumers
- Log security-relevant events: authentication failures, authorisation denials, and unexpected errors
- Do not log sensitive data: passwords, tokens, credit card numbers, PII
- Distinguish between errors that should be logged (server faults) and errors that should not
  be surfaced to clients (validation errors are normal, not alarming)

## 8. Container and Infrastructure Hygiene

- Docker containers must not run as `root` — specify a non-root `USER` in the Dockerfile
- Use official or verified base images; pin to a specific digest or tag
- Do not install unnecessary tools (curl, wget, bash) in production images
- Ensure secrets are not baked into Docker images: use build args carefully, prefer runtime
  environment injection
- `.env` files and credential files must not be copied into Docker images

## 9. CORS Configuration

- Configure CORS explicitly — do not allow all origins (`*`) in production
- Allowlist only known, specific origins; avoid wildcard patterns for credentialed requests
- Do not rely on CORS alone for security — CORS is a browser control, not a server-side guard

## 10. Disclosure and Response Policy

- Maintain a `SECURITY.md` at the repository root describing how to report vulnerabilities
- Include a contact method (email, security advisory link) and the expected response time
- Do not dismiss vulnerability reports — triage and respond within the committed window
- Follow coordinated disclosure: fix privately, then publish after a fix is available

---

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-03-05 | Initial version — repository hygiene and baseline practices |
