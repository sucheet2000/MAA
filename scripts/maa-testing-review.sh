#!/usr/bin/env bash
# scripts/maa-testing-review.sh
# Run a cross-cutting testing hygiene review against a project path.
#
# Usage: scripts/maa-testing-review.sh <project-path>
#
# Scope: Cross-cutting testing discipline and hygiene signals.
#        Complements ecosystem reviews (frontend, backend-node, backend-python)
#        which check for test presence. This review checks for testing maturity.
#        All detection is filesystem-only: grep, test -f, test -d, find.
#        No hard gate — absence of signals is itself a reportable finding.
#
# Checks performed:
#   1.  Test directory present (tests/, test/, __tests__/, spec/)
#   2.  Test runner configuration file
#   3.  Coverage configuration
#   4.  Coverage threshold enforcement
#   5.  CI pipeline runs tests (.github/workflows/)
#   6.  Integration or E2E test evidence
#   7.  Test fixtures, helpers, or mocks
#   8.  Test run command defined (package.json, Makefile, tox.ini)
#   9.  README documents test commands
#  10.  Coverage/test artifacts gitignored
#
# Output: reports/reviews/YYYY-MM-DD-<project>-testing.md

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/skills/review/testing-review/templates/review-report.md"
REPORT_DIR="$REPO_ROOT/reports/reviews"
STANDARD_FILE="$REPO_ROOT/standards/testing.md"

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: maa review testing <project-path>" >&2
  exit 1
fi

PROJECT_PATH="$(cd "$1" 2>/dev/null && pwd)" || {
  echo "Error: project path does not exist or is not accessible: $1" >&2
  exit 1
}

PROJECT_NAME="$(basename "$PROJECT_PATH")"
REVIEW_DATE="$(date +%Y-%m-%d)"
REPORT_SLUG="$(printf '%s' "$PROJECT_NAME" | tr ' /' '--')"
REPORT_FILENAME="${REVIEW_DATE}-${REPORT_SLUG}-testing.md"

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: report template not found at $TEMPLATE" >&2
  exit 1
fi

if [[ ! -f "$STANDARD_FILE" ]]; then
  echo "Error: standards file not found at $STANDARD_FILE" >&2
  exit 1
fi

# Extract standard version
STANDARD_VERSION="$(grep -m1 '^\*\*Version:\*\*' "$STANDARD_FILE" | sed 's/.*\*\*Version:\*\* *//' | tr -d '[:space:]')"
STANDARD_VERSION="${STANDARD_VERSION:-unknown}"

# ---------------------------------------------------------------------------
# Check 1: Test directory at project root
# ---------------------------------------------------------------------------

detect_test_dir() {
  local dir="$1"
  local found=""

  for d in tests test __tests__ spec; do
    if [[ -d "$dir/$d" ]]; then
      found="${found:+$found, }$d/"
    fi
  done

  if [[ -n "$found" ]]; then
    echo "detected ($found)"
  else
    echo "not detected"
  fi
}

CHECK_TEST_DIR="$(detect_test_dir "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 2: Test runner configuration file
# ---------------------------------------------------------------------------

detect_test_config() {
  local dir="$1"

  # Node test runners — check common config filenames
  for f in \
    jest.config.js jest.config.ts jest.config.cjs jest.config.mjs \
    vitest.config.js vitest.config.ts \
    .mocharc.js .mocharc.yaml .mocharc.yml .mocharc.json; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  # Python
  if [[ -f "$dir/pytest.ini" ]]; then
    echo "detected (pytest.ini)"
    return
  fi

  if [[ -f "$dir/pyproject.toml" ]] && grep -qE '^\[tool\.pytest' "$dir/pyproject.toml" 2>/dev/null; then
    echo "detected ([tool.pytest.ini_options] in pyproject.toml)"
    return
  fi

  if [[ -f "$dir/setup.cfg" ]] && grep -qE '^\[tool:pytest\]' "$dir/setup.cfg" 2>/dev/null; then
    echo "detected ([tool:pytest] in setup.cfg)"
    return
  fi

  echo "not detected"
}

