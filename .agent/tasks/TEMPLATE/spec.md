# Task Spec

## ID
TASK_ID

## Title
Short task title

## Goal
Опиши кратко, что должно получиться и зачем это нужно.

## User value
- Что станет проще, безопаснее или быстрее для пользователя
- Почему это стоит делать сейчас
- Какая проблема решается

## Context
- Какие уже существующие части приложения/архитектуры затрагиваются
- Какие batch-ы или решения до этого важны для понимания задачи
- Какие ограничения уже приняты в проекте

## In scope
- ...
- ...
- ...

## Out of scope
- ...
- ...
- ...

## Constraints
- Не менять persistence shape без явной необходимости
- Не ломать accepted runtime behavior
- Не тащить full engine / full rulebook / giant DSL / cloud sync / etc
- Сохранять bounded scope
- Сохранять explainability и local-first behavior
- Сохранять detached-copy semantics, если это релевантно

## User-facing surfaces touched
- Characters
- Profile
- Equipment
- Session / Combat workspace
- Progression
- Dossier / Share
- Import / Export
- Templates / History / Snapshots
- Other: ...

## Rules / data / trust impact
- Affects rules correctness: yes/no
- Affects progression correctness: yes/no
- Affects combat/session trust: yes/no
- Affects destructive data flow: yes/no
- Affects import/replace semantics: yes/no
- Affects persistence observability: yes/no

## Trust-critical risks
- Rules layer may produce plausible but wrong values
- Replace-all or compendium replacement may mutate existing saved data
- Detached-copy semantics may break
- Persistence backend may become ambiguous
- UI may hide or obstruct critical controls on compact devices
- Manual/share/file flows may appear available but fail in practice
- Other task-specific risks:
  - ...
  - ...

## Acceptance criteria
- AC1. ...
- AC2. ...
- AC3. ...
- AC4. ...

## Required validation
- `make fmt`
- `make lint`
- `make typecheck`
- `make test`
- `make ci`
- `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- `swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build`
- `bash ./scripts/run_xcode_coverage.sh`
- `bash ./scripts/check_coverage_policy.sh`
- Xcode `BuildProject`
- Focused host/UI tests:
  - ...
  - ...
- Screenshot/manual pass required: yes/no
- Real-device pass required: yes/no

## Manual acceptance required
- yes / no

If yes, list exactly what must be checked manually:
- iPhone pass:
  - ...
- iPad pass:
  - ...
- Files / Share integration:
  - ...
- Long-session / soak flow:
  - ...
- Compact-screen / dark-theme / layout:
  - ...

## Evidence expectations
The evidence bundle must include:
- exact commands actually executed
- focused runtime/host UI evidence
- rules/data safety evidence where relevant
- explicit unverified risks
- final recommendation: accepted / accepted_with_conditions / rejected

## Notes for implementer
- Keep scope bounded
- Prefer explicit structured models over ad hoc logic
- Do not claim real-device behavior unless it was actually verified
- If uncertain, bias toward transparent/manual/diagnostic behavior
