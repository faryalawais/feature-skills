---
name: openapi-author
description: Author or update OpenAPI 3.1 specs for an API slice from its Gherkin and acceptance criteria. Use for Swagger/OpenAPI documentation, API-first contracts, or before api-implement.
---

# openapi-author

Turns an API slice's requirements into the **machine-readable HTTP contract**
(Swagger / OpenAPI 3.1) that `api-implement` and `api-gate` enforce.

## Inputs

- `features/<id>/<id>.feature` — API slice Gherkin (`@api`).
- `features/backlog.yaml` — API slice entry.
- Existing `docs/openapi/openapi.yaml` — merge, do not blindly overwrite unrelated paths.

## Outputs

- `docs/openapi/paths/<id>.yaml` — path items for this slice only.
- `docs/openapi/components/schemas/<id>.yaml` — request/response/error schemas (when non-trivial).
- Updated `docs/openapi/openapi.yaml` — root spec with `$ref` to the slice files.
- `features/<id>/api-contract.md` — short human summary linking paths, methods, status codes.
- Backlog `status` → `api-contracted` (API slices use this instead of `contracted`).

## Procedure

1. Read the `.feature` file and acceptance criteria. List every endpoint, method,
   request body schema, response schema, and status code.
2. For each response property, ensure a matching **`field.*` path** exists (or will
   be added) in `tokens/api-registry.json` with `$jsonPath` (e.g. `$.id` for
   `{ "id": 1 }`). `openapi-author` and `api-spec-author` share this vocabulary.
3. Write **OpenAPI 3.1** YAML (not JSON) using object forms consistent with the repo:
   - `openapi: 3.1.0`
   - Reuse `components.securitySchemes` / shared `Error` schema from
     `docs/openapi/components/shared.yaml` when present.
   - Document `content.application/json` bodies with explicit `required` fields.
   - Document cookies (e.g. `auth_user_id`) under `responses` + `Set-Cookie` headers when applicable.
4. **Merge into the root spec** — add `$ref` entries under `paths` pointing to
   `docs/openapi/paths/<id>.yaml`. Never delete another feature's paths.
5. Write `features/<id>/api-contract.md`:
   - Endpoints table (method, path, purpose)
   - Status code matrix
   - Link: "Source of truth: `docs/openapi/paths/<id>.yaml`"
6. Run `npm run openapi:validate` and `npm run api-registry:validate`. Fix until PASS.
7. Set backlog `status: api-contracted`.

## Honesty rules

- Do not document endpoints that are not in the slice's AC or `.feature` file.
- If the Gherkin and AC disagree, stop and ask which is authoritative.
- Prefer **zod-equivalent** constraints in schema `minLength`, `format: email`, etc.

## Success criteria

`openapi:validate` passes, `api-contract.md` exists, root `openapi.yaml` references
the new paths, status is `api-contracted`.
