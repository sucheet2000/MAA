#!/usr/bin/env bash
# scripts/maa-review.sh
# Run a frontend standards review against a project path.
#
# Usage: scripts/maa-review.sh <project-path>
#
# Checks performed (all via bash/grep — no jq, Python, or Node required):
#   1. package.json exists
#   2. src/ directory exists
#   3. public/ directory exists (informational)
#   4. Framework signal: React, Next.js, or Vite
#   5. Linting: ESLint config file, eslint dependency, or eslintConfig key in package.json
#   6. Formatting: Prettier config or prettier in package.json
#   7. Testing: test script in package.json or common test config files
#   8. README.md present
#   9. .gitignore present
#
# Output: reports/reviews/YYYY-MM-DD-<project>-frontend.md

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/skills/review/frontend-review/templates/review-report.md"
REPORT_DIR="$REPO_ROOT/reports/reviews"
STANDARD_FILE="$REPO_ROOT/standards/frontend.md"

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: maa review frontend <project-path>" >&2
  exit 1
fi

PROJECT_PATH="$(cd "$1" 2>/dev/null && pwd)" || {
  echo "Error: project path does not exist or is not accessible: $1" >&2
  exit 1
}

PROJECT_NAME="$(basename "$PROJECT_PATH")"
REVIEW_DATE="$(date +%Y-%m-%d)"
REPORT_SLUG="$(printf '%s' "$PROJECT_NAME" | tr ' /' '--')"
REPORT_FILENAME="${REVIEW_DATE}-${REPORT_SLUG}-frontend.md"

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

# Extract standard version from the standards file (line containing "Version:")
STANDARD_VERSION="$(grep -m1 '^\*\*Version:\*\*' "$STANDARD_FILE" | sed 's/.*\*\*Version:\*\* *//' | tr -d '[:space:]')"
STANDARD_VERSION="${STANDARD_VERSION:-unknown}"

# ---------------------------------------------------------------------------
# Check: package.json (required)
# ---------------------------------------------------------------------------

if [[ -f "$PROJECT_PATH/package.json" ]]; then
  CHECK_PACKAGE_JSON="present"
else
  echo "Error: package.json not found in $PROJECT_PATH — not a Node-based frontend project." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Check: src/ directory
# ---------------------------------------------------------------------------

if [[ -d "$PROJECT_PATH/src" ]]; then
  CHECK_SRC_DIR="present"
else
  CHECK_SRC_DIR="not detected"
fi

# ---------------------------------------------------------------------------
# Check: public/ directory (informational)
# ---------------------------------------------------------------------------

if [[ -d "$PROJECT_PATH/public" ]]; then
  CHECK_PUBLIC_DIR="present"
else
  CHECK_PUBLIC_DIR="not detected"
fi

# ---------------------------------------------------------------------------
# Check: framework signal
# Grep package.json for react, next, vite — no jq needed.
# We read the file as plain text; grep matches dependency names.
# ---------------------------------------------------------------------------

PKG="$PROJECT_PATH/package.json"

detect_framework() {
  local pkg="$1"

  # Next.js check first — it implies React, so it's more specific
  if grep -q '"next"' "$pkg" 2>/dev/null; then
    echo "Next.js"
    return
  fi

  # Vite check
  if grep -q '"vite"' "$pkg" 2>/dev/null; then
    # Distinguish Vite + React vs plain Vite
    if grep -q '"react"' "$pkg" 2>/dev/null || grep -q '"@vitejs/plugin-react"' "$pkg" 2>/dev/null; then
      echo "React + Vite"
    else
      echo "Vite"
    fi
    return
  fi

  # React check (CRA or standalone)
  if grep -q '"react"' "$pkg" 2>/dev/null; then
    echo "React"
    return
  fi

  echo "not detected"
}

CHECK_FRAMEWORK="$(detect_framework "$PKG")"

# ---------------------------------------------------------------------------
# Check: linting signal
# ESLint config files or eslint in package.json dependencies
# ---------------------------------------------------------------------------

