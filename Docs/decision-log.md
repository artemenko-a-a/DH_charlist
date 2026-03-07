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

3. **Decision:** Keep UI screens scaffolded and minimal text-driven forms/navigation.
   - **Reason:** данных недостаточно about frozen design tokens/layout; prioritised complete MVP feature coverage and navigation smoke path.
   - **Type:** Assumption.
   - **Impact:** Functional shell exists; visual polish can iterate without changing domain/persistence contracts.
