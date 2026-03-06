#!/usr/bin/env bash
# scripts/maa-backend-python-review.sh
# Run a Python backend Build Review against a project path.
#
# Usage: scripts/maa-backend-python-review.sh <project-path>
#
# Scope: Python backend repository hygiene and tooling baseline.
#        Does NOT run Python tooling (pytest, ruff, mypy, etc.).
#        All detection is filesystem-only: grep, test -f, test -d.
#
# Checks performed:
#   1.  Project definition file (pyproject.toml / requirements.txt / setup.py) — hard gate
#   2.  .gitignore present
#   3.  Framework detection (FastAPI → Django → Flask)
#   4.  Type checking config (mypy / pyright)
#   5.  Linting config (ruff / flake8 / pylint)
#   6.  Formatting config (ruff format / black)
#   7.  Testing setup (pytest + test directory)
#   8.  Dependency lock file (uv.lock / poetry.lock / Pipfile.lock / pdm.lock)
#   9.  Environment template (.env.example / .env.sample / example.env)
#  10.  README present
#
# Output: reports/reviews/YYYY-MM-DD-<project>-backend-python.md

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/skills/review/backend-python-review/templates/review-report.md"
REPORT_DIR="$REPO_ROOT/reports/reviews"
STANDARD_FILE="$REPO_ROOT/standards/backend-python.md"

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: maa review backend-python <project-path>" >&2
  exit 1
fi

PROJECT_PATH="$(cd "$1" 2>/dev/null && pwd)" || {
  echo "Error: project path does not exist or is not accessible: $1" >&2
  exit 1
}

PROJECT_NAME="$(basename "$PROJECT_PATH")"
REVIEW_DATE="$(date +%Y-%m-%d)"
REPORT_SLUG="$(printf '%s' "$PROJECT_NAME" | tr ' /' '--')"
REPORT_FILENAME="${REVIEW_DATE}-${REPORT_SLUG}-backend-python.md"

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

# Extract standard version from the standards file
STANDARD_VERSION="$(grep -m1 '^\*\*Version:\*\*' "$STANDARD_FILE" | sed 's/.*\*\*Version:\*\* *//' | tr -d '[:space:]')"
STANDARD_VERSION="${STANDARD_VERSION:-unknown}"

# ---------------------------------------------------------------------------
# Check 1: Project definition file — HARD GATE
# Determine which project file exists (priority: pyproject.toml > requirements.txt > setup.py).
# Exit if none found — this is not a Python project we can review.
# ---------------------------------------------------------------------------

detect_project_file() {
  local dir="$1"

  if [[ -f "$dir/pyproject.toml" ]]; then
    echo "pyproject.toml"
  elif [[ -f "$dir/requirements.txt" ]]; then
    echo "requirements.txt"
  elif [[ -f "$dir/setup.py" ]]; then
    echo "setup.py"
  else
    echo ""
  fi
}

PROJECT_FILE="$(detect_project_file "$PROJECT_PATH")"

if [[ -z "$PROJECT_FILE" ]]; then
  echo "Error: no Python project definition file found at $PROJECT_PATH" >&2
  echo "Expected one of: pyproject.toml, requirements.txt, setup.py" >&2
  echo "This does not appear to be a Python project." >&2
  exit 1
fi

CHECK_PROJECT_FILE="$PROJECT_FILE"

# ---------------------------------------------------------------------------
# Check 2: .gitignore present
# ---------------------------------------------------------------------------

if [[ -f "$PROJECT_PATH/.gitignore" ]]; then
  CHECK_GITIGNORE="present"
else
  CHECK_GITIGNORE="not detected"
fi

# ---------------------------------------------------------------------------
# Check 3: Framework detection (FastAPI → Django → Flask)
# Searches pyproject.toml and any requirements*.txt files at root.
# ---------------------------------------------------------------------------

