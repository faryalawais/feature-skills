---
name: fe-implement
description: >-
  Implement the FE feature by reading the FE contract (contract.md), Figma
  frame data, @fe Gherkins, and the published OpenAPI spec from BE. Uses
  speckit internally — one task per @fe scenario, component by component.
  Figma is the visual reference; contract.md is the boundary; OpenAPI is the
  data contract. Run only after BE ticket is be-implemented.
---

# fe-implement

Implements the FE feature — React components, pages, and API integration —
using the FE contract as the build checklist and Figma as the visual reference.
BE must be fully implemented and the OpenAPI spec published before this starts.

## Inputs
- `features/<fe-jira-id>/contract.md` — FE implementation boundary
- `features/<fe-jira-id>/figma/` — Figma frame assets, reference.png, spec.json
- `features/<parent-id>/<parent-id>.feature` (`@fe` scenarios only)
- `docs/openapi/paths/<be-jira-id>.yaml` — the published BE API contract
- `tokens/ui-registry.json` — component paths and token bindings
- `reports/tokens-report.md` — allowed token vocabulary
- `features/<parent-id>/memory.md`

## Pre-flight checks (mandatory before any code)

Before writing a single line of UI code:

1. Confirm BE ticket is `be-implemented` in memory. If not, stop — FE
   cannot start until BE is complete.
2. Verify `features/<fe-jira-id>/contract.md` exists and both
   `validate:figma-coverage` and `validate:contract` passed.
3. Verify `features/<fe-jira-id>/figma/reference.png` exists.
4. Read `contract.md` §2 anatomy completely — build a checklist of every
   named element. Every element in §2 must be rendered. No gaps.

## Procedure

### Step 1 — Read all inputs
Read these completely before writing any code:
1. `contract.md` — full component anatomy, layout, tokens, states, API bindings
2. `figma/reference.png` — open and keep as visual reference throughout
3. `figma/spec.json` — exact measurements, colours, spacing
4. `docs/openapi/paths/<be-jira-id>.yaml` — know every endpoint and response field
5. `tokens-report.md` — know which token names to use

### Step 2 — Plan with speckit
Run `speckit-plan` with:
- `@fe` Gherkin scenarios as the task source
- FE contract as the context document
- Output: one task per `@fe` scenario

Task naming: `fe-<component-slug>-<scenario-slug>`
Example: `fe-feedback-form-happy-path`, `fe-feedback-form-empty-state`

### Step 3 — Create task list
Run `speckit-tasks`. Each task must state:
- Which component it builds
- Which `@fe` scenario it covers
- Which `contract.md` anatomy sections it implements
- Which API field bindings apply

### Step 4 — Implement component by component
Run `speckit-implement` one task at a time.

**Token discipline — enforced throughout:**
- No raw hex values. All colours from `var(--token-name)` or Tailwind token class.
- No raw `px` values. All spacing from token-backed Tailwind classes.
- Every token name must exist in `reports/tokens-report.md`.

**Component anatomy enforcement:**
- Every element named in `contract.md` §2 must be rendered.
- Every element with a `[component.*]` tag gets `data-testid={ids.<path>}`.
- Every element with a `data-api-field` marker gets `data-api-field={fields.<path>}`.
- No placeholder text, no skeleton layouts, no "TODO: implement" comments.

**API integration:**
- Fetch from the exact endpoint paths defined in `docs/openapi/paths/<be-jira-id>.yaml`.
- Response fields accessed by their exact JSON paths from contract.md §1b.
- Handle loading, error, and empty states as specified in contract.md §5.

**Figma fidelity:**
- After implementing each component, compare visually against `reference.png`.
- Layout, spacing, typography, colours must match Figma within fidelity tolerance
  defined in contract.md §11.

### Step 5 — Run tests after each component
```bash
npm run test:e2e -- --grep "<scenario name>"
```

Fix failures before moving to the next component. Never move on with a
failing scenario.

### Step 6 — Final gate
After all components implemented:
```bash
npm run test:e2e && npm run test:visual
```

Both must exit 0.

If `test:e2e` fails: fix the component implementation, not the test.
If `test:visual` fails with a diff: compare against `reference.png`.
  If it's a real regression → fix the component.
  If the Figma design changed → re-run `figma-extract` and update the baseline.
  Never update the visual baseline to hide a real fidelity gap.

Also run:
```bash
npm run typecheck && npm run lint && npm run token-lint
```

All three must pass.

### Step 7 — Write to memory
```markdown
## Implementation Notes
### FE notes
<!-- Written by: fe-implement on <ISO date> -->
- Components implemented: <list>
- test:e2e: passed (<N> scenarios)
- test:visual: passed
- typecheck: passed
- token-lint: passed
- Deviations from contract: <none / list if any>
```

### Step 8 — Run `jira-sync`
Set FE ticket to `fe-implemented`.

### Step 9 — Run `figma-comment`
Post FE implementation complete notice to parent Jira ticket.

## Success criteria
- Every element in `contract.md` §2 anatomy is rendered
- Every `[component.*]` tag has a corresponding `data-testid`
- `test:e2e` exits 0
- `test:visual` exits 0
- `typecheck`, `lint`, `token-lint` all pass
- No raw hex or px in `app/` or `components/`
- FE ticket `fe-implemented`

## Hard rules
- FE NEVER starts before BE ticket is `be-implemented`.
- Never modify test files to make them pass. Fix the component.
- Never update visual baseline to hide a fidelity gap. Fix the component.
- Every element in §2 anatomy is required — omitting any element is a blocker.
- No `any`, no `@ts-ignore`, no disabled lint rules.
- speckit is used internally — do not call speckit skills from outside this skill.
