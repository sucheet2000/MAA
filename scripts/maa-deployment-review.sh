#!/usr/bin/env bash
# scripts/maa-deployment-review.sh
# Run a deployment hygiene Build Review against a project path.
#
# Usage: scripts/maa-deployment-review.sh <project-path>
#
# Scope: Deployment configuration hygiene for containerised and PaaS projects.
#        Checks for filesystem evidence that a project can be reliably, safely,
#        and reproducibly deployed.
#        All detection is filesystem-only: grep, test -f, test -d.
#        No hard gate — absence of signals is itself a reportable finding.
#
# Checks performed:
#   1.  Deployment config present (Dockerfile, Procfile, PaaS config, docker-compose)
#   2.  .dockerignore present
#   3.  Multi-stage build (multiple FROM lines)
#   4.  Non-root user (USER instruction, not root)
#   5.  Base image not using :latest tag
#   6.  Process command defined (CMD / ENTRYPOINT / Procfile web:)
#   7.  Health check defined (HEALTHCHECK / docker-compose healthcheck:)
#   8.  .env excluded from image (.dockerignore contains .env pattern)
#   9.  Local dev config present (docker-compose.yml / docker-compose.yaml)
#  10.  Port declared (EXPOSE instruction)
#
# Output: reports/reviews/YYYY-MM-DD-<project>-deployment.md

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/skills/review/deployment-review/templates/review-report.md"
REPORT_DIR="$REPO_ROOT/reports/reviews"
STANDARD_FILE="$REPO_ROOT/standards/deployment.md"

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: maa review deployment <project-path>" >&2
  exit 1
fi

PROJECT_PATH="$(cd "$1" 2>/dev/null && pwd)" || {
  echo "Error: project path does not exist or is not accessible: $1" >&2
  exit 1
}

PROJECT_NAME="$(basename "$PROJECT_PATH")"
REVIEW_DATE="$(date +%Y-%m-%d)"
REPORT_SLUG="$(printf '%s' "$PROJECT_NAME" | tr ' /' '--')"
REPORT_FILENAME="${REVIEW_DATE}-${REPORT_SLUG}-deployment.md"

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

# Resolve Dockerfile path once — used by several checks below.
DOCKERFILE="$PROJECT_PATH/Dockerfile"
HAS_DOCKERFILE=false
[[ -f "$DOCKERFILE" ]] && HAS_DOCKERFILE=true

# ---------------------------------------------------------------------------
# Check 1: Deployment config present
# ---------------------------------------------------------------------------

detect_deploy_config() {
  local dir="$1"
  local found=""

  [[ -f "$dir/Dockerfile" ]]          && found="${found:+$found, }Dockerfile"
  [[ -f "$dir/Procfile" ]]            && found="${found:+$found, }Procfile"
  [[ -f "$dir/fly.toml" ]]            && found="${found:+$found, }fly.toml"
  [[ -f "$dir/render.yaml" ]]         && found="${found:+$found, }render.yaml"
  [[ -f "$dir/railway.toml" ]]        && found="${found:+$found, }railway.toml"
  [[ -f "$dir/docker-compose.yml" ]]  && found="${found:+$found, }docker-compose.yml"
  [[ -f "$dir/docker-compose.yaml" ]] && found="${found:+$found, }docker-compose.yaml"

  if [[ -n "$found" ]]; then
    echo "detected ($found)"
  else
    echo "not detected"
  fi
}

CHECK_DEPLOY_CONFIG="$(detect_deploy_config "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 2: .dockerignore present
# ---------------------------------------------------------------------------

detect_dockerignore() {
  if [[ "$HAS_DOCKERFILE" == false ]]; then
    echo "not checked (no Dockerfile found)"
    return
  fi

  if [[ -f "$PROJECT_PATH/.dockerignore" ]]; then
    echo "detected (.dockerignore)"
  else
    echo "not detected"
  fi
}

CHECK_DOCKERIGNORE="$(detect_dockerignore)"

# ---------------------------------------------------------------------------
# Check 3: Multi-stage build
# ---------------------------------------------------------------------------

detect_multistage() {
  if [[ "$HAS_DOCKERFILE" == false ]]; then
    echo "not checked (no Dockerfile found)"
    return
  fi

  local from_count
  from_count="$(grep -cE '^FROM ' "$DOCKERFILE" 2>/dev/null || true)"

  if [[ "$from_count" -gt 1 ]]; then
    echo "detected ($from_count stages)"
  else
    echo "not detected (single-stage build)"
  fi
}

