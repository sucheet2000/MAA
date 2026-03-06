---
id: deployment-review
name: Deployment Hygiene Build Review
domain: deployment
type: build-review
status: active
version: 1.0.0
standard: standards/deployment.md
script: scripts/maa-deployment-review.sh
template: skills/review/deployment-review/templates/review-report.md
---

# Deployment Hygiene Build Review

A cross-cutting Build Review skill that checks whether a repository shows evidence of
deployment readiness. Covers container image hygiene, security, process definition, health
checks, and local development parity.

All detection is filesystem-only. No containers are built or executed. No cloud APIs are
queried. Signals are detected with `grep`, `test -f`, and `test -d`.

There is no hard gate. Absence of signals is itself a reportable finding — a project with no
deployment configuration receives a maximum-gap report.

## When to run

- When onboarding an existing project into MAA
- Before a major release to verify deployment readiness
- After a Dockerisation or containerisation task to confirm hygiene
- As a complement to the security review

## What it checks

| # | Signal | Detection method |
|---|--------|-----------------|
| 1 | Deployment config present | `test -f` for Dockerfile, Procfile, fly.toml, render.yaml, railway.toml, docker-compose.yml/.yaml |
| 2 | `.dockerignore` present | `test -f .dockerignore` (if Dockerfile present) |
| 3 | Multi-stage build | `grep -cE '^FROM '` in Dockerfile > 1 |
| 4 | Non-root user | `grep -E '^USER'` in Dockerfile; value checked against `root`/`0` |
| 5 | Base image not using `:latest` | `grep -iE '^FROM .*:latest'` — absence is the positive signal |
| 6 | Process command defined | `grep -E '^(CMD\|ENTRYPOINT)'` in Dockerfile; `^web:` in Procfile |
| 7 | Health check defined | `^HEALTHCHECK` in Dockerfile; `healthcheck:` in docker-compose |
| 8 | `.env` excluded from image | `^\.env` pattern in `.dockerignore` |
| 9 | Local dev config present | `test -f docker-compose.yml` or `docker-compose.yaml` |
| 10 | Port declared | `^EXPOSE` in Dockerfile |

Signals 2–8 and 10 output `not checked (no Dockerfile found)` when no Dockerfile is present.
Signal 9 always runs independently.

## What it does NOT check

The following require manual review:

- Whether the Docker image size is appropriate for the workload
- Whether runtime secrets are correctly injected (not baked into image layers via `ENV`)
- Whether the health check endpoint is meaningful (not always-healthy)
- Whether the application handles graceful shutdown (`STOPSIGNAL`, signal handling)
- Whether resource limits (CPU, memory) are defined for orchestration
- Whether a deployment runbook or rollback procedure exists
- Whether base images are digest-pinned (the automated check only verifies `:latest` absence)

These items appear as a manual findings section in the generated report.

## What it does not cover

- GitHub Actions workflow structure (CI/CD pipeline as a domain)
- Kubernetes manifests (Deployment, Service, Ingress)
- Helm charts
- Terraform or other infrastructure-as-code
- Serverless configs (serverless.yml, AWS SAM)
- ECS task definitions
- Cloud-provider-specific artefacts

## Usage

```bash
maa review deployment <project-path>
```

## Output

Writes a Markdown report to `reports/reviews/YYYY-MM-DD-<project>-deployment.md`.

## Interpretation guide

| Result | Meaning |
|--------|---------|
| `detected (...)` | Signal found; detail in parentheses |
| `not detected` | Signal not found — review whether it is needed |
| `not checked (...)` | Check skipped because prerequisite was absent (e.g. no Dockerfile) |
