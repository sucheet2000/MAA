---
name: backend-node-review
description: >
  Review a Node.js backend project against approved standards. Use when you want to check
  an Express, Fastify, or NestJS project for adherence to your engineering standards covering
  project structure, framework detection, TypeScript, linting, formatting, testing setup,
  environment configuration, and baseline hygiene signals. Produces a structured Markdown report.
version: 1.0.0
domain: backend
ecosystem: node
type: review
inputs:
  - type: project-path
    description: Absolute or relative path to the Node.js backend project to review
outputs:
  - type: report
    description: Markdown review report saved to reports/reviews/
reads:
  - standards/backend-node.md
  - policies/approval-process.md
writes:
  - reports/reviews/
---

# Backend Review Skill (Node.js)

## Scope

**This skill covers Node.js backends only.**
Python, Go, Java, and other backend ecosystems are not yet supported.
When additional ecosystem support is added (Sprint 3+), each ecosystem will have its own
skill and script under `skills/review/backend-<ecosystem>-review/`.

## Purpose

Review a Node.js backend project against the approved `standards/backend-node.md` document.
Produce a structured, actionable report organized into detected signals and a standards checklist.

This skill is invoked by `scripts/maa-backend-review.sh`. It does not require Claude — all
checks are bash operations using `grep`, `test -f`, and `test -d`. No jq, Python, or Node
are required to run MAA itself.

## When to Use

- Before merging a significant backend PR
- When onboarding to an unfamiliar Node.js codebase
- Periodic backend health checks
- After a major refactor, framework upgrade, or dependency audit

## Workflow (Sprint 2 — bash checks only)

1. Validate the project path exists and is a directory
2. Check for `package.json` — required to proceed; exits with Node.js scope note if missing
3. Run all informational checks listed under **Checks** below
4. Render the report using `templates/review-report.md`
5. Save report to `reports/reviews/YYYY-MM-DD-<project-dirname>-backend-node.md`

## Checks

### Required signals (script exits if missing)
- `package.json` exists — exit 1, not a Node.js project (or wrong ecosystem)

### Informational signals (marked "not detected" if absent, never a hard stop)
- Entry directory: `src/`, `server/`, or `app/` — reports all that are present
- Framework: NestJS, Fastify, or Express detected in `package.json` deps
- TypeScript: `tsconfig.json` present, or `tsconfig.base.json` (monorepo root) — see standards §3
- Linting: standalone ESLint config file, `"eslint"` dependency in `package.json`, or `"eslintConfig"` key
- Formatting: Prettier config file or `"prettier"` in `package.json` dependencies
- Testing: Jest/Vitest config file, `"jest"` / `"vitest"` / `"supertest"` dependency, or `"test"` script in `package.json`
- Env example: `.env.example`, `.env.sample`, or `example.env` at project root — see standards §9
- `README.md` present at project root
- `.gitignore` present at project root

### Detection method

All checks use simple `grep`, `test -f`, and `test -d` — no JSON parsing, no Node, no Python.
When a check cannot determine a clear result, it outputs "not detected" rather than failing.

## Output Format

Use `templates/review-report.md`. Key sections:
- **Project Metadata** — path, date, project name
- **Detected Signals** — framework, tooling, structure signals
- **Standards Checklist** — pass/not-detected per check, grouped by standards section
- **Manual Review Notes** — space for findings that require reading code
- **Next Actions** — prioritised recommendations

## Constraints

- Do NOT analyze code quality, routing patterns, or logic
- Do NOT require jq, Python, or Node to run
- Do NOT fail hard on optional signals
- Mark uncertain results as "not detected" not "fail"
- Report file must be human-readable without any tooling

## Failure Modes

| Situation | Behaviour |
|-----------|-----------|
| Project path does not exist | Exit 1 with clear error message |
| `package.json` missing | Exit 1 — not a Node.js project; includes ecosystem scope note |
| Same-day report already exists | Exit 1 — delete or rename existing report first |
| Entry directory missing | Mark "not detected" in report, continue |
| Any check errors | Treat as "not detected", continue |

## References

- `standards/backend-node.md` — the standard this skill checks against
- `templates/review-report.md` — the output template
- `scripts/maa-backend-review.sh` — the script that executes this skill
