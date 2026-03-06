# Forge: Personal Engineering Standards Lab

## System Design Specification — v1

---

## 1. System Restatement

Forge is a **skill-based personal engineering system** that lets a single engineer maintain, apply, evaluate, and evolve engineering best practices across multiple domains (frontend, backend, API, security, testing, DevOps, etc.).

The building blocks are **Claude-style Skills** — self-contained folders with a `SKILL.md`, reusable instructions, scripts, templates, and resources. Around these skills sits an orchestration layer that manages a repository of **approved standards**, discovers **candidate practices** from trusted sources, runs **evaluations and comparisons**, generates **reports**, and gates all changes behind **human approval**.

It is not a chatbot, not a generic agent, and not a static prompt library. It is a **standards-driven improvement loop** with skills as the unit of work and human judgment as the final authority.

### What it is

- A local-first, Git-versioned repository of engineering skills and standards
- A CLI-driven orchestration system that invokes skills against real projects
- An evaluation pipeline that compares candidate practices against current standards
- A human-approved evolution workflow for updating standards over time

### What it is not

- An autonomous agent that updates standards without approval
- A web scraper that blindly adopts whatever it finds
- A SaaS product or hosted service
- An over-engineered platform requiring databases, queues, or cloud infra on day one

### Users

- You. One engineer. This is a personal system.

### Design Principles

1. **Skills are concrete** — every skill is a folder with a `SKILL.md`, not a vague capability
2. **Standards are versioned** — every approved standard is a document in Git with a changelog
3. **Human approval is mandatory** — no standard changes without explicit sign-off
4. **Local-first** — runs on your Mac, lives in a Git repo, no cloud dependencies for v1
5. **Start narrow, grow wide** — v1 covers 2-3 domains well, not 10 domains poorly
6. **Evaluation over opinion** — prefer concrete comparisons over subjective judgment
7. **Inspectable** — every decision, evaluation, and report is a file you can read

### Success Criteria (v1)

- You can run a review skill against a real project and get actionable output
- You can discover a candidate practice, evaluate it against your current standard, and approve/reject it
- All standards, evaluations, and decisions are stored in Git
- The entire system runs locally with `claude` CLI + shell scripts

### Non-Goals (v1)

- Multi-user collaboration
- Real-time monitoring or continuous integration hooks
- GUI/dashboard
- Automated discovery (v1 is manual discovery, automated evaluation)
- Plugin marketplace

---

## 2. Architecture

The system has four layers. Each layer has a clear responsibility and a defined interface to the others.

```
┌─────────────────────────────────────────────────────┐
│                  HUMAN (You)                         │
│         Review reports, approve/reject changes       │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              EVOLUTION LAYER                         │
│  Discovery → Candidacy → Evaluation → Approval      │
│  Skills: practice-discovery, practice-comparator,    │
│          benchmark-runner, approval-assistant         │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              EXECUTION LAYER                         │
│  Orchestration CLI, skill invocation, report gen     │
│  Skills: report-generator, all review skills         │
│  Tools: forge CLI (shell scripts)                    │
└──────────────┬───────────────────┬──────────────────┘
               │                   │
┌──────────────▼──────┐ ┌─────────▼──────────────────┐
│   SKILLS LAYER      │ │   STANDARDS LAYER          │
│   Skill folders     │ │   Standards docs           │
│   SKILL.md files    │ │   Policies                 │
│   Scripts/templates │ │   Trusted sources          │
│   References        │ │   Versioned practices      │
└─────────────────────┘ └────────────────────────────┘
```

### Skills Layer

**What lives here:** Individual skill folders, each self-contained.

Each skill is a directory with:
- `SKILL.md` — instructions, trigger conditions, constraints
- `scripts/` — optional executable scripts
- `references/` — optional reference docs
- `templates/` — optional output templates
- `assets/` — optional supporting files

Skills fall into two categories:
- **Review skills** (apply standards to code): `frontend-review`, `api-design-review`, `security-review`, etc.
- **Meta skills** (operate on the system itself): `practice-discovery`, `practice-comparator`, `standards-curator`, `report-generator`, `approval-assistant`