detect_linting() {
  local dir="$1"
  local pkg="$2"

  # Config files
  for f in .eslintrc .eslintrc.js .eslintrc.cjs .eslintrc.mjs .eslintrc.json .eslintrc.yaml .eslintrc.yml eslint.config.js eslint.config.mjs eslint.config.cjs; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  # eslint as a dependency in package.json
  if grep -q '"eslint"' "$pkg" 2>/dev/null; then
    echo "detected (package.json)"
    return
  fi

  # eslintConfig key in package.json — CRA and some other setups configure
  # ESLint inline rather than in a standalone config file
  if grep -q '"eslintConfig"' "$pkg" 2>/dev/null; then
    echo "detected (eslintConfig in package.json)"
    return
  fi

  echo "not detected"
}

CHECK_LINTING="$(detect_linting "$PROJECT_PATH" "$PKG")"

# ---------------------------------------------------------------------------
# Check: formatting signal
# Prettier config files or prettier in package.json
# ---------------------------------------------------------------------------

detect_formatting() {
  local dir="$1"
  local pkg="$2"

  for f in .prettierrc .prettierrc.js .prettierrc.cjs .prettierrc.mjs .prettierrc.json .prettierrc.yaml .prettierrc.yml prettier.config.js prettier.config.cjs prettier.config.mjs; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  if grep -q '"prettier"' "$pkg" 2>/dev/null; then
    echo "detected (package.json)"
    return
  fi

  echo "not detected"
}

CHECK_FORMATTING="$(detect_formatting "$PROJECT_PATH" "$PKG")"

# ---------------------------------------------------------------------------
# Check: testing signal
# Test script in package.json or presence of common test config files
# ---------------------------------------------------------------------------

detect_testing() {
  local dir="$1"
  local pkg="$2"

  # Config files for common test frameworks
  for f in jest.config.js jest.config.ts jest.config.cjs jest.config.mjs vitest.config.js vitest.config.ts vitest.config.mjs playwright.config.js playwright.config.ts cypress.config.js cypress.config.ts; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  # "test" script in package.json scripts section
  # Heuristic: look for "test" key near "scripts" block
  if grep -q '"test"' "$pkg" 2>/dev/null; then
    echo "detected (test script in package.json)"
    return
  fi

  # Dependencies: jest, vitest, playwright, cypress
  for dep in '"jest"' '"vitest"' '"@playwright/test"' '"cypress"'; do
    if grep -q "$dep" "$pkg" 2>/dev/null; then
      echo "detected (dependency in package.json)"
      return
    fi
  done

  echo "not detected"
}

CHECK_TESTING="$(detect_testing "$PROJECT_PATH" "$PKG")"

# ---------------------------------------------------------------------------
# Check: dependency lock file
# ---------------------------------------------------------------------------

detect_lock_file() {
  local dir="$1"

  for f in package-lock.json yarn.lock pnpm-lock.yaml; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  echo "not detected"
}

CHECK_LOCK_FILE="$(detect_lock_file "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check: env example file (.env.example, .env.sample, example.env)
# ---------------------------------------------------------------------------

detect_env_example() {
  local dir="$1"

  for f in .env.example .env.sample example.env; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  echo "not detected"
}

CHECK_ENV_EXAMPLE="$(detect_env_example "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check: README.md
# ---------------------------------------------------------------------------

if [[ -f "$PROJECT_PATH/README.md" ]] || [[ -f "$PROJECT_PATH/readme.md" ]]; then
  CHECK_README="present"
else
  CHECK_README="not detected"
fi

# ---------------------------------------------------------------------------
# Check: .gitignore
# ---------------------------------------------------------------------------

if [[ -f "$PROJECT_PATH/.gitignore" ]]; then
  CHECK_GITIGNORE="present"
else
  CHECK_GITIGNORE="not detected"
fi

# ---------------------------------------------------------------------------
# Check: TypeScript signal
# standards/frontend.md §3 — TypeScript is the default.
# Check for tsconfig.json first; fall back to tsconfig.base.json (monorepos).
# ---------------------------------------------------------------------------

