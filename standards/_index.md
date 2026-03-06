# Standards Index

All approved engineering standards. Each entry is a versioned document in `standards/`.

---

## Active Standards

| ID | File | Domain | Version | Last Updated | Last Reviewed | Summary |
|----|------|--------|---------|--------------|---------------|---------|
| frontend | frontend.md | frontend | 1.0.0 | 2026-03-05 | 2026-03-05 | Component architecture, TypeScript, state, a11y, performance, styling, testing, tooling |
| backend-node | backend-node.md | backend / Node.js | 1.0.0 | 2026-03-05 | 2026-03-05 | Project structure, API design, TypeScript, error handling, validation, auth, DB, testing, config, security, logging |
| api-design | api-design.md | api design | 1.0.0 | 2026-03-05 | 2026-03-05 | OpenAPI spec, versioning, resource naming, HTTP methods, response shapes, errors, docs, auth, pagination |
| security | security.md | security | 1.0.0 | 2026-03-05 | 2026-03-05 | Secret hygiene, dependency management, auth, input validation, HTTP headers, transport security, containers, CORS, disclosure |
| backend-python | backend-python.md | backend / Python | 1.0.0 | 2026-03-06 | 2026-03-06 | Project definition, gitignore, framework, type checking, linting, formatting, testing, lock file, env template, README |
| testing | testing.md | testing (cross-cutting) | 1.0.0 | 2026-03-06 | 2026-03-06 | Test organisation, runner config, coverage, thresholds, CI automation, test breadth, fixtures, DX, docs, artifact hygiene |

---

## Planned (not yet written)

| ID | Domain | Notes |
|----|--------|-------|
| backend-go | backend / Go | Go backend standards — future |

---

## How to Add a Standard

1. Write the standard as `standards/<id>.md` following the format in existing standards
2. Add an entry to this index
3. Record the approval in `decisions/`
4. Commit with message: `docs(standards): add <id> standard v1.0.0`

## Review Schedule

Standards not reviewed in 90 days should be flagged for re-review. Check `Last Reviewed` dates above.