### Standards Layer

**What lives here:** The approved body of knowledge.

- **Standards** — domain-specific best practice documents (e.g., `frontend.md`, `api-design.md`)
- **Policies** — cross-cutting rules (e.g., `security-policy.md`, `review-process.md`)
- **Trusted Sources** — curated list of sources for practice discovery (blogs, repos, RFCs, style guides)
- **Changelog** — history of all standard changes with approval records

Standards are Markdown or YAML files, versioned in Git. A standard change requires a commit with an approval record referencing the evaluation that justified it.

### Execution Layer

**What lives here:** The CLI and orchestration scripts that wire everything together.

- `forge` CLI — a set of shell scripts that invoke skills, run evaluations, generate reports
- Skill invocation — calls `claude` CLI with the appropriate skill loaded
- Report generation — produces Markdown reports from evaluation results
- File routing — puts outputs in the right directories

**Key design decision:** The execution layer is shell scripts and `claude` CLI calls, not a custom framework. This keeps it simple, debuggable, and replaceable.

### Evolution Layer

**What lives here:** The workflow for discovering, evaluating, and adopting new practices.

The evolution loop:
1. **Discover** — find a candidate practice (manual in v1, semi-automated in v2)
2. **Candidacy** — create a structured candidate record with source, description, rationale
3. **Evaluate** — run the `practice-comparator` skill to compare against current standard
4. **Benchmark** (optional) — run the `benchmark-runner` skill against real code
5. **Report** — generate a comparison report with `report-generator`
6. **Approve/Reject** — you review and decide; `approval-assistant` records the decision
7. **Update** (if approved) — `standards-curator` patches the standard and commits

### Data Flow

```
[Your project code]
       │
       ▼
[Review Skill] ──reads──▶ [Standards]
       │
       ▼
[Review Report] ──▶ [You read it]
       
[External source / your reading]
       │
       ▼
[Candidate Practice record]
       │
       ▼
[practice-comparator] ──reads──▶ [Current Standard]
       │
       ▼
[Comparison Report]
       │
       ▼
[You approve/reject]
       │
       ▼ (if approved)
[standards-curator] ──writes──▶ [Updated Standard + Changelog]
```

### v1 vs Later

| Concern | v1 | v2 | v3 |
|---|---|---|---|
| Skill invocation | `claude` CLI + shell | Custom CLI with arg parsing | SDK-based orchestrator |
| Discovery | Manual (you find things) | Semi-auto (curated RSS/feeds) | Scheduled crawls |
| Evaluation | Single comparison | Multi-axis scoring | Statistical benchmarks |
| Reporting | Markdown files | Markdown + summary index | HTML dashboard |
| Standards storage | Markdown in Git | Same + structured YAML metadata | Same + search index |
| Approval | Manual commit + record | CLI-assisted approve/reject | Same with audit trail |

---

## 3. Repository Structure

