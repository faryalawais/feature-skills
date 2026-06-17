---
name: openapi-author
description: Author or update OpenAPI 3.1 specs for an API slice from its Gherkin and acceptance criteria. Use for Swagger/OpenAPI documentation, API-first contracts, or before be-implement.
---

# openapi-author

Turns a BE ticket's Gherkins into the **machine-readable HTTP contract**
(OpenAPI 3.1) that `be-implement` and `gate:api` enforce.

## Inputs

- `features/<parent-id>/<parent-id>.feature` — shared Gherkin file (`@be` scenarios only).
- `docs/features/<parent-id>/prd-v2.md` — for endpoint context.
- Existing `docs/openapi/openapi.yaml` — merge; never delete another feature's paths.
- `features/<parent-id>/memory.md` — confirm gherkin-validate passed before starting.

## Outputs

| File | Purpose |
|------|---------|
| `docs/openapi/paths/<be-jira-id>.yaml` | Feature-scoped path fragment (source of truth for this feature's endpoints) |
| `docs/openapi/openapi.yaml` | Root spec — this feature's paths merged in inline |
| `docs/features/<be-jira-id>/api-contract.md` | Human summary (endpoints table, status matrix, schema list) |
| `tokens/api-registry.json` | Updated with every new response field as a `field.*` entry |

## Two-level spec model

The pipeline keeps **two levels** of OpenAPI spec. Both are maintained by `openapi-author`:

```
docs/openapi/paths/<be-jira-id>.yaml   ← feature fragment (bare path keys, no envelope)
docs/openapi/openapi.yaml              ← root spec (all features merged inline)
```

The feature fragment is scoped to one ticket. The root spec is the aggregated API for the
whole project. They are kept in sync: every path in the fragment must also appear in the root.

**Swagger UI feature isolation:** The `/api/docs` route supports `?feature=<be-jira-id>`.
It reads the fragment to get the feature's path keys, extracts only those paths and their
referenced schemas from the root spec, and returns a valid standalone OpenAPI document.
After running `openapi-author`, verify your feature in isolation at:
`http://localhost:3000/api/docs?feature=<be-jira-id>`

## Procedure

### Step 0 — Read memory
Read `features/<parent-id>/memory.md`. Confirm `gherkin-validate` passed.
If missing, stop — run `gherkin-validate` first.

### Step 1 — Extract endpoints from @be Gherkins
Read every `@be` scenario. For each `When a <METHOD> request is made to "<path>"`:
- List method + path
- `Given` steps → preconditions → request body fields
- `Then` steps → response status codes + response body fields

For each endpoint, identify:
- Request body schema (fields, types, required/optional)
- Response schema(s) per success status code
- Error shape: `error.field` + `error.message` (field error) vs `error.message` only (auth error) vs flat `error` string
- All 4xx status codes

### Step 2 — Register response fields in api-registry.json
For every property in every **success response schema** (2xx):

1. Read `tokens/api-registry.json` (create with `{ "_comment": "..." }` if missing).
2. For each response property add:
   ```json
   "field.<resource>.<property>": {
     "$jsonPath": "$.<property>",
     "description": "<what this field represents>",
     "schema": "<SchemaName>",
     "feature": "<be-jira-id>"
   }
   ```
3. Nested error properties (`$.error.field`, `$.error.message`) get their own entries:
   ```json
   "field.<resource>.error.field":   { "$jsonPath": "$.error.field",   ... }
   "field.<resource>.error.message": { "$jsonPath": "$.error.message", ... }
   ```
4. Never remove existing entries — only add/update entries for this feature.
5. Key convention: `field.<lowerCamelResource>.<lowerCamelProperty>`

### Step 3 — Write the feature fragment
Write `docs/openapi/paths/<be-jira-id>.yaml`.

Format: bare path keys at the top level (no `openapi:` / `info:` envelope — the root spec provides those). Include a `components.schemas` section at the bottom for schemas introduced by this feature.

```yaml
# <be-jira-id> — <Feature Name>
# Endpoints: <comma-separated list>
# Source: features/<parent-id>/<parent-id>.feature (@be scenarios)

/api/<resource>/<action>:
  post:
    operationId: <matchesGherkinSchemaAssertion>
    ...

components:
  schemas:
    <FeatureSchemaName>:
      ...
```

Rules:
- `operationId` must exactly match the name in Gherkin `Then the response body matches the OpenAPI schema for "<operationId>"`.
- Error shapes: use structured `{ error: { field, message } }` when Gherkins assert `error.field` or `error.message` — not flat `ErrorBody`.
- Reuse `$ref: '#/components/schemas/ErrorBody'` only for generic 500s.

### Step 4 — Merge into root openapi.yaml
Add the feature's paths **inline** under a comment block:
```yaml
  # ── <be-jira-id> — <Feature Name> ─────────────────────────────────────────
```
Add the feature's schemas to `components/schemas`.
Never delete or modify paths from other features.

### Step 5 — Write api-contract.md
Write `docs/features/<be-jira-id>/api-contract.md`:
- Endpoints table (method, path, operationId, purpose)
- Status code matrix
- Schema names table
- Error shape examples
- Line: "Source of truth: `docs/openapi/paths/<be-jira-id>.yaml`"
- Line: "Feature view: `http://localhost:3000/api/docs?feature=<be-jira-id>`"

### Step 6 — Run gates (both must exit 0)
```bash
npm run openapi:validate       # validates root OpenAPI 3.1 structure
npm run api-registry:validate  # validates tokens/api-registry.json entries
```
Fix and re-run until both pass. Do not advance until both exit 0.

Verify the feature in isolation:
```
http://localhost:3000/api/docs?feature=<be-jira-id>
```
Confirm only this feature's endpoints appear.

### Step 7 — Update memory
```markdown
## BE Contract
<!-- openapi-author completed: <ISO date> -->
### Endpoints (Contract 1 — OpenAPI)
| Method | Path | Operation ID | Status codes |
...
Full spec: docs/openapi/paths/<be-jira-id>.yaml
Human summary: docs/features/<be-jira-id>/api-contract.md
Feature view: http://localhost:3000/api/docs?feature=<be-jira-id>
```

## Honesty rules

- Only document endpoints present in `@be` Gherkins.
- If Gherkin and AC disagree, stop and ask.
- Never invent `field.*` names — derive from actual response schema properties.
- `operationId` must exactly match what Gherkins assert.

## Success criteria

- `openapi:validate` exits 0
- `api-registry:validate` exits 0
- `api-contract.md` exists
- Root `openapi.yaml` has new paths
- `http://localhost:3000/api/docs?feature=<be-jira-id>` shows **only** this feature's endpoints
- Memory BE Contract section written
