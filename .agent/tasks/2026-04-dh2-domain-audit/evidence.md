# Evidence

## Status
Completed with conditions.

Recommendation: `accepted_with_conditions`

## Facts from implementation
- The repo ships two user-facing surfaces with different breadth:
  - Swift package / iOS-macOS app in `Sources/DHCharList`
  - browser-local web app in `web/`
- The app stores profile fields for `homeWorld`, `background`, `role`, and `aptitudes`, but it does not implement a rule-driven DH2 creation wizard or automatically derive those choices into starting stats.
- The shared domain already implements:
  - characteristic editing and explainable quick checks
  - skill editing and skill-target calculation
  - bounded XP spending with prerequisites
  - resources editing for wounds, fatigue, corruption, insanity, fate, and XP
  - detached weapon/armour compendium workflows
- Before this task:
  - Swift and web modeled skill training as `untrained / known / trained / veteran`, with veteran only adding `+20`
  - web `createDefaultCharacter()` and `coerceCharacter()` invented plausible DH2-looking defaults:
    - all characteristics `30`
    - wounds `10`
    - fate `1`
    - XP total `400`
    - movement `3/6/9/18`
    - one starting `Awareness` skill at `known`
    - one aptitude `Perception`

## Facts from rulebook
- Character creation is a staged process: home world, background, role, then rolled characteristics and other derived starting values.
  - Source: Chapter II, pages 29-32.
- Characteristics are generated as `2d10 + 20`, then modified by other generation choices.
  - Source: Chapter II, page 32.
- Starting XP at character creation is `1,000`.
  - Source: Chapter II, page 79 (printed page 78).
- Untrained skill use carries a `-20` penalty.
  - Source: Chapter I, page 24; Chapter III, pages 95-96.
- Skill ranks are `Known`, `Trained`, `Experienced`, `Veteran` with modifiers `+0`, `+10`, `+20`, `+30`, and advances must be bought in order.
  - Source: Chapter II, page 81.

## Confirmed discrepancies

### 1. Rules-correct skill rank progression was under-modeled
- Rulebook fact:
  - DH2 defines `Known / Trained / Experienced / Veteran` skill ranks with `0 / +10 / +20 / +30`.
- Implementation fact:
  - The app skipped `Experienced` and capped `Veteran` at `+20`.
- Discrepancy:
  - Supported skill-target and XP-progression behavior was materially rules-incorrect inside an explicitly supported feature.
- Criticality:
  - `High`
- Resolution:
  - Added `experienced` to the shared skill training model.
  - Corrected modifiers to `-20 / 0 / +10 / +20 / +30`.
  - Corrected progression ordering/ranking for XP validation.
  - Updated labels and regression expectations on Swift and web.
- Files:
  - `Sources/DHCharList/Domain/Character.swift`
  - `Sources/DHCharList/Rules/MechanicsChecks.swift`
  - `Sources/DHCharList/Rules/XPProgression.swift`
  - `Tests/DHCharListTests/QuickMechanicsCheckTests.swift`
  - `Tests/DHCharListTests/DHCharListTests.swift`
  - `web/src/lib/types.ts`
  - `web/src/lib/domain.ts`
  - `web/src/lib/domain.test.ts`

### 2. Web startup/recovery fabricated unsupported pseudo-canonical characters
- Rulebook fact:
  - Starting values come from a full generation pipeline; the app does not implement that pipeline.
- Implementation fact:
  - The web app created and recovered sparse characters with rulebook-flavored but arbitrary defaults.
- Discrepancy:
  - The app presented manual/blank records as if they were legitimate DH2 starts, which could mislead users and mask storage loss.
- Criticality:
  - `High`
- Resolution:
  - Replaced invented defaults with explicit blank/manual state for new web characters.
  - Changed sparse recovery coercion to default missing characteristics/resources to `0` instead of plausible DH2-looking values.
  - Added regression tests so future changes do not reintroduce fabricated canonical state.
- Files:
  - `web/src/lib/domain.ts`
  - `web/src/lib/domain.test.ts`

## Decisions taken
- The task did not expand scope into a full DH2 creation engine.
- Because the app does not compute actual starting packages from DH2 generation rules, the safer and more truthful behavior is a blank/manual record rather than guessed canonical values.
- Skill-rank fixes were applied cross-surface because that mechanic is already explicitly supported and computed by the app.

## Executed commands
- Baseline / validation:
  - `swift build`
  - `swift test`
  - `cd web && npm test`
  - `cd web && npm run typecheck`
  - `cd web && npm run build`
- Focused regression / debugging:
  - `swift test --filter skillTrainingRanksMatchDh2KnownTrainedExperiencedVeteranBonuses`
  - `cd web && npm test -- domain.test.ts`
- Rulebook support work:
  - local PDF text extraction/search with `pypdf` in a temporary venv

## Observed outcomes
- `swift build`: passed
- `swift test`: passed, `158` tests green
- `cd web && npm test`: passed, `13` tests green
- `cd web && npm run typecheck`: passed
- `cd web && npm run build`: passed

## Verification notes
- Automated verification explicitly covered:
  - shared skill modifier math
  - explainable quick checks
  - XP spend validation/application
  - persistence/update flows in Swift
  - web creation/recovery helpers
  - web app regression tests
- During verification, two stale expectations were found in tests:
  - one Swift expectation still assumed veteran `+20`
  - one web XP test still assumed a fabricated `30` strength baseline
- Both were updated to reflect the corrected domain behavior.

## Confidence
- logic confidence: high for the touched mechanics
- runtime confidence: high in this environment from passing build/test runs
- UI confidence: medium
  - supported flows are covered by automated tests, but no manual simulator/device smoke pass was performed
- real-device confidence: none

## Residual risks
- The app still does not implement rule-driven DH2 character generation, so profile fields such as home world/background/role remain manual and non-authoritative.
- Home world/background/role effects, starting wounds/fate/influence packages, and full XP cost tables are still only partially represented or fully out of scope depending on screen/flow.
- No real-device verification was performed, so interaction-level issues outside the automated suite may still exist.

## Supported / partial / out-of-scope snapshot
- Supported and audited:
  - skill target calculation
  - skill rank ordering/modifiers
  - bounded XP progression helper behavior
  - web character creation/recovery defaults
- Partially supported:
  - profile-level DH2 identity choices (`homeWorld/background/role/aptitudes`) as stored fields without full rules automation
  - combat/session helpers as bounded quick tools rather than a full combat engine
- Out of scope:
  - full DH2 generation pipeline
  - automatic home world/background/role packages
  - full requisition/influence system
  - full talent/advance rules coverage
  - real-device behavior claims
