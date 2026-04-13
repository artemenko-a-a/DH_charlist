# Task Spec

## ID
2026-04-safety-import-resource-normalization

## Title
Atomic roster import and resource-state normalization

## Goal
Убрать риск частично примененного destructive import и ввести базовые инварианты ресурсов, чтобы хранение персонажей оставалось консистентным и предсказуемым.

## User value
- Снижается риск потери/повреждения roster при replace-all import.
- Некорректные значения ресурсов (например отрицательные) больше не сохраняются.
- Критичный trust-сценарий становится надежнее без изменения UX-флоу.

## Context
- Изменяются `CharacterUseCases` и реализация `CharacterRepository`.
- Ранее import выполнялся через последовательные `save`/`delete`, что могло дать частично примененное состояние.
- Проект использует JSON и SwiftData backend, поведение должно остаться согласованным.

## In scope
- Добавить atomic-style API `replaceAll(with:)` в `CharacterRepository`.
- Перевести `CharacterUseCases.importCharacters` на `replaceAll`.
- Реализовать `replaceAll` для JSON и SwiftData repository.
- Добавить нормализацию `ResourceState` в `updateResources`.
- Добавить/обновить unit tests.

## Out of scope
- Изменение формата persistence schema.
- UI/навигационные изменения.
- Полная ревизия инвариантов всех domain-сущностей.

## Constraints
- Не менять persistence shape без явной необходимости.
- Не ломать accepted runtime behavior.
- Сохранять bounded scope.
- Сохранять local-first behavior.

## User-facing surfaces touched
- Import / Export
- Profile/Resources

## Rules / data / trust impact
- Affects rules correctness: no
- Affects progression correctness: no
- Affects combat/session trust: no
- Affects destructive data flow: yes
- Affects import/replace semantics: yes
- Affects persistence observability: no

## Trust-critical risks
- Replace-all path может стать неодинаковым между backend.
- Нормализация ресурсов может поменять ранее допустимые edge-значения.

## Acceptance criteria
- AC1. `importCharacters` использует единый `replaceAll` путь без пошаговых `save`/`delete`.
- AC2. JSON и SwiftData репозитории поддерживают `replaceAll(with:)`.
- AC3. `updateResources` не сохраняет отрицательные и внутренне противоречивые значения ресурсов.
- AC4. Unit tests подтверждают новый import-path и нормализацию ресурсов.

## Required validation
- `swift test`
- `swift build`

## Manual acceptance required
- no

## Evidence expectations
The evidence bundle must include:
- exact commands actually executed
- rules/data safety evidence where relevant
- explicit unverified risks
- final recommendation: accepted / accepted_with_conditions / rejected

## Notes for implementer
- Keep scope bounded.
- Do not claim real-device behavior unless it was actually verified.
