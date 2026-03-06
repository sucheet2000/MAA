# Approval Process

How a candidate practice becomes an approved standard in MAA.

---

## Guiding Principles

- No standard changes without explicit human decision
- Every decision is recorded with rationale
- Evaluation quality matters more than speed
- Approval is permanent record — rejection and deferral are too

---

## The Workflow

```
Candidate record created
        │
        ▼
Evaluation runs (comparison / benchmark)
        │
        ▼
You review the evaluation report
        │
        ▼
Decision: approved | rejected | deferred
        │
   ┌────┴─────┐
   │          │
approved    rejected/deferred
   │          │
   ▼          ▼
Standard    Decision recorded in decisions/
updated     Candidate status updated
   │
   ▼
Changelog entry added
Git commit with decision reference
```

---

## Step 1: Create a Candidate

A candidate is a YAML file in `candidates/` describing the proposed practice.

Filename format: `YYYY-MM-DD-<slug>.yaml`

Required fields:
- `title` — one line description
- `domain` — which standards document this affects
- `source_id` — id from `sources/trusted-sources.yaml`
- `source_url` — direct link to the source material
- `current_practice` — what we do now (quote from the standard if possible)
- `proposed_practice` — what we would do instead
- `rationale` — why this change is worth evaluating
- `risks` — list of known downsides or unknowns

---

## Step 2: Evaluate

Run the `practice-comparator` skill (Sprint 2+) or evaluate manually.

A good evaluation covers at minimum:
- **Correctness** — is the proposed practice technically sound?
- **Complexity** — does it add cognitive overhead?
- **Adoption cost** — how much migration/retraining is required?
- **Source quality** — how authoritative is the source?

Score each axis 1–5. Include a written rationale for each score.

Save the evaluation to `evaluations/YYYY-MM-DD-<slug>/`.

---

## Step 3: Make a Decision

Options:

| Decision | Meaning |
|----------|---------|
| `approved` | Practice accepted. Standard will be updated. |
| `rejected` | Practice declined. Do not revisit without new evidence. |
| `deferred` | Not adopting now. Revisit at a specified future date. |

Create a decision record in `decisions/YYYY-MM-DD-<slug>.yaml`:

```yaml
id: dec-YYYY-MM-DD-<slug>
candidate_id: YYYY-MM-DD-<slug>
evaluation_id: eval-YYYY-MM-DD-<slug>   # if evaluation exists
decided: YYYY-MM-DD
decision: approved | rejected | deferred
rationale: |
  One or more sentences explaining your reasoning.
standard_changed: true | false
next_review: YYYY-MM-DD   # required if deferred
```

---

## Step 4: Update the Standard (if approved)

If the decision is `approved`:
1. Edit the relevant `standards/<domain>.md` file
2. Bump the version number in the frontmatter
3. Add a changelog entry at the bottom of the standards file
4. Update `standards/_index.md` with the new version and date
5. Commit everything together:
   ```
   docs(standards): update frontend.md v1.0.0 → v1.1.0

   Adopts [practice title]. See decisions/YYYY-MM-DD-<slug>.yaml.
   ```

---

## Trust Levels

Practices from `authoritative` sources require less evidence for approval.
Practices from `medium` trust sources require manual cross-referencing before approval.

See `sources/trusted-sources.yaml` for source trust levels.
