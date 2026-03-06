#!/usr/bin/env bash
# scripts/maa-security-review.sh
# Run a security hygiene review against a project path.
#
# Usage: scripts/maa-security-review.sh <project-path>
#
# Scope: Repository-level security hygiene signals.
#        Does NOT perform vulnerability scanning, static analysis, or runtime checks.
#        Absence of a signal is a finding — the review runs and surfaces gaps.
#
# Checks performed (all via bash/grep — no jq, Python, or Node required):
#   1.  .gitignore present
#   2.  .env* entries present in .gitignore
#   3.  Sensitive env files at project root (.env, .env.local, .env.production, .env.development)
#   4.  Private key/cert files at project root (id_rsa, id_ed25519, id_dsa, *.pem, *.key)
#   5.  Dependency lock file present (ecosystem-agnostic)
#   6.  SECURITY.md present
#   7.  Automated dependency update config (Dependabot or Renovate)
#   8.  Secret scanning config (.gitleaks.toml, .secretlintrc, .trufflehog.yml)
#   9.  Docker non-root user (conditional on Dockerfile presence)
#  10.  Environment template file (.env.example, .env.sample, example.env)
#
# Output: reports/reviews/YYYY-MM-DD-<project>-security.md

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/skills/review/security-review/templates/review-report.md"
REPORT_DIR="$REPO_ROOT/reports/reviews"
STANDARD_FILE="$REPO_ROOT/standards/security.md"

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: maa review security <project-path>" >&2
  exit 1
fi

PROJECT_PATH="$(cd "$1" 2>/dev/null && pwd)" || {
  echo "Error: project path does not exist or is not accessible: $1" >&2
  exit 1
}

PROJECT_NAME="$(basename "$PROJECT_PATH")"
REVIEW_DATE="$(date +%Y-%m-%d)"
REPORT_FILENAME="${REVIEW_DATE}-${PROJECT_NAME}-security.md"

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
# Check 1: .gitignore present
# ---------------------------------------------------------------------------

if [[ -f "$PROJECT_PATH/.gitignore" ]]; then
  CHECK_GITIGNORE="present"
else
  CHECK_GITIGNORE="not detected"
fi

# ---------------------------------------------------------------------------
# Check 2: .env* entries in .gitignore
# ---------------------------------------------------------------------------

if [[ "$CHECK_GITIGNORE" == "present" ]]; then
  if grep -qE '^\s*\.env' "$PROJECT_PATH/.gitignore" 2>/dev/null; then
    CHECK_ENV_GITIGNORED="detected"
  else
    CHECK_ENV_GITIGNORED="not detected"
  fi
else
  CHECK_ENV_GITIGNORED="not checked (no .gitignore found)"
fi

# ---------------------------------------------------------------------------
# Check 3: Sensitive env files at project root
# Report which specific files are present.
# ---------------------------------------------------------------------------

detect_env_files() {
  local dir="$1"
  local found=""

  for f in .env .env.local .env.production .env.development; do
    if [[ -f "$dir/$f" ]]; then
      found="${found:+$found, }$f"
    fi
  done

  if [[ -n "$found" ]]; then
    echo "found ($found)"
  else
    echo "not detected"
  fi
}

CHECK_ENV_PRESENT="$(detect_env_files "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 4: Private key/cert files at project root
# ---------------------------------------------------------------------------

detect_key_files() {
  local dir="$1"
  local found=""

  # Named key files
  for f in id_rsa id_ed25519 id_dsa; do
    if [[ -f "$dir/$f" ]]; then
      found="${found:+$found, }$f"
    fi
  done

  # *.pem and *.key at root
  local pem_files
  pem_files="$(find "$dir" -maxdepth 1 -name '*.pem' 2>/dev/null | head -3)"
  for f in $pem_files; do
    found="${found:+$found, }$(basename "$f")"
  done

  local key_files
  key_files="$(find "$dir" -maxdepth 1 -name '*.key' 2>/dev/null | head -3)"
  for f in $key_files; do
    found="${found:+$found, }$(basename "$f")"
  done

  if [[ -n "$found" ]]; then
    echo "found ($found) — verify these are not committed secrets"
  else
    echo "not detected"
  fi
}

CHECK_KEY_FILES="$(detect_key_files "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 5: Dependency lock file (ecosystem-agnostic)
# ---------------------------------------------------------------------------

detect_lock_file() {
  local dir="$1"

  for f in \
    package-lock.json yarn.lock pnpm-lock.yaml \
    Pipfile.lock poetry.lock uv.lock \
    Gemfile.lock go.sum Cargo.lock; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  echo "not detected"
}

CHECK_LOCK_FILE="$(detect_lock_file "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 6: SECURITY.md
# ---------------------------------------------------------------------------

if [[ -f "$PROJECT_PATH/SECURITY.md" ]] || [[ -f "$PROJECT_PATH/security.md" ]]; then
  CHECK_SECURITY_MD="detected"
else
  CHECK_SECURITY_MD="not detected"
fi

# ---------------------------------------------------------------------------
# Check 7: Automated dependency update config (Dependabot or Renovate)
# ---------------------------------------------------------------------------

