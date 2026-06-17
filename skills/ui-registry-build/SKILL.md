---
name: ui-registry-build
description: >-
  Build tokens/ui-registry.json from the Figma spec.json for the FE feature.
  Catalogues every component, state, and token binding found in the Figma
  frame. Run after figma-extract and design-tokens, before design-contract.
---

# ui-registry-build

Reads `features/<fe-jira-id>/figma/spec.json` and the compiled token
vocabulary (`reports/tokens-report.md`) to produce `tokens/ui-registry.json`.
This registry is the component catalogue that `design-contract` and
`fe-implement` use to know what exists, what states it has, and which tokens
it uses.

## Inputs
- `features/<fe-jira-id>/figma/spec.json` — Figma frame extract
- `reports/tokens-report.md` — compiled token vocabulary
- `features/<fe-jira-id>/memory.md` — to read Gherkins section for component paths

## Procedure

### Step 1 — Read spec.json
Parse every named element in spec.json:
- `sections[].name`
- `sections[].layers[].name`
- `sections[].widgets[].name`
- `sections[].columns[].name`
- `sections[].banners[].name`
- Any nested sub-elements with `name` fields

Build a flat list of every named Figma element.

### Step 2 — Map to component paths
For each Figma element, derive a `component.*` path using lowerCamelCase:
- Screen-level containers → `screen.<featureName>`
- Top-level sections → `component.<featureName>.<sectionName>`
- Sub-elements → `component.<featureName>.<sectionName>.<elementName>`

Path rules:
- All segments lowerCamelCase (`[a-z][a-zA-Z0-9]*`)
- No spaces, no PascalCase, no slashes, no underscores
- Maximum 4 segments deep

### Step 3 — Identify states for each component
For each component, check spec.json for variant data or layer naming that
indicates states (hover, active, disabled, empty, error, loading).
Default state is always `default`.

### Step 4 — Map token bindings
For each component, look up which design tokens apply based on:
- Background colour → `$background` token from `tokens-report.md`
- Text colour → `$color` token
- Border → `$border` token
- Border radius → `$radius` token
- Spacing/padding → `$spacing` token

If a Figma value has no exact token match, record `"tokenMissing": true`
and note the raw Figma value.

### Step 5 — Write `tokens/ui-registry.json`

```json
{
  "screen.<featureName>": {
    "$description": "<what this screen is>",
    "$states": ["default"],
    "$tokens": {}
  },
  "component.<featureName>.<sectionName>": {
    "$description": "<what this component is>",
    "$screen": "screen.<featureName>",
    "$states": ["default", "hover", "empty"],
    "$tokens": {
      "$background": "<token-name>",
      "$color": "<token-name>",
      "$radius": "<token-name>"
    }
  }
}
```

Merge into existing `tokens/ui-registry.json` if the file exists — do not
overwrite entries for other features.

### Step 6 — Run `registry-validate`
Run `registry-validate` immediately after writing. Fix any failures before
writing to memory.

### Step 7 — Write to memory
Append to `features/<parent-id>/memory.md`:
```markdown
## UI Registry
<!-- Written by: ui-registry-build on <ISO date> -->
<!-- Validated by: registry-validate — pending -->
Full file: tokens/ui-registry.json

### Components catalogued
- <component.path>: <description>
```

### Step 8 — Run `jira-sync`
Set FE ticket to `ui-registry-ready`.

## Success criteria
- `tokens/ui-registry.json` updated with all Figma components
- Every named Figma element has a `component.*` entry
- Every entry has `$states` and `$tokens`
- `registry-validate` exits 0
- Memory UI Registry section written

## Hard rules
- Never invent component paths. Every path must trace to a named Figma element.
- Never merge-overwrite entries from other features in the registry.
- If spec.json is missing or empty → stop. Do not write the registry.
  Report and instruct user to run `figma-extract` first.
