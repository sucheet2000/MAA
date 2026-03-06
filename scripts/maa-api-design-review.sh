#!/usr/bin/env bash
# scripts/maa-api-design-review.sh
# Run an API design standards review against a project path.
#
# Usage: scripts/maa-api-design-review.sh <project-path>
#
# Scope: HTTP/REST APIs with OpenAPI specifications.
#        GraphQL and gRPC are not supported yet.
#        If no OpenAPI spec is found, the review still runs and surfaces the gap.
#
# Checks performed (all via bash/grep — no jq, Python, or Node required):
#   1. OpenAPI spec file present (openapi.yaml, swagger.yaml, and common variants)
#   2. Spec format version: OpenAPI 3.x or Swagger 2.x
#   3. Spec info completeness: title and version present
#   4. Spec has descriptions (documentation quality signal)
#   5. Spec uses components/schemas (reuse signal)
#   6. API versioning signal: /v1 or /v2 in spec paths
#   7. Spec has examples (example: or examples: keys)
#   8. API client collection: Postman, Insomnia, or Bruno
#   9. API documentation file: README.md, API.md, ENDPOINTS.md, docs/api.md
#  10. .gitignore present
#
# Checks 2-7 are only evaluated if a spec file is found (check 1).
# If no spec is found, those checks report "not checked (no spec found)".
#
# Output: reports/reviews/YYYY-MM-DD-<project>-api-design.md

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/skills/review/api-design-review/templates/review-report.md"
REPORT_DIR="$REPO_ROOT/reports/reviews"
STANDARD_FILE="$REPO_ROOT/standards/api-design.md"

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: maa review api-design <project-path>" >&2
  exit 1
fi

PROJECT_PATH="$(cd "$1" 2>/dev/null && pwd)" || {
  echo "Error: project path does not exist or is not accessible: $1" >&2
  exit 1
}

PROJECT_NAME="$(basename "$PROJECT_PATH")"
REVIEW_DATE="$(date +%Y-%m-%d)"
REPORT_FILENAME="${REVIEW_DATE}-${PROJECT_NAME}-api-design.md"

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
# Check 1: OpenAPI spec file
# Search common locations and filenames. First match wins.
# ---------------------------------------------------------------------------

detect_spec() {
  local dir="$1"

  for f in \
    openapi.yaml openapi.json \
    swagger.yaml swagger.json \
    api/openapi.yaml api/openapi.json \
    docs/openapi.yaml docs/openapi.json \
    api-spec.yaml api-spec.json \
    spec/openapi.yaml spec/openapi.json; do
    if [[ -f "$dir/$f" ]]; then
      echo "$dir/$f"
      return
    fi
  done

  echo ""
}

SPEC_FILE="$(detect_spec "$PROJECT_PATH")"

if [[ -n "$SPEC_FILE" ]]; then
  CHECK_SPEC_FILE="detected (${SPEC_FILE#"$PROJECT_PATH/"})"
else
  CHECK_SPEC_FILE="not detected"
fi

# ---------------------------------------------------------------------------
# Checks 2-7: spec-gated — only run if a spec file was found
# ---------------------------------------------------------------------------

NOT_CHECKED="not checked (no spec found)"

if [[ -n "$SPEC_FILE" ]]; then

  # Check 2: spec format version
  if grep -q '^openapi:' "$SPEC_FILE" 2>/dev/null; then
    SPEC_VER="$(grep -m1 '^openapi:' "$SPEC_FILE" | sed 's/openapi: *//' | tr -d '"'"'"'[:space:]')"
    CHECK_SPEC_VERSION="OpenAPI ${SPEC_VER:-3.x}"
  elif grep -q '^swagger:' "$SPEC_FILE" 2>/dev/null; then
    SPEC_VER="$(grep -m1 '^swagger:' "$SPEC_FILE" | sed 's/swagger: *//' | tr -d '"'"'"'[:space:]')"
    CHECK_SPEC_VERSION="Swagger ${SPEC_VER:-2.x} (upgrade to OpenAPI 3.x recommended)"
  else
    CHECK_SPEC_VERSION="not detected"
  fi

  # Check 3: info completeness (title + version)
  HAS_TITLE=false
  HAS_VERSION=false
  grep -q 'title:' "$SPEC_FILE" 2>/dev/null && HAS_TITLE=true
  grep -q 'version:' "$SPEC_FILE" 2>/dev/null && HAS_VERSION=true

  if $HAS_TITLE && $HAS_VERSION; then
    CHECK_SPEC_INFO="title and version present"
  elif $HAS_TITLE; then
    CHECK_SPEC_INFO="title present, version missing"
  elif $HAS_VERSION; then
    CHECK_SPEC_INFO="version present, title missing"
  else
    CHECK_SPEC_INFO="title and version missing"
  fi

  # Check 4: descriptions
  if grep -q 'description:' "$SPEC_FILE" 2>/dev/null; then
    CHECK_SPEC_DESCRIPTIONS="detected"
  else
    CHECK_SPEC_DESCRIPTIONS="not detected"
  fi

  # Check 5: components/schemas (reuse signal)
  if grep -q '^components:' "$SPEC_FILE" 2>/dev/null; then
    CHECK_SPEC_COMPONENTS="detected"
  else
    CHECK_SPEC_COMPONENTS="not detected"
  fi

  # Check 6: API versioning (/v1, /v2 in paths)
  if grep -qE '"/v[0-9]|/v[0-9]/' "$SPEC_FILE" 2>/dev/null; then
    CHECK_VERSIONING="detected"
  else
    CHECK_VERSIONING="not detected"
  fi

  # Check 7: examples
  if grep -qE '^\s+examples?:' "$SPEC_FILE" 2>/dev/null; then
    CHECK_SPEC_EXAMPLES="detected"
  else
    CHECK_SPEC_EXAMPLES="not detected"
  fi

