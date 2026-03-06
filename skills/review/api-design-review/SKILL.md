---
name: api-design-review
description: >
  Review a project's API design artifacts against approved standards. Use when you want to
  check whether an API has an OpenAPI specification, versioning strategy, inline documentation,
  reusable schema components, and examples. Produces a structured Markdown report.
  Works best when the project contains an OpenAPI 3.x spec; also runs on projects without
  a spec and surfaces the gap explicitly.
version: 1.0.0
domain: api-design
type: review
inputs:
  - type: project-path
    description: Absolute or relative path to the project or API directory to review
outputs:
  - type: report
    description: Markdown review report saved to reports/reviews/
reads:
  - standards/api-design.md
  - policies/approval-process.md
writes:
  - reports/reviews/
---

# API Design Review Skill

## Scope

This skill covers HTTP/REST APIs with OpenAPI specifications (2.x or 3.x).
GraphQL and gRPC are not yet supported.

Unlike the frontend and backend-node skills, this review does **not** exit if the primary
artifact (an OpenAPI spec) is absent. The absence of a spec is itself a finding — the review
runs, surfaces the gap prominently, and the checklist marks it as a critical item.

This skill is designed as a bridge between Build Review and Plan Review Mode. The same
`standards/api-design.md` governs both:
- **Build Review (Sprint 3):** checks a spec that already exists in the repo
- **Plan Review (future):** will check a design document or spec draft before implementation

## Purpose

Review API design artifacts against `standards/api-design.md`. Produce a structured,
actionable report organized into detected signals and a standards checklist — with an
emphasis on manual review items, since most API design quality cannot be auto-detected.

This skill is invoked by `scripts/maa-api-design-review.sh`. All checks are bash operations
using `grep`, `test -f`, and `test -d`. No jq, Python, or Node are required.

## When to Use

- Before shipping a new API or major API version
- When onboarding to an unfamiliar API codebase
- After adding or changing endpoints, to verify spec is up to date
- When evaluating whether an API is ready for external consumers
- Periodic API hygiene check alongside backend-node review

## Workflow (Sprint 3 — bash checks only)

1. Validate the project path exists and is a directory
2. Search common locations for an OpenAPI spec file
3. If a spec is found, run spec-gated checks (signals 2–7)
4. If no spec is found, mark spec-gated checks as "not checked (no spec found)"
5. Run non-spec-gated checks regardless of spec presence (signals 8–10)
6. Render the report using `templates/review-report.md`
7. Save report to `reports/reviews/YYYY-MM-DD-<project-dirname>-api-design.md`

## Checks

### Signal 1 — OpenAPI spec file (not spec-gated)
- Search locations (first match wins): `openapi.yaml`, `openapi.json`, `swagger.yaml`,
  `swagger.json`, `api/openapi.yaml`, `api/openapi.json`, `docs/openapi.yaml`,
  `docs/openapi.json`, `api-spec.yaml`, `api-spec.json`, `spec/openapi.yaml`,
  `spec/openapi.json`
- Not present → all spec-gated checks report "not checked (no spec found)"; review continues

### Signals 2–7 — spec-gated (only evaluated if spec found)
- **Spec version:** grep `^openapi:` (3.x) or `^swagger:` (2.x)
- **Info completeness:** grep `title:` and `version:` in spec
- **Descriptions:** grep `description:` — indicates endpoints/schemas are documented
- **Components/schemas:** grep `^components:` — indicates reusable schema definitions
- **Versioning:** grep `/v1` or `/v2` pattern in spec paths
- **Examples:** grep `example:` or `examples:` — indicates response/request examples present

### Signals 8–10 — not spec-gated (always checked)
- **Client collection:** Postman (`*.postman_collection.json`), Insomnia (`.insomnia/`),
  or Bruno (`*.bru`) — indicates the API has been manually tested or documented
- **API docs:** `README.md`, `API.md`, `ENDPOINTS.md`, `docs/api.md`
- **`.gitignore`** present at project root

### Detection method

All checks use `grep`, `test -f`, `test -d`, and `find -maxdepth 2`. No JSON parsing,
no Node, no Python. When a check cannot determine a clear result, it outputs
"not detected" rather than failing.

## Output Format

Use `templates/review-report.md`. Key sections:
- **Project Metadata** — path, date, project name
- **Detected Signals** — spec presence, spec quality signals, documentation signals
- **Standards Checklist** — grouped by standards section; heavy use of `(Manual)` items
- **Manual Review Notes** — naming conventions, status codes, error shapes, auth scheme
- **Next Actions** — prioritised recommendations

## Constraints

- Do NOT run spec validation tools (Spectral, swagger-validator) — no external tools
- Do NOT parse YAML structure beyond line-level grep
- Do NOT fail hard if no spec is found — surface the gap and continue
- Mark uncertain results as "not detected" or "not checked (no spec found)"
- Report file must be human-readable without any tooling

## Failure Modes

| Situation | Behaviour |
|-----------|-----------|
| Project path does not exist | Exit 1 with clear error message |
| No OpenAPI spec found | Continue; spec-gated checks report "not checked (no spec found)" |
| Same-day report already exists | Exit 1 — delete or rename existing report first |
| Any check errors | Treat as "not detected", continue |

## References

- `standards/api-design.md` — the standard this skill checks against
- `templates/review-report.md` — the output template
- `scripts/maa-api-design-review.sh` — the script that executes this skill
