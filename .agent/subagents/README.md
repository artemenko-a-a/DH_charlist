# Project Subagents

These repo-local subagents operationalize the task-proof-loop philosophy.

## Available subagents

1. `spec-agent.md` — freezes scope and writes the task spec.
2. `build-agent.md` — implements only in-scope changes.
3. `evidence-agent.md` — captures executable evidence and confidence levels.
4. `verify-agent.md` — performs independent verification against acceptance.
5. `fix-agent.md` — resolves verification failures and updates proof artifacts.

## Canonical workflow

Use subagents in this strict sequence:

`spec -> build -> evidence -> verify -> fix (loop until acceptance)`

The orchestrator guidance is defined in:

- `.agent/workflows/repo-task-proof-loop.md`

## Task bundle destination

Create bundles under:

- `.agent/tasks/<TASK_ID>/`

Minimum required artifacts per task:

- `spec.md`
- `acceptance.md`
- `evidence.md`
- `verdict.json`

If verification finds real issues, add:

- `problems.md`
