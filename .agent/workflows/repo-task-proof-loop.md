# Managed Workflow: repo-task-proof-loop

This managed workflow initializes and runs the repo-local proof loop for trust-sensitive tasks.

## Trigger
Use this workflow when a task affects any of:
- rules correctness
- destructive data flow
- persistence behavior
- session-time user trust
- device/user handoff readiness

## Setup
1. Choose `TASK_ID` (kebab-case, stable).
2. Create `.agent/tasks/<TASK_ID>/`.
3. Create at minimum:
   - `spec.md`
   - `acceptance.md`
   - `evidence.md`
   - `verdict.json`
4. Add `problems.md` only when verification finds real issues.

## Orchestration sequence
1. **spec-agent**
   - freeze scope and explicit out-of-scope
   - define acceptance and confidence categories
2. **build-agent**
   - implement bounded scope
3. **evidence-agent**
   - record executed commands and observed outcomes
4. **verify-agent**
   - independent acceptance pass
5. **fix-agent** (if needed)
   - remediate verified issues
6. Repeat **verify -> fix** until verdict is stable.

## Confidence model (required)
Report four distinct confidence signals:
- **logic confidence**: rules/calculation correctness from tests and inspection
- **runtime confidence**: build/test/runtime execution quality in this environment
- **UI confidence**: visual/interaction behavior validated by screenshots/manual pass
- **real-device confidence**: physical-device verification only

## Truth discipline
- Never claim verification that was not executed.
- Keep assumptions and unverified risks explicit.
- Prefer links/paths to artifacts and command logs.
- Use `accepted_with_conditions` when evidence is strong but device/manual sign-off is pending.

## Recommended repo conventions
- Store raw command logs in `.agent/tasks/<TASK_ID>/raw/`.
- Keep `verdict.json` machine-readable and concise.
- If a historical task id was misspelled, create a corrected task id for future work rather than reusing the typo.
