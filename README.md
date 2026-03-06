# MAA — My Automated Advisor

A local-first engineering standards enforcement system.
Runs on your machine. Lives in Git. No cloud, no database, no web UI.

---

## What MAA is

MAA reviews engineering work — plans and implementations — against a curated body of engineering standards. It detects what is present or absent in a repository, maps findings against a standard, and produces a structured Markdown report.

MAA's job starts after you have decided what to build. It does not originate decisions. It verifies that your decisions and implementation meet a known quality bar.

**Current operating mode: Build Review.** Given a project path and a domain, MAA probes the filesystem for detectable signals — config files, dependency files, directory conventions, tooling markers — and produces a gap report against the relevant standard. All detection is `grep`, `test -f`, and `find`. No code execution, no network calls.

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

## Supported Review Domains

| Domain | Command | Standard | Notes |
|--------|---------|----------|-------|
| Frontend | `maa review frontend` | `standards/frontend.md` | React/Node ecosystem |
| Backend | `maa review backend` | `standards/backend-node.md` | Node.js only currently |
| API Design | `maa review api-design` | `standards/api-design.md` | OpenAPI/Swagger spec detection |
| Security | `maa review security` | `standards/security.md` | Repository hygiene signals |

---

## Commands

```bash
# Run a review
maa review frontend   <project-path>
maa review backend    <project-path>
maa review api-design <project-path>
maa review security   <project-path>

# Help
maa help
```

Reports are written to `reports/reviews/YYYY-MM-DD-<project>-<domain>.md` in this repo.

---

## Repo Structure

```
MAA/
├── maa                          # CLI entrypoint
├── scripts/                     # One bash script per domain
│   ├── maa-review.sh            # frontend
│   ├── maa-backend-review.sh    # backend (Node.js)
│   ├── maa-api-design-review.sh # api-design
│   └── maa-security-review.sh   # security
├── standards/                   # Approved standards (Markdown, versioned)
│   ├── frontend.md
│   ├── backend-node.md
│   ├── api-design.md
│   ├── security.md
│   └── _index.md                # Standards registry
├── skills/review/               # Skill definitions and report templates
│   ├── frontend-review/
│   ├── backend-node-review/
│   ├── api-design-review/
│   └── security-review/
├── reports/reviews/             # Generated review reports (gitignored)
├── docs/                        # Project documentation
│   └── maa-product-definition.md
├── decisions/                   # Approval and rejection records
├── candidates/                  # Candidate practices under evaluation
└── .maa/config.yaml             # Local configuration (not yet read at runtime)
```

---

## Roadmap

### Build Review (current focus)

| Domain | Status |
|--------|--------|
| Frontend | Done |
| Backend — Node.js | Done |
| API Design | Done |
| Security | Done |
| Backend — Python | Planned |
| Testing (cross-domain) | Planned |

### Plan Review (deferred)

Plan Review — reviewing documents (specs, architecture docs, ADRs) against standards — requires different infrastructure than Build Review. It is not built yet and will not be started until there are enough solid Build Review domains to make the standards corpus useful.

See `docs/maa-product-definition.md` for the full product definition and system boundary.

---

## Philosophy

- Every standard is a file you can read and edit
- Every report is a file in Git
- Every decision is recorded with rationale
- Nothing runs without your knowledge
- Human approval is always the final gate
