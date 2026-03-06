# Trusted-Source Registry

Authoritative and reference sources used when revising MAA standards.

Use source IDs from this file in the `**Sources:**` field of approved standards.

**Trust levels:**
- `authoritative` — official specification, official documentation, or widely-adopted
  industry standard. Treat as ground truth within its domain.
- `reference` — high-quality practitioner resource. Opinions are well-reasoned and
  broadly accepted, but not official specification.
- `community` — useful signal, but verify claims against authoritative sources.
  Do not cite alone.

To add a source: append an entry below, sorted by domain, with `last_checked` set to
today's date. Prefer fewer high-quality sources over many mediocre ones.

---

## Frontend

| ID | Name | URL | Trust | Last Checked | Notes |
|----|------|-----|-------|--------------|-------|
| react-docs | React Official Documentation | https://react.dev | authoritative | 2026-03-06 | Official source for React patterns and APIs. Prefer over blog posts for component model questions. |
| typescript-handbook | TypeScript Handbook | https://www.typescriptlang.org/docs/handbook/ | authoritative | 2026-03-06 | Official TypeScript language semantics and configuration reference. |
| mdn-web-docs | MDN Web Docs | https://developer.mozilla.org | authoritative | 2026-03-06 | Ground truth for HTML semantics, CSS, browser APIs, and web platform features. |
| nextjs-docs | Next.js Documentation | https://nextjs.org/docs | authoritative | 2026-03-06 | Official Next.js docs. Use for Next-specific patterns; use react-docs for React fundamentals. |
| eslint-docs | ESLint Documentation | https://eslint.org/docs/latest/ | authoritative | 2026-03-06 | Official ESLint rules and configuration reference. |
| web-dev-google | web.dev (Google Chrome team) | https://web.dev | reference | 2026-03-06 | Performance, Core Web Vitals, accessibility, and modern web platform guidance. |
| kent-c-dodds-blog | Kent C. Dodds Blog | https://kentcdodds.com/blog | reference | 2026-03-06 | Testing and React patterns. Author of Testing Library. Opinionated but well-reasoned. |

---

## Backend — Node.js

| ID | Name | URL | Trust | Last Checked | Notes |
|----|------|-----|-------|--------------|-------|
| nodejs-docs | Node.js Documentation | https://nodejs.org/en/docs | authoritative | 2026-03-06 | Official Node.js runtime API and best practices. |
| nestjs-docs | NestJS Documentation | https://docs.nestjs.com | authoritative | 2026-03-06 | Official NestJS framework docs. Prefer for NestJS-specific architecture questions. |
| fastify-docs | Fastify Documentation | https://fastify.dev/docs/latest/ | authoritative | 2026-03-06 | Official Fastify docs. Trust for Fastify plugin model and lifecycle hooks. |
| express-docs | Express.js Documentation | https://expressjs.com/en/guide/ | authoritative | 2026-03-06 | Official Express docs. Minimal guidance; supplement with community resources. |

---

## Backend — Python

| ID | Name | URL | Trust | Last Checked | Notes |
|----|------|-----|-------|--------------|-------|
| python-docs | Python Official Documentation | https://docs.python.org/3/ | authoritative | 2026-03-06 | Official Python language docs. Ground truth for stdlib and language semantics. |
| pep-8 | PEP 8 — Style Guide for Python Code | https://peps.python.org/pep-0008/ | authoritative | 2026-03-06 | Official Python style guide. Canonical reference for formatting and naming conventions. |
| fastapi-docs | FastAPI Documentation | https://fastapi.tiangolo.com | authoritative | 2026-03-06 | Official FastAPI docs. Best source for dependency injection, routing, and pydantic integration. |
| pydantic-docs | Pydantic Documentation | https://docs.pydantic.dev/latest/ | authoritative | 2026-03-06 | Official Pydantic v2 docs. Ground truth for data validation and settings management. |
| mypy-docs | mypy Documentation | https://mypy.readthedocs.io/en/stable/ | authoritative | 2026-03-06 | Official mypy docs. Reference for type checking configuration and strictness settings. |