if [[ -f "$PROJECT_PATH/tsconfig.json" ]]; then
  CHECK_TYPESCRIPT="detected (tsconfig.json)"
elif [[ -f "$PROJECT_PATH/tsconfig.base.json" ]]; then
  CHECK_TYPESCRIPT="detected (tsconfig.base.json)"
else
  CHECK_TYPESCRIPT="not detected"
fi

# ---------------------------------------------------------------------------
# Render the report
# Replace {{PLACEHOLDER}} tokens in the template with check results.
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
# In sed s|pattern|replacement|g, three chars are special in the replacement:
#   &  → expands to the matched text   → must become \&
#   \  → starts an escape sequence     → must become \\
#   |  → the delimiter we chose        → must become \|
# Escape \ first so later substitutions don't double-escape it.
escape_sed() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/[&|]/\\&/g'
}

sed \
  -e "s|{{PROJECT_NAME}}|$(escape_sed "$PROJECT_NAME")|g" \
  -e "s|{{PROJECT_PATH}}|$(escape_sed "$PROJECT_PATH")|g" \
  -e "s|{{REVIEW_DATE}}|$REVIEW_DATE|g" \
  -e "s|{{STANDARD_VERSION}}|$(escape_sed "$STANDARD_VERSION")|g" \
  -e "s|{{CHECK_PACKAGE_JSON}}|$(escape_sed "$CHECK_PACKAGE_JSON")|g" \
  -e "s|{{CHECK_SRC_DIR}}|$(escape_sed "$CHECK_SRC_DIR")|g" \
  -e "s|{{CHECK_PUBLIC_DIR}}|$(escape_sed "$CHECK_PUBLIC_DIR")|g" \
  -e "s|{{CHECK_FRAMEWORK}}|$(escape_sed "$CHECK_FRAMEWORK")|g" \
  -e "s|{{CHECK_LINTING}}|$(escape_sed "$CHECK_LINTING")|g" \
  -e "s|{{CHECK_FORMATTING}}|$(escape_sed "$CHECK_FORMATTING")|g" \
  -e "s|{{CHECK_TESTING}}|$(escape_sed "$CHECK_TESTING")|g" \
  -e "s|{{CHECK_README}}|$(escape_sed "$CHECK_README")|g" \
  -e "s|{{CHECK_GITIGNORE}}|$(escape_sed "$CHECK_GITIGNORE")|g" \
  -e "s|{{CHECK_TYPESCRIPT}}|$(escape_sed "$CHECK_TYPESCRIPT")|g" \
  -e "s|{{CHECK_LOCK_FILE}}|$(escape_sed "$CHECK_LOCK_FILE")|g" \
  -e "s|{{CHECK_ENV_EXAMPLE}}|$(escape_sed "$CHECK_ENV_EXAMPLE")|g" \
  "$TEMPLATE" > "$REPORT_PATH"

# ---------------------------------------------------------------------------
# Summary output
# ---------------------------------------------------------------------------

echo ""
echo "MAA Frontend Review"
echo "==================="
echo "Project:  $PROJECT_NAME"
echo "Path:     $PROJECT_PATH"
echo "Date:     $REVIEW_DATE"
echo ""
echo "Signals detected:"
echo "  package.json     : $CHECK_PACKAGE_JSON"
echo "  src/             : $CHECK_SRC_DIR"
echo "  public/          : $CHECK_PUBLIC_DIR"
echo "  Framework        : $CHECK_FRAMEWORK"
echo "  Linting          : $CHECK_LINTING"
echo "  Formatting       : $CHECK_FORMATTING"
echo "  Testing          : $CHECK_TESTING"
echo "  TypeScript       : $CHECK_TYPESCRIPT"
echo "  Lock file        : $CHECK_LOCK_FILE"
echo "  Env example      : $CHECK_ENV_EXAMPLE"
echo "  README.md        : $CHECK_README"
echo "  .gitignore       : $CHECK_GITIGNORE"
echo ""
echo "Report saved to:"
echo "  $REPORT_PATH"
echo ""
echo "Next: open the report, fill in the manual findings section, then commit it."