CHECK_TEST_CONFIG="$(detect_test_config "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 3: Coverage configuration
# ---------------------------------------------------------------------------

detect_coverage_config() {
  local dir="$1"

  # Python coverage
  if [[ -f "$dir/.coveragerc" ]]; then
    echo "detected (.coveragerc)"
    return
  fi

  if [[ -f "$dir/pyproject.toml" ]] && grep -qE '^\[tool\.coverage' "$dir/pyproject.toml" 2>/dev/null; then
    echo "detected ([tool.coverage] in pyproject.toml)"
    return
  fi

  # Node / Istanbul / NYC
  for f in .nycrc .nycrc.json; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  # Coverage key in jest config
  for f in jest.config.js jest.config.ts jest.config.cjs jest.config.mjs; do
    if [[ -f "$dir/$f" ]]; then
      if grep -qE 'collectCoverage|coverageDirectory' "$dir/$f" 2>/dev/null; then
        echo "detected (coverage config in $f)"
        return
      fi
    fi
  done

  echo "not detected"
}

CHECK_COVERAGE_CONFIG="$(detect_coverage_config "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 4: Coverage threshold enforcement
# ---------------------------------------------------------------------------

detect_coverage_threshold() {
  local dir="$1"

  # Python: fail_under in .coveragerc or pyproject.toml
  if [[ -f "$dir/.coveragerc" ]] && grep -qE 'fail_under' "$dir/.coveragerc" 2>/dev/null; then
    echo "detected (fail_under in .coveragerc)"
    return
  fi

  if [[ -f "$dir/pyproject.toml" ]] && grep -qE 'fail_under' "$dir/pyproject.toml" 2>/dev/null; then
    echo "detected (fail_under in pyproject.toml)"
    return
  fi

  # Jest: coverageThreshold
  for f in jest.config.js jest.config.ts jest.config.cjs jest.config.mjs; do
    if [[ -f "$dir/$f" ]] && grep -qE 'coverageThreshold' "$dir/$f" 2>/dev/null; then
      echo "detected (coverageThreshold in $f)"
      return
    fi
  done

  # Vitest: coverage.thresholds
  for f in vitest.config.js vitest.config.ts; do
    if [[ -f "$dir/$f" ]] && grep -qE 'thresholds' "$dir/$f" 2>/dev/null; then
      echo "detected (thresholds in $f)"
      return
    fi
  done

  echo "not detected"
}

CHECK_COVERAGE_THRESHOLD="$(detect_coverage_threshold "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 5: CI pipeline runs tests
# ---------------------------------------------------------------------------

detect_ci_tests() {
  local dir="$1"
  local workflows_dir="$dir/.github/workflows"

  if [[ ! -d "$workflows_dir" ]]; then
    echo "not checked (no .github/workflows directory found)"
    return
  fi

  local matching_files=""
  local wf_file

  # Search each workflow file for test invocations
  while IFS= read -r wf_file; do
    if grep -qE 'pytest|jest|vitest|npm test|npm run test|yarn test|pnpm test|cargo test|go test|bundle exec rspec' \
      "$wf_file" 2>/dev/null; then
      local fname
      fname="$(basename "$wf_file")"
      matching_files="${matching_files:+$matching_files, }$fname"
    fi
  done < <(find "$workflows_dir" -maxdepth 1 \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null)

  if [[ -n "$matching_files" ]]; then
    echo "detected ($matching_files)"
  else
    echo "not detected (workflow files present but no test commands found)"
  fi
}

CHECK_CI_TESTS="$(detect_ci_tests "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 6: Integration or E2E test evidence
# ---------------------------------------------------------------------------