CHECK_MULTISTAGE="$(detect_multistage)"

# ---------------------------------------------------------------------------
# Check 4: Non-root user
# ---------------------------------------------------------------------------

detect_nonroot_user() {
  if [[ "$HAS_DOCKERFILE" == false ]]; then
    echo "not checked (no Dockerfile found)"
    return
  fi

  # Extract the last USER instruction (final stage is what matters)
  local user_line
  user_line="$(grep -E '^USER ' "$DOCKERFILE" 2>/dev/null | tail -1)"

  if [[ -z "$user_line" ]]; then
    echo "not detected (no USER instruction)"
    return
  fi

  # Extract the value after USER — could be a name or numeric UID
  local user_value
  user_value="$(printf '%s' "$user_line" | sed 's/^USER[[:space:]]*//' | tr -d '[:space:]')"

  if [[ "$user_value" == "root" || "$user_value" == "0" ]]; then
    echo "not detected (USER is root)"
  else
    echo "detected (USER $user_value)"
  fi
}

CHECK_NONROOT_USER="$(detect_nonroot_user)"

# ---------------------------------------------------------------------------
# Check 5: Base image not using :latest tag
# ---------------------------------------------------------------------------

detect_base_image_version() {
  if [[ "$HAS_DOCKERFILE" == false ]]; then
    echo "not checked (no Dockerfile found)"
    return
  fi

  # Check all FROM lines for :latest usage (case-insensitive; latest is case-insensitive in practice)
  if grep -qiE '^FROM [^:]+:latest(\s|$)' "$DOCKERFILE" 2>/dev/null; then
    echo "not detected (:latest tag found)"
  else
    echo "detected (no :latest tag found)"
  fi
}

CHECK_BASE_IMAGE_VERSION="$(detect_base_image_version)"

# ---------------------------------------------------------------------------
# Check 6: Process command defined
# ---------------------------------------------------------------------------

detect_process_command() {
  local dir="$1"
  local found=""

  # Dockerfile CMD or ENTRYPOINT
  if [[ "$HAS_DOCKERFILE" == true ]]; then
    if grep -qE '^(CMD|ENTRYPOINT)' "$DOCKERFILE" 2>/dev/null; then
      local instruction
      instruction="$(grep -E '^(CMD|ENTRYPOINT)' "$DOCKERFILE" | tail -1 | awk '{print $1}')"
      found="$instruction in Dockerfile"
    fi
  fi

  # Procfile web: process
  if [[ -f "$dir/Procfile" ]] && grep -qE '^web\s*:' "$dir/Procfile" 2>/dev/null; then
    found="${found:+$found, }web: in Procfile"
  fi

  if [[ -n "$found" ]]; then
    echo "detected ($found)"
  else
    if [[ "$HAS_DOCKERFILE" == true ]]; then
      echo "not detected (no CMD or ENTRYPOINT in Dockerfile)"
    else
      echo "not checked (no Dockerfile or Procfile found)"
    fi
  fi
}

CHECK_PROCESS_COMMAND="$(detect_process_command "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 7: Health check defined
# ---------------------------------------------------------------------------

detect_healthcheck() {
  local dir="$1"
  local found=""

  # Dockerfile HEALTHCHECK instruction
  if [[ "$HAS_DOCKERFILE" == true ]]; then
    if grep -qE '^HEALTHCHECK' "$DOCKERFILE" 2>/dev/null; then
      found="HEALTHCHECK in Dockerfile"
    fi
  fi

  # docker-compose healthcheck: key
  for f in docker-compose.yml docker-compose.yaml; do
    if [[ -f "$dir/$f" ]] && grep -qE '^\s+healthcheck\s*:' "$dir/$f" 2>/dev/null; then
      found="${found:+$found, }healthcheck in $f"
    fi
  done

  if [[ -n "$found" ]]; then
    echo "detected ($found)"
  else
    if [[ "$HAS_DOCKERFILE" == true ]] || [[ -f "$dir/docker-compose.yml" ]] || [[ -f "$dir/docker-compose.yaml" ]]; then
      echo "not detected"
    else
      echo "not checked (no Dockerfile or docker-compose found)"
    fi
  fi
}

CHECK_HEALTHCHECK="$(detect_healthcheck "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 8: .env excluded from image
# ---------------------------------------------------------------------------

