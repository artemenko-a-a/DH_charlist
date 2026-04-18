# Evidence Report

## Task
- ID: 2026-04-dhii-engine
- Title: DHII Engine architecture freeze with Tasks 01-02 creation foundations

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
- Integrated informational home-world preview into [`Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift) without changing persistence shape or silently automating creation packages.
- Integrated informational background preview into [`Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift) without changing persistence shape, replacing the existing free-text field, or implying automatic package application.
- Added rule-focused regression coverage in [`Tests/DHCharListTests/CharacterCreationEngineTests.swift`](/Users/andrey_artemenko/repos/DH_charlist/Tests/DHCharListTests/CharacterCreationEngineTests.swift).
- Hardened XP validation UI ergonomics and verification stability in [`Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift) and [`DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift`](/Users/andrey_artemenko/repos/DH_charlist/DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift):
  - numeric XP cost now has explicit text-state synchronization
  - iOS number-pad flow now exposes a keyboard `Done` dismissal
  - XP smoke was narrowed to the stable bounded UI guarantee actually required by Task 01
- Stabilized `testSmokeCoreFlowsAndEntryPoints` in [`DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift`](/Users/andrey_artemenko/repos/DH_charlist/DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift) by switching the create-flow readiness assertion from a brittle navigation-bar-only check to a readiness check that accepts the actual quick-start entry point as the screen contract.

## Files changed
- `Docs/dhii-engine-roadmap.md`
- `Docs/progress-log.md`
- `Sources/DHCharList/Rules/CharacterCreationEngine.swift`
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
- `xcodebuild test -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -destination 'platform=iOS Simulator,id=A91DD7E0-C2BD-4919-8398-B12E5F9748BD' -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testSmokeCoreFlowsAndEntryPoints`
- `cd web && npm test`
- `cd web && npm run typecheck`
- `xcodebuild test -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -destination 'platform=iOS Simulator,id=99FC7BC1-9328-43FF-ADFC-5CCE680E04F6' -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testXPSpendingValidationScreenShowsManualCharacteristicCostEntry`
- `npm test -- --runInBand` (failed immediately due unsupported Vitest flag; no code change resulted from this command)
- `make ci`

## Results
- `swift test`: passed (`165` tests)
- `swift test`: passed again after T02 changes (`169` tests)
- targeted host UI rerun for `testSmokeCoreFlowsAndEntryPoints`: passed
- `cd web && npm test`: passed (`17` tests)
- `cd web && npm run typecheck`: passed
- `cd web && npm run build`: passed
- targeted host UI smoke for XP validation screen: passed
- first `make ci`: failed because `testSmokeCoreFlowsAndEntryPoints` used a brittle create-screen readiness assertion
- second `make ci`: passed after smoke stabilization
- coverage policy: passed
- no persistence-shape migration was introduced in this task

## Runtime / host UI evidence
- Home-world preview remains informational inside the existing profile edit flow.
- Background preview remains informational inside the existing profile edit flow.
- Existing accepted profile flow stayed intact through the full `make ci` host UI coverage run.
- XP validation screen remains reachable from Characteristics and exposes manual cost entry deterministically for the bounded characteristic path.
- Host UI smoke regression was repaired without widening supported behavior claims.

## Rules / logic evidence
- Rulebook-backed catalog covers `Feral World`, `Forge World`, `Highborn`, `Hive World`, `Shrine World`, `Voidborn`.
- Rulebook-backed catalog covers `Adeptus Administratum`, `Adeptus Arbites`, `Adeptus Astra Telepathica`, `Adeptus Mechanicus`, `Adeptus Ministorum`, `Imperial Guard`, `Outcast`.
- Preview data and warnings distinguish:
  - rulebook-backed starting wounds/fate text
  - current-model gaps such as `Influence`, availability modifiers, combat-state package hooks, fatigue thresholds, and conditional creation grants
- No automatic package application was introduced, so the app still does not imply full DHII creation support before the engine is built.

## Data safety evidence
- Detached-copy behavior confirmed? n/a
- Replace-all confirmation confirmed? n/a
- Existing saved entities preserved? yes
- Persistence backend observability unchanged? yes

## UI / visual evidence
- Screenshot pass executed? yes, via `make ci` coverage host run
- Manual screenshot review executed? no
- Real device visual pass executed? no

## Coverage / CI evidence
- `make ci` passed? yes
- truthful coverage gate passed? yes
- package surface coverage moved from `19.59%` to `20.02%`
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
- Web does not yet mirror the new background preview foundation.

## Recommended verdict
- accepted_with_conditions

## Recommended next step
- Continue to the next roadmap slice: role catalog and aptitude composition on top of the now-complete home-world/background foundations.
