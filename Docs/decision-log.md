# Decision Log

## 2026-03-07

1. **Decision:** Use a single Swift Package with layered + feature-first folders (`Domain`, `Application`, `Infrastructure`, `Presentation`) instead of immediately creating an Xcode multi-target workspace.
   - **Reason:** Safer reversible path in a Linux CI/container environment while preserving architecture boundaries.
   - **Type:** Fact.
   - **Impact:** Keeps domain pure and testable; iOS target wiring can be added without reworking contracts.

2. **Decision:** Implement local-first persistence with `JSONFileCharacterRepository` and keep `SwiftDataCharacterRepository` as availability-gated adapter placeholder.
   - **Reason:** данных недостаточно about runtime Apple frameworks in this environment; SwiftData cannot be validated here.
   - **Type:** Assumption.
   - **Impact:** MVP local persistence and import/export flows are usable now, with a clear path to native SwiftData integration.

3. **Decision:** Re-baseline delivery status as bootstrap/foundation, not completed MVP.
   - **Reason:** Current repository contains architecture foundation and partial vertical delivery, but not full MVP scope.
   - **Type:** Fact.
   - **Impact:** Documentation and planning must avoid completion claims until runtime-validated feature batches are delivered.

4. **Decision:** Deliver first real vertical slice focused only on character list/profile lifecycle with JSON persistence (create/open/edit autosave/duplicate/delete).
   - **Reason:** Safest reversible slice that proves end-to-end user value without expanding into broader scope while requirements are still evolving.
   - **Type:** Fact.
   - **Impact:** Establishes usable app flow and persistence confidence; additional MVP areas stay planned.

5. **Decision:** Introduce `AppContainer` as a single composition root for app-facing dependency wiring and remove repository construction from Presentation code.
   - **Reason:** Preserve architecture boundaries: Presentation depends on use-cases, while infrastructure wiring stays in bootstrap/composition.
   - **Type:** Fact.
   - **Impact:** UI stays decoupled from persistence implementation and can be tested/evolved with fewer cross-layer leaks.

6. **Decision:** Drive detail/profile screens from `characterID` + shared observable list state instead of passing a captured `Character` snapshot.
   - **Reason:** Prevent stale detail overview after profile edits and autosave operations.
   - **Type:** Fact.
   - **Impact:** Returning from profile edit immediately reflects latest state in overview.

7. **Decision:** Use debounced/coalesced autosave via `ProfileAutosaveCoordinator` with a default 500ms delay and cancellation of previous pending save for the same character.
   - **Reason:** данных недостаточно about exact UX debounce target; 500ms is a conservative reversible default.
   - **Type:** Assumption.
   - **Impact:** Reduces write churn compared to per-keystroke persistence while keeping no-explicit-save UX for this slice.

8. **Decision:** Guard autosave cleanup with a per-save token so only the currently tracked task can clear its own pending entry.
   - **Reason:** Actor re-entrancy across awaits can resume older tasks after a newer save has been registered.
   - **Type:** Fact.
   - **Impact:** Prevents newer pending saves from being dropped while preserving debounce/coalescing semantics.

9. **Decision:** For this repository (Swift Package without `.xcodeproj`/`.xcworkspace`), validation for this batch uses SwiftPM commands with explicit writable build path and does not require `xcodebuild -list`.
   - **Reason:** `xcodebuild -list` is not a meaningful gate for a package-only repo and produced environment/tooling noise rather than package validation signal.
   - **Type:** Fact.
   - **Impact:** Validation remains focused on `swift test`/`swift build` outcomes and avoids irrelevant package-host mismatch checks.

10. **Decision:** Keep the accepted package composition root and app shell as the host entry source (`DHCharListAppShell(container: .live())` / `DHCharListIOSAppHost`) and defer only iOS app-target creation to a manual Xcode step.
   - **Reason:** Repository has no committed runnable iOS target/project; adding/committing a safe `.xcodeproj` target setup was not completed in this environment.
   - **Type:** Fact.
   - **Impact:** No feature behavior change; simulator launch becomes available immediately after creating one minimal iOS host target wired to the existing package entry path.

11. **Decision:** Implement SwiftData persistence with a conservative reversible model (`SwiftDataCharacterRecord`) that stores `id`, `updatedAt`, and a serialized `Character` payload, with explicit mapper functions between domain and persistence.
   - **Reason:** Full normalized SwiftData graph modeling for all nested fields is more invasive than Batch 14 scope; payload-backed storage preserves current domain shape and minimizes migration risk while still providing a real working SwiftData adapter.
   - **Type:** Fact.
   - **Impact:** SwiftData adapter is operational now (`fetchAll`, `fetch(id:)`, `save`, `delete`) and persists/restores accepted nested domain data without changing domain contracts.

12. **Decision:** Add explicit persistence selection at composition root (`AppContainer.live(persistence:)`) and keep JSON as default runtime backend.
   - **Reason:** Preserve accepted JSON-backed behavior while enabling controlled SwiftData opt-in and safe fallback if SwiftData store initialization fails.
   - **Type:** Fact.
   - **Impact:** JSON path remains intact/validated; SwiftData path can be enabled for validation and rollout without forcing migration by default.

13. **Decision:** Introduce a minimal Xcode unit-test target (`DHCharListHostTests`) and bind it to the shared `DHCharListHost` scheme test action to unblock host-scheme coverage execution.
   - **Reason:** Batch 16 required host-scheme result-bundle-based coverage, but `DHCharListHost` previously had no attached tests and `xcodebuild test` exited with scheme test-action configuration errors.
   - **Type:** Fact.
   - **Impact:** Host scheme is now coverage-capable from a scheme/test-attachment perspective (`GetTestList` reports enabled tests), while existing SwiftPM/package tests remain intact and unchanged.

14. **Decision:** Freeze an explicit measured coverage baseline and enforce staged non-regression gates via repository-local scripts (`check_coverage_policy.sh` + `refresh_coverage_baseline.sh`) instead of introducing vanity global thresholds.
   - **Reason:** Batch 17 requires practical CI-oriented protection against regression using validated local `.xcresult`/`xccov` artifacts, while current layer-level mapping is not yet robust enough for strict per-layer numeric gating.
   - **Type:** Fact.
   - **Impact:** Current gate now fails on meaningful regression (overall and tracked non-test target coverage drops) while keeping policy realistic and staged for later tightening when stronger layer-level signals are available.

## 2026-03-08

15. **Decision:** Remove committed personal signing team identifiers from `DHCharListHost` project settings and keep Automatic signing with neutral placeholder bundle identifiers (`com.example.*`).
   - **Reason:** Batch 18 requires signing-readiness without hardcoding user/team-specific identities in repository state.
   - **Type:** Fact.
   - **Impact:** Project stays ready for local development and archive preparation, while real distribution signing remains an explicit per-developer/manual configuration step.

16. **Decision:** Add temporary placeholder app icon assets (1024x1024 light/dark/tinted) in `AppIcon.appiconset` and document them as non-final branding.
   - **Reason:** Final branded assets are not yet provided, but archive/distribution preparation should not be blocked by missing app icon files.
   - **Type:** Fact.
   - **Impact:** Asset catalog is structurally complete for current release-readiness work; final branding replacement remains a manual pre-distribution step.