else
  CHECK_SPEC_VERSION="$NOT_CHECKED"
  CHECK_SPEC_INFO="$NOT_CHECKED"
  CHECK_SPEC_DESCRIPTIONS="$NOT_CHECKED"
  CHECK_SPEC_COMPONENTS="$NOT_CHECKED"
  CHECK_VERSIONING="$NOT_CHECKED"
  CHECK_SPEC_EXAMPLES="$NOT_CHECKED"
fi

# ---------------------------------------------------------------------------
# Check 8: API client collection (Postman, Insomnia, Bruno)
# ---------------------------------------------------------------------------

detect_client_collection() {
  local dir="$1"

  # Postman collection files
  for f in \
    "$(find "$dir" -maxdepth 2 -name '*.postman_collection.json' 2>/dev/null | head -1)"; do
    if [[ -f "$f" ]]; then
      echo "detected (Postman)"
      return
    fi
  done

  # Insomnia
  if [[ -d "$dir/.insomnia" ]]; then
    echo "detected (Insomnia)"
    return
  fi

  # Bruno
  if find "$dir" -maxdepth 2 -name '*.bru' 2>/dev/null | grep -q .; then
    echo "detected (Bruno)"
    return
  fi

  echo "not detected"
}

CHECK_CLIENT_COLLECTION="$(detect_client_collection "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 9: API documentation file
# ---------------------------------------------------------------------------

detect_api_docs() {
  local dir="$1"

  for f in README.md readme.md API.md api.md ENDPOINTS.md endpoints.md docs/api.md docs/API.md; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  echo "not detected"
}

CHECK_API_DOCS="$(detect_api_docs "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 10: .gitignore
# ---------------------------------------------------------------------------

if [[ -f "$PROJECT_PATH/.gitignore" ]]; then
  CHECK_GITIGNORE="present"
else
  CHECK_GITIGNORE="not detected"
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
ESC_SPEC_FILE="$(escape_sed "$CHECK_SPEC_FILE")"

sed \
  -e "s|{{PROJECT_NAME}}|$ESC_PROJECT_NAME|g" \
  -e "s|{{PROJECT_PATH}}|$ESC_PROJECT_PATH|g" \
  -e "s|{{REVIEW_DATE}}|$REVIEW_DATE|g" \
  -e "s|{{STANDARD_VERSION}}|$ESC_STANDARD_VERSION|g" \
  -e "s|{{CHECK_SPEC_FILE}}|$ESC_SPEC_FILE|g" \
  -e "s|{{CHECK_SPEC_VERSION}}|$(escape_sed "$CHECK_SPEC_VERSION")|g" \
  -e "s|{{CHECK_SPEC_INFO}}|$(escape_sed "$CHECK_SPEC_INFO")|g" \
  -e "s|{{CHECK_SPEC_DESCRIPTIONS}}|$(escape_sed "$CHECK_SPEC_DESCRIPTIONS")|g" \
  -e "s|{{CHECK_SPEC_COMPONENTS}}|$(escape_sed "$CHECK_SPEC_COMPONENTS")|g" \
  -e "s|{{CHECK_VERSIONING}}|$(escape_sed "$CHECK_VERSIONING")|g" \
  -e "s|{{CHECK_SPEC_EXAMPLES}}|$(escape_sed "$CHECK_SPEC_EXAMPLES")|g" \
  -e "s|{{CHECK_CLIENT_COLLECTION}}|$(escape_sed "$CHECK_CLIENT_COLLECTION")|g" \
  -e "s|{{CHECK_API_DOCS}}|$(escape_sed "$CHECK_API_DOCS")|g" \
  -e "s|{{CHECK_GITIGNORE}}|$(escape_sed "$CHECK_GITIGNORE")|g" \
  "$TEMPLATE" > "$REPORT_PATH"

# ---------------------------------------------------------------------------
# Summary output
# ---------------------------------------------------------------------------

echo ""
echo "MAA API Design Review"
echo "====================="
echo "Project:  $PROJECT_NAME"
echo "Path:     $PROJECT_PATH"
echo "Date:     $REVIEW_DATE"
echo ""
echo "Signals detected:"
echo "  Spec file        : $CHECK_SPEC_FILE"
echo "  Spec version     : $CHECK_SPEC_VERSION"
echo "  Spec info        : $CHECK_SPEC_INFO"
echo "  Descriptions     : $CHECK_SPEC_DESCRIPTIONS"
echo "  Components       : $CHECK_SPEC_COMPONENTS"
echo "  Versioning       : $CHECK_VERSIONING"
echo "  Examples         : $CHECK_SPEC_EXAMPLES"
echo "  Client collection: $CHECK_CLIENT_COLLECTION"
echo "  API docs         : $CHECK_API_DOCS"
echo "  .gitignore       : $CHECK_GITIGNORE"
echo ""
echo "Report saved to:"
echo "  $REPORT_PATH"
echo ""
echo "Next: open the report, fill in the manual findings section, then commit it."
