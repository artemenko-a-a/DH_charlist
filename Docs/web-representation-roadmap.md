# Web Representation Roadmap

## Current stage status
1. Web foundation: complete
2. Read-only vertical slice: complete
3. Editable core: complete
4. Session/progression/compendium parity: complete for the bounded accepted scope
5. Final acceptance: web + Swift package validation complete; host-project Xcode validation blocked on missing local iOS 26.4 platform install

## Remaining follow-up after this run
- Install the local iOS 26.4 platform/component in Xcode and rerun `make ci`
- Rerun `bash ./scripts/run_xcode_coverage.sh` and `bash ./scripts/check_coverage_policy.sh` after the platform install completes
- Run manual browser sanity on real iPhone/iPad Safari if device confidence is required for release sign-off
- Consider broader visual/browser coverage if desktop/mobile browser matrix support becomes a release requirement
