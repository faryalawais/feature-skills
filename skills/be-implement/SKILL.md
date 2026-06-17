---
name: be-implement
description: >-
  Implement the BE feature by reading all 3 BE contracts (OpenAPI spec,
  Business Logic, ORM schema) and the @be Gherkins. Uses speckit internally
  to plan and execute one task per scenario. Swagger is the enforced API
  contract; business-logic.md is the rules reference; db/schema.ts is the
  data model. Run after be-contract-ready. When complete, triggers FE flow.
---

# be-implement

Implements the BE feature — API route handlers, middleware, validation, and
DB operations — using all three BE contracts as the source of truth. Uses
speckit to break the work into one task per `@be` Gherkin scenario.

## Inputs
- `docs/openapi/paths/<be-jira-id>.yaml` — Contract 1: endpoints and schemas
- `docs/features/<be-jira-id>/business-logic.md` — Contract 2: rules and logic
- `db/schema.ts` — Contract 3: data model (read directly, no introspection)
- `features/<parent-id>/<parent-id>.feature` (`@be` scenarios only)
- `features/<parent-id>/memory.md`

## Procedure

### Step 0 — Read memory
Read `features/<parent-id>/memory.md`. Confirm all three BE contracts exist
and `be-contract-ready` status is set. If not, stop.

### Step 1 — Read all three contracts
Read these files completely before writing any code:
1. `docs/openapi/paths/<be-jira-id>.yaml` — know every endpoint, request shape, response shape
2. `docs/features/<be-jira-id>/business-logic.md` — know every validation rule, state machine, auth rule
3. `db/schema.ts` — know every table and column by name (do not query the DB to discover schema)

### Step 2 — Plan with speckit
Run `speckit-plan` with these inputs:
- The `@be` Gherkin scenarios as the task source
- The three contracts as context documents
- Output: one speckit task per `@be` scenario, each mapping to one endpoint behaviour

Tasks are named: `be-<method>-<path-slug>-<scenario-slug>`
Example: `be-post-feedback-happy-path`

### Step 3 — Create task list
Run `speckit-tasks` to produce the implementation task list.
Each task must state:
- Which endpoint it implements (`METHOD /path`)
- Which `@be` scenario it covers
- Which business logic rules apply
- Which DB tables it reads/writes

### Step 4 — Implement endpoint by endpoint
Run `speckit-implement` one task at a time. For each endpoint:

**Route handler structure:**
```typescript
// app/api/<resource>/route.ts (Next.js) or equivalent

export async function METHOD(request: Request) {
  // 1. Parse and validate input (per business-logic.md validation rules)
  // 2. Authorize (per business-logic.md authorization rules)
  // 3. Execute DB operation (using db/schema.ts table names)
  // 4. Apply calculations/state transitions (per business-logic.md)
  // 5. Return response matching OpenAPI response schema exactly
}
```

**Enforcement rules during implementation:**
- Every request field validated against the Validation Rules table in
  `business-logic.md` — no skipping validation
- Every response shaped exactly as the OpenAPI spec defines — no extra fields,
  no missing required fields
- Every DB query uses the exact table/column names from `db/schema.ts`
- Every error response uses the error codes and messages from the Error
  Catalogue in `business-logic.md`
- No raw SQL — use Drizzle ORM query builder throughout

### Step 5 — Run tests after each endpoint
After implementing each endpoint, run:
```bash
npm run test:api
```

Fix failures before moving to the next endpoint. Never implement the next
endpoint with a failing test.

### Step 6 — Final gate
After all endpoints implemented:
```bash
npm run test:api && npm run openapi:validate
```

Both must exit 0.

If either fails:
- For `test:api` failures: fix the implementation, do not modify the test
- For `openapi:validate` failures: the implementation drifted from the spec;
  fix the route handler to match the spec — do not modify the spec

### Step 7 — Write to memory
```markdown
## Implementation Notes
### BE notes
<!-- Written by: be-implement on <ISO date> -->
- Endpoints implemented: <list of METHOD /path>
- test:api: passed (<N> tests)
- openapi:validate: passed
- Deviations from contract: <none / list if any>
```

### Step 8 — Run `jira-sync`
Set BE ticket to `be-implemented`. This triggers FE flow to begin.

### Step 9 — Run `figma-comment`
Post BE implementation complete notice to parent Jira ticket.

## Success criteria
- All `@be` scenarios have a corresponding implemented endpoint
- `npm run test:api` exits 0
- `npm run openapi:validate` exits 0
- Memory updated
- BE ticket `be-implemented`

## Hard rules
- Never modify test files to make them pass. Fix the implementation.
- Never modify the OpenAPI spec during implementation. It is frozen.
- Never modify `db/schema.ts` during implementation. Run `orm-schema-author` again if schema changes are needed.
- `db/schema.ts` is read directly — never call `PRAGMA table_info` or
  equivalent to discover the schema at runtime.
- speckit is used internally — this skill drives it. Do not call speckit
  skills directly from outside this skill.
