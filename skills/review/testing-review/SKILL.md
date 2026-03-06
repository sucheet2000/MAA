---
id: testing-review
name: Testing Build Review
domain: testing
type: build-review
status: active
version: 1.0.0
standard: standards/testing.md
script: scripts/maa-testing-review.sh
template: skills/review/testing-review/templates/review-report.md
---

# Testing Build Review

A cross-cutting Build Review skill that checks whether a repository shows evidence of a
mature testing practice. Complements the ecosystem reviews (`frontend`, `backend-node`,
`backend-python`) which check for test presence — this review checks for testing depth.

All detection is filesystem-only. No test tooling is executed. No code is parsed.
Signals are detected with `grep`, `test -f`, `test -d`, and `find`.

There is no hard gate. Absence of signals is itself a reportable finding — a project
with no test infrastructure receives a maximum-gap report.

## When to run

- When onboarding an existing project into MAA
- Before a major release to verify testing baseline
- After a period of rapid feature development where testing may have been deprioritised
- As a complement to any ecosystem review

## What it checks

| # | Signal | Detection method |
|---|--------|-----------------|
| 1 | Test directory | `test -d` for `tests/`, `test/`, `__tests__/`, `spec/` |
| 2 | Test runner config | `test -f` for jest/vitest/mocha config files; `grep` for `[tool.pytest` in pyproject.toml |
| 3 | Coverage configuration | `test -f` for `.coveragerc`, `.nycrc`; `grep` for `[tool.coverage` in pyproject.toml; `grep` for coverage keys in jest config |
| 4 | Coverage threshold | `grep` for `fail_under`, `coverageThreshold`, `thresholds` in config files |
| 5 | CI test automation | `grep -r` for test commands in `.github/workflows/*.yml` |
| 6 | Integration or E2E tests | `test -d` for integration/e2e directories; `test -f` for playwright/cypress config |
| 7 | Test fixtures, helpers, or mocks | `test -f conftest.py`; `test -d` for fixture/helper/mock directories |
| 8 | Test run command defined | `grep` for `"test"` script in `package.json`; `grep` for `test:` in `Makefile`; `test -f tox.ini` |
| 9 | README documents tests | `grep -iE` for test mentions in README |
| 10 | Artifacts gitignored | `grep` for `.coverage`, `htmlcov/`, `.nyc_output/`, `coverage/`, `.pytest_cache/`, `test-results/` in `.gitignore` |

## What it does NOT check

The following require manual review:

- Whether tests are meaningful (not just trivially passing)
- Test naming quality and readability
- Whether coverage numbers are actually acceptable
- Flaky test management
- Test isolation (tests that share global state or depend on execution order)
- Performance of the test suite
- Whether mocks accurately reflect real dependencies

These items appear as a manual findings section in the generated report.

## Relationship to ecosystem reviews

The ecosystem reviews check:
- "Is pytest/jest/vitest configured?" → Yes/No

This review checks:
- "Is there a coverage threshold?" → tells you if coverage is enforced, not just measured
- "Are artifacts gitignored?" → tells you if hygiene is maintained
- "Do CI workflows run tests?" → tells you if tests are actually gated

Run both together for a complete picture.

## Usage

```bash
maa review testing <project-path>
```

## Output

Writes a Markdown report to `reports/reviews/YYYY-MM-DD-<project>-testing.md`.

## Interpretation guide

| Result | Meaning |
|--------|---------|
| `detected (...)` | Signal found; detail in parentheses |
| `partial (...)` | Partially detected; what's covered and what's missing shown |
| `all covered (...)` | All expected artifact patterns gitignored |
| `not detected` | Signal not found — review whether it is needed |
| `not checked (...)` | Check skipped because prerequisite was absent |
