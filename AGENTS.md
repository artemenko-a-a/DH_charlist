## Task Proof Loop

For high-risk or high-scope work, create a task bundle under:

`.agent/tasks/<TASK_ID>/`

Use this process when the task affects:
- rules correctness,
- destructive data flows,
- persistence behavior,
- session-time user trust,
- device/user handoff readiness.

Minimum required artifacts:
- `spec.md`
- `acceptance.md`
- `evidence.md`
- `verdict.json`

Rules:
- freeze scope before implementation
- keep out-of-scope explicit
- distinguish logic confidence, runtime confidence, UI confidence, and real-device confidence
- never claim real-device behavior unless actually verified
- if verification finds real issues, record them in `problems.md`
- prefer explicit evidence over narrative confidence
