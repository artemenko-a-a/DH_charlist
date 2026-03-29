# Problems

## External machine blocker: iOS platform not installed in local Xcode

- Observed command failures:
  - `make ci`
  - `xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj -scheme DHCharListHost -configuration Debug -destination 'generic/platform=iOS' build`
- Observed error:
  - `Unable to find a destination matching the provided destination specifier`
  - `iOS 26.4 is not installed. Please download and install the platform from Xcode > Settings > Components.`
- Attempted local remediation:
  - `xcodebuild -downloadPlatform iOS` started downloading `iOS 26.4 Simulator (23E244) (arm64)` and logged progress to `.agent/tasks/2026-03-web-final-acceptance/raw/xcode-download-ios-platform.log`
- Why this is external:
  - the missing platform/component lives in the local Xcode installation rather than in the repo
  - repo code cannot make the machine eligible for host-project destinations without the host completing the Xcode component install
- Repo-side normalization completed before hitting the blocker:
  - `Makefile` no longer hardcodes a stale package path
  - SwiftData compile guards no longer over-assume macro availability
  - `swift-testing` is declared in `Package.swift`
  - `Package.swift` uses a manifest argument order accepted by current SwiftPM/Xcode
- Validation that now passes on this machine:
  - `make fmt`
  - `make lint`
  - `make typecheck`
  - `make test`
  - `cd web && npm install && npm run typecheck && npm run test && npm run build`
