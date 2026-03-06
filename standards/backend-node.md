# Node.js Backend Engineering Standards

**Version:** 1.0.0
**Last updated:** 2026-03-05
**Domain:** Backend
**Ecosystem:** Node.js
**Status:** Approved
**Origin:** seed
**Sources:** none

---

## 1. Project Structure

- Source code lives in `src/`, `server/`, or `app/` — pick one and be consistent
- Separate concerns by layer: routes, controllers (or handlers), services, models/repositories
- Keep route definitions thin — business logic belongs in services, not in route handlers
- One responsibility per file; avoid files that grow beyond ~200 lines
- Co-locate tests with the code they test unless the project already uses a `tests/` convention

## 2. API Design

- Follow REST conventions: use nouns for resources, HTTP verbs for actions
- Use appropriate HTTP status codes: `200` for success, `201` for creation, `400` for bad input, `401`/`403` for auth, `404` for not found, `500` for unexpected server error
- Version APIs from the start: prefer path versioning (`/v1/`) for public APIs
- Return consistent response shapes — success and error responses should follow the same envelope if one is used
- Never return raw database objects directly from endpoints; use a response mapping layer

## 3. TypeScript

- TypeScript is the default. JavaScript is acceptable only in config or tooling files.
- Enable strict mode (`"strict": true`) in `tsconfig.json`
- Avoid `any`. Use `unknown` when the type is genuinely unknown, then narrow it
- Type all function signatures, request/response shapes, and service return values
- Use `zod` or similar to derive types from runtime validation schemas — avoids duplication between type and validator

## 4. Error Handling

- Implement a single centralized error handler (Express middleware or NestJS exception filter)
- Error responses must use appropriate HTTP status codes — never return `200` with an error body
- Never expose stack traces, internal paths, or database error messages to the client
- Distinguish between operational errors (expected, handle gracefully) and programmer errors (unexpected, log and let the process crash cleanly)
- Log all 5xx errors with enough context to reproduce: request method, path, user ID if available

## 5. Validation

- Validate all incoming data at the request boundary before it reaches business logic
- Use a schema validation library: Zod (preferred), Joi, or NestJS class-validator
- Reject invalid input with `400` and a clear message describing what was wrong
- Never trust `req.body`, `req.query`, or `req.params` without validation
- Validate environment variables at startup using a schema — fail fast rather than fail late

## 6. Authentication

- Authentication logic belongs in middleware or guards — not scattered across route handlers
- Never store passwords in plaintext; use bcrypt or argon2
- JWT: use short expiry on access tokens; use refresh tokens for long-lived sessions
- Secrets (JWT secret, OAuth credentials) must come from environment variables, never hardcoded
- Log authentication failures with enough context to detect brute-force patterns

## 7. Database and ORM

- Use parameterized queries or an ORM — never concatenate user input into SQL strings
- Define a schema explicitly (Prisma schema, TypeORM entity, or Sequelize model) — avoid schema-less access
- Keep database access in a repository or data-access layer; do not query the database from route handlers directly
- Run migrations as a separate step; do not auto-migrate in production without review
- Index foreign keys and any column used in `WHERE` or `ORDER BY` at scale

## 8. Testing

- Unit test service and utility functions in isolation using Jest or Vitest
- Integration test routes using Supertest — send real HTTP requests against the app
- Test error paths as well as happy paths; `400` and `404` responses should be tested
- Aim for meaningful coverage of critical paths — login, auth, main CRUD operations
- Do not test internal implementation details; test the observable behavior

## 9. Configuration Management

- All configuration comes from environment variables — no hardcoded URLs, ports, or keys
- Provide a `.env.example` (or `.env.sample` / `example.env`) file committed to the repo with all required keys and placeholder values
- Never commit `.env` files containing real secrets
- Validate all required environment variables at startup; fail fast if any are missing
- Use a dedicated config module that reads and validates `process.env` in one place

## 10. Security

- Set security headers using `helmet` (or equivalent)
- Configure CORS explicitly — do not use `cors()` with no options in production
- Apply rate limiting to authentication endpoints at minimum
- Keep dependencies up to date; review `npm audit` output before release
- Never log request bodies that may contain credentials or PII

## 11. Logging

- Use structured logging (JSON output): pino or winston are preferred
- Log at appropriate levels: `debug` for development detail, `info` for operational events, `warn` for recoverable issues, `error` for failures
- Include a correlation ID on each request and pass it through to all log lines for that request
- Do not log sensitive data: passwords, tokens, credit card numbers, or personal identifiers
- In production, write logs to stdout/stderr and let the infrastructure collect them — do not write to local files

## 12. Tooling

- Linting: ESLint with a strict config. No committed code should have lint errors.
- Formatting: Prettier. Format on save or as a pre-commit hook.
- Package manager: consistent across the project — pick one (npm, pnpm, or yarn) and do not mix lock files.
- Type-checking: run `tsc --noEmit` as part of CI or pre-commit to catch type errors independently of the build.

---

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-03-05 | Initial version — Node.js ecosystem only |
