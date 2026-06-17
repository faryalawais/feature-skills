---
name: visual-regression
description: Set up and run visual regression tests for a feature using Playwright screenshots, and produce a Figma-vs-app comparison for human review. Use this skill whenever the user wants visual testing, screenshot tests, pixel or visual diffing, UI fidelity checks, or to compare the build against the Figma design — even if they don't say "skill".
---

# visual-regression

Adds the visual-fidelity pillar. It is deliberately honest about what
automation can and cannot do, and splits into two jobs.

## Inputs
- A feature `id` and its `features/<id>/contract.md`.
- `features/<id>/figma/reference.png` — the Figma baseline, if it exists.
- The implemented, running feature.

## Job 1 — Golden-master regression  (the automated gate check)

Catches **drift between runs**. It does *not* prove a match to Figma.

1. Create `tests/visual/<id>.spec.ts`. For each key view and state listed in
   the feature's `contract.md`, navigate to it and call
   `await expect(page).toHaveScreenshot()`.
2. Use the contract's **Fidelity tolerance** as `maxDiffPixelRatio`
   (default `0.02`).
3. **First run** for a feature: no baseline exists, so Playwright *creates*
   one. This is **not a pass** — it means a human must approve the initial
   render (see Job 2). Report it as "baseline established, pending approval".
4. **Later runs:** any diff beyond tolerance is a real regression → fail.

## Job 2 — Figma fidelity review  (a human aid, not an automated assertion)

A browser render and a Figma export are never byte-identical, so app-vs-Figma
**cannot** be a hard pass/fail. Instead, produce a structured review artifact:

1. Capture the current app screenshot for each view/state.
2. Place it beside `features/<id>/figma/reference.png`.
3. Write `reports/<id>-visual.md` with a **section-by-section comparison**:
   - Walk every named section and element in `contract.md` §2 (anatomy).
   - For each one, explicitly note: **Present** (matches Figma), **Differs**
     (present but visually wrong — describe the difference), or **Missing**
     (visible in Figma / contract but absent from the app screenshot).
   - "Missing" is a hard finding that must be resolved before approval.
     Do not write "out of scope" or "deferred" — every element in the
     contract is in scope and must be present.
   - Flag specific discrepancies: wrong column count, absent footer section,
     missing icon strip, truncated link list, placeholder text where real
     content is specified, incorrect token (wrong colour / spacing / radius).

The human uses this report during approval to verify the implementation
exactly matches the Figma design. Any "Missing" or "Differs" finding means
the feature is not ready for approval — return to `feature-implement`.

## Integration with governance-gate
`governance-gate` runs `npm run test:visual` as its fourth check:
- No baseline yet → record "visual baseline pending human approval"
  (neither pass nor fail; surfaces in the gate report).
- Baseline exists, no drift → pass.
- Baseline exists, drift beyond tolerance → fail.

## Hard rules

**Never delete or overwrite an approved baseline just to make a test pass.** A
failing visual test is either a real regression (fix the code) or an intended
change (a human runs `npm run test:visual:update` to re-baseline).

**Fresh clone / new machine rule:** Playwright baselines are machine-specific
(OS, GPU, font rendering, screen resolution). On a freshly cloned repo or a
new machine, `npm run test:visual` will fail because existing baselines were
generated on a different machine. The first action on any new environment is:

```bash
npm run test:visual:update   # re-baseline for this machine
```

This is mandatory before running `governance-gate` on a fresh clone. The
re-baselined snapshots must be committed. This is not a skip or a cheat — it
is a required environment-calibration step documented here as a hard rule so
no one silently disables visual tests when they fail on setup.

## Success criteria
`tests/visual/<id>.spec.ts` exists and runs; baselines are generated or
compared; `reports/<id>-visual.md` is written.
