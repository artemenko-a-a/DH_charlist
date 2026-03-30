# Problems

## Resolved during final acceptance

- Local machine blocker resolved:
  - the iOS 26.4 simulator/platform is now installed and `make ci` completes locally
- Repo issues resolved during re-verification:
  - SwiftData compile guards were refined so CLI SwiftPM stays green while Xcode-host builds still exercise SwiftData
  - `Character` `Codable` coverage was restored with a direct roundtrip regression test
  - the quick-mechanics host smoke test was hardened against control-type/visibility flake for the custom modifier input
  - the repository coverage baseline was refreshed from the latest truthful package-surface capture

No open acceptance blocker remains for the bounded scope validated in this run.
