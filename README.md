# feature-skills

Claude Code skills for the feature-level SDLC pipeline.

## Structure

```
skills/
  <skill-name>/
    SKILL.md        ← skill definition (read by Claude Code)
    [other files]   ← templates, examples, etc.
scripts/
  sync.sh           ← copies skills into a project repo
```

## Syncing to a project repo

```bash
./scripts/sync.sh ../sdlc-fe
./scripts/sync.sh ../sdlc-be
```

Re-run after adding or updating any skill.

## Pipeline overview

See the full pipeline rules at:
`docs/end-to-end-sdlc-feature-flow.md` in the sdlc-poc repo.

### Common flow (both repos)
`feature-brief` → `prd-author` → `prd-review` → `prd-update` → `prd-review`
→ `ticket-generate` → `spec-author` → `bdd-scaffold` → `scenario-review`
→ `gherkin-validate`

### BE flow (sdlc-be repo)
`openapi-author` → `business-logic-author` → `orm-schema-author` → `be-implement`

### FE flow (sdlc-fe repo)
`figma-extract` → `design-tokens` → `ui-registry-build` → `registry-validate`
→ `design-contract` → `fe-implement`

### Cross-cutting
`jira-sync` · `figma-comment`

## Skills

| Skill | Flow | Status |
|-------|------|--------|
| `feature-brief` | Common | New |
| `prd-author` | Common | Existing |
| `prd-update` | Common | New |
| `prd-review` | Common | New |
| `ticket-generate` | Common | New |
| `spec-author` | Common | Existing |
| `bdd-scaffold` | Common | Existing |
| `scenario-review` | Common | New |
| `gherkin-validate` | Common | New |
| `jira-sync` | Cross-cutting | New |
| `figma-comment` | Cross-cutting | New |
| `figma-extract` | FE | Existing |
| `design-tokens` | FE | Existing |
| `token-validate` | FE | Existing |
| `ui-registry-build` | FE | New |
| `registry-validate` | FE | New |
| `design-contract` | FE | Existing |
| `visual-regression` | FE | Existing |
| `fe-implement` | FE | New |
| `openapi-author` | BE | Existing |
| `business-logic-author` | BE | New |
| `orm-schema-author` | BE | New |
| `be-implement` | BE | New |
| `speckit-*` (16 skills) | Internal | Existing |
