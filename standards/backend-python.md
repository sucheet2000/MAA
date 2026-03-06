# Backend Standards — Python

**Version:** 1.0.0
**Last updated:** 2026-03-06
**Domain:** Backend / Python
**Status:** Approved
**Origin:** seed
**Sources:** none

---

## Scope

This standard applies to Python backend services: APIs, background workers, and server-side
applications. It covers project hygiene, structure, tooling, and quality baseline. It does not
prescribe application architecture, database choices, or deployment topology.

Framework-specific patterns (Django ORM, FastAPI dependency injection, etc.) are not mandated
here. The standard addresses practices that apply across all Python backend frameworks.

---

## 1. Project Definition

Every Python backend must have an explicit project definition file:

- `pyproject.toml` is the modern standard and should be used for all new projects. It is the
  single source of configuration for the project, its dependencies, and its tooling.
- `requirements.txt` is acceptable for simple services that do not use a build system. If used,
  keep it pinned (`package==1.2.3`) and pair it with a lock file.
- `setup.py` is legacy. Maintain it if inherited; do not start new projects with it.

Do not mix `pyproject.toml` and `requirements.txt` as co-equal dependency sources. Pick one.

## 2. Source Control Hygiene

- `.gitignore` must be present and must cover at minimum: `__pycache__/`, `*.pyc`, `.venv/`,
  `venv/`, `env/`, `dist/`, `.eggs/`, `*.egg-info/`, `.env*`
- Do not commit virtual environment directories, compiled bytecode, or distribution artefacts
- Use `.gitignore` from a known source (e.g., GitHub's Python template) as a baseline

## 3. Framework Usage

- **FastAPI** — for async-first APIs. Use Pydantic models for request/response validation.
  Use dependency injection for shared resources (DB sessions, auth).
- **Django** — for projects needing ORM, admin, auth, or full-stack features out of the box.
  Use Django REST Framework or Ninja for API layers.
- **Flask** — for small, simple services or when minimal overhead is a hard requirement.
  Do not use Flask for large APIs — the ecosystem scaffolding is too manual at scale.

Do not mix frameworks within a single service. Do not add Django to a FastAPI project for
its ORM alone — use SQLAlchemy or SQLModel instead.

## 4. Type Hints

- All function signatures must have type hints: parameters and return types
- Use `mypy` or `pyright` in standard or strict mode — configuration must be committed
- `Any` should be minimised and justified when used
- Use `from __future__ import annotations` in Python ≤ 3.9 to enable deferred evaluation
- For libraries and shared packages, include a `py.typed` marker file

Configuration: `[tool.mypy]` in `pyproject.toml`, or `.mypy.ini` at project root.

## 5. Linting

- Use `ruff` as the primary linter — it covers flake8, isort, pyupgrade, and more, with faster
  execution. Configure via `[tool.ruff]` in `pyproject.toml` or a standalone `ruff.toml`.
- If inheriting a project that uses `flake8` or `pylint`, do not remove them without also
  resolving all findings they were catching.
- Enable at minimum: `E`, `W`, `F` rule sets (pycodestyle + pyflakes). Enable `I` (isort) for
  import ordering.
- Linting must be runnable with a single command and must produce no warnings on a clean codebase.

## 6. Formatting

- Use `ruff format` (preferred) or `black`. Both are acceptable; do not use both.
- Configure line length consistently with your linting config — default is 88 for black/ruff.
- Formatting must be enforced — do not leave it to developer preference.
- Configuration: `[tool.ruff.format]` or `[tool.black]` in `pyproject.toml`.

## 7. Testing

- Use `pytest`. No other test runner is required at this stage.
- All tests live in a `tests/` directory at the project root (preferred) or `test/`.
- Test files follow the `test_*.py` naming convention.
- For FastAPI services: use `httpx` + `pytest-anyio` or `pytest-asyncio` for async HTTP tests.
- For Django: use `pytest-django`.
- Configure pytest in `pyproject.toml` under `[tool.pytest.ini_options]`.
- Tests must be runnable with `pytest` from the project root with no extra arguments required.

## 8. Configuration Management

- Load configuration from environment variables — never hard-code values that differ between
  environments
- Use `pydantic-settings` (for FastAPI/Pydantic projects) or `python-dotenv` — do not scatter
  `os.environ` calls across the codebase
- Provide a `.env.example`, `.env.sample`, or `example.env` listing every required variable
  with a placeholder value and a short comment
- Never commit `.env`, `.env.local`, `.env.production`, or similar files containing real values

## 9. Dependency Management

- A dependency lock file is required: `uv.lock` (preferred), `poetry.lock`, `Pipfile.lock`,
  or `pdm.lock`. Commit it.
- Use a virtual environment: `uv`, `poetry`, `pipenv`, or plain `venv`. Do not install into
  the system Python.
- Separate production and development dependencies. In `pyproject.toml`, use
  `[project.dependencies]` for production and `[project.optional-dependencies]` or
  `[dependency-groups]` for dev.
- Pin transitive dependencies via the lock file — do not rely on minimum-version constraints
  alone in production.

## 10. Tooling

- `pyproject.toml` is the single configuration source — consolidate tool config here rather
  than maintaining `.flake8`, `mypy.ini`, `setup.cfg`, and `pytest.ini` as separate files.
- Use a consistent package manager across the team: `uv` (recommended for speed and
  reproducibility), `poetry`, or `pip` + `venv`. Do not mix.
- Define repeatable local tasks: a `Makefile` with `lint`, `format`, `test`, `typecheck`
  targets, or equivalent, so contributors do not need to remember invocation details.
- `pre-commit` is strongly recommended for enforcing linting and formatting at commit time.

---

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-03-06 | Initial version |
