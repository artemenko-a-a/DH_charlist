# Task Spec

## ID
repo-task-proof-loop

## Title
Initialize repo-local proof-loop workflow and project-scoped subagents

## Goal
Set up a durable repository-local workflow for `spec -> build -> evidence -> verify -> fix`, including reusable project-scoped subagent prompts and managed guidance documents.

## In scope
- Add project-scoped subagent definitions under `.agent/subagents/`.
- Add managed workflow guidance under `.agent/workflows/repo-task-proof-loop.md`.
- Refresh proof-loop documentation to point to managed workflow and confidence categories.
- Refresh task template naming (`evidence.md` spelling fix).

## Out of scope
- Application feature changes in `Sources/`.
- Runtime behavior or persistence logic changes.
- Real-device validation of app UX.

## Risk profile
- Affects process trust and verification discipline.
- Does not directly alter production runtime code.

## Acceptance criteria
- AC1: Subagent documents exist and define responsibilities for spec/build/evidence/verify/fix.
- AC2: Managed workflow guidance exists and encodes orchestration + truth rules.
- AC3: Documentation references the managed workflow.
- AC4: Task template includes correctly named `evidence.md` file.

## Required validation
- `test -f .agent/subagents/spec-agent.md`
- `test -f .agent/subagents/build-agent.md`
- `test -f .agent/subagents/evidence-agent.md`
- `test -f .agent/subagents/verify-agent.md`
- `test -f .agent/subagents/fix-agent.md`
- `test -f .agent/workflows/repo-task-proof-loop.md`
- `test -f .agent/tasks/TEMPLATE/evidence.md`
- `git diff --name-only`
