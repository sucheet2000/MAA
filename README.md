# MAA — My Automated Advisor

A local-first, skill-based engineering standards system. Runs on your machine. Lives in Git. No cloud, no database, no web UI.

## What It Does

MAA lets you:
- Run structured reviews of real projects against your approved engineering standards
- Track candidate practices you're considering adopting
- Record approvals and rejections with rationale
- Keep all standards, decisions, and reports version-controlled in Git

## Directory Layout

```
MAA/
├── maa                          # CLI entrypoint — run this
├── standards/                   # Approved engineering standards (Markdown)
├── policies/                    # Cross-cutting rules and processes
├── sources/                     # Curated trusted sources (YAML)
├── skills/                      # Skill folders (SKILL.md + templates)
│   └── review/
│       └── frontend-review/
├── scripts/                     # Bash scripts invoked by the CLI
├── reports/reviews/             # Generated review reports
├── candidates/                  # Candidate practices under consideration
├── evaluations/                 # Evaluation records
├── decisions/                   # Approval/rejection records
└── .maa/config.yaml             # Local configuration
```

## Quick Start

### Run a frontend review

```bash
./maa review frontend /path/to/your/project
```

This will:
1. Validate the project path
2. Detect whether it looks like a frontend project
3. Run a set of concrete checks (framework, linting, formatting, tests, etc.)
4. Write a Markdown report to `reports/reviews/`
5. Print the report path

### Read the report

```bash
cat reports/reviews/YYYY-MM-DD-<project>-frontend.md
```

## Commands

```bash
./maa review frontend <project-path>   # Run a frontend standards review
./maa help                             # Show usage
```

## Sprint 1 Scope

Sprint 1 implements the narrowest useful slice:
- Repo scaffolding
- Frontend standards document
- Frontend review skill
- `maa review frontend` command with concrete bash checks

Future sprints will add: evaluation pipeline, approval workflow, more domains, discovery tooling.

## Configuration

`.maa/config.yaml` is scaffolded but **not yet read at runtime** (Sprint 1). The scripts
hardcode paths relative to the repo root, which match the defaults in the config file.
Fill in your name; everything else takes effect once config parsing is wired up in a later sprint.

## Philosophy

- Every standard is a file you can read and edit
- Every report is a file in Git
- Every decision is recorded with rationale
- Nothing runs without your knowledge
- Human approval is always the final gate
