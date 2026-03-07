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
