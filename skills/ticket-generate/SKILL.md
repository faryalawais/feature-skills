---
name: ticket-generate
description: >-
  Auto-create FE and BE Jira child tickets from approved PRD v2. Populates
  each with the relevant PRD sections, Figma frames, and ACs. The ticket IDs
  produced here are used in every file path, folder, branch, and skill from
  this point forward. Run after prd-v2 is approved.
---

# ticket-generate

Reads the approved `prd-v2.md` and creates two child Jira tickets under the
parent: one for FE (`<fe-jira-id>`) and one for BE (`<be-jira-id>`).

These IDs are immutable once created. Every subsequent file, folder, branch,
and skill reference uses them.

## Inputs
- `docs/features/<parent-id>/prd-v2.md` — approved PRD v2
- `features/<parent-id>/memory.md` — to update Feature Identity
- Jira project credentials / base URL (from environment or user config)

## Procedure

### Step 1 — Read memory
Confirm `<parent-id>` exists in memory and PRD v2 is marked approved.
If not approved, stop — do not create tickets.

### Step 2 — Prepare FE ticket content
Extract from PRD v2:
- Feature name and one-line description
- Figma frames section
- Screens and AC items tagged for UI (happy / empty / error states)
- Data Points table (fields FE needs from BE)

FE ticket body:
```
Feature: <Feature Name>
Parent: <parent-id>

## What to build
<screens and UI behaviours from PRD v2>

## Figma frames
<list of frames and nodeIds>

## Data Points (fields this FE ticket needs from BE)
<Data Points table from PRD v2>

## Acceptance Criteria
<@fe-relevant ACs from Updated Acceptance Criteria>

## Dependencies
BE ticket (<be-jira-id>) must be implemented and OpenAPI spec published
before FE implementation begins.
```

### Step 3 — Prepare BE ticket content
Extract from PRD v2:
- Feature name and one-line description
- Gherkin @be scenarios summary
- Data Points table (endpoints BE must expose)
- Edge cases related to data validation and business logic

BE ticket body:
```
Feature: <Feature Name>
Parent: <parent-id>

## What to build
<endpoints and data behaviours from PRD v2>

## Data to expose (from Data Points table)
<list of fields FE depends on>

## Acceptance Criteria
<@be-relevant ACs from Updated Acceptance Criteria>

## Gherkins
Shared Gherkins file: features/<parent-id>/<parent-id>.feature
Run with --tags @be for BE-only execution.
```

### Step 4 — Create tickets
If Jira integration is configured: create the tickets via API and record the
generated IDs.

If Jira integration is not configured: display the ticket bodies and ask
the user to create them manually and provide the IDs.

Ask the user to confirm:
- `<fe-jira-id>` = ?
- `<be-jira-id>` = ?

### Step 5 — Update memory
```markdown
## Feature Identity
- **Parent ticket:** <parent-id>
- **FE ticket:** <fe-jira-id>
- **BE ticket:** <be-jira-id>
- **Status:** tickets-created
- **Last updated:** <ISO date>
```

Also create the feature directories:
```
features/<fe-jira-id>/
features/<be-jira-id>/
docs/features/<fe-jira-id>/
docs/features/<be-jira-id>/
```

### Step 6 — Run `jira-sync`
Set all three tickets to `tickets-created`.

## Success criteria
- FE and BE child tickets exist (in Jira or confirmed by user)
- `<fe-jira-id>` and `<be-jira-id>` recorded in memory
- Feature directories created
- Jira status `tickets-created`

## Hard rules
- Never invent ticket IDs. They come from Jira (or the user).
- Once written to memory, IDs are immutable — no skill may rename them.
- FE and BE tickets are always separate — never merge into one ticket.
