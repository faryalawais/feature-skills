---
name: be-implement
description: >-
  Implement the BE feature by reading all 3 BE contracts (OpenAPI spec,
  Business Logic, ORM schema) and the @be Gherkins. Swagger is the enforced
  API contract; business-logic.md is the rules reference; db/schema.ts is the
  data model. Run after be-contract-ready. When complete, triggers FE flow.
---

# be-implement

Implements the BE feature — API route handlers, middleware, validation, and
DB operations — using all three BE contracts as the source of truth.

## Inputs
- `docs/openapi/paths/<be-jira-id>.yaml` — Contract 1: endpoints and schemas
- `docs/features/<be-jira-id>/business-logic.md` — Contract 2: rules and logic
- `db/schema.ts` — Contract 3: data model (read directly, no introspection)
- `features/<parent-id>/<parent-id>.feature` (`@be` scenarios only)
- `features/<parent-id>/memory.md`

## File layout

All files produced by this skill are scoped to the feature ID:

```
app/api/<resource>/           ← route handlers (one folder per resource)
  route.ts                    ← e.g. app/api/auth/signup/route.ts
lib/<be-jira-id>/             ← shared logic for this feature only (validators, helpers)
tests/api/<be-jira-id>/       ← ALL test files for this feature (never tests/api/ flat)
  <endpoint>.test.ts
```

Keeping test files under `tests/api/<be-jira-id>/` is mandatory — it allows
`npm run test:api:feature -- tests/api/<be-jira-id>` to run only this feature's
tests during development without touching other features' suites.

## Procedure

### Step 0 — Read memory
Read `features/<parent-id>/memory.md`. Confirm all three BE contracts exist
and `be-contract-ready` status is set. If not, stop.

### Step 1 — Read all three contracts
Read these files completely before writing any code:
1. `docs/openapi/paths/<be-jira-id>.yaml` — every endpoint, request shape, response shape
2. `docs/features/<be-jira-id>/business-logic.md` — every validation rule, state machine, auth rule
3. `db/schema.ts` — every table and column by name (never query the DB to discover schema)

### Step 2 — Plan implementation
List every endpoint in the OpenAPI path file. For each, record:
- Method + path
- Which `@be` scenario(s) cover it
- Which business logic rules apply (from business-logic.md)
- Which DB tables it reads/writes (from db/schema.ts)
- Which test file it goes in

Group by route file: endpoints sharing a resource go in the same `route.ts`.

### Step 3 — Implement endpoint by endpoint

**Route handler structure:**
```typescript
// app/api/<resource>/route.ts

export async function METHOD(request: Request) {
  // 1. Parse and validate input (per business-logic.md Validation Rules table)
  // 2. Authorize (per business-logic.md Authorization table)
  // 3. Execute DB operation (exact table/column names from db/schema.ts)
  // 4. Apply calculations / state transitions (per business-logic.md)
  // 5. Return response exactly matching OpenAPI response schema
}
```

**Enforcement rules:**
- Every request field validated against the Validation Rules table in `business-logic.md`
- Every response shaped exactly as the OpenAPI spec defines — no extra fields, no missing required fields
- Every DB query uses the exact table/column names from `db/schema.ts` via Drizzle ORM
- Every error response uses the error codes and messages from the Error Catalogue in `business-logic.md`
- No raw SQL — Drizzle ORM query builder only

### Step 4 — Write feature-scoped tests
Write test files to `tests/api/<be-jira-id>/`. One file per route is typical:

```
tests/api/<be-jira-id>/
  signup.test.ts
  verify-email.test.ts
  signin.test.ts
  ...
```

Each test file:
- Imports the route handler directly (no HTTP server)
- Has one test per `@be` scenario for that endpoint
- Tests the exact response shape from the OpenAPI spec (status code + body fields)
- Tests every error case from the Error Catalogue

### Step 5 — Run feature-scoped tests after each endpoint
After writing each endpoint and its tests:
```bash
npm run test:api:feature -- tests/api/<be-jira-id>
```

Fix failures before moving to the next endpoint.

**Why feature-scoped:** Other features' tests may exist and may currently fail
(their routes not yet implemented). Running the full suite mid-development would
permanently block this endpoint even if it is correct. Feature-scoped runs only
during development; the full suite runs at the final gate.

### Step 6 — Final gate (full suite)
After all endpoints are implemented:
```bash
npm run gate:api
```

This runs `typecheck` + `openapi:validate` + `api-registry:validate` + the full
`test:api` suite. All must exit 0.

If `test:api` fails on a **different feature's tests** that were already failing
before this feature started — do not fix those. Document it in memory as a
pre-existing failure and ask the user whether to unblock.

If either fails on **this feature's tests**: fix the implementation, never the test.
If `openapi:validate` fails: the implementation drifted from the spec; fix the
route handler — never the spec.

### Step 7 — Write to memory
```markdown
## Implementation Notes
### BE notes
<!-- Written by: be-implement on <ISO date> -->
- Endpoints implemented: <list of METHOD /path>
- Route files: <list of app/api/... files>
- Test files: tests/api/<be-jira-id>/ (<N> tests)
- gate:api: passed
- Deviations from contract: <none / list if any>
```

### Step 8 — Update ticket status
Set BE ticket to `be-implemented`.

## Success criteria
- All `@be` scenarios have a corresponding implemented endpoint
- All test files are under `tests/api/<be-jira-id>/`
- `npm run test:api:feature -- tests/api/<be-jira-id>` exits 0
- `npm run gate:api` exits 0 (full suite)
- Memory Implementation Notes written
- BE ticket `be-implemented`

## Hard rules
- **Never modify test files to make them pass.** Fix the implementation.
- **Never modify the OpenAPI spec during implementation.** It is frozen.
- **Never modify `db/schema.ts` during implementation.** Run `orm-schema-author` again if schema changes are needed.
- `db/schema.ts` is read directly — never call `PRAGMA table_info` or any DB introspection at runtime.
- Test files always live under `tests/api/<be-jira-id>/` — never flat in `tests/api/`.
