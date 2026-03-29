# Problems

## External machine blocker: Xcode license not accepted

- Observed command failures:
  - `make typecheck`
  - `make test`
  - `swift test --disable-sandbox --package-path /Users/andrey_artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build-direct-test-2`
- Observed error:
  - `You have not agreed to the Xcode license agreements. Please run 'sudo xcodebuild -license'...`
- Why this is external:
  - accepting the license requires privileged local-machine access (`sudo`)
  - the repo cannot self-remediate it without host credentials
- Repo-side normalization completed before hitting the blocker:
  - `Makefile` no longer hardcodes a stale package path
  - SwiftData compile guards no longer over-assume macro availability
  - `swift-testing` is declared in `Package.swift`
