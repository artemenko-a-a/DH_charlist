# Task Spec

## ID
2026-04-dhii-engine

## Title
DHII Engine architecture freeze and Task 01 home-world foundation

## Goal
Зафиксировать целевую архитектуру полноценного DHII Engine для `DH_charlist` и сразу реализовать первый безопасный вертикальный срез: typed home-world creation foundation с каноническим источником правил, compatibility diagnostics и read-only интеграцией в текущий профиль.

## User value
- Пользователь получает первый rulebook-backed creation surface вместо полностью свободного текстового поля без доменной опоры.
- Команда получает согласованную архитектуру и последовательный roadmap, а не хаотичное наращивание UI.
- Риск ложных или неполных стартовых правил снижается за счёт явного catalog/preview и честной индикации текущих доменных пробелов.

## Context
- Текущая кодовая база уже имеет bounded `Rules` слой для quick checks, progression и damage foundation, но не имеет полноценного character-creation engine.
- `Character` остаётся snapshot-first aggregate с freeform `profile.homeWorld/background/role` и без first-class `Influence`.
- В проекте уже есть стратегический `Docs/rules-engine-roadmap.md`; новая работа должна расширять этот путь, а не заменять его.
- Локальный proof-loop контракт задаётся `AGENTS.md`, `Docs/task-proof-loop.md`, `.agent/tasks/TEMPLATE/*`.

## In scope
- Current-state assessment и target DHII Engine architecture в repo docs.
- Подробный phased roadmap и task decomposition для дальнейшей реализации движка.
- Task 01: канонический typed registry для всех шести DHII home worlds на основе core rulebook.
- Explainable home-world preview и compatibility diagnostics для текущей snapshot-модели.
- Read-only integration в `ProfileScreen` без изменения persistence shape.
- Unit/regression tests на новый foundation slice.

## Out of scope
- Полный character creation pipeline.
- Автоматическое применение background/role packages.
- Полная миграция persistence shape под rich engine state.
- Web parity для нового creation foundation.
- Real-device validation.

## Constraints
- Не менять persistence shape без явной необходимости.
- Не ломать accepted runtime behavior.
- Не тащить full engine / full rulebook digitization / giant DSL.
- Сохранять bounded scope и explainability.
- Явно отделять подтверждённые rulebook-факты от будущих phases.

## User-facing surfaces touched
- Profile
- Rules / creation foundation
- Other: roadmap / proof artifacts

## Rules / data / trust impact
- Affects rules correctness: yes
- Affects progression correctness: no
- Affects combat/session trust: no
- Affects destructive data flow: no
- Affects import/replace semantics: no
- Affects persistence observability: no

## Trust-critical risks
- Home-world facts can look authoritative while current app still lacks full creation pipeline.
- Current saved character snapshot cannot yet represent `Influence` as a first-class DHII creation field.
- UI could over-promise automation if the preview is not clearly marked informational.
- Future phases could diverge if the roadmap is not frozen before additional implementation.

## Acceptance criteria
- AC1. Repo docs record the current-state assessment, target DHII Engine architecture, phased roadmap, and ordered task decomposition.
- AC2. The rules layer exposes a canonical typed home-world catalog for all six DHII core home worlds with rulebook-backed modifiers, fate threshold, aptitude, wounds, bonus, and recommended backgrounds.
- AC3. The engine exposes a deterministic preview/compatibility API that can recognize canonical home worlds from current freeform profile text and explicitly flag unsupported current-model fields such as `Influence`.
- AC4. The existing profile flow surfaces the recognized home-world preview in read-only form without changing saved data semantics.
- AC5. Targeted tests and broader regression gates pass, and no previously supported flow regresses.

## Required validation
- `make fmt`
- `make lint`
- `make typecheck`
- `make test`
- `make ci`
- `swift test`
- `swift build`
- `cd web && npm test`
- `cd web && npm run typecheck`
- `cd web && npm run build`
- Screenshot/manual pass required: no
- Real-device pass required: no

## Manual acceptance required
- no

## Evidence expectations
The evidence bundle must include:
- exact commands actually executed
- focused rules/data evidence for the home-world foundation
- explicit separation between tested behavior and future phases
- confidence split across logic, runtime, UI, and real-device categories
- final recommendation: accepted / accepted_with_conditions / rejected

## Notes for implementer
- Keep Task 01 limited to home-world foundation plus documentation.
- Prefer typed domain structures over raw strings in the new rules layer.
- Treat the read-only preview as an integration seam, not as the full creation UI.
- Be explicit that `Influence` remains a known model gap.
