# Evidence

## qa-verifier
- Web app exists and is usable under `web/`.
- Web validation passed:
  - `.agent/tasks/2026-03-web-final-acceptance/raw/web-npm-install.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/web-typecheck.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/web-test.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/web-build.log`
- Repo-level machine evidence:
  - `.agent/tasks/2026-03-web-final-acceptance/raw/xcodebuild-version.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/xcodebuild-showsdks.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/make-fmt.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/make-lint.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/make-typecheck.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/make-test.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/make-ci.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/run-xcode-coverage.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/refresh-coverage-baseline.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/check-coverage-policy.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/xcodebuild-swiftdata-smoke.log`
  - `.agent/tasks/2026-03-web-final-acceptance/raw/xcodebuild-quick-mechanics-smoke.log`

## fix-agent
- Normalized `Makefile` package paths to use the current repo root instead of a stale host-specific absolute path.
- Tightened SwiftData compile guards so CLI SwiftPM builds stay green, then refined them to allow SwiftData in Xcode-host builds via the existing `Xcode` compilation condition.
- Added the missing `swift-testing` package dependency to make the test target’s `import Testing` declaration manifest-truthful.
- Restored valid SwiftPM manifest argument ordering in `Package.swift` so current Xcode/SwiftPM accepts the package after adding `swift-testing`.
- Added a direct `Character` `Codable` roundtrip regression test so package-surface `Domain` coverage remains truthful.
- Hardened the quick-mechanics host smoke test to reveal and resolve the custom-modifier control as either a text field or text view before interacting with it.
- Refreshed `Docs/coverage-baseline.json` from the latest truthful package-surface capture after the SwiftPM/Xcode coverage source was stabilized.

## Acceptance result
- `make fmt`, `make lint`, `make typecheck`, `make test`, and `make ci` all pass locally on this machine.
- `bash ./scripts/run_xcode_coverage.sh`, `bash ./scripts/refresh_coverage_baseline.sh`, and `bash ./scripts/check_coverage_policy.sh` pass locally after the final fixes.
- Host-project Xcode validation and the repository coverage gate are now green rather than conditionally blocked.

## Confidence
- logic confidence: high for the web app’s bounded scope
- runtime confidence: high for the validated local toolchains and bounded product scope
- UI confidence: medium
- real-device confidence: none
