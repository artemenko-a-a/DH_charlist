# Problems Found During Task

## Resolved

### P1. Web bootstrap/recovery fabricated pseudo-canonical DH2 characters
- Severity: High
- Area: web domain defaults and storage recovery
- Symptom:
  - new and sparsely recovered characters were silently given plausible-but-arbitrary stats, resources, aptitude, movement, and a starting skill
- Risk:
  - user trust erosion
  - masked storage-loss scenarios
  - apparently valid characters that were not rule-derived
- Resolution:
  - replaced fabricated defaults with explicit blank/manual state
  - added regression tests for new-character defaults and sparse recovery

### P2. Skill training ranks were rules-incorrect
- Severity: High
- Area: shared rules model, quick mechanics, XP progression, web mirror
- Symptom:
  - `Experienced` rank was missing
  - `Veteran` granted only `+20` instead of `+30`
- Risk:
  - incorrect skill targets
  - incorrect progression semantics
  - cross-surface rules mismatch
- Resolution:
  - added `experienced`
  - corrected modifiers and progression ordering
  - updated Swift and web regression suites

## Verification-discovered regressions fixed during task

### V1. Old tests still encoded veteran `+20`
- Severity: Low
- Resolution:
  - updated expected derived target from `62` to `72`

### V2. One web XP test implicitly depended on fabricated `30` baseline stats
- Severity: Low
- Resolution:
  - set the required baseline characteristic explicitly inside the test
