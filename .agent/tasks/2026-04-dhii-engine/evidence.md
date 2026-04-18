# Evidence Report

## Task
- ID: 2026-04-dhii-engine
- Title: DHII Engine architecture freeze with Tasks 01-06 creation foundations

## What was implemented
- Frozen DHII Engine roadmap with explicit phase/task decomposition for the full engine rollout.
- Added typed home-world creation foundation in [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift) with:
  - canonical six-core-world catalog
  - alias normalization
  - rulebook-backed previews
  - compatibility diagnostics for effects the current model cannot yet project safely
- Added typed background catalog foundation in [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift) with:
  - canonical seven-core-background registry
  - alias normalization over the existing raw `profile.background` field
  - rulebook-backed package summaries for aptitudes, starting package contents, background bonuses, and recommended roles
  - explicit unsupported-mechanics diagnostics for current-model gaps such as availability modifiers, combat-state hooks, and conditional creation grants
- Added typed role catalog foundation in [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift) with:
  - canonical eight-role registry
  - alias normalization over the existing raw `profile.role` field
  - rulebook-backed summaries for role aptitudes, talent choices, and role bonuses
  - explicit unsupported-mechanics diagnostics for role-talent choices, role-bonus hooks, Psyker elite-advance hooks, and aptitude-choice provenance
- Added explainable aptitude composition in [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift) that:
  - composes fixed aptitudes from canonical home world/background/role selections
  - preserves legacy profile aptitudes as fallback input/output without mutating persistence
  - keeps unresolved background/role choice-slots explicit instead of silently guessing
- Added typed in-memory creation draft support in [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift) that:
  - derives canonical home world/background/role selections from the current raw `Profile`
  - separates inferred background/role aptitude choices from legacy fallback aptitudes where possible
  - preserves unknown freeform inputs as explicit non-canonical state
  - safely prunes stale background/role choice state when upstream selections change
