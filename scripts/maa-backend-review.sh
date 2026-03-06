#!/usr/bin/env bash
# scripts/maa-backend-review.sh
# Run a Node.js backend standards review against a project path.
#
# Usage: scripts/maa-backend-review.sh <project-path>
#
# Scope: Node.js backends only. Requires package.json.
#        Python, Go, Java, and other backend ecosystems are not supported yet.
#
# Checks performed (all via bash/grep — no jq, Python, or Node required):
#   1. package.json exists (required — exits if missing)
#   2. Entry directory: src/, server/, or app/
#   3. Framework signal: NestJS, Fastify, or Express
#   4. TypeScript: tsconfig.json or tsconfig.base.json
#   5. Linting: ESLint config file, eslint dependency, or eslintConfig key
#   6. Formatting: Prettier config or prettier in package.json
#   7. Testing: test config files, test script, or test dependencies
#   8. Env example: .env.example, .env.sample, or example.env
#   9. README.md present
#  10. .gitignore present
#
# Output: reports/reviews/YYYY-MM-DD-<project>-backend-node.md

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/skills/review/backend-node-review/templates/review-report.md"
REPORT_DIR="$REPO_ROOT/reports/reviews"
STANDARD_FILE="$REPO_ROOT/standards/backend-node.md"

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: maa review backend <project-path>" >&2
  exit 1
fi

PROJECT_PATH="$(cd "$1" 2>/dev/null && pwd)" || {
  echo "Error: project path does not exist or is not accessible: $1" >&2
  exit 1
}

PROJECT_NAME="$(basename "$PROJECT_PATH")"
REVIEW_DATE="$(date +%Y-%m-%d)"
REPORT_FILENAME="${REVIEW_DATE}-${PROJECT_NAME}-backend-node.md"

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

PKG="$PROJECT_PATH/package.json"

if [[ -f "$PKG" ]]; then
  CHECK_PACKAGE_JSON="present"
else
  echo "Error: package.json not found in $PROJECT_PATH — not a Node.js project." >&2
  echo "Note: this skill only supports Node.js backends. Python, Go, and Java are not yet supported." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Check: entry directory (src/, server/, or app/)
# ---------------------------------------------------------------------------

detect_entry_dir() {
  local dir="$1"
  local found=""

  for d in src server app; do
    if [[ -d "$dir/$d" ]]; then
      found="${found:+$found, }${d}/"
    fi
  done

  echo "${found:-not detected}"
}

CHECK_ENTRY_DIR="$(detect_entry_dir "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check: framework signal
# NestJS first (most specific — implies full framework), then Fastify, then Express.
# ---------------------------------------------------------------------------

detect_framework() {
  local pkg="$1"

  if grep -q '"@nestjs/core"' "$pkg" 2>/dev/null; then
    echo "NestJS"
    return
  fi

  if grep -q '"fastify"' "$pkg" 2>/dev/null; then
    echo "Fastify"
    return
  fi

  if grep -q '"express"' "$pkg" 2>/dev/null; then
    echo "Express"
    return
  fi

  echo "not detected"
}

CHECK_FRAMEWORK="$(detect_framework "$PKG")"

# ---------------------------------------------------------------------------
# Check: TypeScript signal
# standards/backend-node.md §3 — TypeScript is the default.
# ---------------------------------------------------------------------------

if [[ -f "$PROJECT_PATH/tsconfig.json" ]]; then
  CHECK_TYPESCRIPT="detected (tsconfig.json)"
elif [[ -f "$PROJECT_PATH/tsconfig.base.json" ]]; then
  CHECK_TYPESCRIPT="detected (tsconfig.base.json)"
else
  CHECK_TYPESCRIPT="not detected"
fi

# ---------------------------------------------------------------------------
# Check: linting signal
# ESLint config files, eslint dependency, or eslintConfig key in package.json
# ---------------------------------------------------------------------------

