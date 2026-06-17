---
name: spec-author
description: Write a Gherkin feature spec for one backlog feature. Use this skill whenever the user wants a feature spec, Gherkin scenarios, a .feature file, or BDD scenarios for a feature — even if they don't explicitly say "skill". Run this after story-author and before design-contract.
---

# spec-author

Step 5a of the agentic SDLC loop. Turns one backlog story into an executable
Gherkin specification. (The *design contract* is a separate concern — the
`design-contract` skill owns it.)

## Inputs
- `features/backlog.yaml` — and a target feature `id` (ask the user if unclear,
  otherwise take the highest-priority `pending` feature).
- `docs/specs/<parent-id>/spec.md` — **primary input** (the Spec Kit requirements doc).
  For a UI slice `F-NNN.2`, parent id is `F-NNN` (without the `.2`). For a classic
  full feature, the spec path is `docs/specs/<id>/spec.md`.
  If this file is missing, stop and tell the user to run **speckit-requirements** first.
  Do not write Gherkin without it.
- `docs/specs/<parent-id>/plan.md` — implementation plan (read if present).
- `docs/specs/<parent-id>/checklists/ux.md` — UX checklist of states and edge cases (read if present).
- `reports/tokens-report.md` — the allowed design-token vocabulary.

## Outputs
- `features/<id>/<id>.feature` — the Gherkin spec.

## Procedure

0. If the target has `slice: api` (id `F-NNN.1`), **stop** — run **api-spec-author**
   instead. This skill is for UI slices (`.2`), classic full features, and parents
   that are not API-only.

1. Read `docs/specs/<parent-id>/spec.md` as the authoritative requirements source.
   Cross-reference with the feature's `acceptance_criteria` in backlog.yaml — prefer
   spec.md where they differ (it has been through grilling and clarification).
   Read `plan.md` and `checklists/ux.md` if present for additional states and edge cases.
2. Write `features/<id>/<id>.feature` in Gherkin:
   - One `Feature:` block.
   - A `Scenario:` for the happy path plus scenarios for the key edge cases
     drawn from the story's `acceptance_criteria`.
   - **Component paths** — interactive UI uses `` `component.…` `` paths from the
     UI registry (backticks).
   - **Field bindings** — when UI displays API/server data, use field-path steps:
     `` Then `field.user.info.firstName` is displayed in `component.dashboard.overview.welcomeHeading` ``
     or slash aliases registered in `tokens/api-registry.json` (e.g.
     `` `/user/info.firstName` ``). See `reports/api-registry-glossary.md`.
   - **Token steps** — where appearance matters, use
     `Then … uses token "color.action.primary"` (tokens from `reports/tokens-report.md` only).
3. Update the feature's `status` in `backlog.yaml` to `specced`.

## Success criteria
The `.feature` file is valid Gherkin, every referenced token exists in the
tokens report, and the backlog status is `specced`.

## Failure handling
If a scenario needs a token that does not exist, do not invent one — stop and
tell the user the design system is missing that token.
