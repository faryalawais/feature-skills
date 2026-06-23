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

## Smart zone check (run before anything else)

Count the `@fe` scenarios in the feature file:
```bash
grep -c "^\s*@fe" features/<parent-id>/<parent-id>.feature
```

- **≤ 10 scenarios** → proceed normally.
- **11–20 scenarios** → warn: _"⚠️ This feature has N @fe scenarios — you may hit the smart zone limit mid-run. Consider starting a fresh chat for each group of ~10 scenarios, or split the feature further with `/to-issues`."_ Then ask: _"Continue in this chat or split first?"_
- **> 20 scenarios** → warn strongly: _"⚠️ This feature has N @fe scenarios — too large for reliable output in one context window. Recommended: split the feature using `/to-issues` into smaller slices, then implement each slice in a fresh chat. Continue anyway?"_ Wait for the user to decide.

Each scenario = one component task. Never implement more than one component per task pass.

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

### Step 0 — Validate feature branch
```bash
git rev-parse --abbrev-ref HEAD
```
Must equal `feature/<fe-jira-id>`. If it is `main` or anything else, stop:
> "Wrong branch. Switch with: `git checkout feature/<fe-jira-id>`"
> `design-contract` creates the branch — if it does not exist yet, that skill must run first.

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

**§4 Token Audit — mandatory after EVERY component, before moving on:**
`token-lint` only catches raw values — it cannot catch a wrong token. `bg-surface-warning`
and `bg-surface-brand` are both valid tokens; only `contract.md §4` says which is correct.

After writing each component, open `contract.md §4 Tokens per element` and walk every row
that applies to elements in that component. For each row, verify the exact token used in
the className matches §4 — background, text, border, radius, font size, font weight.

Example check:
```
§4 says: Promo Side Banner | bg: color.surface.brand | text: color.text.inverse
Component uses: bg-surface-brand ✓  text-text-inverse ✓  → pass

§4 says: Feature label | font: font.weight.semibold
Component uses: font-medium  → FAIL — fix before continuing
```

Do not move to the next component until every §4 row for the current component passes.
A §4 mismatch is a blocker, the same as a failing test.

**globals.css — must import tokens before any code is written:**
`app/globals.css` MUST have `@import '../tokens/build/tokens.css';` as its first line,
before the Tailwind directives. Without it, every `var(--color-*)` / `var(--spacing-*)`
reference resolves to `unset` — the page renders with no colour, no spacing, no shadows.
Check this file exists and has the import before writing any component.

```css
@import '../tokens/build/tokens.css';

@tailwind base;
@tailwind components;
@tailwind utilities;
```

**Layout shell — mandatory for every feature layout:**
Every `app/<group>/layout.tsx` that renders a nav + main + footer shell MUST use:
```tsx
<div className="flex flex-col min-h-screen">
  <SiteNav />
  <main className="flex-1">{children}</main>
  <SiteFooter />
</div>
```
Without `min-h-screen` + `flex-1`, short-content pages leave a large white gap
between the content card and the footer, and the footer floats in the middle
of the viewport instead of sitting at the bottom. Never use a bare fragment `<>`
as the layout root when the layout includes a header, main, and footer.

**Component anatomy enforcement:**
- Every element named in `contract.md` §2 must be rendered.
- Every element with a `[component.*]` tag gets `data-testid={ids.<path>}`.
- Every element with a `data-api-field` marker gets `data-api-field={fields.<path>}`.
- No placeholder text, no skeleton layouts, no "TODO: implement" comments.

**API integration:**
- Fetch from the exact endpoint paths defined in `docs/openapi/paths/<be-jira-id>.yaml`.
- Response fields accessed by their exact JSON paths from contract.md §1b.
- Handle loading, error, and empty states as specified in contract.md §5.

**Responsive design — mandatory on every component:**
Every page and component MUST be responsive across all screen sizes. Figma shows
desktop at a fixed width — that is the fidelity target for desktop, but the
implementation must also work at mobile (≥320px) and tablet (≥768px).
- Use Tailwind responsive prefixes (`sm:`, `md:`, `lg:`, `xl:`) for layout changes.
- Fixed widths like `w-[424px]` that are wider than mobile viewport MUST get a
  mobile override: `w-full sm:w-[424px]`.
- Horizontal padding like `px-[300px]` (allow-raw) that would collapse content on
  mobile MUST have a responsive alternative: `px-4 sm:px-8 lg:px-[300px]`.
- Multi-column layouts (nav tiers, footer columns) MUST stack vertically on mobile.
- Never ship a component that clips or overflows horizontally on any viewport width.
- After implementing each component, resize the browser to 375px wide and verify
  nothing overflows before moving to the next component.

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
After all components implemented, run a full §4 sweep across every implemented component:
re-open `contract.md §4` and check each row against the finished files. This is the last
chance to catch any wrong token that slipped through the per-component audit.

Then run:
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

### Step 10 — Commit, push branch, open PR
```bash
# Stage all feature work
git add app/ components/ features/<fe-jira-id>/ docs/ tokens/

# Commit
git commit -m "feat(<fe-jira-id>): <short description of feature>

- <component 1>
- <component 2>
- test:e2e passed, test:visual passed

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

# Push feature branch
git push origin feature/<fe-jira-id>

# Open PR targeting main
gh pr create \
  --base main \
  --head feature/<fe-jira-id> \
  --title "feat(<fe-jira-id>): <Feature Name>" \
  --body "$(cat <<'EOF'
## Summary
- Implements <Feature Name> FE
- All @fe Gherkin scenarios covered
- test:e2e passed, test:visual passed, typecheck passed

## Components
<list of components>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**Hard rule: never push directly to `main`. The PR is the only merge path.**

## Success criteria
- Every element in `contract.md` §2 anatomy is rendered
- Every `[component.*]` tag has a corresponding `data-testid`
- `test:e2e` exits 0
- `test:visual` exits 0
- `typecheck`, `lint`, `token-lint` all pass
- No raw hex or px in `app/` or `components/`
- All pages render correctly at 375px, 768px, and 1280px+ viewport widths
- FE ticket `fe-implemented`
- Feature branch `feature/<fe-jira-id>` pushed to origin
- PR opened targeting `main`
- `main` branch unchanged — no direct commits to main

## Hard rules
- FE NEVER starts before BE ticket is `be-implemented`.
- Never modify test files to make them pass. Fix the component.
- Never update visual baseline to hide a fidelity gap. Fix the component.
- Every element in §2 anatomy is required — omitting any element is a blocker.
- **After every component: audit §4 (Tokens per element) row by row. `token-lint` cannot
  catch a wrong token — `bg-surface-warning` and `bg-surface-brand` are both valid tokens,
  only §4 says which is correct. A §4 mismatch is a blocker.**
- No `any`, no `@ts-ignore`, no disabled lint rules.
- **Never push directly to `main`.** Commit to `feature/<fe-jira-id>` and open a PR.
- Every component must be responsive — no horizontal overflow at any viewport width.
- speckit is used internally — do not call speckit skills from outside this skill.
