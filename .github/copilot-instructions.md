# Copilot Instructions — DH_charlist

Dark Heresy II character manager for iPhone/iPad. Swift Package + Xcode host app.

## Repository layout

| Path | Purpose |
|------|---------|
| `Package.swift` | Swift Package manifest (targets: `DHCharList`, `DHCharListTests`) |
| `Sources/DHCharList/` | All library source: Domain / Application / Infrastructure / Presentation |
| `Tests/DHCharListTests/` | Swift Package unit tests |
| `DHCharListHost/` | Xcode project — host app for simulator launch and Xcode-level tests |
| `scripts/` | Local dev/CI helper scripts |
| `Docs/` | Decision log, progress log, coverage baseline, manual checklist |

## Canonical commands

### Build and test (Swift Package)

```bash
swift build
swift test
```

These are the authoritative commands. Do not add `--disable-sandbox`, `--package-path`, or `--build-path` flags unless explicitly required by a specific environment constraint.

### Xcode host app build (no simulator required)

```bash
xcodebuild \
  -project DHCharListHost/DHCharListHost.xcodeproj \
  -scheme DHCharListHost \
  -destination "generic/platform=iOS Simulator" \
  -configuration Debug \
  build
```

### UI smoke tests (requires a booted simulator)

```bash
./scripts/run_ui_smoke.sh
```

Override destination (optional):

```bash
UI_DESTINATION="platform=iOS Simulator,OS=latest,name=iPhone 16" ./scripts/run_ui_smoke.sh
```

### Coverage (Xcode result bundle, local only)

```bash
./scripts/run_xcode_coverage.sh
./scripts/check_coverage_policy.sh
```

## Architecture

- **Domain** — pure Swift, no framework dependencies
- **Application** — use-cases and repositories (protocols)
- **Infrastructure** — persistence implementations: `JSONFileCharacterRepository` (default) and `SwiftDataCharacterRepository` (opt-in)
- **Presentation** — SwiftUI views; does not construct infrastructure directly
- **Composition root** — `AppContainer.live(persistence:)` wires everything; JSON is the default/fallback

## CI

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | push/PR to `main` | `swift build`, `swift test`, Xcode build + analyze |
| `ui-tests.yml` | `workflow_dispatch` | Manual UI smoke or screenshot tests (not a required gate) |

### Required checks for branch protection

These two checks from `ci.yml` should be marked **required** in branch protection:
- `SwiftPM build + test`
- `Xcode build + analyze (DHCharListHost)`

The `UI Tests (manual)` workflow is **not** a required gate — it is heavy, simulator-dependent, and should remain opt-in/manual.

### Coverage gate

Coverage scripts exist and are tracked in `Docs/coverage-baseline.json`, but **the coverage gate is not a required CI check**. The `DHCharListHost` scheme previously reported 0 attached tests; validate carefully before enabling coverage as a merge gate.

## Key decisions

- JSON-backed persistence is the default. SwiftData is opt-in via `AppContainer.live(persistence: .swiftData)`.
- Bundle ID is a placeholder: `com.example.DHCharListHost`. Real signing and distribution IDs must be configured manually.
- UI tests are fragile and simulator-dependent; they live in `DHCharListHostUITests` and are only run manually.
- Do not hardcode simulator UUIDs or local paths in scripts; use `xcrun simctl list devices available` for auto-detection.
