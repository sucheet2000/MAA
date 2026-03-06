# Standards Index

All approved engineering standards. Each entry is a versioned document in `standards/`.

---

## Active Standards

| ID | File | Domain | Version | Last Updated | Last Reviewed | Summary |
|----|------|--------|---------|--------------|---------------|---------|
| frontend | frontend.md | frontend | 1.0.0 | 2026-03-05 | 2026-03-05 | Component architecture, TypeScript, state, a11y, performance, styling, testing, tooling |

---

## Planned (not yet written)

| ID | Domain | Notes |
|----|--------|-------|
| backend | backend | Python/Node API standards |
| api-design | api | REST and GraphQL conventions |
| security | security | Auth, secrets, headers, dependency hygiene |
| testing | testing | Cross-domain testing standards |

---

## How to Add a Standard

1. Write the standard as `standards/<id>.md` following the format in existing standards
2. Add an entry to this index
3. Record the approval in `decisions/`
4. Commit with message: `docs(standards): add <id> standard v1.0.0`

## Review Schedule

Standards not reviewed in 90 days should be flagged for re-review. Check `Last Reviewed` dates above.
