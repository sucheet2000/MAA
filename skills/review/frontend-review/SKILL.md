---
name: frontend-review
description: >
  Review a frontend project against approved standards. Use when you want to check
  a React, Next.js, or Vite project for adherence to your engineering standards covering
  tooling, project structure, framework choice, linting, formatting, testing setup, and
  baseline signals. Produces a structured Markdown report.
version: 1.0.0
domain: frontend
type: review
inputs:
  - type: project-path
    description: Absolute or relative path to the frontend project to review
outputs:
  - type: report
    description: Markdown review report saved to reports/reviews/
reads:
  - standards/frontend.md
  - policies/approval-process.md
writes:
  - reports/reviews/
---

# Frontend Review Skill

## Purpose

Review a frontend project against the approved `standards/frontend.md` document.
Produce a structured, actionable report organized into detected signals and a standards checklist.

This skill is invoked by `scripts/maa-review.sh`. It does not require Claude — Sprint 1
checks are deterministic bash operations. Future versions may invoke Claude for deeper
code analysis.

## When to Use

- Before merging a large frontend PR
- When onboarding to an unfamiliar frontend codebase
- Periodic codebase health checks
- After a major refactor or dependency upgrade

## Workflow (Sprint 1 — bash checks only)

1. Validate the project path exists and is a directory
2. Check for `package.json` — required to proceed
3. Detect whether this looks like a frontend project (src/ present, frontend framework signal)
4. Run all checks listed under **Checks** below
5. Render the report using `templates/review-report.md`
6. Save report to `reports/reviews/YYYY-MM-DD-<project-dirname>-frontend.md`

## Checks

### Required signals (script exits if missing)
- `package.json` exists — exit 1, not a Node-based frontend project

### Informational signals (marked "not detected" if absent, never a hard stop)
- `src/` directory exists — expected but absence does not abort the review
- `public/` directory — standard for CRA, Vite, Next.js with static assets
- Framework: React, Next.js, or Vite detected in `package.json`
- TypeScript: `tsconfig.json` present, or `tsconfig.base.json` (monorepo root) — see standards §3
- Linting: standalone ESLint config file, `"eslint"` dependency in `package.json`, or `"eslintConfig"` key in `package.json` (CRA pattern)
- Formatting: Prettier config file or prettier in `package.json` dependencies
- Testing: test script in `package.json`, or Jest/Vitest/Playwright/Cypress config file
- `README.md` present at project root
- `.gitignore` present at project root

### Detection method

All checks use simple `grep`, `test -f`, and `test -d` — no JSON parsing, no Node, no Python.
When a check cannot determine a clear result, it outputs "not detected" rather than failing.

## Output Format

Use `templates/review-report.md`. Key sections:
- **Project Metadata** — path, date, project name
- **Detected Signals** — framework, tooling, structure signals
- **Standards Checklist** — pass/not-detected/fail per check
- **Notes / Next Actions** — space for manual findings

## Constraints

- Do NOT analyze code quality, component patterns, or logic in Sprint 1
- Do NOT require jq, Python, or Node to run
- Do NOT fail hard on optional signals (public/, README, .gitignore)
- Mark uncertain results as "not detected" not "fail"
- Report file must be human-readable without any tooling

## Failure Modes

| Situation | Behaviour |
|-----------|-----------|
| Project path does not exist | Exit 1 with clear error message |
| `package.json` missing | Exit 1 — not a Node-based frontend project |
| Same-day report already exists | Exit 1 — delete or rename existing report first |
| `src/` missing | Mark "not detected" in report, continue |
| Any check errors | Treat as "not detected", continue |

## References

- `standards/frontend.md` — the standard this skill checks against
- `templates/review-report.md` — the output template
- `scripts/maa-review.sh` — the script that executes this skill
