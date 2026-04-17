# Task Spec

## ID
2026-04-ios-audit-hardening

## Title
Bounded iOS audit, UX hardening, and regression-proof delivery

## Goal
Audit the existing iPhone/iPad character manager end-to-end, identify the highest-value UX/UI and reliability gaps that are provable from the current codebase and local runtime, implement a bounded set of improvements, and validate the result locally with truthful evidence.

## User value
- Makes day-to-day character management clearer and less error-prone on the accepted iOS app surface.
- Reduces regression risk around trust-sensitive flows such as persistence, navigation, and session-time editing.
- Produces a concrete branch-ready improvement set instead of a report-only audit.

## Context
- The repo contains a Swift Package app core plus `DHCharListHost` for simulator/runtime validation.
- The project already uses a repo-local proof-loop process for trust-sensitive work.
- Existing validated surfaces include characters, profile, characteristics/resources, skills, notes, equipment, session mode, templates, history, import/export, dossier, and bounded rules helpers.
- The app also contains a web client, but this task is focused on the iOS host/package implementation unless shared logic changes are strictly needed.

## In scope
- Establish a truthful local baseline for build, tests, host validation, UI smoke, and coverage tooling on this machine.
- Perform a structured audit of product UX, UI implementation quality, architecture/testability, and test coverage for user-facing mechanics.
- Implement a bounded set of high-impact improvements supported by audit evidence, prioritizing usability, consistency, and regression resistance over cosmetic churn.
- Add or strengthen automated tests where they materially reduce regression risk for the touched flows.
- Record executed evidence, residual risks, and a truthful final verdict.

## Out of scope
- Full product redesign or broad visual re-theme.
- Major architecture rewrite or module split not required by the chosen fixes.
- New cloud sync, online services, or full rules-engine expansion.
- Real-device verification claims without an actual device pass.
- Unrelated web-app feature work.

## Constraints
- Do not change persistence shape unless required for a targeted fix and covered by tests.
- Do not break accepted runtime behavior or detached/local-first semantics.
- Keep scope bounded to issues that can be implemented and validated in this session.
- Prefer transparent behavior and explicit diagnostics over hidden magic.
- Use a separate branch/worktree and keep the final report evidence-backed.

## User-facing surfaces touched
- Characters / detail navigation
- Editing flows on major character subscreens
- Session / combat workspace
- Dossier / share entry path
- Host smoke/screenshot validation flows
- Other: only if required by selected fixes

## Rules / data / trust impact
- Affects rules correctness: possible, but not a planned primary target
- Affects progression correctness: no unless audit uncovers a directly related bug
- Affects combat/session trust: yes
- Affects destructive data flow: possible if delete/import related fixes are selected
- Affects import/replace semantics: possible if audit shows a concrete UX/reliability gap
- Affects persistence observability: possible

## Trust-critical risks
- UX polish could accidentally change accepted editing/navigation behavior.
- Test additions may still miss simulator-only regressions if coverage is implementation-heavy.
- Persistence- or import-adjacent fixes could create silent state divergence if not validated thoroughly.
- Simulator-only validation cannot stand in for real share sheet / Files / physical device behavior.

## Acceptance criteria
- AC1. A reproducible local baseline is established with actual command results for build/test/runtime-related checks.
- AC2. The audit identifies concrete problems with location, user impact, risk, and recommended verification.
- AC3. A bounded set of high-value fixes is implemented and covered by relevant automated tests where practical.
- AC4. All relevant local checks for the touched scope pass before completion, or blockers are documented truthfully.
- AC5. Evidence and verdict distinguish logic, runtime, UI, and real-device confidence.

## Required validation
- `make fmt`
- `make lint`
- `make typecheck`
- `make test`
- `swift build --disable-sandbox --package-path . --build-path /tmp/dh_charlist-build`
- `swift test --disable-sandbox --package-path . --build-path /tmp/dh_charlist-build`
- `xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -configuration Debug -destination 'generic/platform=iOS Simulator' build`
- `bash ./scripts/run_xcode_coverage.sh`
- `bash ./scripts/check_coverage_policy.sh`
- Focused host/UI tests derived from the touched scope
- Screenshot/manual pass required: yes, on simulator
- Real-device pass required: no in this session unless explicitly executed

## Manual acceptance required
yes

If yes, list exactly what must be checked manually:
- iPhone pass:
  - major touched flows remain readable and operable on compact width
  - empty/error/success states for touched flows remain understandable
- iPad pass:
  - touched screens still have readable width and stable sheet behavior
- Files / Share integration:
  - dossier/share flow only at simulator/manual level unless a real-device pass is executed
- Compact-screen / layout:
  - no critical action is occluded or clipped on touched screens

## Evidence expectations
The evidence bundle must include:
- exact commands actually executed
- focused runtime/host UI evidence where available
- clear list of implemented fixes and their verification
- explicit unverified risks
- final recommendation: accepted / accepted_with_conditions / rejected

## Notes for implementer
- Keep implementation tightly coupled to audit findings.
- Prefer improvements that increase clarity, reduce cognitive load, or harden regression detection.
- Do not claim real-device behavior unless it was actually verified on a device.