detect_test_breadth() {
  local dir="$1"
  local found=""

  # Integration test directories
  for d in tests/integration test/integration integration; do
    if [[ -d "$dir/$d" ]]; then
      found="${found:+$found, }$d/"
    fi
  done

  # E2E test directories
  for d in tests/e2e test/e2e e2e; do
    if [[ -d "$dir/$d" ]]; then
      found="${found:+$found, }$d/"
    fi
  done

  # Playwright
  for f in playwright.config.js playwright.config.ts; do
    if [[ -f "$dir/$f" ]]; then
      found="${found:+$found, }$f"
    fi
  done

  # Cypress
  for f in cypress.config.js cypress.config.ts; do
    if [[ -f "$dir/$f" ]]; then
      found="${found:+$found, }$f"
    fi
  done

  if [[ -n "$found" ]]; then
    echo "detected ($found)"
  else
    echo "not detected"
  fi
}

CHECK_TEST_BREADTH="$(detect_test_breadth "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 7: Test fixtures, helpers, or mocks
# ---------------------------------------------------------------------------

detect_test_fixtures() {
  local dir="$1"
  local found=""

  # Python conftest
  for f in conftest.py tests/conftest.py test/conftest.py; do
    if [[ -f "$dir/$f" ]]; then
      found="${found:+$found, }$f"
    fi
  done

  # Fixture / helper / factory / mock directories
  for d in tests/fixtures test/fixtures tests/helpers test/helpers \
            tests/factories test/factories __mocks__ test/mocks tests/mocks; do
    if [[ -d "$dir/$d" ]]; then
      found="${found:+$found, }$d/"
    fi
  done

  if [[ -n "$found" ]]; then
    echo "detected ($found)"
  else
    echo "not detected"
  fi
}

CHECK_TEST_FIXTURES="$(detect_test_fixtures "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 8: Test run command defined
# ---------------------------------------------------------------------------

detect_test_script() {
  local dir="$1"

  # package.json "test" script
  if [[ -f "$dir/package.json" ]] && grep -qE '"test"\s*:' "$dir/package.json" 2>/dev/null; then
    echo "detected (\"test\" script in package.json)"
    return
  fi

  # Makefile test target
  if [[ -f "$dir/Makefile" ]] && grep -qE '^test\s*:' "$dir/Makefile" 2>/dev/null; then
    echo "detected (test target in Makefile)"
    return
  fi

  # tox.ini
  if [[ -f "$dir/tox.ini" ]]; then
    echo "detected (tox.ini)"
    return
  fi

  echo "not detected"
}

CHECK_TEST_SCRIPT="$(detect_test_script "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 9: README documents test commands
# ---------------------------------------------------------------------------

detect_test_docs() {
  local dir="$1"

  for f in README.md README.rst README; do
    if [[ -f "$dir/$f" ]]; then
      if grep -qiE 'pytest|jest|vitest|npm test|yarn test|pnpm test|make test' "$dir/$f" 2>/dev/null; then
        echo "detected ($f mentions tests)"
      else
        echo "not detected ($f present but no test commands mentioned)"
      fi
      return
    fi
  done

  echo "not checked (no README found)"
}

CHECK_TEST_DOCS="$(detect_test_docs "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 10: Coverage/test artifacts are gitignored
# Report which common artifact patterns are covered and which are missing.
# ---------------------------------------------------------------------------

detect_artifacts_gitignored() {
  local dir="$1"

  if [[ ! -f "$dir/.gitignore" ]]; then
    echo "not checked (no .gitignore found)"
    return
  fi

  local covered="" missing=""
  local artifacts=(".coverage" "htmlcov/" ".nyc_output/" "coverage/" ".pytest_cache/" "test-results/")

  for artifact in "${artifacts[@]}"; do
    # Strip trailing slash for grep — gitignore entries may appear with or without it
    local pattern="${artifact%/}"
    if grep -qE "(^|/)${pattern}(/|$)" "$dir/.gitignore" 2>/dev/null; then
      covered="${covered:+$covered, }$artifact"
    else
      missing="${missing:+$missing, }$artifact"
    fi
  done

  if [[ -z "$missing" ]]; then
    echo "all covered ($covered)"
  elif [[ -z "$covered" ]]; then
    echo "not detected (none of the common patterns found)"
  else
    echo "partial (covered: $covered | missing: $missing)"
  fi
}

