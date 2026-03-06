# Candidates

Candidate practices under evaluation for adoption into the standards corpus.

A candidate is a practice that has been identified as potentially worth adding to an
approved standard, but has not yet been reviewed and approved. This directory is the
staging area between "interesting idea" and "approved standard".

---

## What belongs here

- A practice from an identified external source that is not yet covered by an approved standard
- A proposed update to an existing standard criterion (tighter wording, new signal, changed threshold)
- A conflict between two standards that needs resolution before either is updated

Does not belong here:
- Exploratory notes or brainstorming — start those elsewhere
- Rejected practices — those are recorded in `decisions/` once reviewed

---

## File naming

```
candidates/<domain>-<slug>.md
```

Examples:
- `candidates/security-subresource-integrity.md`
- `candidates/deployment-distroless-base-images.md`
- `candidates/testing-mutation-coverage.md`

One practice per file. If a candidate touches multiple domains, name it after the
primary domain and note the secondary domain inside.

---

## Candidate document format

```markdown
# Candidate: <short name>

**Domain:** <domain>
**Affects standard:** standards/<id>.md §<section>
**Date opened:** YYYY-MM-DD
**Status:** under evaluation | approved | rejected

---

## Proposed practice

<State the practice precisely. One clear sentence is better than a paragraph.>

## Source

<Source name and URL. Cross-reference the ID from sources/registry.md if listed there.>
**Trust level:** <authoritative | reference | community>

## Current standard says

<Quote or paraphrase the relevant criterion from the current standard, or "not covered".>

## Argument for adoption

<Why this practice belongs in the standard.>

## Argument against / risks

<What could go wrong; why we might not adopt it; what we'd be giving up.>

## Open questions

<Anything unresolved that must be answered before a decision can be made.>

## Decision

<Fill in when reviewed. Link to the decision record in decisions/.>
```

---

## Approval workflow

See `docs/standards-provenance.md` for the full workflow. In brief:

1. Write candidate document here
2. Review: evaluate source quality, specificity, and fit against existing criteria
3. Record decision in `decisions/` regardless of outcome
4. If approved: update the standard, bump its version, update `_index.md`,
   set `**Origin:** curated` and `**Sources:**` in the standard's header
5. Commit with `docs(standards): adopt <practice> into <id> standard v<version>`

---

## Current candidates

_(none — directory is empty)_