detect_dep_updates() {
  local dir="$1"

  # Dependabot
  if [[ -f "$dir/.github/dependabot.yml" ]] || [[ -f "$dir/.github/dependabot.yaml" ]]; then
    echo "detected (Dependabot)"
    return
  fi

  # Renovate
  if [[ -f "$dir/renovate.json" ]] || [[ -f "$dir/.renovaterc" ]] || [[ -f "$dir/.renovaterc.json" ]]; then
    echo "detected (Renovate)"
    return
  fi

  echo "not detected"
}

CHECK_DEP_UPDATES="$(detect_dep_updates "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 8: Secret scanning config
# ---------------------------------------------------------------------------

detect_secret_scan() {
  local dir="$1"

  for f in .gitleaks.toml .secretlintrc .secretlintrc.json .trufflehog.yml .trufflehog.yaml; do
    if [[ -f "$dir/$f" ]]; then
      echo "detected ($f)"
      return
    fi
  done

  echo "not detected"
}

CHECK_SECRET_SCAN="$(detect_secret_scan "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 9: Docker non-root user (conditional on Dockerfile presence)
# ---------------------------------------------------------------------------

detect_docker_nonroot() {
  local dir="$1"

  local dockerfile=""
  for f in Dockerfile dockerfile Dockerfile.prod Dockerfile.production; do
    if [[ -f "$dir/$f" ]]; then
      dockerfile="$dir/$f"
      break
    fi
  done

  if [[ -z "$dockerfile" ]]; then
    echo "not checked (no Dockerfile found)"
    return
  fi

  # Use the last USER instruction — that is the effective user when the container starts.
  local last_user
  last_user="$(grep -iE '^\s*USER\s+' "$dockerfile" 2>/dev/null | tail -1 \
    | sed 's/^[[:space:]]*[Uu][Ss][Ee][Rr][[:space:]]*//' | tr -d '[:space:]')"

  if [[ -z "$last_user" ]]; then
    echo "not detected (no USER instruction found)"
  elif [[ "$last_user" == "root" || "$last_user" == "0" ]]; then
    echo "not detected (last USER is root)"
  else
    echo "detected (non-root USER: $last_user)"
  fi
}

CHECK_DOCKER="$(detect_docker_nonroot "$PROJECT_PATH")"

# ---------------------------------------------------------------------------
# Check 10: Environment template file
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

sed \
  -e "s|{{PROJECT_NAME}}|$(escape_sed "$PROJECT_NAME")|g" \
  -e "s|{{PROJECT_PATH}}|$(escape_sed "$PROJECT_PATH")|g" \
  -e "s|{{REVIEW_DATE}}|$REVIEW_DATE|g" \
  -e "s|{{STANDARD_VERSION}}|$(escape_sed "$STANDARD_VERSION")|g" \
  -e "s|{{CHECK_GITIGNORE}}|$(escape_sed "$CHECK_GITIGNORE")|g" \
  -e "s|{{CHECK_ENV_GITIGNORED}}|$(escape_sed "$CHECK_ENV_GITIGNORED")|g" \
  -e "s|{{CHECK_ENV_PRESENT}}|$(escape_sed "$CHECK_ENV_PRESENT")|g" \
  -e "s|{{CHECK_KEY_FILES}}|$(escape_sed "$CHECK_KEY_FILES")|g" \
  -e "s|{{CHECK_LOCK_FILE}}|$(escape_sed "$CHECK_LOCK_FILE")|g" \
  -e "s|{{CHECK_SECURITY_MD}}|$(escape_sed "$CHECK_SECURITY_MD")|g" \
  -e "s|{{CHECK_DEP_UPDATES}}|$(escape_sed "$CHECK_DEP_UPDATES")|g" \
  -e "s|{{CHECK_SECRET_SCAN}}|$(escape_sed "$CHECK_SECRET_SCAN")|g" \
  -e "s|{{CHECK_DOCKER}}|$(escape_sed "$CHECK_DOCKER")|g" \
  -e "s|{{CHECK_ENV_TEMPLATE}}|$(escape_sed "$CHECK_ENV_TEMPLATE")|g" \
  "$TEMPLATE" > "$REPORT_PATH"

# ---------------------------------------------------------------------------
# Summary output
# ---------------------------------------------------------------------------

echo ""
echo "MAA Security Review"
echo "==================="
echo "Project:  $PROJECT_NAME"
echo "Path:     $PROJECT_PATH"
echo "Date:     $REVIEW_DATE"
echo ""
echo "Signals detected:"
echo "  .gitignore           : $CHECK_GITIGNORE"
echo "  .env* in .gitignore  : $CHECK_ENV_GITIGNORED"
echo "  Sensitive env files  : $CHECK_ENV_PRESENT"
echo "  Key/cert files       : $CHECK_KEY_FILES"
echo "  Lock file            : $CHECK_LOCK_FILE"
echo "  SECURITY.md          : $CHECK_SECURITY_MD"
echo "  Dep update config    : $CHECK_DEP_UPDATES"
echo "  Secret scan config   : $CHECK_SECRET_SCAN"
echo "  Docker non-root      : $CHECK_DOCKER"
echo "  Env template         : $CHECK_ENV_TEMPLATE"
echo ""
echo "Report saved to:"
echo "  $REPORT_PATH"
echo ""
echo "Next: open the report, fill in the manual findings section, then commit it."