---

## API Design

| ID | Name | URL | Trust | Last Checked | Notes |
|----|------|-----|-------|--------------|-------|
| openapi-spec | OpenAPI Specification | https://spec.openapis.org/oas/latest.html | authoritative | 2026-03-06 | Official OpenAPI specification. Ground truth for schema format and API description. |
| microsoft-api-guidelines | Microsoft REST API Guidelines | https://github.com/microsoft/api-guidelines | reference | 2026-03-06 | Widely-cited REST API design guidance. Good for naming conventions, pagination, and error shapes. |
| stripe-api-docs | Stripe API Reference | https://stripe.com/docs/api | reference | 2026-03-06 | Industry-standard example of well-designed REST API. Use as a design reference, not a spec. |
| json-api-spec | JSON:API Specification | https://jsonapi.org | reference | 2026-03-06 | Formal specification for API response shapes, pagination, and error objects. Use when response shape consistency is a goal. |

---

## Security

| ID | Name | URL | Trust | Last Checked | Notes |
|----|------|-----|-------|--------------|-------|
| owasp-top-10 | OWASP Top 10 | https://owasp.org/www-project-top-ten/ | authoritative | 2026-03-06 | Industry-standard security vulnerability classification. Required reading for security standards. |
| owasp-asvs | OWASP Application Security Verification Standard | https://owasp.org/www-project-application-security-verification-standard/ | authoritative | 2026-03-06 | Detailed security requirements checklist. Use for specific control requirements at L1/L2/L3. |
| cwe-top-25 | CWE Top 25 Most Dangerous Software Weaknesses | https://cwe.mitre.org/top25/ | authoritative | 2026-03-06 | MITRE's ranked list of common software weaknesses. Use alongside OWASP Top 10. |
| nodejs-security-docs | Node.js Security Best Practices | https://nodejs.org/en/docs/guides/security/ | authoritative | 2026-03-06 | Official Node.js security guidance. Covers prototype pollution, path traversal, and timing attacks. |

---

## Testing

| ID | Name | URL | Trust | Last Checked | Notes |
|----|------|-----|-------|--------------|-------|
| jest-docs | Jest Documentation | https://jestjs.io/docs/getting-started | authoritative | 2026-03-06 | Official Jest docs. Reference for configuration, matchers, and coverage setup. |
| vitest-docs | Vitest Documentation | https://vitest.dev/guide/ | authoritative | 2026-03-06 | Official Vitest docs. Preferred over Jest docs for Vite-based projects. |
| testing-library-docs | Testing Library Documentation | https://testing-library.com/docs/ | authoritative | 2026-03-06 | Official Testing Library docs. Ground truth for user-centric component and integration testing. |
| pytest-docs | pytest Documentation | https://docs.pytest.org/en/stable/ | authoritative | 2026-03-06 | Official pytest docs. Reference for configuration, fixtures, and plugin ecosystem. |

---

## Deployment

| ID | Name | URL | Trust | Last Checked | Notes |
|----|------|-----|-------|--------------|-------|
| docker-docs | Docker Documentation | https://docs.docker.com | authoritative | 2026-03-06 | Official Docker docs. Ground truth for Dockerfile syntax, build context, and security hardening. |
| twelve-factor | The Twelve-Factor App | https://12factor.net | reference | 2026-03-06 | Foundational methodology for deployable, maintainable services. Informs config, process, and parity standards. |
| docker-best-practices | Docker Dockerfile Best Practices | https://docs.docker.com/develop/develop-images/dockerfile_best-practices/ | authoritative | 2026-03-06 | Official Docker guidance on layer ordering, caching, and image hardening. Subset of docker-docs. |
| hadolint-wiki | Hadolint Wiki | https://github.com/hadolint/hadolint/wiki | reference | 2026-03-06 | Documents Dockerfile lint rules. Useful for understanding what a linter enforces and why. |

---

## Notes

`sources/trusted-sources.yaml` predates this registry. `sources/registry.md` is the
canonical format going forward. The YAML is retained for reference but is not maintained.
