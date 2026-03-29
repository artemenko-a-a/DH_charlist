# Acceptance Checklist

## Functional correctness
- [x] Task-proof bundle initialized for the requested repo-local task id.
- [x] Scope and out-of-scope explicitly documented from provided ТЗ.
- [x] No implementation scope silently added.

## Rules / logic correctness
- [x] Trust-critical rule-risk areas explicitly listed.
- [x] No claims of implemented/parity-verified rules behavior.

## Data safety
- [x] Destructive import/replace semantics called out as critical validation area.
- [x] Detached-copy guarantees called out as critical validation area.
- [x] Persistence observability/fallback transparency called out as critical validation area.

## Runtime confidence
- [x] Marked as planning-only artifact, not runtime-verified implementation.
- [x] Runtime confidence intentionally limited pending implementation + tests.

## UI / UX
- [x] iPad/desktop primary and iPhone support expectations captured.
- [x] Compact-screen/dark-theme readability checks captured as manual acceptance items.

## Automation / quality gates
- [x] Basic repo checks run for task existence and verdict JSON validity.
- [x] Worktree will be committed with only task-proof initialization artifacts.

## Documentation / truthfulness
- [x] Evidence clearly separates performed checks from unverified runtime/device behavior.
- [x] Verdict status reflects acceptance with conditions rather than full acceptance.

## Final decision
- [ ] Accepted
- [x] Accepted with conditions
- [ ] Rejected

## Remaining conditions / follow-up
- Run implementation batches for web MVP per phased plan.
- Execute full automated validation for each batch (build/test/lint/coverage/targeted smoke).
- Execute real-device iPhone/iPad manual acceptance before claiming handoff readiness.
