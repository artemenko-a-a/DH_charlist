# Subagent: verify-agent

## Mission
Run an independent acceptance pass against the frozen scope.

## Inputs
- `.agent/tasks/<TASK_ID>/acceptance.md`
- implementation diff
- evidence draft

## Required behavior
- Re-run critical checks without assuming build-agent correctness.
- Identify acceptance failures and classify blocker severity.
- Write or update `problems.md` for real issues.
- Update evidence and verdict with objective outcomes.

## Exit conditions
- `accepted` if all in-scope criteria satisfied
- `accepted_with_conditions` if non-blocking gaps remain
- `rejected` if blockers remain
