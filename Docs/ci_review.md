# CI Review — DH_charlist

Engineering review of the project's current state and CI setup.
Date: 2026-03-08.

---

## 1. Project state (what was found)

### Architecture

The project is a Swift Package (`DHCharList`) with a clean layered structure:

- `Domain/` — pure Swift, no framework deps; `Character`, `CharacterTemplate` entities
- `Application/` — use-cases, repository protocols, autosave coordinator
- `Infrastructure/Persistence/` — two implementations: `JSONFileCharacterRepository` (default) and `SwiftDataCharacterRepository` (opt-in)
- `Presentation/` — SwiftUI screens; does not touch infrastructure directly
- `App/AppContainer.swift` — single composition root

A host Xcode project (`DHCharListHost/DHCharListHost.xcodeproj`) wraps the package for simulator launch and Xcode-level test execution.

**Assessment:** architecture is sound and boundaries are respected.

### Package / app boundary

- Swift Package is clean and dependency-free (no third-party packages).
- Host app correctly imports `DHCharList` as a local package dependency.
- Two test targets exist: `DHCharListTests` (SwiftPM) and `DHCharListHostTests` (Xcode, attached to host scheme).

### Persistence

| Path | Status |
|------|--------|
| JSON (`JSONFileCharacterRepository`) | Validated, default |
| SwiftData (`SwiftDataCharacterRepository`) | Implemented, opt-in via `AppContainer.live(persistence: .swiftData)` |

Both paths support characters and templates.

### Test coverage

| Target | Tests |
|--------|-------|
| `DHCharListTests` (SwiftPM) | Minimal — 1 test covering `Character` and/or domain logic |
| `DHCharListHostTests` (Xcode unit) | 2 tests: `DHCharListHostCoverageSmokeTests`, `DHCharListHostLaunchConfigurationTests` |
| `DHCharListHostUITests` (Xcode UI) | 2 test classes: `DHCharListHostSmokeUITests`, `DHCharListHostScreenshotUITests` |

Coverage baseline is tracked in `Docs/coverage-baseline.json` (overall: 62.5%). Coverage scripts exist (`scripts/run_xcode_coverage.sh`, `scripts/check_coverage_policy.sh`) but are not part of the required CI gate — see below.

### Scripts

| Script | Purpose | Status |
|--------|---------|--------|
| `scripts/run_ui_smoke.sh` | Run UI smoke tests | Fixed: auto-selects simulator instead of hardcoded UUID |
| `scripts/run_ui_screenshots.sh` | Capture screenshots | Fixed: auto-selects simulator |
| `scripts/run_xcode_coverage.sh` | Generate coverage bundle | Fixed: auto-selects simulator |
| `scripts/check_coverage_policy.sh` | Non-regression gate vs baseline | Not in required CI |
| `scripts/refresh_coverage_baseline.sh` | Update baseline intentionally | Local/manual only |
| `scripts/write_coverage_metrics.py` | Extract metrics from xcresult | Used by coverage script |

---

## 2. Risks and gaps found (before changes)

| Risk | Severity | Decision |
|------|----------|---------|
| **Hardcoded simulator UUID** (`id=99E2D143-...`) in 3 scripts | High — UUID is machine-specific; scripts fail on any other machine | Fixed: auto-detect via `xcrun simctl list` |
| **Hardcoded local paths** in README build/test commands | Medium — misleads contributors and AI agents | Fixed: corrected to `swift build` / `swift test` |
| **Coverage gate not stable** — `DHCharListHost` scheme previously reported 0 attached tests | High — coverage gate would produce unreliable signal | Kept outside required CI; documented |
| **UI tests as required gate** — simulator-dependent, heavy, timing-sensitive | High — would cause flaky PR failures | Moved to manual `workflow_dispatch` only |
| **`macos-14` runner** in CI | Low — still functional, but `macos-15` aligns with current Xcode 16 availability | Updated to `macos-15` |
| **No step names in `swift-package` job** | Low — makes CI logs harder to read | Fixed: added explicit `name:` to all steps |

---

## 3. What was NOT done (and why)

| Item | Reason |
|------|--------|
| Coverage as required merge gate | Coverage collection from `DHCharListHost` scheme is documented as having `0 attached tests` issues; enforcing it now would cause false failures |
| Linting / SwiftLint | No linting infrastructure in the repo; adding now would be ceremony without foundation |
| Code scanning (CodeQL) | Not asked for; would add noise without existing baseline |
| Strict per-layer numeric coverage gating | Not enough stable multi-run evidence; `Docs/coverage-baseline.json` is in Stage 2 of a planned 3-stage rollout |
| UI tests as PR gate | Too fragile and slow for a required gate; moved to manual dispatch |
| Architecture refactors | Out of scope; architecture is sound |

---

## 4. Changes made

### `.github/workflows/ci.yml`
- Updated runner from `macos-14` → `macos-15`
- Added explicit `name:` to all steps for readable CI log output
- No functional change to what is tested

### `.github/workflows/ui-tests.yml` (new)
- `workflow_dispatch`-only (not triggered on push/PR)
- Accepts `test_target` input: `smoke` or `screenshots`
- Auto-detects first available iPhone simulator via `xcrun simctl list devices available`
- Uploads screenshot attachments as GitHub Actions artifacts when `screenshots` mode is selected

### `scripts/run_ui_smoke.sh`
- Removed hardcoded simulator UUID `id=99E2D143-E43E-4CE7-9F72-D05AE2A7A51C` as default
- Added `_pick_simulator_destination()` — auto-selects first available iPhone simulator via `xcrun simctl list devices available --json`; falls back to `platform=iOS Simulator,OS=latest`
- `UI_DESTINATION` env var still works as before

### `scripts/run_ui_screenshots.sh`
- Same fix as `run_ui_smoke.sh`

### `scripts/run_xcode_coverage.sh`
- Same fix: removed hardcoded UUID, added `_pick_simulator_destination()`
- Variable order unchanged; `COVERAGE_DESTINATION` env var override still works

### `README.md`
- Fixed canonical build/test commands: removed `--disable-sandbox --package-path ... --build-path ...` flags that contained hardcoded local paths
- Commands are now simply `swift build` and `swift test`

### `.github/copilot-instructions.md` (new)
- Canonical commands for AI agents and contributors
- Architecture summary, CI summary, key decisions

---

## 5. Required checks (branch protection recommendations)

The following checks from `ci.yml` should be configured as **required** in branch protection:

| Check name | Rationale |
|-----------|-----------|
| `SwiftPM build + test` | Validates the package builds and all unit tests pass; fast, reliable, no simulator |
| `Xcode build + analyze (DHCharListHost)` | Validates the host Xcode project builds cleanly and passes Xcode's static analyzer |

The following should remain **optional / manual**:

| Workflow | Rationale |
|----------|-----------|
| `UI Tests (manual)` | Simulator-dependent, heavy, timing-sensitive; not proven stable enough for a required gate |
| Coverage scripts | Not in CI; requires local Xcode result bundles |
