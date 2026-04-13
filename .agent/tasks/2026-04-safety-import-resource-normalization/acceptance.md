# Acceptance Checklist

## Functional correctness
- [x] Core feature works as described in spec
- [x] Existing accepted flows remain intact
- [x] No hidden destructive side effects introduced
- [x] Out-of-scope areas were not silently expanded

## Rules / logic correctness
- [x] Outputs are explainable where relevant
- [x] Structured breakdowns/results remain stable and meaningful
- [x] Golden/scenario tests updated where applicable
- [x] No new silent calculation path bypasses the accepted rules layer

## Data safety
- [x] Existing saved entities are not silently mutated
- [x] Replace semantics are explicit if applicable
- [x] Detached-copy behavior is preserved where relevant
- [x] Persistence path remains truthful / observable where relevant
- [x] Cancel path is safe for destructive flows

## Runtime confidence
- [x] Focused host/runtime sanity passed
- [x] Relevant smoke path remains green
- [x] No newly observed blocker in active-play/session flow
- [x] No newly observed blocker in progression/import/export flow

## UI / UX
- [x] No obvious unreadable state introduced
- [x] No obvious compact-screen blocker introduced
- [x] No critical control is occluded by floating/tab UI
- [ ] If visual sign-off is needed, screenshots/manual review completed

## Automation / quality gates
- [ ] `make fmt` passed
- [ ] `make lint` passed
- [ ] `make typecheck` passed
- [ ] `make test` passed
- [ ] `make ci` passed
- [ ] truthful coverage gate passed
- [ ] worktree clean after commit

## Documentation / truthfulness
- [ ] Progress log updated
- [ ] README updated if user/developer-facing behavior changed
- [ ] Roadmap updated if architecture direction changed
- [x] Evidence clearly distinguishes tested vs unverified behavior

## Final decision
- [ ] Accepted
- [x] Accepted with conditions
- [ ] Rejected

## Remaining conditions / follow-up
- Run full `make ci` and coverage gate in follow-up wave.
- Execute manual host/UI smoke pass if required before release branch merge.
