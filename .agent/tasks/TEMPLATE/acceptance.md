# Acceptance Checklist

## Functional correctness
- [ ] Core feature works as described in spec
- [ ] Existing accepted flows remain intact
- [ ] No hidden destructive side effects introduced
- [ ] Out-of-scope areas were not silently expanded

## Rules / logic correctness
- [ ] Outputs are explainable where relevant
- [ ] Structured breakdowns/results remain stable and meaningful
- [ ] Golden/scenario tests updated where applicable
- [ ] No new silent calculation path bypasses the accepted rules layer

## Data safety
- [ ] Existing saved entities are not silently mutated
- [ ] Replace semantics are explicit if applicable
- [ ] Detached-copy behavior is preserved where relevant
- [ ] Persistence path remains truthful / observable where relevant
- [ ] Cancel path is safe for destructive flows

## Runtime confidence
- [ ] Focused host/runtime sanity passed
- [ ] Relevant smoke path remains green
- [ ] No newly observed blocker in active-play/session flow
- [ ] No newly observed blocker in progression/import/export flow

## UI / UX
- [ ] No obvious unreadable state introduced
- [ ] No obvious compact-screen blocker introduced
- [ ] No critical control is occluded by floating/tab UI
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
- [ ] Evidence clearly distinguishes tested vs unverified behavior

## Final decision
- [ ] Accepted
- [ ] Accepted with conditions
- [ ] Rejected

## Remaining conditions / follow-up
- ...
- ...
- ...
