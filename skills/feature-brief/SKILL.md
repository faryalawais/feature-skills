---
name: feature-brief
description: >-
  Create a one-paragraph feature brief and initialise project memory for the
  feature. This is the entry point for every new feature in the pipeline. Run
  this first — before prd-author, before any Figma or Swagger work.
---

# feature-brief

Creates `docs/features/<parent-id>/brief.md` and initialises
`features/<parent-id>/memory.md`. Everything downstream depends on these two
files existing.

## Inputs
- User's description of the feature (verbal or written — any form)
- Jira parent ticket ID (`<parent-id>`) — ask the user if not provided

## Procedure

### Step 1 — Collect the brief
Ask the user for:
1. **What is the feature?** One sentence describing what it does.
2. **Who is it for?** The primary user or persona.
3. **What problem does it solve?** The pain without it.
4. **Any Figma frames or designs ready?** (yes/no, URL if yes)
5. **Any existing API or Swagger spec?** (yes/no, URL if yes)

Do not move to Step 2 until all five are answered.

### Step 2 — Write `docs/features/<parent-id>/brief.md`

```markdown
# Feature Brief — <parent-id>

**Feature:** <one sentence>
**Persona:** <who it's for>
**Problem:** <pain without it>
**Figma:** <URL or "none yet">
**Swagger:** <URL or "none yet">
**Created:** <ISO date>
```

### Step 3 — Initialise `features/<parent-id>/memory.md`

Create the file with this structure and populate Feature Identity:

```markdown
# Feature Memory — <parent-id>: <Feature Name>

## Feature Identity
- **Parent ticket:** <parent-id>
- **FE ticket:** TBD (set by ticket-generate)
- **BE ticket:** TBD (set by ticket-generate)
- **Status:** brief-created
- **Last updated:** <ISO date>

---

## PRD v1
<!-- To be written by: prd-author -->

---

## PRD v2
<!-- To be written by: prd-update -->

---

## Gherkins
<!-- To be written by: spec-author -->

---

## UI Registry
<!-- To be written by: ui-registry-build -->

---

## FE Contract
<!-- To be written by: design-contract -->

---

## BE Contract
<!-- To be written by: openapi-author + business-logic-author + orm-schema-author -->

---

## Implementation Notes
<!-- To be written by: fe-implement and be-implement -->

---

## Gate Results
<!-- To be written by: impl-gate -->
```

### Step 4 — Run `jira-sync`
Update parent ticket status to `brief-created`.

## Success criteria
- `docs/features/<parent-id>/brief.md` exists and is non-empty
- `features/<parent-id>/memory.md` exists with Feature Identity populated
- Jira parent ticket status is `brief-created`

## Hard rules
- Never invent a `<parent-id>`. If the user has not provided a Jira ticket ID, ask.
- Never skip Step 1 grilling. A brief written without answers is not a brief.
- `memory.md` must be created even if partially empty — downstream skills depend on the file existing.