```
forge/
├── README.md
├── forge                          # CLI entry point (bash script)
│
├── skills/
│   ├── review/
│   │   ├── frontend-review/
│   │   │   ├── SKILL.md
│   │   │   ├── references/
│   │   │   │   └── react-patterns.md
│   │   │   └── templates/
│   │   │       └── review-report.md
│   │   ├── backend-review/
│   │   │   └── SKILL.md
│   │   ├── api-design-review/
│   │   │   └── SKILL.md
│   │   ├── security-review/
│   │   │   └── SKILL.md
│   │   ├── accessibility-review/
│   │   │   └── SKILL.md
│   │   └── middleware-review/
│   │       └── SKILL.md
│   │
│   └── meta/
│       ├── practice-discovery/
│       │   └── SKILL.md
│       ├── practice-comparator/
│       │   └── SKILL.md
│       ├── benchmark-runner/
│       │   └── SKILL.md
│       ├── standards-curator/
│       │   └── SKILL.md
│       ├── report-generator/
│       │   └── SKILL.md
│       └── approval-assistant/
│           └── SKILL.md
│
├── standards/
│   ├── frontend.md
│   ├── backend.md
│   ├── api-design.md
│   ├── security.md
│   ├── testing.md
│   └── _index.md                  # Master index of all standards
│
├── policies/
│   ├── review-process.md
│   ├── approval-process.md
│   └── source-trust-policy.md
│
├── sources/
│   └── trusted-sources.yaml       # Curated list of trusted sources
│
├── candidates/
│   ├── 2026-03-05-react-server-components.yaml
│   └── ...
│
├── evaluations/
│   ├── 2026-03-05-react-server-components/
│   │   ├── comparison.md
│   │   ├── benchmark-results.md
│   │   └── metadata.yaml
│   └── ...
│
├── decisions/
│   ├── 2026-03-05-react-server-components.yaml
│   └── ...
│
├── reports/
│   ├── reviews/
│   │   └── 2026-03-05-project-x-frontend.md
│   └── evaluations/
│       └── 2026-03-05-react-server-components.md
│
├── scripts/
│   ├── forge-review.sh            # Run a review skill against a project
│   ├── forge-discover.sh          # Create a candidate practice
│   ├── forge-evaluate.sh          # Run comparison/benchmark
│   ├── forge-approve.sh           # Record approval decision
│   ├── forge-report.sh            # Generate a report
│   └── forge-status.sh            # Show system status
│
└── .forge/
    └── config.yaml                # Local configuration
```

**Key decisions:**
- Flat-ish structure. No deeply nested hierarchies.
- Date-prefixed filenames for candidates, evaluations, decisions (natural chronological ordering, avoids ID management).
- Standards are plain Markdown — maximum readability, maximum portability.
- Scripts are bash — no build step, no dependencies beyond `claude` CLI and standard Unix tools.

---

## 4. Skill Folder Structure

Every skill follows this standard pattern:

```
skill-name/
├── SKILL.md              # Required. Instructions + metadata.
├── scripts/              # Optional. Executable helper scripts.
├── references/           # Optional. Domain docs loaded on demand.
├── templates/            # Optional. Output templates.
└── assets/               # Optional. Supporting files.
```

### SKILL.md Format

Every `SKILL.md` has YAML frontmatter followed by Markdown instructions:

```yaml
---
name: skill-name
description: >
  One-paragraph description of what this skill does and when to trigger it.
  Be specific about trigger conditions.
version: 1.0.0
domain: frontend | backend | api | security | meta | ...
type: review | meta
inputs:
  - type: code | standard | candidate | project-path
    description: What this input is
outputs:
  - type: report | comparison | decision-record | updated-standard
    description: What this output is
reads:
  - standards/frontend.md
  - policies/review-process.md
writes:
  - reports/reviews/
---

# Skill Name

## Purpose

One paragraph explaining what this skill does and why it exists.

## When to Use

Bullet list of specific trigger conditions.

## Workflow

Step-by-step instructions for how to execute this skill.

## Inputs

What you need before starting.

## Evaluation Criteria

What you're checking / comparing / measuring.

## Output Format

Exact structure of the output (template or example).

## Constraints

Things this skill must NOT do. Boundaries.

## Failure Modes

What can go wrong and how to handle it.

## References

Pointers to reference docs in `references/` subdirectory.
```

### Example: `frontend-review/SKILL.md`

