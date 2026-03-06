# MAA: Product Definition and System Boundary

## What MAA is

MAA (My Automated Advisor) is a **standards enforcement system for the software
development lifecycle**. It reviews engineering work — plans and implementations —
against a curated, maintained body of engineering standards mapped to the stages of
the SDLC from design through delivery. It produces structured outputs: detected
signals, applicable standards, gaps, risk flags, checklists, and next actions.

It operates against two input types:

- **Documents** (specs, architecture docs, API designs, deployment plans, ADRs)
  → Plan Review Mode
- **Repositories** (actual code, config, directory structure)
  → Build Review Mode

MAA's job starts after the engineer has decided what to build and how. MAA does not
originate those decisions, but it may validate or challenge them against standards —
surfacing where a plan or implementation deviates from known good practice. It
verifies that decisions meet a known standard of engineering quality, before you
build and after.

---

## What MAA is not

| MAA is NOT | Notes |
|---|---|
| A product strategy tool | Does not evaluate market fit, feature scope, or prioritisation |
| An architecture advisor | Does not invent system designs or propose technical approaches from scratch |
| A code generator or scaffolding tool | Reviews code — does not produce it |
| A linter, formatter, or static analyser | Those are tools MAA *checks for*; MAA does not run them |
| A CI/CD pipeline component | Local-first, human-invoked — not a gate in automated pipelines |

The sharpest statement of the boundary: **MAA does not decide what to build.
It decides whether what you are building meets the bar.**

---

## Two operating modes

### Plan Review Mode

**Input:** a document — product spec, architecture doc, API design, deployment
plan, ADR, stack proposal, or any structured engineering artifact written before
or during build.

**What MAA does:**
- Identifies which standards domains are applicable to the plan (frontend,
  backend-node, api-design, security, testing, deployment, etc.)
- Surfaces what the plan addresses adequately, what it glosses over, and what it
  omits entirely
- Produces a readiness checklist: "Before you build this, these concerns should
  be resolved"
- Flags risks: gaps that are cheap to address in planning and expensive after
  implementation
- Recommends which Build Review domains to run once the system is built

**What MAA does not do:** evaluate whether the architecture is a good idea,
suggest alternatives, or rewrite the plan.

**Output:** readiness checklist, applicable standards list, missing concern log,
risk flags, recommended Build Review domains.

---

### Build Review Mode

**Input:** a repository path and an explicit domain (`frontend`, `backend-node`,
`testing`, `deployment`, etc.).

**What MAA does:**
- Probes the filesystem for detectable signals: config files, dependencies,
  directory conventions, tooling markers, deployment artefacts
- Maps findings against the domain's standard checklist
- Surfaces implementation gaps — things the standard requires that the repo does
  not show evidence of
- Leaves space for manual review of things that cannot be auto-detected

**What MAA does not do:** run linters, execute tests, parse source code, query
cloud APIs, or make judgment calls that require reading logic.

**Output:** detected signals table, standards checklist with detected/not-detected
results, implementation gaps, manual review notes section, next actions.

Some domains have multiple ecosystem variants. The backend domain has `backend-node`
for Node.js and `backend-python` for Python. Cross-cutting domains — `security`,
`testing`, `deployment` — apply regardless of ecosystem and run alongside any
ecosystem review.

---

## Coverage across the software development lifecycle

Build Review currently covers these SDLC stages:

| Stage | Domain | Standard |
|-------|--------|----------|
| Design | `api-design` | `standards/api-design.md` |
| Implementation | `frontend` | `standards/frontend.md` |
| Implementation | `backend-node` | `standards/backend-node.md` |
| Implementation | `backend-python` | `standards/backend-python.md` |
| Cross-cutting | `security` | `standards/security.md` |
| Cross-cutting | `testing` | `standards/testing.md` |
| Delivery | `deployment` | `standards/deployment.md` |

Each domain's standard is a versioned Markdown file — a concrete, checkable body
of criteria. Standards are intentionally written to serve both modes: the criteria
that drive Build Review signal detection also express the concerns that Plan Review
maps against in documents.

Not yet covered by a dedicated domain: observability and runtime operations,
CI/CD pipeline hygiene, infrastructure-as-code, database hygiene.

---

## How the two modes connect

They are independent — either can be used without the other. The intended full
workflow is:

```
[Plan] → Plan Review → readiness checklist + recommended domains
                                    ↓
[Build] → Build Review (per domain) → implementation gap report
```

Plan Review is a quality gate on the plan, when changes are cheap. Build Review is
a quality gate on the implementation, when the evidence is concrete. Running both
creates a closed loop: concerns raised in Plan Review become checklist items in
Build Review.

A future integration: Plan Review output explicitly names the Build Review domains
to run, and Build Review can reference an associated plan review to track which
concerns were addressed and which persisted into the implementation.

---

## Roadmap

### Build Review track — current state

Seven domains are active, spanning design through delivery. The system completed a
hardening and consistency pass after Sprint 7.

| Domain | SDLC stage | Status |
|--------|-----------|--------|
| `frontend` | Implementation | Active |
| `backend-node` | Implementation | Active |
| `backend-python` | Implementation | Active |
| `api-design` | Design | Active |
| `security` | Cross-cutting | Active |
| `testing` | Cross-cutting | Active |
| `deployment` | Delivery | Active |

The standards corpus is now broad enough and concrete enough to support Plan
Review. Build Review remains the primary track until Plan Review infrastructure
is in place.

Next Build Review candidates: observability (logging, error tracking, health check
patterns), CI/CD pipeline hygiene.

---

### Plan Review track — design phase

Plan Review reviews documents against the standards corpus. It is not yet built.

The original prerequisite for starting Plan Review was a minimum of 3–4 solid Build
Review domains, to ensure the standards corpus was worth mapping against. That
threshold is now well exceeded.

The infrastructure question remains: Plan Review must interpret intent from prose
and map it against applicable standard sections. That requires structured input
templates, AI-assisted interpretation, or both. The implementation approach is
under consideration.

Standards are already written with Plan Review in mind. Each standard's criteria are
specific and checkable — not vague guidance — so they can serve both Build Review
signal detection and Plan Review concern mapping without revision.

---

### Future phases

In approximate order of priority:

1. **Observability domain** — next Build Review domain; logging structure, error
   tracking configuration, health endpoint signals (filesystem detection only)
2. **Plan Review** — review documents against the standards corpus; first
   implementation of structured input templates or AI-assisted concern mapping
3. **Standards provenance and discovery** — surface which standards apply to a
   given technology stack; navigate from a stack description to applicable sections
4. **Standards comparison** — diff standard versions; compare project coverage
   across time or across multiple projects
5. **Visualization layer** — summary view of SDLC coverage across all active
   domains for a given project
