# MAA: Product Definition and System Boundary

## What MAA is

MAA (My Automated Advisor) is a **standards enforcement system**. It reviews
engineering work — plans and implementations — against a curated, maintained
body of industry-standard expectations. It produces structured outputs:
applicable standards, gaps, risk flags, checklists, and next actions.

It operates against two input types:

- **Documents** (specs, architecture docs, API designs, stack proposals)
  → Plan Review Mode
- **Repositories** (actual code, config, directory structure)
  → Build Review Mode

MAA's job starts after the engineer has decided what to build and how. MAA
does not originate those decisions, but it may validate or challenge them
against standards — surfacing where a plan deviates from known good practice.
It verifies that the decisions meet a known standard of engineering quality,
before you build and after.

---

## What MAA is not

| MAA is NOT | Notes |
|---|---|
| A product strategy tool | It does not evaluate market fit, feature scope, or prioritization |
| An architecture advisor | It does not invent system designs or propose technical approaches from scratch |
| A code generator or scaffolding tool | It reviews code; it does not produce it |
| A linter, formatter, or static analyzer | Those are tools MAA *checks for*; MAA does not run them |
| A CI/CD pipeline component | Local-first, human-invoked — not a gate in automated pipelines (yet) |

The sharpest statement of the boundary: **MAA does not decide what to build.
It decides whether what you are building meets the bar.**

---

## Two operating modes

### Plan Review Mode

**Input:** a document — product spec, architecture doc, API design, deployment
plan, ADR, stack proposal, or any structured engineering artifact written
before or during build.

**What MAA does:**
- Identifies which standards domains are applicable to the plan (frontend,
  backend-node, api-design, security, etc.)
- Surfaces what the plan addresses adequately, what it glosses over, and
  what it omits entirely
- Produces a readiness checklist: "Before you build this, these concerns
  should be resolved"
- Flags risks: gaps that are cheap to address in planning and expensive
  after implementation
- Recommends which Build Review domains to run once the system is built

**What MAA does not do:** evaluate whether the architecture is a good idea,
suggest alternatives, or rewrite the plan.

**Output:** readiness checklist, applicable standards list, missing concern
log, risk flags, recommended Build Review domains.

---

### Build Review Mode

**Input:** a repository path and an explicit domain (`frontend`,
`backend-node`, etc.).

**What MAA does:**
- Probes the filesystem for detectable signals: config files, dependencies,
  directory conventions, tooling markers
- Scores the implementation against the domain's standard checklist
- Surfaces implementation gaps — things the standard requires that the repo
  does not show evidence of
- Leaves space for manual review of things that cannot be auto-detected

**What MAA does not do:** run linters, execute tests, parse source code, or
make judgment calls that require reading logic.

**Output:** detected signals table, standards checklist with
pass/fail/not-detected, implementation gaps, manual review notes, next
actions.

> **Note on ecosystem-specific implementations:** some domains have multiple
> ecosystem variants. For example, the backend domain has `backend-node` for
> Node.js projects and will have `backend-python` for Python projects. Each
> variant detects ecosystem-specific signals and checks against
> ecosystem-appropriate standards, while sharing the same domain-level
> principles.

---

## How the two modes connect

They are independent — either can be used without the other. The intended
full workflow is:

```
[Plan] → Plan Review → readiness checklist + recommended domains
                                    ↓
[Build] → Build Review (per domain) → implementation gap report
```

Plan Review is a quality gate on the plan, when changes are cheap. Build
Review is a quality gate on the implementation, when the evidence is
concrete. Running both creates a closed loop: concerns raised in Plan Review
become checklist items in Build Review.

A future tight integration: Plan Review output explicitly names the Build
Review domains to run, and Build Review can reference an associated plan
review to track which concerns were addressed and which persisted into the
implementation.

---

## Roadmap

### Build Review track — current implementation focus

| Sprint | Scope | Status |
|---|---|---|
| 1 | Frontend (Node/React ecosystem) | Done |
| 2 | Node.js backend | Next |
| 3 | Python backend | Queued |
| 4+ | Go, Java, API design domain, Security domain | Later |

Build Review is the right place to start because it is fully
signal-detectable today, it forces standards to be specific and testable, and
it generates the standards corpus that Plan Review will eventually map
against.

### Plan Review track — deferred implementation

Plan Review requires fundamentally different infrastructure. Rather than
probing a filesystem, it must map intent from prose against applicable
standards. That requires either structured input formats (templates the
engineer fills in) or AI-assisted interpretation — or both. Neither should be
built until there are at least 3–4 solid Build Review domains, because Plan
Review's value is proportional to the breadth and depth of the standards it
can reference.

**Standards should be written with both modes in mind.** A signal useful for
Build Review ("check for `.env.example`") has a corresponding concern for
Plan Review ("the plan should address configuration management and secret
handling"). Write standards with this dual purpose even before Plan Review is
built.