```yaml
---
name: frontend-review
description: >
  Review frontend code against approved standards. Use when you want to check
  React/TypeScript/CSS code for adherence to your engineering standards covering
  component architecture, state management, accessibility, performance, and
  styling patterns. Produces a structured review report.
version: 1.0.0
domain: frontend
type: review
inputs:
  - type: project-path
    description: Path to the frontend code to review
outputs:
  - type: report
    description: Markdown review report in reports/reviews/
reads:
  - standards/frontend.md
writes:
  - reports/reviews/
---

# Frontend Review

## Purpose

Review frontend code against your approved frontend engineering standards.
Produce actionable findings organized by severity.

## When to Use

- Before merging a frontend PR
- When onboarding to an unfamiliar frontend codebase
- Periodic codebase health checks
- After major refactors

## Workflow

1. Read `standards/frontend.md` to load current approved standards
2. Scan the target project structure (focus on src/, components/, pages/)
3. For each standard category, check adherence:
   - Component architecture patterns
   - State management approach
   - Accessibility (a11y) compliance
   - Performance patterns (bundle size, lazy loading, memoization)
   - Styling approach (CSS modules, Tailwind usage, design tokens)
   - TypeScript usage and type safety
   - Error handling and loading states
4. Produce findings organized by severity: critical, warning, info
5. Write the report using the template in `templates/review-report.md`

## Output Format

Use the template at `templates/review-report.md`. Key sections:
- Summary (pass/fail + score)
- Critical findings (must fix)
- Warnings (should fix)
- Informational (nice to fix)
- Positive observations (what's done well)
- Recommendations

## Constraints

- Do NOT suggest changes that contradict approved standards
- Do NOT review backend code even if found in the project
- Flag findings you're uncertain about as "needs human review"
- Limit report to top 20 findings to avoid noise

## Failure Modes

- Standards file missing → abort with clear error message
- Project path invalid → abort with clear error
- Project too large → focus on recently changed files or a specified subset
```

---

## 5. Data Model (Schemas)

All data is stored as YAML or Markdown files in the repo. No database.

### Standard

```yaml
# standards/frontend.md is Markdown, but the metadata is:
# Stored implicitly via Git (author, date, history)
# The _index.md tracks metadata:

# standards/_index.md entry:
- id: frontend
  file: frontend.md
  domain: frontend
  version: 3
  last_updated: 2026-03-01
  last_reviewed: 2026-03-01
  approved_by: you
  summary: "Frontend engineering standards covering React, TypeScript, CSS, a11y, performance"
```

**The standard itself** is a Markdown document with sections like:

```markdown
# Frontend Engineering Standards

## Component Architecture
- Use functional components with hooks exclusively
- ...

## State Management
- ...

## Accessibility
- ...
```

### Trusted Source

```yaml
# sources/trusted-sources.yaml
sources:
  - id: react-docs
    name: React Official Documentation
    url: https://react.dev
    domain: frontend
    trust_level: authoritative    # authoritative | high | medium
    last_checked: 2026-03-01
    notes: "Official source of truth for React patterns"

  - id: owasp-top-10
    name: OWASP Top 10
    url: https://owasp.org/www-project-top-ten/
    domain: security
    trust_level: authoritative
    last_checked: 2026-02-15
    notes: "Industry standard security vulnerability classification"

  - id: kent-c-dodds-blog
    name: Kent C. Dodds Blog
    url: https://kentcdodds.com/blog
    domain: frontend
    trust_level: high
    notes: "Testing and React patterns. Opinionated but well-reasoned."
```

### Candidate Practice

```yaml
# candidates/2026-03-05-react-server-components.yaml
id: 2026-03-05-react-server-components
title: "Adopt React Server Components for data-heavy pages"
domain: frontend
source_id: react-docs
source_url: https://react.dev/reference/rsc/server-components
discovered: 2026-03-05
discovered_by: manual
status: pending    # pending | evaluating | approved | rejected | deferred

current_standard_section: "standards/frontend.md#component-architecture"
current_practice: "All components are client components. Data fetching via useEffect + API calls."
proposed_practice: "Use React Server Components for data-heavy pages. Keep interactive components as client components."

rationale: |
  Server Components reduce client bundle size and eliminate client-side
  data fetching waterfalls for read-heavy pages. The React team recommends
  this as the default for new projects using Next.js or compatible frameworks.

risks:
  - "Requires Next.js or compatible framework"
  - "Team needs to learn server/client component boundary rules"
  - "Testing story is still maturing"

tags:
  - react
  - architecture
  - performance
```

### Evaluation