detect_linting() {
  local dir="$1"
  local pkg="$2"

  for f in .eslintrc .eslintrc.js .eslintrc.cjs .eslintrc.mjs .eslintrc.json .eslintrc.yaml .eslintrc.yml eslint.config.js eslint.config.mjs eslint.config.cjs; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  if grep -q '"eslint"' "$pkg" 2>/dev/null; then
    echo "detected (package.json)"
    return
  fi

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
# Test config files, test script in package.json, or test dependencies.
# Includes supertest as a backend-specific integration testing signal.
# ---------------------------------------------------------------------------

detect_testing() {
  local dir="$1"
  local pkg="$2"

  for f in jest.config.js jest.config.ts jest.config.cjs jest.config.mjs vitest.config.js vitest.config.ts vitest.config.mjs; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  for dep in '"jest"' '"vitest"' '"supertest"'; do
    if grep -q "$dep" "$pkg" 2>/dev/null; then
      echo "detected (dependency in package.json)"
      return
    fi
  done

  if grep -q '"test"' "$pkg" 2>/dev/null; then
    echo "detected (test script in package.json)"
    return
  fi

  echo "not detected"
}

CHECK_TESTING="$(detect_testing "$PROJECT_PATH" "$PKG")"

# ---------------------------------------------------------------------------
# Check: env example signal
# .env.example, .env.sample, or example.env
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

ESC_PROJECT_NAME="$(escape_sed "$PROJECT_NAME")"
ESC_PROJECT_PATH="$(escape_sed "$PROJECT_PATH")"
ESC_STANDARD_VERSION="$(escape_sed "$STANDARD_VERSION")"

sed \
  -e "s|{{PROJECT_NAME}}|$ESC_PROJECT_NAME|g" \
  -e "s|{{PROJECT_PATH}}|$ESC_PROJECT_PATH|g" \
  -e "s|{{REVIEW_DATE}}|$REVIEW_DATE|g" \
  -e "s|{{STANDARD_VERSION}}|$ESC_STANDARD_VERSION|g" \
  -e "s|{{CHECK_PACKAGE_JSON}}|$CHECK_PACKAGE_JSON|g" \
  -e "s|{{CHECK_ENTRY_DIR}}|$CHECK_ENTRY_DIR|g" \
  -e "s|{{CHECK_FRAMEWORK}}|$CHECK_FRAMEWORK|g" \
  -e "s|{{CHECK_TYPESCRIPT}}|$CHECK_TYPESCRIPT|g" \
  -e "s|{{CHECK_LINTING}}|$CHECK_LINTING|g" \
  -e "s|{{CHECK_FORMATTING}}|$CHECK_FORMATTING|g" \
  -e "s|{{CHECK_TESTING}}|$CHECK_TESTING|g" \
  -e "s|{{CHECK_ENV_EXAMPLE}}|$CHECK_ENV_EXAMPLE|g" \
  -e "s|{{CHECK_README}}|$CHECK_README|g" \
  -e "s|{{CHECK_GITIGNORE}}|$CHECK_GITIGNORE|g" \
  "$TEMPLATE" > "$REPORT_PATH"

# ---------------------------------------------------------------------------
# Summary output
# ---------------------------------------------------------------------------

echo ""
echo "MAA Backend Review (Node.js)"
echo "============================"
echo "Project:  $PROJECT_NAME"
echo "Path:     $PROJECT_PATH"
echo "Date:     $REVIEW_DATE"
echo ""
echo "Signals detected:"
echo "  package.json     : $CHECK_PACKAGE_JSON"
echo "  Entry dir        : $CHECK_ENTRY_DIR"
echo "  Framework        : $CHECK_FRAMEWORK"
echo "  TypeScript       : $CHECK_TYPESCRIPT"
echo "  Linting          : $CHECK_LINTING"
echo "  Formatting       : $CHECK_FORMATTING"
echo "  Testing          : $CHECK_TESTING"
echo "  Env example      : $CHECK_ENV_EXAMPLE"
echo "  README.md        : $CHECK_README"
echo "  .gitignore       : $CHECK_GITIGNORE"
echo ""
echo "Report saved to:"
echo "  $REPORT_PATH"
echo ""
echo "Next: open the report, fill in the manual findings section, then commit it."
