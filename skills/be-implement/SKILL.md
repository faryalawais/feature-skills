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

### Step 0 — Smart zone check (run before anything else)

Count the `@be` scenarios in the feature file:
```bash
grep -c "^\s*@be" features/<parent-id>/<parent-id>.feature
```

- **≤ 10 scenarios** → proceed normally.
- **11–20 scenarios** → warn: _"⚠️ This feature has N @be scenarios — you may hit the smart zone limit mid-run. Consider starting a fresh chat for each group of ~10 scenarios, or split the feature further with `/to-issues`."_ Then ask: _"Continue in this chat or split first?"_
- **> 20 scenarios** → warn strongly: _"⚠️ This feature has N @be scenarios — too large for reliable output in one context window. Recommended: split the feature using `/to-issues` into smaller slices, then implement each slice in a fresh chat. Continue anyway?"_ Wait for the user to decide.

Each scenario is implemented as one isolated task. Never batch multiple scenarios into a single code-writing pass.

### Step 1 — Validate feature branch
```bash
git rev-parse --abbrev-ref HEAD
```
Must equal `feature/<be-jira-id>`. If it is `main` or anything else, stop:
> "Wrong branch. Switch with: `git checkout feature/<be-jira-id>`"

### Step 1 — Read memory
Read `features/<parent-id>/memory.md`. Confirm all three BE contracts exist
and `be-contract-ready` status is set. If not, stop.

### Step 2 — Read all three contracts
Read these files completely before writing any code:
1. `docs/openapi/paths/<be-jira-id>.yaml` — every endpoint, request shape, response shape
2. `docs/features/<be-jira-id>/business-logic.md` — every validation rule, state machine, auth rule
3. `db/schema.ts` — every table and column by name (never query the DB to discover schema)

### Step 3 — Plan implementation
List every endpoint in the OpenAPI path file. For each, record:
- Method + path
- Which `@be` scenario(s) cover it
- Which business logic rules apply (from business-logic.md)
- Which DB tables it reads/writes (from db/schema.ts)
- Which test file it goes in

Group by route file: endpoints sharing a resource go in the same `route.ts`.

### Step 4 — Implement endpoint by endpoint

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

### Step 5 — Write feature-scoped tests
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

### Step 6 — Run feature-scoped tests after each endpoint
After writing each endpoint and its tests:
```bash
npm run test:api:feature -- tests/api/<be-jira-id>
```

Fix failures before moving to the next endpoint.

**Why feature-scoped:** Other features' tests may exist and may currently fail
(their routes not yet implemented). Running the full suite mid-development would
permanently block this endpoint even if it is correct. Feature-scoped runs only
during development; the full suite runs at the final gate.

### Step 7 — Final gate (full suite)
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

### Step 8 — Write to memory
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

### Step 9 — Update ticket status
Set BE ticket to `be-implemented`.

### Step 10 — Commit, push branch, open PR
```bash
# Stage all feature work
git add app/api/ lib/<be-jira-id>/ tests/api/<be-jira-id>/ docs/ features/ tokens/ db/

# Commit
git commit -m "feat(<be-jira-id>): <short description of feature>

- <endpoint 1>
- <endpoint 2>
- <N> tests, gate:api passed

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

# Push feature branch
git push origin feature/<be-jira-id>

# Open PR targeting main
gh pr create \
  --base main \
  --head feature/<be-jira-id> \
  --title "feat(<be-jira-id>): <Feature Name>" \
  --body "$(cat <<'EOF'
## Summary
- Implements <N> endpoints for <Feature Name>
- All @be Gherkin scenarios covered
- gate:api passed (typecheck + openapi:validate + api-registry:validate + <N> tests)

## Endpoints
<list of METHOD /path>

## Test coverage
tests/api/<be-jira-id>/ — <N> tests

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**Hard rule: never push directly to `main`. The PR is the only merge path.**

## Success criteria
- All `@be` scenarios have a corresponding implemented endpoint
- All test files are under `tests/api/<be-jira-id>/`
- `npm run test:api:feature -- tests/api/<be-jira-id>` exits 0
- `npm run gate:api` exits 0 (full suite)
- Memory Implementation Notes written
- BE ticket `be-implemented`
- Feature branch `feature/<be-jira-id>` pushed to origin
- PR opened targeting `main`
- `main` branch unchanged — no direct commits to main

## Hard rules
- **Never modify test files to make them pass.** Fix the implementation.
- **Never modify the OpenAPI spec during implementation.** It is frozen.
- **Never modify `db/schema.ts` during implementation.** Run `orm-schema-author` again if schema changes are needed.
- **Never push directly to `main`.** Commit to `feature/<be-jira-id>` and open a PR.
- `db/schema.ts` is read directly — never call `PRAGMA table_info` or any DB introspection at runtime.
- Test files always live under `tests/api/<be-jira-id>/` — never flat in `tests/api/`.