```yaml
# evaluations/2026-03-05-react-server-components/metadata.yaml
id: eval-2026-03-05-rsc
candidate_id: 2026-03-05-react-server-components
evaluated: 2026-03-06
type: comparison    # comparison | benchmark | expert-review

method: |
  Compared current client-component pattern against RSC pattern
  using the practice-comparator skill on the dashboard project.

axes:
  - name: performance
    current_score: 3
    candidate_score: 4
    notes: "RSC eliminates data-fetching waterfalls on product listing page"
  - name: complexity
    current_score: 4
    candidate_score: 2
    notes: "RSC adds framework coupling and server/client boundary management"
  - name: testability
    current_score: 4
    candidate_score: 3
    notes: "RSC testing patterns are less mature"
  - name: adoption_cost
    current_score: 5
    candidate_score: 2
    notes: "Requires Next.js migration and team training"

overall_recommendation: defer
recommendation_rationale: |
  Performance gains are real but adoption cost is high.
  Revisit when current project moves to Next.js.

artifacts:
  - comparison.md
  - benchmark-results.md
```

### Decision

```yaml
# decisions/2026-03-05-react-server-components.yaml
id: dec-2026-03-05-rsc
candidate_id: 2026-03-05-react-server-components
evaluation_id: eval-2026-03-05-rsc
decided: 2026-03-07
decision: deferred    # approved | rejected | deferred

rationale: |
  Agreed with evaluation. Performance benefits don't justify the migration
  cost right now. Will revisit when we start a Next.js project.

standard_changed: false
next_review: 2026-06-01
```

### Report

Reports are Markdown files. No special schema — they follow the template defined by the `report-generator` skill. Two kinds:

- **Review reports** — output of running a review skill against a project
- **Evaluation reports** — output of comparing a candidate practice against current standards

---

## 6. v1 Build Plan

### What to build first (Week 1-2)

