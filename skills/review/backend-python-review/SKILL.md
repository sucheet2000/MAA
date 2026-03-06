---
id: backend-python-review
name: Python Backend Build Review
domain: backend-python
type: build-review
status: active
version: 1.0.0
standard: standards/backend-python.md
script: scripts/maa-backend-python-review.sh
template: skills/review/backend-python-review/templates/review-report.md
---

# Python Backend Build Review

A Build Review skill for Python backend repositories. Checks repository-level
hygiene and tooling signals against `standards/backend-python.md`.

All detection is filesystem-only. No Python tooling is executed. No code is
parsed. Signals are detected with `grep`, `test -f`, and `test -d`.

## When to run

- Before opening a PR that ships to production
- When onboarding a Python project into MAA
- After a significant dependency or tooling change
- When setting up a new Python backend service

## Hard gate

The review requires at least one of `pyproject.toml`, `requirements.txt`, or
`setup.py` to be present. If none is found, the review exits immediately — the
target is not a Python project.

## What it checks

| # | Signal | Detection method |
|---|--------|-----------------|
| 1 | Project definition file | `test -f` for `pyproject.toml`, `requirements.txt`, `setup.py` |
| 2 | `.gitignore` present | `test -f .gitignore` |
| 3 | Framework | `grep -iE` for `fastapi`, `django`, `flask` in project files |
| 4 | Type checking config | `test -f` for `.mypy.ini`, `pyrightconfig.json`; `grep` for `[tool.mypy]` in pyproject.toml |
| 5 | Linting config | `test -f` for `ruff.toml`, `.flake8`, `.pylintrc`; `grep` for `[tool.ruff]` in pyproject.toml |
| 6 | Formatting config | `grep` for `[tool.ruff.format]`, `[tool.black]` in pyproject.toml |
| 7 | Testing setup | `test -d tests/`; `test -f pytest.ini`; `grep` for `[tool.pytest` in pyproject.toml |
| 8 | Dependency lock file | `test -f` for `uv.lock`, `poetry.lock`, `Pipfile.lock`, `pdm.lock` |
| 9 | Environment template | `test -f` for `.env.example`, `.env.sample`, `example.env` |
| 10 | README | `test -f README.md`, `README.rst`, `README` |

## What it does NOT check

The following require manual review:

- Whether type hints are actually used throughout the codebase
- Whether tests pass or provide meaningful coverage
- Whether linting produces zero warnings
- Whether formatting is consistently applied
- Authentication and authorization logic
- Input validation patterns
- Database query safety (parameterisation)
- Configuration management implementation

These items appear as a manual findings section in the generated report.

## Usage

```bash
maa review backend-python <project-path>
```

## Output

Writes a Markdown report to `reports/reviews/YYYY-MM-DD-<project>-backend-python.md`.

The report contains:
- Automated signal results
- A manual findings checklist for items that require code inspection
- Recommendations keyed to `standards/backend-python.md` section numbers

## Interpretation guide

| Result | Meaning |
|--------|---------|
| `pyproject.toml` / `requirements.txt` | Project definition found (specific file named) |
| `detected (...)` | Signal found; tool or config named in parentheses |
| `partial (...)` | Partially detected; detail in parentheses |
| `present` | File exists |
| `not detected` | Signal not found — review whether it is needed |
