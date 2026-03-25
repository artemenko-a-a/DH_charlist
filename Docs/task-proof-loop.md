# Task Proof Loop

## Purpose

This repo uses a lightweight proof-loop process for high-risk or high-scope tasks.

The purpose is to ensure that for important work we preserve:
- frozen scope before implementation,
- explicit acceptance criteria,
- repo-local evidence,
- independent verification,
- truthful final verdicts.

This is especially important for:
- rules correctness,
- destructive data flows,
- persistence behavior,
- compendium replacement,
- progression/combat trust,
- user/device handoff readiness.

## When to use

Use a task proof bundle when at least one of these is true:
- the task affects rules correctness,
- the task affects data safety,
- the task includes destructive or replace-all behavior,
- the task has meaningful scope-creep risk,
- the task needs independent verification,
- the task is part of final user/device handoff readiness.

Examples:
- progression/rules batches,
- import/replace logic,
- compendium flows,
- device handoff readiness,
- UI hardening with manual sign-off.

## Bundle structure

Each task bundle lives in:

`.agent/tasks/<TASK_ID>/`

Typical files:
- `spec.md`
- `acceptance.md`
- `evidence.md`
- `verdict.json`
- `problems.md`
- `raw/` for logs/artifacts

## Workflow

1. Freeze scope in `spec.md`
2. Define acceptance in `acceptance.md`
3. Implement within bounded scope
4. Collect raw logs and evidence
5. Perform fresh verification
6. Write `evidence.md`
7. Write `verdict.json`
8. Record problems in `problems.md` if needed

## Truth rules

- Never claim anything not actually tested.
- Separate executed checks from assumptions.
- Real-device behavior must not be claimed unless actually verified.
- Green CI is not a substitute for manual UX/device sign-off where required.
- Rules/data safety confidence and UI/device confidence must be reported separately.

## Recommended verdicts

- `accepted`
- `accepted_with_conditions`
- `rejected`

## Notes

This process is intentionally lightweight.
It is not required for every small change.
Use it when the cost of being wrong is higher than the cost of documenting proof.
