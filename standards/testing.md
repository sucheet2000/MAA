# Testing Standards

**Version:** 1.0.0
**Last updated:** 2026-03-06
**Domain:** Testing (cross-cutting)
**Status:** Approved
**Origin:** seed
**Sources:** none

---

## Scope

This standard applies to all repositories regardless of ecosystem. It covers testing
discipline, structure, and hygiene. It does not prescribe testing frameworks (those are
addressed in ecosystem-specific standards) or testing patterns within a specific language.

The ecosystem reviews (`backend-node`, `backend-python`, `frontend`) check whether testing
is configured. This standard checks whether testing is practised seriously.

---

## 1. Test Organisation

- All tests must live in a dedicated directory at the project root: `tests/`, `test/`,
  `__tests__/`, or `spec/`. Do not scatter test files alongside production code unless the
  project's ecosystem convention requires it (e.g., Go co-location).
- Organise tests by type when the project has more than one type:
  - `tests/unit/` — isolated unit tests
  - `tests/integration/` — tests that cross component or service boundaries
  - `tests/e2e/` — end-to-end tests against a running application
- Test files must follow a consistent naming convention: `test_*.py`, `*.test.ts`,
  `*.spec.ts`, or the equivalent for the ecosystem.
- Do not commit test output, coverage reports, or generated artefacts to the repository.

## 2. Test Runner and Configuration

- The test runner must be explicitly configured — do not rely on defaults that vary by
  environment or tool version.
- Configuration must be committed: `jest.config.*`, `vitest.config.*`, `pytest.ini`,
  `[tool.pytest.ini_options]` in `pyproject.toml`, or equivalent.
- Tests must be runnable in a consistent way across all environments: developer machine,
  CI, and production-equivalent staging.
- Do not use different test runners for the same test type within a project.

## 3. Code Coverage

- Coverage must be measured on every CI run — not just locally, not just on demand.
- Coverage configuration must be committed (`.coveragerc`, `.nycrc`, `[tool.coverage]`
  in `pyproject.toml`, or coverage config in `jest.config.*`).
- Coverage reports should be generated in a machine-readable format for CI consumption,
  not only HTML for human review.
- Coverage of 0% or missing coverage data should fail the build.

## 4. Coverage Thresholds

- Set and enforce a minimum coverage threshold. The exact number is less important than
  having a floor that fails the build when coverage drops below it.
- Raise thresholds over time as the test suite matures — never lower them to make a
  build pass.
- Do not target 100% coverage as a practical goal — focus on meaningful coverage of
  critical paths and business logic, not line-count coverage.
- Configuration: `fail_under` in `.coveragerc` or `pyproject.toml`, `coverageThreshold`
  in `jest.config.*`, `thresholds` in `vitest.config.*`.

## 5. CI/CD Test Automation

- All tests must run in CI on every pull request. Tests must pass before merge.
- Never skip tests in CI to unblock a deployment.
- CI must run the same test command used locally — no special CI-only test modes that
  mask failures.
- Coverage reporting should be part of the CI step, not a separate optional job.

## 6. Test Types and Breadth

- Unit tests alone are insufficient for most production systems. Projects should have
  evidence of integration tests that cross component boundaries.
- APIs must have tests that exercise the HTTP layer, not only the business logic in
  isolation.
- For user-facing applications, at least a minimal E2E test suite covering the critical
  user path is expected.
- Do not write tests that test the framework or language — write tests that test your code.

## 7. Test Data and Fixtures

- Shared test setup must not be duplicated across test files. Use fixtures, factories, or
  builder patterns to centralise test data construction.
- For Python projects: use `conftest.py` for shared fixtures.
- For Node projects: use shared helper modules in `tests/helpers/` or `__mocks__/`.
- Test data must not include real production data, PII, or credentials. Use synthetic data
  or anonymised samples.
- Large test data files (fixtures, seed files) should be reviewed for size before
  committing.

## 8. Developer Experience

- Tests must be runnable locally with a single command: `pytest`, `npm test`, `yarn test`,
  `make test`, or equivalent.
- The test command must be documented — either in the README or in a `Makefile` target.
- Do not require production credentials or external services for unit and integration tests.
  Use mocks, stubs, or test doubles for external dependencies.
- Watch mode or incremental test running should be available for TDD workflows.

## 9. Test Documentation

- The README must document how to run tests and how to view coverage results.
- If the project has multiple test types (unit, integration, e2e), document the command
  for each.
- Document any non-obvious prerequisites for running the test suite (test database setup,
  environment variables, etc.).

## 10. Test Artefact Hygiene

- Generated test artefacts must not be committed to the repository. Add them to `.gitignore`.
- Common artefacts to gitignore:
  - `.coverage` — Python coverage data file
  - `htmlcov/` — Python coverage HTML report
  - `.nyc_output/` — Node.js NYC/Istanbul coverage data
  - `coverage/` — generic coverage output directory
  - `.pytest_cache/` — pytest cache directory
  - `test-results/` — Playwright and other test result directories
  - `junit.xml`, `test-results.xml` — CI test report files
- Committing artefacts bloats the repository, creates spurious diffs, and can expose
  sensitive path or code information in coverage data.

---

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-03-06 | Initial version |
