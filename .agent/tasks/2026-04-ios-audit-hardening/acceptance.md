# Acceptance Checklist

## Functional correctness
- [ ] Core touched flows work as described in the spec
- [ ] Existing accepted flows remain intact
- [ ] No hidden destructive side effects introduced
- [ ] Out-of-scope areas were not silently expanded

## Rules / logic correctness
- [ ] Touched behavior remains explainable
- [ ] No accepted rules path was silently bypassed
- [ ] Regression tests cover the most failure-prone touched logic
- [ ] No new hidden state transitions were introduced

## Data safety
- [ ] Existing saved entities are not silently mutated
- [ ] Replace/delete semantics remain explicit where touched
- [ ] Persistence behavior remains truthful and observable where touched
- [ ] Cancel/safe paths remain available for destructive interactions

## Runtime confidence
- [ ] SwiftPM build/test baseline passed
- [ ] Host app build passed
- [ ] Relevant host/UI smoke passed
- [ ] Coverage script and policy gate passed

## UI / UX
- [ ] No obvious unreadable state introduced
- [ ] No obvious compact-screen blocker introduced
- [ ] No critical control is occluded or confusing on touched screens
- [ ] Simulator manual/screenshot review completed for touched flows

## Automation / quality gates
- [ ] `make fmt` passed
- [ ] `make lint` passed
- [ ] `make typecheck` passed
- [ ] `make test` passed
- [ ] `swift build --disable-sandbox --package-path . --build-path /tmp/dh_charlist-build` passed
- [ ] `swift test --disable-sandbox --package-path . --build-path /tmp/dh_charlist-build` passed
- [ ] `bash ./scripts/run_xcode_coverage.sh` passed
- [ ] `bash ./scripts/check_coverage_policy.sh` passed

## Documentation / truthfulness
- [ ] Audit findings are evidence-backed
- [ ] Evidence clearly distinguishes tested vs unverified behavior
- [ ] Residual risks are explicit
- [ ] Progress log updated if user-facing behavior materially changed

## Final decision
- [ ] Accepted
- [ ] Accepted with conditions
- [ ] Rejected

## Remaining conditions / follow-up
- Real-device validation remains separate unless executed later.
