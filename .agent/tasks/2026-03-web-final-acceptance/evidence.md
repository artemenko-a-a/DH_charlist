# Evidence

## qa-verifier findings
- Web app exists and is runnable (`web/`).
- Web build/typecheck/test pass in this environment.
- Mandatory iOS/macOS checks cannot be executed here due missing required toolchain/runtime assumptions:
  - `make fmt` fails because `/bin/zsh` is unavailable in this environment.
  - `swift build` command in project docs references non-existent absolute path.
  - `xcodebuild` is unavailable on Linux.

## conclusion
Hard external blocker for full acceptance in this environment: required macOS/Xcode-based validation cannot be run here.