detect_framework() {
  local dir="$1"
  local search_files=()

  [[ -f "$dir/pyproject.toml" ]]    && search_files+=("$dir/pyproject.toml")
  [[ -f "$dir/requirements.txt" ]]  && search_files+=("$dir/requirements.txt")
  [[ -f "$dir/requirements-dev.txt" ]] && search_files+=("$dir/requirements-dev.txt")
  [[ -f "$dir/requirements/base.txt" ]] && search_files+=("$dir/requirements/base.txt")
  [[ -f "$dir/Pipfile" ]]           && search_files+=("$dir/Pipfile")

  if [[ ${#search_files[@]} -eq 0 ]]; then
    echo "not detected"
    return
  fi

  if grep -qiE '\bfastapi\b' "${search_files[@]}" 2>/dev/null; then
    echo "detected (FastAPI)"
  elif grep -qiE '\bdjango\b' "${search_files[@]}" 2>/dev/null; then
    echo "detected (Django)"
  elif grep -qiE '\bflask\b' "${search_files[@]}" 2>/dev/null; then
    echo "detected (Flask)"
  else
    echo "not detected"
  fi
}

CHECK_FRAMEWORK="$(detect_framework "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 4: Type checking config (mypy / pyright)
# ---------------------------------------------------------------------------

detect_type_check() {
  local dir="$1"

  # Standalone config files
  for f in .mypy.ini mypy.ini pyrightconfig.json; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  # Section in pyproject.toml
  if [[ -f "$dir/pyproject.toml" ]]; then
    if grep -qE '^\[tool\.mypy\]' "$dir/pyproject.toml" 2>/dev/null; then
      echo "detected ([tool.mypy] in pyproject.toml)"
      return
    fi
    if grep -qE '^\[tool\.pyright\]' "$dir/pyproject.toml" 2>/dev/null; then
      echo "detected ([tool.pyright] in pyproject.toml)"
      return
    fi
  fi

  echo "not detected"
}

CHECK_TYPE_CHECK="$(detect_type_check "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 5: Linting config (ruff / flake8 / pylint)
# ---------------------------------------------------------------------------

detect_linting() {
  local dir="$1"

  # Standalone config files
  for f in ruff.toml .ruff.toml .flake8 .pylintrc; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  # Section in pyproject.toml
  if [[ -f "$dir/pyproject.toml" ]]; then
    if grep -qE '^\[tool\.ruff\]' "$dir/pyproject.toml" 2>/dev/null; then
      echo "detected ([tool.ruff] in pyproject.toml)"
      return
    fi
    if grep -qE '^\[tool\.pylint' "$dir/pyproject.toml" 2>/dev/null; then
      echo "detected ([tool.pylint] in pyproject.toml)"
      return
    fi
  fi

  # setup.cfg with [flake8] section
  if [[ -f "$dir/setup.cfg" ]]; then
    if grep -qE '^\[flake8\]' "$dir/setup.cfg" 2>/dev/null; then
      echo "detected ([flake8] in setup.cfg)"
      return
    fi
  fi

  echo "not detected"
}

CHECK_LINTING="$(detect_linting "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 6: Formatting config (ruff format / black)
# ---------------------------------------------------------------------------

detect_formatting() {
  local dir="$1"

  if [[ -f "$dir/pyproject.toml" ]]; then
    if grep -qE '^\[tool\.ruff\.format\]' "$dir/pyproject.toml" 2>/dev/null; then
      echo "detected (ruff format in pyproject.toml)"
      return
    fi
    if grep -qE '^\[tool\.black\]' "$dir/pyproject.toml" 2>/dev/null; then
      echo "detected (black in pyproject.toml)"
      return
    fi
  fi

  # Standalone black config
  for f in .black .black.toml; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  echo "not detected"
}

CHECK_FORMATTING="$(detect_formatting "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 7: Testing setup (pytest + test directory)
# ---------------------------------------------------------------------------

detect_testing() {
  local dir="$1"
  local found_dir="" found_config="" found_async=""

  # Test directory
  if [[ -d "$dir/tests" ]]; then
    found_dir="tests/"
  elif [[ -d "$dir/test" ]]; then
    found_dir="test/"
  fi

  # pytest config
  if [[ -f "$dir/pytest.ini" ]]; then
    found_config="pytest.ini"
  elif [[ -f "$dir/pyproject.toml" ]] && grep -qE '^\[tool\.pytest' "$dir/pyproject.toml" 2>/dev/null; then
    found_config="pyproject.toml"
  elif [[ -f "$dir/setup.cfg" ]] && grep -qE '^\[tool:pytest\]' "$dir/setup.cfg" 2>/dev/null; then
    found_config="setup.cfg"
  fi

  # Async test support
  if [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/requirements.txt" ]]; then
    local req_files=()
    [[ -f "$dir/pyproject.toml" ]]   && req_files+=("$dir/pyproject.toml")
    [[ -f "$dir/requirements.txt" ]] && req_files+=("$dir/requirements.txt")
    [[ -f "$dir/requirements-dev.txt" ]] && req_files+=("$dir/requirements-dev.txt")
    if grep -qiE 'pytest-anyio|pytest-asyncio' "${req_files[@]}" 2>/dev/null; then
      found_async=" + async support"
    fi
  fi

  if [[ -n "$found_dir" && -n "$found_config" ]]; then
    echo "detected ($found_dir, config in $found_config$found_async)"
  elif [[ -n "$found_dir" ]]; then
    echo "partial ($found_dir found, no pytest config$found_async)"
  elif [[ -n "$found_config" ]]; then
    echo "partial (pytest config in $found_config, no test directory$found_async)"
  else
    echo "not detected"
  fi
}

CHECK_TESTING="$(detect_testing "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 8: Dependency lock file
# ---------------------------------------------------------------------------

detect_lock_file() {
  local dir="$1"

  for f in uv.lock poetry.lock Pipfile.lock pdm.lock; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  echo "not detected"
}

CHECK_LOCK_FILE="$(detect_lock_file "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 9: Environment template
# ---------------------------------------------------------------------------

detect_env_template() {
  local dir="$1"

  for f in .env.example .env.sample example.env env.example; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  echo "not detected"
}

CHECK_ENV_TEMPLATE="$(detect_env_template "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 10: README
# ---------------------------------------------------------------------------

if [[ -f "$PROJECT_PATH/README.md" ]] || [[ -f "$PROJECT_PATH/README.rst" ]] || [[ -f "$PROJECT_PATH/README" ]]; then
  CHECK_README="present"
else
  CHECK_README="not detected"
fi

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
  -e "s|{{CHECK_PROJECT_FILE}}|$(escape_sed "$CHECK_PROJECT_FILE")|g" \
  -e "s|{{CHECK_GITIGNORE}}|$(escape_sed "$CHECK_GITIGNORE")|g" \
  -e "s|{{CHECK_FRAMEWORK}}|$(escape_sed "$CHECK_FRAMEWORK")|g" \
  -e "s|{{CHECK_TYPE_CHECK}}|$(escape_sed "$CHECK_TYPE_CHECK")|g" \
  -e "s|{{CHECK_LINTING}}|$(escape_sed "$CHECK_LINTING")|g" \
  -e "s|{{CHECK_FORMATTING}}|$(escape_sed "$CHECK_FORMATTING")|g" \
  -e "s|{{CHECK_TESTING}}|$(escape_sed "$CHECK_TESTING")|g" \
  -e "s|{{CHECK_LOCK_FILE}}|$(escape_sed "$CHECK_LOCK_FILE")|g" \
  -e "s|{{CHECK_ENV_TEMPLATE}}|$(escape_sed "$CHECK_ENV_TEMPLATE")|g" \
  -e "s|{{CHECK_README}}|$(escape_sed "$CHECK_README")|g" \
  "$TEMPLATE" > "$REPORT_PATH"

# ---------------------------------------------------------------------------
# Summary output
# ---------------------------------------------------------------------------

echo ""
echo "MAA Backend Review — Python"
echo "==========================="
echo "Project:  $PROJECT_NAME"
echo "Path:     $PROJECT_PATH"
echo "Date:     $REVIEW_DATE"
echo ""
echo "Signals detected:"
echo "  Project definition   : $CHECK_PROJECT_FILE"
echo "  .gitignore           : $CHECK_GITIGNORE"
echo "  Framework            : $CHECK_FRAMEWORK"
echo "  Type checking        : $CHECK_TYPE_CHECK"
echo "  Linting              : $CHECK_LINTING"
echo "  Formatting           : $CHECK_FORMATTING"
echo "  Testing              : $CHECK_TESTING"
echo "  Lock file            : $CHECK_LOCK_FILE"
echo "  Env template         : $CHECK_ENV_TEMPLATE"
echo "  README               : $CHECK_README"
echo ""
echo "Report saved to:"
echo "  $REPORT_PATH"
echo ""
echo "Next: open the report, fill in the manual findings section, then commit it."
