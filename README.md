# MAA — My Automated Advisor

A local-first engineering standards enforcement system for the software development lifecycle.
Runs on your machine. Lives in Git. No cloud, no database, no web UI.

---

## What MAA is

MAA reviews engineering work — plans and implementations — against a curated body of
engineering standards mapped to the stages of the SDLC. It detects what is present or
absent in a repository, maps findings against a standard, and produces a structured
Markdown report.

MAA's job starts after you have decided what to build. It does not originate decisions.
It verifies that your decisions and implementation meet a known quality bar.

**Current operating mode: Build Review.** Given a project path and a domain, MAA probes
the filesystem for detectable signals — config files, dependency files, directory
conventions, tooling markers — and produces a gap report against the relevant standard.
All detection is `grep`, `test -f`, and `find`. No code execution, no network calls.

---

## What MAA is not

| MAA is NOT | Notes |
|---|---|
| A product strategy tool | Does not evaluate market fit, scope, or prioritisation |
| An architecture advisor | Does not invent system designs or propose approaches |
| A code generator | Reviews code — does not produce it |
| A linter or static analyser | Checks whether linters are configured — does not run them |
| A CI/CD pipeline component | Local-first, human-invoked — not an automated gate |

The sharpest statement of the boundary: **MAA does not decide what to build. It decides whether what you are building meets the bar.**

---

## Active Review Domains

| Domain | Command | SDLC Stage | Standard |
|--------|---------|-----------|----------|
| Frontend | `maa review frontend` | Implementation | `standards/frontend.md` |
| Backend — Node.js | `maa review backend` | Implementation | `standards/backend-node.md` |
| Backend — Python | `maa review backend-python` | Implementation | `standards/backend-python.md` |
| API Design | `maa review api-design` | Design | `standards/api-design.md` |
| Security | `maa review security` | Cross-cutting | `standards/security.md` |
| Testing | `maa review testing` | Cross-cutting | `standards/testing.md` |
| Deployment | `maa review deployment` | Delivery | `standards/deployment.md` |

---

## Commands

```bash
# Run a review
maa review frontend        <project-path>
maa review backend         <project-path>
maa review backend-python  <project-path>
maa review api-design      <project-path>
maa review security        <project-path>
maa review testing         <project-path>
maa review deployment      <project-path>

# Help
maa help
```

Reports are written to `reports/reviews/YYYY-MM-DD-<project>-<domain>.md` in this repo.

---

## Repo Structure

```
MAA/
├── maa                                  # CLI entrypoint
├── scripts/                             # One bash script per domain
│   ├── maa-review.sh                    # frontend
│   ├── maa-backend-review.sh            # backend (Node.js)
│   ├── maa-backend-python-review.sh     # backend (Python)
│   ├── maa-api-design-review.sh         # api-design
│   ├── maa-security-review.sh           # security
│   ├── maa-testing-review.sh            # testing
│   └── maa-deployment-review.sh         # deployment
├── standards/                           # Approved standards (Markdown, versioned)
│   ├── frontend.md
│   ├── backend-node.md
│   ├── backend-python.md
│   ├── api-design.md
│   ├── security.md
│   ├── testing.md
│   ├── deployment.md
│   └── _index.md                        # Standards registry
├── skills/review/                       # Skill definitions and report templates
│   ├── frontend-review/
│   ├── backend-node-review/
│   ├── backend-python-review/
│   ├── api-design-review/
│   ├── security-review/
│   ├── testing-review/
│   └── deployment-review/
├── reports/reviews/                     # Generated review reports (gitignored)
├── docs/                                # Project documentation
│   └── maa-product-definition.md
├── decisions/                           # Approval and rejection records
├── candidates/                          # Candidate practices under evaluation
└── .maa/config.yaml                     # Local configuration
```

---

## Roadmap

### Build Review — current state

Seven domains are active across the SDLC from design through deployment. The system
completed a hardening pass for signal parity and correctness after Sprint 7.

| Domain | Stage | Status |
|--------|-------|--------|
| Frontend | Implementation | Active |
| Backend — Node.js | Implementation | Active |
| Backend — Python | Implementation | Active |
| API Design | Design | Active |
| Security | Cross-cutting | Active |
| Testing | Cross-cutting | Active |
| Deployment | Delivery | Active |

Next Build Review candidates: observability, CI/CD pipeline hygiene.

### Plan Review — design phase

Plan Review — reviewing documents (specs, architecture docs, ADRs, deployment plans)
against the standards corpus — requires different infrastructure than Build Review.
It is not yet built. The prerequisite of a mature standards corpus is now met.

See `docs/maa-product-definition.md` for the full product definition, system
boundary, and roadmap.

### Future phases

- Plan Review
- Standards provenance and discovery
- Standards comparison
- Visualization layer

---

## Philosophy

- Every standard is a file you can read and edit
- Every report is a file in Git
- Every decision is recorded with rationale
- Nothing runs without your knowledge
- Human approval is always the final gate