1. **Repository scaffolding** — create the directory structure, README, config
2. **Two standards documents** — `frontend.md` and `api-design.md` (write these yourself based on your current practices; they don't need to be perfect)
3. **One review skill** — `frontend-review` (fully built out with SKILL.md, template, references)
4. **The `forge` CLI wrapper** — a simple bash script that routes commands to the right sub-scripts
5. **`forge review` command** — invokes `claude -p` with the frontend-review skill against a target directory
6. **One meta skill** — `practice-comparator` (the core of the evolution loop)
7. **`forge evaluate` command** — creates a candidate record and runs comparison

### What to postpone

- All other review skills beyond frontend (build them incrementally as you need them)
- `benchmark-runner` (comparisons are enough for v1; benchmarks add complexity)
- `practice-discovery` automation (manual discovery is fine for v1)
- Dashboard or HTML reporting (Markdown is enough)
- Scheduled jobs or cron tasks
- Multi-project support (target one project at a time)

### What to fake/mock initially

- **Trusted sources checking** — just maintain the YAML list manually. No crawling.
- **Scoring** — use simple 1-5 scales with prose justification. No quantitative metrics.
- **Approval workflow** — a YAML file you create manually. No CLI wizard needed yet.

### Tools/frameworks for v1

| Tool | Purpose |
|---|---|
| `claude` CLI (`claude -p`) | Invoke skills via Claude |
| Bash scripts | CLI orchestration |
| Git | Version control and changelog |
| YAML | Structured data (candidates, evaluations, decisions) |
| Markdown | Standards, reports, skill docs |
| Your text editor | Writing standards, reviewing reports |

**Not needed for v1:** Python, Node.js, databases, Docker, web frameworks, CI/CD.

### What you should NOT build yet

- A web UI or dashboard
- A plugin system for skills
- Automated discovery/crawling
- A custom evaluation framework
- Integration with GitHub PRs or CI
- Multi-model support (just use Claude)
- A "skill marketplace" or sharing system

---

## 7. Example End-to-End Flows

### Flow 1: Frontend Review

```
You: forge review frontend ~/projects/my-app

What happens:
1. forge-review.sh resolves the "frontend" skill → skills/review/frontend-review/
2. Script calls: claude -p "Review this project against frontend standards" \
     --skill skills/review/frontend-review/ \
     --context standards/frontend.md \
     --target ~/projects/my-app
3. Claude reads SKILL.md, loads standards/frontend.md, scans the project
4. Claude produces a review report following the template
5. Script saves report to reports/reviews/2026-03-05-my-app-frontend.md
6. Script prints: "Review complete. Report: reports/reviews/2026-03-05-my-app-frontend.md"
7. You open and read the report
```

### Flow 2: New Frontend Practice Discovered → Evaluated → Deferred

```
Step 1 — You read an article about React Server Components

Step 2 — Create candidate:
  forge discover --domain frontend --title "Adopt React Server Components"
  → Opens your editor with a candidate YAML template
  → You fill in source, rationale, proposed practice
  → Saved to candidates/2026-03-05-react-server-components.yaml

Step 3 — Evaluate:
  forge evaluate candidates/2026-03-05-react-server-components.yaml
  → practice-comparator skill is invoked
  → Claude reads the candidate, reads current standard, compares on axes
  → Produces evaluations/2026-03-05-react-server-components/comparison.md
  → report-generator produces a readable summary

Step 4 — You review the report

Step 5 — Decide:
  forge approve candidates/2026-03-05-react-server-components.yaml --decision deferred
  → Creates decisions/2026-03-05-react-server-components.yaml
  → Candidate status updated to "deferred"
  → Standards unchanged
  → Git commit with decision record
```

### Flow 3: Security Practice Discovered → Evaluated → Approved

```
Step 1 — You learn about a new CSP header best practice from OWASP

Step 2 — forge discover --domain security --title "Strict CSP with nonce-based scripts"
  → You fill in the candidate YAML

Step 3 — forge evaluate candidates/2026-03-10-strict-csp-nonces.yaml
  → practice-comparator loads current security.md standard
  → Compares: current practice (CSP with unsafe-inline) vs proposed (nonce-based)
  → Evaluation report shows clear security improvement, low adoption cost

Step 4 — You review and agree

Step 5 — forge approve candidates/2026-03-10-strict-csp-nonces.yaml --decision approved
  → standards-curator skill is invoked
  → Claude reads the approval, reads current security.md
  → Proposes a diff to security.md adding the nonce-based CSP section
  → You review the diff
  → On confirmation: security.md updated, changelog entry added, git commit

Step 6 — Future security reviews now check for nonce-based CSP
```

---

## 8. Guardrails

### Risk: Noisy External Discovery

**Problem:** Too many candidate practices, most low-value, creating review fatigue.

**Guardrails:**
- v1 is manual discovery only — you control what enters the pipeline
- v2: Rate-limit automated discovery to N candidates per domain per week
- Every candidate requires a `rationale` field — no drive-by entries
- Add a `priority` field (high/medium/low) and only auto-evaluate high-priority

### Risk: Bad Source Quality

**Problem:** A "trusted source" publishes something wrong or outdated.

**Guardrails:**
- Trust levels (authoritative / high / medium) weight evaluations
- `last_checked` field on sources — flag stale sources
- Policy: never auto-approve from medium-trust sources
- You review every decision — this is the ultimate guardrail

### Risk: Weak Evaluations

**Problem:** The comparator skill produces shallow or wrong assessments.

**Guardrails:**
- Require multi-axis evaluation (never a single yes/no)
- Include a `confidence` field in evaluations
- Low-confidence evaluations are flagged for manual deep-dive
- Iterate on the `practice-comparator` skill over time (it's a skill — you can improve it)

### Risk: Standards Drift

**Problem:** Standards accumulate contradictions or become bloated over time.

**Guardrails:**
- Periodic "standards review" — run the `standards-curator` skill to check for contradictions
- Version numbers on standards — major versions require full re-review
- Keep standards documents under 500 lines each — split if needed
- `_index.md` tracks last-reviewed dates — flag standards not reviewed in 90 days

### Risk: Over-automation

**Problem:** You stop thinking critically because the system handles everything.

**Guardrails:**
- Human approval gate is architecturally mandatory — not optional, not bypassable
- Reports include an explicit "areas of uncertainty" section
- System never auto-commits standard changes
- Regular "manual review" where you read standards end-to-end without AI help

### Risk: Dangerous Security Recommendations

**Problem:** The system recommends a security practice that sounds good but is harmful.

**Guardrails:**
- Security domain evaluations always require `risks` field
- Security standard changes require you to verify against OWASP or equivalent authoritative source
- practice-comparator for security includes a "threat model impact" axis
- Never approve security changes based solely on AI evaluation — always cross-reference

### Risk: Maintenance Burden

**Problem:** The system itself becomes a project that takes more time than it saves.

**Guardrails:**
- v1 is deliberately minimal — bash scripts, Markdown, YAML, Git
- No custom frameworks to maintain
- Skills are independent — a broken skill doesn't break the system
- Measure: if you spend more time on the system than on actual engineering, scale back
- Built-in "escape hatch" — everything is plain files, you can always just read them manually

---

## 9. Implementation Roadmap

### Sprint 1 (Days 1-3): Foundation

- [ ] Create the repo with the directory structure above
- [ ] Write `README.md` explaining the system
- [ ] Write `.forge/config.yaml` with basic settings (your name, default domain, project paths)
- [ ] Write `standards/frontend.md` — your current frontend practices (start with what you already know and believe, even if incomplete)
- [ ] Write `standards/_index.md`
- [ ] Write `policies/approval-process.md`
- [ ] Write `sources/trusted-sources.yaml` with 5-10 sources you already trust
- [ ] Git init, first commit

### Sprint 2 (Days 4-7): First Review Skill

- [ ] Write `skills/review/frontend-review/SKILL.md`
- [ ] Write the review report template
- [ ] Write `scripts/forge-review.sh` — wires `claude -p` to the skill
- [ ] Write the top-level `forge` CLI script (routes `forge review` → `forge-review.sh`)
- [ ] Test: run `forge review frontend` against a real project
- [ ] Iterate on the skill based on output quality
- [ ] Commit the skill and first review report

### Sprint 3 (Days 8-12): Evolution Loop

- [ ] Write `skills/meta/practice-comparator/SKILL.md`
- [ ] Write `skills/meta/report-generator/SKILL.md`
- [ ] Write `skills/meta/standards-curator/SKILL.md`
- [ ] Write `scripts/forge-discover.sh` (creates candidate YAML from template)
- [ ] Write `scripts/forge-evaluate.sh` (invokes comparator, generates report)
- [ ] Write `scripts/forge-approve.sh` (records decision, optionally invokes curator)
- [ ] Test: run the full discovery → evaluation → approval flow
- [ ] Commit everything

### Sprint 4 (Days 13-17): Second Domain + Polish

- [ ] Write `standards/api-design.md`
- [ ] Write `skills/review/api-design-review/SKILL.md`
- [ ] Write `scripts/forge-status.sh` (show pending candidates, recent reviews, stale standards)
- [ ] Run both review skills against a real project
- [ ] Run one end-to-end evolution flow with a real candidate
- [ ] Fix rough edges, improve skill instructions based on real usage
- [ ] Write `policies/review-process.md`

### Sprint 5 (Days 18-21): Harden + Document

- [ ] Review all skills for consistency (frontmatter, structure, constraints)
- [ ] Ensure every script has usage help (`forge help`)
- [ ] Write 2-3 more trusted sources
- [ ] Run `forge status` and verify it reflects reality
- [ ] Write a "Getting Started" section in README
- [ ] Tag `v1.0` in Git

### After v1

- Add review skills one at a time as you need them (security → backend → testing → ...)
- Improve existing skills based on real usage
- Consider a `forge init` command to scaffold new skills from a template
- Consider semi-automated discovery (RSS feeds → candidate suggestions)
- Consider a simple HTML report index (generated from Markdown reports)

---

## 10. Quick Reference: forge CLI Commands (v1)

```bash
# Run a review
forge review <domain> <project-path>
# Example: forge review frontend ~/projects/my-app

# Create a candidate practice
forge discover --domain <domain> --title "Practice title"
# Opens editor with candidate template

# Evaluate a candidate
forge evaluate <candidate-file>
# Runs comparison, generates report

# Record a decision
forge approve <candidate-file> --decision <approved|rejected|deferred>
# Records decision, optionally updates standard

# System status
forge status
# Shows pending candidates, recent reviews, stale standards

# Help
forge help
```

---

*This is a living document. Update it as the system evolves.*
