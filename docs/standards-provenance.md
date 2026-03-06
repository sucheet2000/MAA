# Standards Provenance and Discovery

Describes the provenance schema used in MAA's standards corpus, how origin and sources are
recorded, how trusted external sources are registered, and how candidate practices move
through evaluation to approval.

---

## Why provenance matters

Every approved standard in MAA is a claim: _this practice is good, and you should be
checked against it_. Provenance records the basis for that claim. It answers:

- Was this standard written from first principles, or derived from identified external sources?
- Which external sources informed it?
- When was it last reviewed against those sources?

Provenance makes standards auditable and improveable. It is not a quality gate — a `seed`
standard is as valid as a `curated` one. It is a record of how the standard came to exist.

---

## Provenance schema

Each approved standard file carries two provenance fields in its header block, after `**Status:**`:

```
**Origin:** <value>
**Sources:** <value>
```

### Origin

Describes how the standard was produced.

| Value | Meaning |
|-------|---------|
| `seed` | Written from the owner's expert judgment. No external sources were formally cited when the standard was written. |
| `curated` | Synthesised from one or more identified trusted sources listed in `**Sources:**`. |

`seed` is the starting point for all current standards. A standard can be upgraded to
`curated` when it is revised with reference to identified trusted sources and those
sources are listed. This does not require rewriting the standard — it requires noting
which sources informed the revision.

### Sources

Lists the trusted-source IDs (from `sources/registry.md`) that were consulted when the
standard was written or last revised.

| Value | Meaning |
|-------|---------|
| `none` | No trusted sources were formally cited (expected for all `seed` standards). |
| `<id>, <id>, ...` | Comma-separated IDs from `sources/registry.md`. |

Example for a curated standard:

```
**Origin:** curated
**Sources:** owasp-top-10, owasp-asvs, nodejs-security-docs
```

---

## Trusted-source registry

The registry of known authoritative external sources is at `sources/registry.md`.

Each entry records:
- A short ID used in the `**Sources:**` field
- Name, URL, and the domain it applies to
- Trust level: `authoritative`, `reference`, or `community`
- Date last checked for relevance
- Brief notes on when to use it

The registry exists to keep source selection consistent. When revising a standard with
reference to external sources, look here first. If the right source is not listed, add it
to the registry as part of the revision.

---

## Candidate practices

Before a practice enters an approved standard, it may spend time as a candidate —
under evaluation, not yet approved.

Candidate documents live in `candidates/`. See `candidates/README.md` for the directory
structure and intake process.

A candidate document captures:

- The proposed practice, stated precisely
- The domain and applicable standard section it would affect
- The source(s) the practice comes from (with trust level reasoning)
- Comparison to what the current standard says
- Arguments for and against adoption
- Open questions

### Evaluation criteria

A candidate is ready for adoption when:
- The source(s) are in `sources/registry.md` at `authoritative` or `reference` trust level
- The practice is specific enough to produce a detectable signal (Build Review) or a
  checkable concern (Plan Review)
- There is no material conflict with existing criteria, or the conflict is resolved by
  replacing the weaker criterion

### Approval workflow

1. **Draft** — Write candidate document in `candidates/<domain>-<slug>.md`
2. **Review** — Evaluate against the criteria above; add comparison notes
3. **Decision** — Record approval or rejection in `decisions/`; use format
   `YYYY-MM-DD-<domain>-<slug>-<approved|rejected>.md`
4. **Merge** — If approved: update the standard, bump its version, update `_index.md`,
   update `**Origin:**` to `curated` and `**Sources:**` to the relevant source IDs
5. **Commit** — `docs(standards): adopt <practice> into <id> standard v<version>`

Rejection is not failure. A rejected candidate with a clear rationale is useful —
it prevents the same discussion from repeating.

---

## Current corpus state (2026-03-06)

All 7 approved standards are `seed` origin. No external sources have been formally
cited against any standard. The trusted-source registry in `sources/registry.md`
is seeded with known authoritative sources per domain for use in future revisions.

The standards are ready to be upgraded to `curated` as they are revised. The
infrastructure (schema, registry, candidate format, approval workflow) is now in place.