CHECK_ARTIFACTS_GITIGNORED="$(detect_artifacts_gitignored "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Render the report
# ---------------------------------------------------------------------------

mkdir -p "$REPORT_DIR"
REPORT_PATH="$REPORT_DIR/$REPORT_FILENAME"

# Guard: do not silently overwrite a report that may already have manual notes.
if [[ -f "$REPORT_PATH" ]]; then
  echo "Error: a report already exists for today:" >&2
  echo "  $REPORT_PATH" >&2
  echo "Delete or rename the existing report first, then re-run." >&2
  exit 1
fi

# Escape values for safe use in sed replacement strings.
escape_sed() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/[&|]/\\&/g'
}

sed \
  -e "s|{{PROJECT_NAME}}|$(escape_sed "$PROJECT_NAME")|g" \
  -e "s|{{PROJECT_PATH}}|$(escape_sed "$PROJECT_PATH")|g" \
  -e "s|{{REVIEW_DATE}}|$REVIEW_DATE|g" \
  -e "s|{{STANDARD_VERSION}}|$(escape_sed "$STANDARD_VERSION")|g" \
  -e "s|{{CHECK_TEST_DIR}}|$(escape_sed "$CHECK_TEST_DIR")|g" \
  -e "s|{{CHECK_TEST_CONFIG}}|$(escape_sed "$CHECK_TEST_CONFIG")|g" \
  -e "s|{{CHECK_COVERAGE_CONFIG}}|$(escape_sed "$CHECK_COVERAGE_CONFIG")|g" \
  -e "s|{{CHECK_COVERAGE_THRESHOLD}}|$(escape_sed "$CHECK_COVERAGE_THRESHOLD")|g" \
  -e "s|{{CHECK_CI_TESTS}}|$(escape_sed "$CHECK_CI_TESTS")|g" \
  -e "s|{{CHECK_TEST_BREADTH}}|$(escape_sed "$CHECK_TEST_BREADTH")|g" \
  -e "s|{{CHECK_TEST_FIXTURES}}|$(escape_sed "$CHECK_TEST_FIXTURES")|g" \
  -e "s|{{CHECK_TEST_SCRIPT}}|$(escape_sed "$CHECK_TEST_SCRIPT")|g" \
  -e "s|{{CHECK_TEST_DOCS}}|$(escape_sed "$CHECK_TEST_DOCS")|g" \
  -e "s|{{CHECK_ARTIFACTS_GITIGNORED}}|$(escape_sed "$CHECK_ARTIFACTS_GITIGNORED")|g" \
  "$TEMPLATE" > "$REPORT_PATH"

# ---------------------------------------------------------------------------
# Summary output
# ---------------------------------------------------------------------------

echo ""
echo "MAA Testing Review"
echo "=================="
echo "Project:  $PROJECT_NAME"
echo "Path:     $PROJECT_PATH"
echo "Date:     $REVIEW_DATE"
echo ""
echo "Signals detected:"
echo "  Test directory       : $CHECK_TEST_DIR"
echo "  Test runner config   : $CHECK_TEST_CONFIG"
echo "  Coverage config      : $CHECK_COVERAGE_CONFIG"
echo "  Coverage threshold   : $CHECK_COVERAGE_THRESHOLD"
echo "  CI test automation   : $CHECK_CI_TESTS"
echo "  Test breadth         : $CHECK_TEST_BREADTH"
echo "  Test fixtures        : $CHECK_TEST_FIXTURES"
echo "  Test run command     : $CHECK_TEST_SCRIPT"
echo "  README test docs     : $CHECK_TEST_DOCS"
echo "  Artifacts gitignored : $CHECK_ARTIFACTS_GITIGNORED"
echo ""
echo "Report saved to:"
echo "  $REPORT_PATH"
echo ""
echo "Next: open the report, fill in the manual findings section, then commit it."