detect_env_excluded() {
  if [[ "$HAS_DOCKERFILE" == false ]]; then
    echo "not checked (no Dockerfile found)"
    return
  fi

  if [[ ! -f "$PROJECT_PATH/.dockerignore" ]]; then
    echo "not checked (no .dockerignore found)"
    return
  fi

  if grep -qE '^\.env' "$PROJECT_PATH/.dockerignore" 2>/dev/null; then
    echo "detected (.env pattern in .dockerignore)"
  else
    echo "not detected (.env not found in .dockerignore)"
  fi
}

CHECK_ENV_EXCLUDED="$(detect_env_excluded)"

# ---------------------------------------------------------------------------
# Check 9: Local dev config present
# ---------------------------------------------------------------------------

detect_local_dev_config() {
  local dir="$1"

  if [[ -f "$dir/docker-compose.yml" ]]; then
    echo "detected (docker-compose.yml)"
  elif [[ -f "$dir/docker-compose.yaml" ]]; then
    echo "detected (docker-compose.yaml)"
  else
    echo "not detected"
  fi
}

CHECK_LOCAL_DEV_CONFIG="$(detect_local_dev_config "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 10: Port declared
# ---------------------------------------------------------------------------

detect_port_declared() {
  if [[ "$HAS_DOCKERFILE" == false ]]; then
    echo "not checked (no Dockerfile found)"
    return
  fi

  if grep -qE '^EXPOSE' "$DOCKERFILE" 2>/dev/null; then
    local ports
    ports="$(grep -E '^EXPOSE' "$DOCKERFILE" | sed 's/^EXPOSE[[:space:]]*//' | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
    echo "detected (EXPOSE $ports)"
  else
    echo "not detected (no EXPOSE instruction)"
  fi
}

CHECK_PORT_DECLARED="$(detect_port_declared)"

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
  -e "s|{{CHECK_DEPLOY_CONFIG}}|$(escape_sed "$CHECK_DEPLOY_CONFIG")|g" \
  -e "s|{{CHECK_DOCKERIGNORE}}|$(escape_sed "$CHECK_DOCKERIGNORE")|g" \
  -e "s|{{CHECK_MULTISTAGE}}|$(escape_sed "$CHECK_MULTISTAGE")|g" \
  -e "s|{{CHECK_NONROOT_USER}}|$(escape_sed "$CHECK_NONROOT_USER")|g" \
  -e "s|{{CHECK_BASE_IMAGE_VERSION}}|$(escape_sed "$CHECK_BASE_IMAGE_VERSION")|g" \
  -e "s|{{CHECK_PROCESS_COMMAND}}|$(escape_sed "$CHECK_PROCESS_COMMAND")|g" \
  -e "s|{{CHECK_HEALTHCHECK}}|$(escape_sed "$CHECK_HEALTHCHECK")|g" \
  -e "s|{{CHECK_ENV_EXCLUDED}}|$(escape_sed "$CHECK_ENV_EXCLUDED")|g" \
  -e "s|{{CHECK_LOCAL_DEV_CONFIG}}|$(escape_sed "$CHECK_LOCAL_DEV_CONFIG")|g" \
  -e "s|{{CHECK_PORT_DECLARED}}|$(escape_sed "$CHECK_PORT_DECLARED")|g" \
  "$TEMPLATE" > "$REPORT_PATH"

# ---------------------------------------------------------------------------
# Summary output
# ---------------------------------------------------------------------------

echo ""
echo "MAA Deployment Review"
echo "====================="
echo "Project:  $PROJECT_NAME"
echo "Path:     $PROJECT_PATH"
echo "Date:     $REVIEW_DATE"
echo ""
echo "Signals detected:"
echo "  Deployment config    : $CHECK_DEPLOY_CONFIG"
echo "  .dockerignore        : $CHECK_DOCKERIGNORE"
echo "  Multi-stage build    : $CHECK_MULTISTAGE"
echo "  Non-root user        : $CHECK_NONROOT_USER"
echo "  Base image version   : $CHECK_BASE_IMAGE_VERSION"
echo "  Process command      : $CHECK_PROCESS_COMMAND"
echo "  Health check         : $CHECK_HEALTHCHECK"
echo "  .env excluded        : $CHECK_ENV_EXCLUDED"
echo "  Local dev config     : $CHECK_LOCAL_DEV_CONFIG"
echo "  Port declared        : $CHECK_PORT_DECLARED"
echo ""
echo "Report saved to:"
echo "  $REPORT_PATH"
echo ""
echo "Next: open the report, fill in the manual findings section, then commit it."
