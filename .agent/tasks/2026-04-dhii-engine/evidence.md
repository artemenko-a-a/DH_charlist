# Evidence Report

## Task
- ID: 2026-04-dhii-engine
- Title: DHII Engine architecture freeze and Task 01 home-world foundation

## What was implemented
- Frozen DHII Engine roadmap with explicit phase/task decomposition for the full engine rollout.
- Added typed home-world creation foundation in [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift) with:
  - canonical six-core-world catalog
  - alias normalization
  - rulebook-backed previews
  - compatibility diagnostics for effects the current model cannot yet project safely
- Integrated informational home-world preview into [`Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift) without changing persistence shape or silently automating creation packages.
- Added rule-focused regression coverage in [`Tests/DHCharListTests/CharacterCreationEngineTests.swift`](/Users/andrey_artemenko/repos/DH_charlist/Tests/DHCharListTests/CharacterCreationEngineTests.swift).
- Hardened XP validation UI ergonomics and verification stability in [`Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift) and [`DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift`](/Users/andrey_artemenko/repos/DH_charlist/DHCharListHost/DHCharListHostUITests/DHCharListHostSmokeUITests.swift):
  - numeric XP cost now has explicit text-state synchronization
  - iOS number-pad flow now exposes a keyboard `Done` dismissal
  - XP smoke was narrowed to the stable bounded UI guarantee actually required by Task 01

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
- `cd web && npm test`
- `cd web && npm run typecheck`
- `xcodebuild test -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -destination 'platform=iOS Simulator,id=99FC7BC1-9328-43FF-ADFC-5CCE680E04F6' -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testXPSpendingValidationScreenShowsManualCharacteristicCostEntry`
- `make ci`

## Results
- `swift test`: passed (`165` tests)
- `cd web && npm test`: passed (`17` tests)
- `cd web && npm run typecheck`: passed
- targeted host UI smoke for XP validation screen: passed
- `make ci`: passed
- coverage policy: passed
- no persistence-shape migration was introduced in this task

## Runtime / host UI evidence
- Home-world preview remains informational inside the existing profile edit flow.
- Existing accepted profile flow stayed intact through the full `make ci` host UI coverage run.
- XP validation screen remains reachable from Characteristics and exposes manual cost entry deterministically for the bounded characteristic path.
- Host UI smoke regression was repaired without widening supported behavior claims.

## Rules / logic evidence
- Rulebook-backed catalog covers `Feral World`, `Forge World`, `Highborn`, `Hive World`, `Shrine World`, `Voidborn`.
- Preview data and warnings distinguish:
  - rulebook-backed starting wounds/fate text
  - current-model gaps such as Influence and later package interactions
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

## Recommended verdict
- accepted_with_conditions

## Recommended next step
- Continue to the next roadmap slice: background package catalog and typed creation-state expansion.
