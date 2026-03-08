# DH_charlist

Dark Heresy II character manager for iPhone/iPad.

> Current state: the project is implemented and validated on two local persistence paths:
> - JSON-backed path — validated and kept as the default/fallback path
> - SwiftData path — validated and selectable through composition/bootstrap

## Implemented and validated

The project currently includes:

- character lifecycle flow:
  - list characters
  - create
  - open details
  - edit profile with autosave
  - duplicate
  - delete
- characteristics and resources editing
- skills editing
- notes / talents / traits / mutations / disorders / psychic powers / special abilities editing
- equipment editing:
  - weapons
  - armour
  - movement
  - inventory
- session mode editing
- user-facing JSON import/export
- runtime host app bridge for simulator launch via `DHCharListHost`
- two validated local persistence paths:
  - JSON repository
  - SwiftData repository

## Persistence modes

### Default / fallback
The default local persistence path is JSON-backed.

### SwiftData
SwiftData is also implemented and validated and can be selected through composition:

- `AppContainer.live(persistence: .swiftData)`

The JSON-backed path remains available as the conservative fallback.

## How to run tests

```bash
swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build
```
How to build the package
```bash
swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build
```
## Coverage workflow (Batch 17)

Coverage source of truth is Xcode result bundles plus `xccov` output.

Canonical local coverage command:
```bash
./scripts/run_xcode_coverage.sh
```

What this command does:
- runs `xcodebuild test` with code coverage enabled for the `DHCharListHost` scheme
- writes a `.xcresult` bundle
- exports human-readable coverage summary text via `xcrun xccov view --report`
- exports machine-readable JSON coverage report via `xcrun xccov view --report --json`
- writes normalized machine metrics JSON for automation

Coverage artifact locations:
- default per-run output: `DHCharListHost/artifacts/coverage/<timestamp>/`
- latest run symlink: `DHCharListHost/artifacts/coverage/latest`
- key files:
  - `TestResults.xcresult`
  - `xcodebuild-test.log`
  - `xccov-summary.txt`
  - `xccov-report.json`
  - `coverage-metrics.json`
- override output root when needed:
```bash
COVERAGE_OUTPUT_ROOT=/absolute/path ./scripts/run_xcode_coverage.sh
```

Policy + regression check:
- baseline/policy file: `Docs/coverage-baseline.json`
- canonical local coverage gate command:
```bash
./scripts/check_coverage_policy.sh
```
- baseline refresh command (intentional/manual):
```bash
./scripts/refresh_coverage_baseline.sh
```

Current enforced policy (staged, non-vanity):
- baseline-first from real `xccov` artifacts (`coverage-metrics.json`)
- overall non-regression gate:
  - baseline: `62.50%`
  - allowed drop: `0.50pp`
- conservative per-target non-regression gate (non-test targets captured in baseline):
  - currently enforced target: `DHCharListHost.app`
  - allowed drop: `1.00pp`
- Domain/Application/Infrastructure still carry stronger testing expectations by policy intent, but strict per-layer numeric gating remains staged until layer mapping in coverage artifacts is robust.

Coverage gate failure conditions:
- `coverage-metrics.json` is missing
- baseline file is missing or baseline overall is unset
- current overall coverage drops below `baseline - allowed_overall_drop_pp`
- any enforced non-test target drops below `target_baseline - allowed_target_drop_pp`
- any enforced target disappears from current metrics or loses executable lines below policy floor

How to intentionally refresh baseline:
1. Run a new coverage capture with `./scripts/run_xcode_coverage.sh`.
2. Review `DHCharListHost/artifacts/coverage/latest/coverage-metrics.json`.
3. Run `./scripts/refresh_coverage_baseline.sh`.
4. Re-run `./scripts/check_coverage_policy.sh` to confirm the updated baseline is internally consistent.

Current environment note:
- the active `DHCharListHost` scheme reports `0` attached tests in Xcode test-plan metadata, so coverage collection from that scheme requires test action coverage to be present in the selected scheme.

How to run in simulator

Open DHCharListHost.xcodeproj in Xcode, choose the DHCharListHost scheme, select an iOS simulator, and run the app.

The host app launches the accepted package UI and is the intended simulator/runtime entry point.

Current architectural state
    •    Domain remains independent from SwiftUI and SwiftData.
    •    Presentation does not construct infrastructure directly.
    •    Composition/bootstrap chooses the persistence implementation.
    •    JSON-backed path is the default validated runtime-safe path.
    •    SwiftData path is implemented as a validated alternative.

Notes

This repository was delivered in controlled batches with validation and recovery passes.
Historical delivery details and batch-by-batch status are tracked in:
    •    Docs/progress-log.md
    •    Docs/decision-log.md
    •    Docs/manual-smoke-checklist.md
