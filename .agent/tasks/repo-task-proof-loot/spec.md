# Task Spec

## ID
repo-task-proof-loot

## Title
Web MVP foundation plan for Dark Heresy II character manager

## Goal
Сформировать и зафиксировать bounded MVP-контур веб-версии как task-proof bundle перед реализацией, чтобы снизить риск divergence между iOS и web и сохранить доверие в rules/data-потоках.

## User value
- Пользователь получает понятный и проверяемый план перехода в web без потери trust-critical семантики.
- Риски destructive/import/persistence сценариев фиксируются до кодовых изменений.
- Команда получает явные acceptance gates для поэтапной доставки web vertical slices.

## Context
- Репозиторий уже содержит iOS/Swift foundation со слоями Domain/Application/Rules/Infrastructure/Presentation.
- Проект уже использует task-proof-loop подход и expects evidence-driven verification.
- Входное ТЗ задаёт high-scope web migration, но требует bounded MVP и local-first usage.

## In scope
- Зафиксировать scope MVP web-версии на основе присланного ТЗ.
- Зафиксировать архитектурные принципы: presentation-layer-first web, минимизация rule duplication, explicit policy/destructive semantics.
- Определить phased delivery (Этапы 1–6) и acceptance criteria для gate-переходов.
- Зафиксировать обязательные verification areas: rules correctness, detached-copy semantics, import safety, persistence confidence, dossier/export readiness.

## Out of scope
- Реализация web-кода (React/TS или иная конкретная реализация) в этом task-proof шаге.
- Изменение текущей iOS runtime логики.
- Cloud sync, multi-user, live sync с iOS, full combat engine, OCR/PDF parsing и прочие explicitly out-of-scope пункты из ТЗ.

## Constraints
- Freeze scope до начала implementation.
- Не расширять MVP за пределы перечисленных bounded модулей.
- Не заявлять real-device confidence без фактической проверки на устройствах.
- Явно различать logic/runtime/UI/real-device confidence.
- Предпочитать explicit evidence над narrative confidence.

## User-facing surfaces touched
- Characters list/detail/editing
- Session / Combat workspace
- Progression
- Compendium (weapon/armour)
- Import / Export
- Dossier / printable view

## Rules / data / trust impact
- Affects rules correctness: yes
- Affects progression correctness: yes
- Affects combat/session trust: yes
- Affects destructive data flow: yes
- Affects import/replace semantics: yes
- Affects persistence observability: yes

## Trust-critical risks
- Divergence между iOS rules outcomes и web parity implementation.
- Нечёткие replace semantics в import flows.
- Поломка detached-copy guarantees для weapon/armour instances.
- Неочевидность persistence backend и fallback-поведения.
- UI degradation на compact layouts в trust-critical controls.
- Неподтверждённый handoff readiness для реальных iPad/iPhone игровых сессий.

## Acceptance criteria
- AC1. MVP scope и out-of-scope зафиксированы и согласованы в task bundle.
- AC2. Архитектурные принципы и layered boundaries для web зафиксированы без скрытой business logic в UI.
- AC3. Validation matrix включает обязательные проверки trust-critical зон.
- AC4. Verdict отражает текущий статус как planning/foundation, без ложных claims о runtime/web parity.

## Required validation
- `git status --short`
- `find .agent/tasks -maxdepth 2 -mindepth 1 -type d | sort`
- `python3 -m json.tool .agent/tasks/repo-task-proof-loot/verdict.json`

## Manual acceptance required
- yes

If yes, list exactly what must be checked manually:
- iPhone pass:
  - Verify web layout readability and action accessibility in core session/combat/progression flows.
- iPad pass:
  - Verify primary usability target for list/detail/editing/workspace flows.
- Files / Share integration:
  - Verify import/export and dossier/share path with real destinations.
- Long-session / soak flow:
  - Verify no accidental data loss during prolonged editing/combat usage.
- Compact-screen / dark-theme / layout:
  - Verify no unreadable rows and no critical control occlusion.

## Evidence expectations
The evidence bundle must include:
- exact commands actually executed
- explicit statement of what is planned vs not verified
- final recommendation: accepted_with_conditions

## Notes for implementer
- Start implementation only after this scope baseline is accepted.
- Keep each implementation batch independently verifiable via task-proof-loop.
