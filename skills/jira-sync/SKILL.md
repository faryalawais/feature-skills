---
name: jira-sync
description: >-
  Update Jira ticket status at a pipeline stage completion. Cross-cutting skill
  run after every stage. Also updates the Status field in feature memory.
---

# jira-sync

Cross-cutting skill. Updates the Jira ticket status to the correct value for
the current pipeline stage, and syncs the memory file Status field.

## Status values by stage

| Stage completed | Ticket | Status to set |
|----------------|--------|---------------|
| feature-brief | parent | `brief-created` |
| prd-author + prd-review (v1) | parent | `prd-v1-approved` |
| prd-update + prd-review (v2) | parent | `prd-v2-approved` |
| ticket-generate | parent + FE + BE | `tickets-created` |
| gherkin-validate | parent | `gherkins-ready` |
| figma-extract (FE) | FE ticket | `figma-extracted` |
| design-tokens (FE) | FE ticket | `tokens-compiled` |
| ui-registry-build (FE) | FE ticket | `ui-registry-ready` |
| design-contract (FE) | FE ticket | `fe-contract-ready` |
| repo-setup (BE) | BE ticket | `be-repo-ready` |
| orm-schema-author (BE) | BE ticket | `be-contract-ready` |
| be-implement (BE) | BE ticket | `be-implemented` |
| fe-implement (FE) | FE ticket | `fe-implemented` |

## Procedure

### Step 1 — Identify which ticket and which status
Determine from context which stage just completed and which ticket to update.

### Step 2 — Update Jira
If Jira integration is configured: PATCH ticket status via Jira API.
If not configured: display the required status change and ask the user to
apply it manually. Do not block — continue immediately after.

### Step 3 — Update memory
Open `features/<parent-id>/memory.md` and update the Feature Identity block:
```markdown
- **Status:** <new status>
- **Last updated:** <ISO date>
```

## Success criteria
- Jira ticket status updated (or user notified)
- Memory Status field updated

## Hard rules
- This skill never advances a ticket to `approved` — only humans do that.
- This skill has no output file of its own.
- Never set `awaiting-approval` — that status is set by the final impl-gate only.
