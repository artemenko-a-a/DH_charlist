# Evidence Report

## Task
- ID: 2026-04-dhii-engine
- Title: DHII Engine architecture freeze with Tasks 01-07 creation foundations and persistence seam

## What was implemented
- Repo architecture, DHII engine target state, phased roadmap, and ordered task decomposition are documented in [`Docs/dhii-engine-roadmap.md`](/Users/andrey_artemenko/repos/DH_charlist/Docs/dhii-engine-roadmap.md).
- Tasks 01-03 established canonical DHII catalogs and explainable previews in [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift):
  - six core home worlds
  - seven core backgrounds
  - eight core roles
  - alias normalization
  - rulebook-backed summaries and compatibility diagnostics
- Task 03 also added deterministic aptitude composition and bounded progression integration in:
  - [`Sources/DHCharList/Rules/XPProgression.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/XPProgression.swift)
  - [`Sources/DHCharList/Rules/ProgressionRegistries.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/ProgressionRegistries.swift)
  - [`Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Progression/XPSpendScreen.swift)
- Task 04 introduced the typed in-memory creation aggregate in [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift):
  - canonical selections
  - explicit choice-slot state
  - legacy fallback aptitude separation
  - stale-choice pruning on upstream changes
- Task 05 introduced typed creation-time characteristic generation in:
  - [`Sources/DHCharList/Rules/CharacterCreationCharacteristics.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationCharacteristics.swift)
  - [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift)
  - supports standard DHII random generation (`2d10 + 20`, one reroll, home-world modifiers)
  - supports standard point allocation (`25` base, `60` points, `40` cap)
  - keeps transient `Influence` explicit
- Task 06 introduced bounded starting-package projection in [`Sources/DHCharList/Rules/CharacterCreationProjection.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationProjection.swift), yielding a safe legacy `Character` snapshot plus transient `Influence` from a fully resolved creation draft.
- Task 07 introduced additive persisted engine state in:
  - [`Sources/DHCharList/Domain/CharacterEngineState.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Domain/CharacterEngineState.swift)
  - [`Sources/DHCharList/Domain/Character.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Domain/Character.swift)
  - [`Sources/DHCharList/Rules/CharacterCreationEngine.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationEngine.swift)
  - [`Sources/DHCharList/Rules/CharacterCreationProjection.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Rules/CharacterCreationProjection.swift)
  - [`Sources/DHCharList/Infrastructure/ImportExport/CharacterJSONImportExportService.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Infrastructure/ImportExport/CharacterJSONImportExportService.swift)
- Persisted engine state now stores, in additive form:
  - canonical home world/background/role ids
  - supported choice-slot selections
  - starting wounds/fate rolls
  - legacy fallback aptitudes
  - characteristic-generation provenance and point-allocation state
- Draft restoration now prefers persisted engine state when available and sanitizes stale or unknown persisted values before rebuilding the typed draft.
- Export/import now remains backward-compatible:
  - schema `1` imports still load
  - schema `2` exports round-trip `dhiiEngineState`
- Profile preview surfaces remain informational in [`Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift`](/Users/andrey_artemenko/repos/DH_charlist/Sources/DHCharList/Presentation/Features/Profile/ProfileScreen.swift); no full engine-backed creation UI has been claimed or introduced yet.

## Test files added or expanded
- [`Tests/DHCharListTests/CharacterCreationEngineTests.swift`](/Users/andrey_artemenko/repos/DH_charlist/Tests/DHCharListTests/CharacterCreationEngineTests.swift)
- [`Tests/DHCharListTests/DHCharListTests.swift`](/Users/andrey_artemenko/repos/DH_charlist/Tests/DHCharListTests/DHCharListTests.swift)
- Existing web regression tests remained part of the validation gate

## Commands actually run
- `swift test --filter CharacterCreationEngineTests`
- `swift test --filter DHCharListTests`
- `swift build`
- `swift test`
- `cd web && npm test`
- `cd web && npm run typecheck`
- `cd web && npm run build`
- `make fmt`
- `make lint`
- `make typecheck`
- `make test`
- `make ci`

## Results
- `swift test --filter CharacterCreationEngineTests`: passed
- `swift test --filter DHCharListTests`: passed
- `swift build`: passed
- `swift test`: passed (`198` tests)
- `cd web && npm test`: passed (`17` tests)
- `cd web && npm run typecheck`: passed
- `cd web && npm run build`: passed
- `make fmt`: passed (`no-op fallback; no repository formatter configured`)
- `make lint`: passed (`no-op fallback; no repository linter configured`)
- `make typecheck`: passed
- `make test`: passed
- `make ci`: passed
- Coverage policy: passed
- Coverage highlights from the final `make ci` run:
  - package surface coverage: `27.06%`
  - Domain: `96.91%`
  - Rules: `94.27%`

## Rules / logic evidence
- Canonical engine catalogs cover the full DHII core sets already targeted by the roadmap:
  - home worlds: `Feral World`, `Forge World`, `Highborn`, `Hive World`, `Shrine World`, `Voidborn`
  - backgrounds: `Adeptus Administratum`, `Adeptus Arbites`, `Adeptus Astra Telepathica`, `Adeptus Mechanicus`, `Adeptus Ministorum`, `Imperial Guard`, `Outcast`
  - roles: `Assassin`, `Chirurgeon`, `Desperado`, `Hierophant`, `Mystic`, `Sage`, `Seeker`, `Warrior`
- Explainable aptitude composition distinguishes:
  - fixed package aptitudes that can be derived safely now
  - unresolved choice-slots that must stay explicit
  - leftover legacy fallback aptitudes that must not be silently reinterpreted
- Characteristic generation is typed and rulebook-backed for the supported standard modes only.
- Starting-package projection refuses unresolved or unsupported states instead of guessing.
- Persisted creation-state restoration is sanitized; stale/unknown canonical ids do not get blindly trusted as valid DHII state.
- Engine-backed projection now persists its bounded creation truth explicitly, instead of forcing later reloads to rely only on ambiguous legacy `Profile` text.

## Data safety evidence
- Existing saved characters still decode if `dhiiEngineState` is absent.
- Additive persistence does not rewrite legacy freeform profile fields into typed replacements.
- Import/export remains backward-compatible for legacy schema `1`.
- Export now emits schema `2`, making the migration explicit instead of silent.
- `Character` codable round-trip preserves `dhiiEngineState` when present and defaults it to `nil` when absent.
- Projected engine-backed characters round-trip without losing persisted creation state.
- No silent destructive migration path was introduced.

## Runtime / UI evidence
- Existing profile flow remains intact and still treats DHII previews as informational.
- Host/UI regression coverage stayed green through the final `make ci` run, including the long smoke suite.
- No new contradictory user-visible state was observed in the bounded flows covered by the regression suite.
- Manual screenshot review was not performed.

## Confidence split
- Logic confidence: high
- Runtime confidence: high
- UI confidence: medium-high
- Real-device confidence: low

## Not verified in this environment
- Real-device behavior
- Full engine-backed staged creation/edit UI flow
- Progression/dependency hardening beyond the currently bounded helpers

## Residual issues
- `Influence` still is not a first-class persisted field on the public `Character` snapshot.
- The app still does not provide a full engine-backed creation/edit flow.
- Background and role package automation outside the currently supported bounded projection surface remains unfinished.
- Web still does not consume the new creation engine seam directly.

## Recommended verdict
- accepted_with_conditions

## Recommended next step
- Proceed to Task 08: replace the current manual creation illusion with a staged engine-backed creation/edit flow that reads and writes the persisted DHII engine state safely.
