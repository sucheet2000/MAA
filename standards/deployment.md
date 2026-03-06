# Deployment Hygiene Standards

**Version:** 1.0.0
**Last updated:** 2026-03-06
**Domain:** Deployment (cross-cutting)
**Status:** Approved

---

## Scope

This standard applies to all repositories that ship software to a production environment. It
covers the configuration artefacts that indicate a project can be reliably, safely, and
reproducibly deployed. It does not cover infrastructure-as-code, cloud provider specifics,
CI/CD pipeline structure, Kubernetes manifests, or runtime observability.

The deployment hygiene review checks for filesystem evidence of deployment readiness. It does
not execute builds, run containers, or query cloud APIs.

---

## 1. Deployment Target Defined

- Every project that runs in production must have an explicit deployment configuration file
  committed to the repository.
- Acceptable artefacts: `Dockerfile`, `Procfile`, `fly.toml`, `render.yaml`, `railway.toml`,
  `docker-compose.yml`, `docker-compose.yaml`.
- The absence of any deployment configuration is a finding — it indicates the deployment
  process is undocumented or entirely manual.
- If multiple deployment targets exist (e.g. Docker for production, Procfile for a PaaS),
  all present artefacts should be noted and kept consistent.

## 2. Container Image Hygiene

- A `.dockerignore` file must be present alongside every `Dockerfile`.
- `.dockerignore` must exclude at minimum: `.env`, `.env.*`, `.git`, and language-specific
  build artefacts (`node_modules/`, `__pycache__/`, `.pytest_cache/`, `coverage/`,
  `.nyc_output/`, `dist/`, `build/`).
- Production images should use multi-stage builds to separate build-time dependencies from
  the runtime image. A single-stage build that installs all dependencies — including dev
  dependencies — into the production image is a hygiene failure.
- Multi-stage builds reduce image size, reduce attack surface, and prevent build tooling from
  being present in the running container.

## 3. Container Security

- Containers must not run as `root`. A `USER` instruction must be present in the `Dockerfile`
  and must specify a non-root user.
- Secrets must never be baked into the image. Do not use `ENV KEY=value` to set secret values
  in a `Dockerfile` — use runtime environment injection instead.
- `.env` files must be excluded from the Docker build context via `.dockerignore`. A `.env`
  file present in the build context and not excluded can be silently copied into the image.
- Build-time secrets (e.g. private package registry tokens) must use `--secret` mount syntax
  or multi-stage build patterns, not `ARG`/`ENV` instructions that persist in image layers.

## 4. Base Image Versioning

- Base images must not use the `:latest` tag. `FROM python:latest` or `FROM node:latest` is a
  hygiene failure — it produces non-reproducible builds and can introduce breaking changes
  silently.
- Specify at minimum a major.minor version tag: `FROM python:3.12-slim`, `FROM node:20-alpine`.
- For maximum reproducibility, pin to a digest: `FROM python:3.12-slim@sha256:...`. Digest
  pinning is the strongest form and is recommended for production images, though version-tag
  pinning is the minimum required signal.

## 5. Process Definition

- The `Dockerfile` must declare an `ENTRYPOINT` or `CMD` instruction. An image with no
  declared command is not self-describing and requires callers to supply the command at
  runtime, which is error-prone.
- For PaaS deployments using a `Procfile`, a `web:` process must be defined.
- The declared process must be the production process. Do not leave a development server
  (e.g. `flask run`, `nodemon`) as the declared `CMD` in a production image.
- `EXPOSE` the port the application listens on. This is documentation, not enforcement, but
  it makes the image self-describing for orchestrators and operators.

## 6. Health Checks

- Every containerised service must declare a health check.
- In a `Dockerfile`: use the `HEALTHCHECK` instruction.
- In `docker-compose.yml`: use the `healthcheck:` key on the service.
- Health checks must target a meaningful endpoint — a lightweight `/health` or `/healthz`
  route that confirms the process is accepting requests. A health check that always returns
  `healthy` regardless of application state is not meaningful.
- Orchestrators (Docker Swarm, ECS, Fly.io, Railway) use health check results to route
  traffic and restart unhealthy containers. Missing health checks mean silent failures.

## 7. Local Development Parity

- A `docker-compose.yml` or `docker-compose.yaml` must be present for projects that use
  Docker, to enable local development with the same runtime environment used in production.
- The compose file must define the same service configuration (ports, environment variables,
  volumes) as the production deployment, adjusted only where local access requires it.
- Developers must be able to run the full application stack locally with a single command.
- Do not require developers to construct manual `docker run` commands with long option lists —
  that knowledge lives in no document and diverges over time.

## 8. Environment Configuration

- Applications must read all runtime configuration from environment variables, not hardcoded
  values or committed config files.
- An `.env.example` (or `.env.sample`, `example.env`) must be present and kept current,
  documenting every environment variable the application requires to run.
- `.env` files containing real values must never be committed. They must be listed in
  `.gitignore`.
- Production environment variables must be injected at deployment time by the platform or
  secrets manager, not stored in the repository.

## 9. Port and Network Declaration

- Containerised applications must declare the port they listen on with an `EXPOSE` instruction.
- The application must read its bind port from an environment variable (`PORT`, `APP_PORT`,
  or equivalent) rather than hardcoding it. Hardcoded ports conflict with orchestrator
  assignment and make multi-instance deployments error-prone.
- Do not bind to `0.0.0.0` without intention — document why if the service needs to accept
  external connections at the container level.

## 10. Deployment Artefact Hygiene

- Generated deployment artefacts must not be committed to the repository.
- Common artefacts to exclude via `.gitignore`:
  - `.docker/` — local Docker context caches
  - `*.tar` or `*.tar.gz` — exported image tarballs
  - `.fly/` — Fly.io local state
- The `.dockerignore` file should be treated as security-critical: an overly permissive
  `.dockerignore` (or an absent one) can leak credentials, local configs, and test data into
  the production image.
- Review `.dockerignore` completeness as part of every deployment configuration change.

---

## Changelog

| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-03-06 | Initial version |
