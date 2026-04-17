# Evidence Log

## Scope freeze
- Task bundle initialized before implementation.
- Scope bounded to audit-driven UX/UI/reliability improvements plus validation.
- Out of scope kept explicit: no real-device claims, no broad architectural rewrite, no design-system rebuild, no speculative feature expansion.

## Executed commands
- `git worktree add -b codex/ios-audit-hardening /Users/andrey_artemenko/.config/superpowers/worktrees/DH_charlist/codex-ios-audit-hardening`
- `make ci` baseline and post-fix runs from the isolated worktree.
- Targeted validation:
  - `swift test --disable-sandbox --parallel`
  - `xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -testPlan DHCharListHost -destination 'platform=iOS Simulator,id=A91DD7E0-C2BD-4919-8398-B12E5F9748BD' -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testQuickMechanicsHelpersAcrossCharacteristicSkillAndSessionFlows test`
- Coverage / policy validation via repo scripts:
  - `bash ./scripts/run_xcode_coverage.sh`
  - `bash ./scripts/check_coverage_policy.sh`
- Supporting environment checks:
  - `xcodebuild -version`
  - `xcrun simctl list devices available`
  - `swift -e '...'` for error-behavior confirmation while writing branch-coverage tests.

## Observed baseline
- Repo shape: Swift package `DHCharList` plus Xcode host app `DHCharListHost`.
- Local workflow: `Makefile` defines `ci` as `fmt` + `lint` no-op, `swift build`, `swift test`, host build, coverage generation, coverage policy check.
- Initial worktree-specific blocker: `DHCharListHost.xcodeproj` pointed local package to a hardcoded relative path that broke host builds outside the main checkout.
- Initial persistence regression risk: fallback diagnostics in `AppContainer` were being improved, but new logic was not yet fully covered by tests and later surfaced as a real coverage-policy failure.
- Quick Check UX finding: the most important value, final target, was not surfaced early enough in the sheet; the modifier section also moved deeper once summary content was improved, exposing brittle UI smoke assumptions.
- Test coverage finding: logic and host/UI tests were already substantial, but some smoke checks asserted layout traversal details rather than user-visible outcomes.

## Implemented changes
- Fixed host project local package reference for worktree portability in `DHCharListHost.xcodeproj/project.pbxproj`.
- Kept Quick Check sheets opening at `.large` detent in characteristics, skills, and session flows to preserve context density and avoid cramped modal starts.
- Reworked `QuickMechanicsHelperView` so the resolved target is surfaced immediately:
  - new "Current Target" section near the top,
  - visible `quick-check.final-target` chip,
  - clearer check/source summary before lower-priority controls.
- Hardened persistence fallback diagnostics in `AppContainer`:
  - prefer `LocalizedError.errorDescription`,
  - else use trimmed `localizedDescription`,
  - else fall back to `String(describing:)`.
- Added direct tests for all diagnostic formatting branches.
- Updated smoke UI test expectations to validate the new Quick Check hierarchy without depending on the removed custom-modifier path, and increased reveal budget where the UI became intentionally deeper.
- Preserved repo CI behavior by keeping explicit `swift-testing` package resolution; `Package.resolved` now records the resolved pins used by the successful local run.

## Verification summary
- Final full local validation succeeded on this machine through `make ci`.
- Verified outcomes from the successful final run:
  - Swift package build succeeded.
  - Swift package tests passed: `157 tests passed`.
  - Host app build succeeded.
  - Host/unit/UI test suite passed under Xcode coverage run.
  - Coverage artifacts were generated under `DHCharListHost/artifacts/coverage/20260417-122731/`.
  - Coverage policy passed, including `App` area recovery to `93.75%` vs required minimum `91.68%`.
- Key raw evidence:
  - Baseline failing worktree run: `.agent/tasks/2026-04-ios-audit-hardening/raw/make-ci-baseline.txt`
  - Final green CI log: `.agent/tasks/2026-04-ios-audit-hardening/raw/make-ci-final.txt`
  - Final coverage metrics: `DHCharListHost/artifacts/coverage/20260417-122731/coverage-metrics.json`
  - Targeted Quick Check UI validation result bundle:
    `/Users/andrey_artemenko/Library/Developer/Xcode/DerivedData/DHCharListHost-bansmeejvsdiqxgnyhbfrxhdgwrk/Logs/Test/Test-DHCharListHost-2026.04.17_11-42-32-+0700.xcresult`

## Confidence
- Logic confidence: high
- Runtime confidence: high for simulator/local CI paths
- UI confidence: medium-high on simulator-backed smoke flows; improved Quick Check behavior and validated end-to-end through host UI tests
- Real-device confidence: not verified

## Residual risks
- Real-device behavior is still unverified and must not be inferred from simulator success.
- iPad-specific runtime behavior was reviewed from code structure but not explicitly exercised in a dedicated simulator matrix during this task.
- `swift-testing` dependency currently remains explicit for reproducible `make ci` behavior with the repo’s isolated build path, despite deprecation warnings under the Swift 6 toolchain.
