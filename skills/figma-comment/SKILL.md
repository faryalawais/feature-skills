---
name: figma-comment
description: >-
  Post a stage summary as a comment on the Jira ticket and/or Figma file for
  the current feature. Used to keep stakeholders informed at key pipeline
  milestones. Run after PRD v1, Gherkins, and major gate passes.
---

# figma-comment

Cross-cutting skill. Posts a concise summary of the current stage output as a
comment on the parent Jira ticket and (optionally) the Figma file. Keeps
product, design, and engineering in sync without manual updates.

## When to run
- After PRD v1 grilling is complete (prd-author)
- After Gherkins are finalised and validated
- After FE Contract is written (design-contract)
- After gate passes (impl-gate)

## Inputs
- Current stage output (PRD file, .feature file, contract.md, or gate report)
- `features/<parent-id>/memory.md` — for ticket IDs and Figma URL
- `docs/features/<parent-id>/brief.md` — for Figma URL if needed

## Procedure

### Step 1 — Identify the trigger
Determine which stage just completed and what summary to post:

| Trigger | Summary content |
|---------|----------------|
| After `prd-author` | Problem, goal, screen list, open questions |
| After `gherkin-validate` | Scenario count, @fe/@be split, AC coverage |
| After `design-contract` | Component list, API bindings, Figma coverage check result |
| After `impl-gate` pass | Gate result, test counts, visual diff status |

### Step 2 — Format the comment
```markdown
## Pipeline Update — <Stage Name> ✓
**Feature:** <parent-id> — <Feature Name>
**Date:** <ISO date>

<stage summary — 3-8 bullet points>

**Next step:** <next skill in pipeline>
```

### Step 3 — Post to Jira
If Jira integration is configured: POST comment via Jira API to `<parent-id>`.
If not configured: display the comment and ask the user to post it manually.

### Step 4 — Post to Figma (optional)
If `brief.md` has a Figma URL and the Figma MCP is available:
Post the same summary as a Figma comment on the relevant frame.
If Figma MCP is unavailable, skip silently — do not block the pipeline.

## Success criteria
- Comment posted (or user confirmed manual post) on Jira ticket
- No pipeline blocking — this skill is informational only

## Hard rules
- Never block the pipeline waiting for a Figma comment to succeed.
- This skill has no output file. It only posts comments.
- Keep comments concise — stakeholders skim; use bullet points, not paragraphs.