- Added typed characteristic-generation foundation in [`Sources/DHCharList/Rules/CharacterCreationCharacteristics.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationCharacteristics.swift) and [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift) that:
  - models all ten DHII creation characteristics, including transient `Influence`
  - supports standard random generation (`2d10 + 20`) with home-world roll modifiers and one allowed re-roll
  - supports standard point allocation (`25` base, `60` discretionary points, `40` cap) with home-world starting-score modifiers
  - keeps random-roll provenance and point-allocation state transient inside the creation draft instead of flattening it into the persisted snapshot
  - exposes explainable per-characteristic breakdowns, validation errors, and honest invalidation when a home-world change makes prior random results no longer valid
- Added starting-package projection in [`Sources/DHCharList/Rules/CharacterCreationProjection.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationProjection.swift) plus supporting draft state in [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift) and [`Sources/DHCharList/Rules/CharacterCreationCharacteristics.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationCharacteristics.swift) that:
  - models explicit home-world/background/role choice slots and starting wounds/fate rolls on the typed creation draft
  - validates that canonical selections, supported choice slots, characteristic generation, and roll gates are resolved before projection
  - projects bounded supported DHII creation outputs into the legacy `Character` snapshot: aptitudes, starting resources, skills, talents, traits, special abilities, weapons, inventory, and movement
  - keeps transient `Influence` explicit alongside the projected legacy snapshot instead of inventing persistence fields prematurely
  - preserves unsupported rule effects as compatibility diagnostics instead of flattening them into misleading saved state
- Integrated informational home-world preview into [`Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift) without changing persistence shape or silently automating creation packages.
- Integrated informational background preview into [`Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift) without changing persistence shape, replacing the existing free-text field, or implying automatic package application.
- Integrated informational role preview and composed-aptitude preview into [`Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift) without changing persistence shape or implying that typed creation choices already exist.
- Routed Profile composed-aptitude preview through the typed creation draft seam in [`Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift) while keeping raw autosave semantics intact.
- Wired bounded progression to consume engine-backed composed aptitudes in [`Sources/DHCharList/Rules/XPProgression.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/XPProgression.swift), [`Sources/DHCharList/Rules/ProgressionRegistries.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/ProgressionRegistries.swift), and [`Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift) without rewriting `profile.aptitudes`.
- Added rule-focused regression coverage in [`Tests/DHCharListTests/CharacterCreationEngineTests.swift`](/Users/andrey_artemenko/repos/DH_charlist/Tests/DHCharListTests/CharacterCreationEngineTests.swift).
- Expanded regression coverage in [`Tests/DHCharListTests/CharacterCreationEngineTests.swift`](/Users/andrey_artemenko/repos/DH_charlist/Tests/DHCharListTests/CharacterCreationEngineTests.swift) for draft inference, ambiguous legacy choices, unknown freeform inputs, setter validation, recomposition pruning, and coverage-policy recovery.
- Hardened XP validation UI ergonomics and verification stability in [`Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift) and [`DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift`](/Users/andrey_artemenko/repos/DH_charlist/DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift):
  - numeric XP cost now has explicit text-state synchronization
  - iOS number-pad flow now exposes a keyboard `Done` dismissal
  - XP smoke was narrowed to the stable bounded UI guarantee actually required by Task 01
- Stabilized `testSmokeCoreFlowsAndEntryPoints` in [`DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift`](/Users/andrey_artemenko/repos/DH_charlist/DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift) by switching the create-flow readiness assertion from a brittle navigation-bar-only check to a readiness check that accepts the actual quick-start entry point as the screen contract.

## Files changed
- `Docs/dhii-engine-roadmap.md`
- `Docs/progress-log.md`
- `Sources/DHCharList/Rules/CharacterCreationEngine.swift`
- `Sources/DHCharList/Rules/CharacterCreationCharacteristics.swift`
- `Sources/DHCharList/Rules/CharacterCreationProjection.swift`
- `Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift`
- `Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift`
- `Tests/DHCharListTests/CharacterCreationEngineTests.swift`
- `DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift`
- `.agent/tasks/2026-04-dhii-engine/acceptance.md`
- `.agent/tasks/2026-04-dhii-engine/evidence.md`
- `.agent/tasks/2026-04-dhii-engine/problems.md`
- `.agent/tasks/2026-04-dhii-engine/verdict.json`

## Commands executed
List only commands actually executed:
- `swift test`
- `swift test --filter CharacterCreationEngineTests`
- `swift test --filter XPProgressionTests`
- `swift test --filter RulesRegistryTests`
- `swift build`
- `swift test --filter CharacterCreationEngineTests` (after draft coverage additions)
- `xcodebuild test -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -destination 'platform=iOS Simulator,id=A91DD7E0-C2BD-4919-8398-B12E5F9748BD' -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testSmokeCoreFlowsAndEntryPoints`
- `cd web && npm test`
- `cd web && npm run typecheck`
- `cd web && npm run build`
- `xcodebuild test -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -destination 'platform=iOS Simulator,id=99FC7BC1-9328-43FF-ADFC-5CCE680E04F6' -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testXPSpendingValidationScreenShowsManualCharacteristicCostEntry`
- `npm test -- --runInBand` (failed immediately due unsupported Vitest flag; no code change resulted from this command)
- `make ci`
- `make ci` (rerun after draft coverage hardening)
- `swift test --filter CharacterCreationEngineTests` (after T05 characteristic-generation additions)
- `swift build` (after T05 characteristic-generation additions)
- `cd web && npm test` (after T05 characteristic-generation additions)
- `cd web && npm run typecheck` (after T05 characteristic-generation additions)
- `cd web && npm run build` (after T05 characteristic-generation additions)
- `swift test` (after T05 characteristic-generation additions)
- `make ci` (after T05 characteristic-generation additions)
- `swift build` (after T06 starting-package projection additions)
- `swift test --filter CharacterCreationEngineTests` (after T06 starting-package projection additions)
- `swift test` (after T06 starting-package projection additions)
- `cd web && npm test` (after T06 starting-package projection additions)
- `cd web && npm run typecheck` (after T06 starting-package projection additions)
- `cd web && npm run build` (after T06 starting-package projection additions)
- `make ci` (after T06 starting-package projection additions)
- `make fmt`
- `make lint`
- `make typecheck`
- `make test`

## Results
- `swift test`: passed (`165` tests)
- `swift test`: passed again after T02 changes (`169` tests)
- `swift test --filter CharacterCreationEngineTests`: passed
- `swift test --filter XPProgressionTests`: passed
- `swift test --filter RulesRegistryTests`: passed
- `swift build`: passed
- `swift test`: passed again after T03 changes (`176` tests)
- `swift test --filter CharacterCreationEngineTests`: passed again after T04 draft coverage additions (`19` tests)
- targeted host UI rerun for `testSmokeCoreFlowsAndEntryPoints`: passed
- `cd web && npm test`: passed (`17` tests)
- `cd web && npm run typecheck`: passed
- `cd web && npm run build`: passed
- targeted host UI smoke for XP validation screen: passed
- first `make ci`: failed because `testSmokeCoreFlowsAndEntryPoints` used a brittle create-screen readiness assertion
- second `make ci`: passed after smoke stabilization
- `swift test`: passed after T04 changes (`179` tests)
- first `make ci` after T04 changes: failed only on `Rules` coverage regression (`91.87% < 93.55%`)
- second `make ci` after draft coverage hardening: passed
- `swift test --filter CharacterCreationEngineTests`: passed after T05 additions (`24` tests)
- `swift build`: passed after T05 additions
- `cd web && npm test`: passed after T05 additions (`17` tests)
- `cd web && npm run typecheck`: passed after T05 additions
- `cd web && npm run build`: passed after T05 additions
- `swift test`: passed after T05 additions (`187` tests)
- `make ci`: passed after T05 additions
- `swift build`: passed after T06 additions
- `swift test --filter CharacterCreationEngineTests`: passed after T06 additions (`30` tests)
- `swift test`: passed after T06 additions (`193` tests)
- `cd web && npm test`: passed after T06 additions (`17` tests)
- `cd web && npm run typecheck`: passed after T06 additions
- `cd web && npm run build`: passed after T06 additions
- `make ci`: passed after T06 additions
- `make fmt`: passed (`no-op fallback; no repository formatter configured`)
- `make lint`: passed (`no-op fallback; no repository linter configured`)
- `make typecheck`: passed
- `make test`: passed (`193` tests)
- coverage policy: passed with `Rules` at `95.19%`
- no persistence-shape migration was introduced in this task

## Runtime / host UI evidence
- Home-world preview remains informational inside the existing profile edit flow.
- Background preview remains informational inside the existing profile edit flow.
- Role preview remains informational inside the existing profile edit flow.
- Composed aptitude preview remains informational and explicitly warns when rulebook choice-slots are unresolved.
- Profile composed-aptitude preview now reads through the typed draft seam rather than recomputing directly from the overloaded raw profile fields.
- T05 runtime verification stayed green while characteristic-generation state remained transient and non-destructive.
- Existing accepted profile flow stayed intact through the full `make ci` host UI coverage run.
- XP validation screen remains reachable from Characteristics and exposes manual cost entry deterministically for the bounded characteristic path.
- XP prerequisites and registry-backed skill-cost defaults now consume engine-backed composed aptitudes when canonical fixed selections resolve.
- Host UI smoke regression was repaired without widening supported behavior claims.
- Starting-package projection remained rules-layer only and did not introduce a premature engine-backed create/edit UI flow.

## Rules / logic evidence
- Rulebook-backed catalog covers `Feral World`, `Forge World`, `Highborn`, `Hive World`, `Shrine World`, `Voidborn`.
- Rulebook-backed catalog covers `Adeptus Administratum`, `Adeptus Arbites`, `Adeptus Astra Telepathica`, `Adeptus Mechanicus`, `Adeptus Ministorum`, `Imperial Guard`, `Outcast`.
- Rulebook-backed catalog covers `Assassin`, `Chirurgeon`, `Desperado`, `Hierophant`, `Mystic`, `Sage`, `Seeker`, `Warrior`.
- Preview data and warnings distinguish:
  - rulebook-backed starting wounds/fate text
  - current-model gaps such as `Influence`, availability modifiers, combat-state package hooks, fatigue thresholds, conditional creation grants, role-bonus hooks, role-talent choices, Psyker elite advances, and typed aptitude-choice provenance
- Aptitude composition distinguishes:
  - fixed canonical package aptitudes that can be resolved safely now
  - unresolved background/role choice-slots that cannot yet be stored truthfully in the current snapshot model
- Typed creation draft distinguishes:
  - canonical selections
  - inferred choice provenance consumed from legacy `profile.aptitudes`
  - leftover fallback aptitudes that must not be silently reinterpreted after upstream choice changes
- Draft recomposition now drops no-longer-applicable background/role choices instead of letting stale engine-derived aptitude state survive a selection change.
- Characteristic generation now distinguishes:
  - standard random-roll generation with explicit dice provenance and one reroll seam
  - standard point allocation with explicit overspend/cap validation
  - transient `Influence`, which remains part of creation truth but not the current persisted `Character` snapshot
- Home-world changes now recompute or invalidate characteristic-generation state honestly instead of silently preserving stale semantics.
- Starting-package projection now distinguishes:
  - supported package effects that can be safely represented in the existing `Character` snapshot
  - unresolved supported choices that must be provided explicitly before projection
  - unsupported effects that remain compatibility diagnostics rather than silent guesses
- No automatic package application was introduced, so the app still does not imply full DHII creation support before the engine is built.

## Data safety evidence
- Detached-copy behavior confirmed? n/a
- Replace-all confirmation confirmed? n/a
- Existing saved entities preserved? yes
- Persistence backend observability unchanged? yes
- Characteristic-generation provenance silently persisted? no
- Starting-package engine state silently persisted? no

## UI / visual evidence
- Screenshot pass executed? yes, via `make ci` coverage host run
- Manual screenshot review executed? no
- Real device visual pass executed? no

## Coverage / CI evidence
- `make ci` passed? yes
- truthful coverage gate passed? yes
- package surface coverage moved from `19.59%` to `23.39%`
- per-area non-regression gate passed for App/Application/Domain/Infrastructure/Presentation/Rules

## Real-device evidence
- Real iPhone pass executed? no
- Real iPad pass executed? no
- Files picker verified on device? no
- Share destinations verified on device? no
- Hard-kill relaunch verified on device? no

## Unverified risks
- Real-device behavior is unverified.
- Full creation pipeline remains outside the current task scope.

## Residual issues
- Current character snapshot still lacks first-class `Influence`.
- Background and role package automation are still not implemented.
- Typed persistence for background/role aptitude choices is not implemented yet.
- Typed persistence for characteristic-generation state is not implemented yet.
- Typed persistence for starting-package choice provenance is not implemented yet.
- Web does not yet mirror the new creation preview foundations.

## Recommended verdict
- accepted_with_conditions

## Recommended next step
- Continue to the next roadmap slice: persistence-safe creation-state projection and migration work, followed by the engine-backed creation UI flow.
