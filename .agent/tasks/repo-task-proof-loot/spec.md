# Task Spec

## ID
repo-task-proof-loot

## Canonical note
Historical task id contains a typo (`loot`), but this bundle is the matching repo-local task for the web MVP planning scope and should be reused for continuity.

## Title
Web MVP foundation plan for Dark Heresy II character manager

## Goal
Зафиксировать и продолжить bounded task-proof план веб-версии на основе полного ТЗ, чтобы последующая реализация шла по фазам без divergence между iOS и web в trust-critical flows.

## In scope
- Freeze MVP scope из присланного ТЗ (core management, session/combat bounded flows, progression, compendium, import/export, dossier).
- Freeze explicit out-of-scope (cloud/live sync/full engine/OCR/account systems и т.д.).
- Подтвердить архитектурный принцип: web как новый presentation layer с shared/equivalent rules-contract.
- Уточнить следующий шаг для implementation phase (Web foundation vertical slice).

## Out of scope
- Реализация production web-кода в рамках этого planning checkpoint.
- Любые claims о parity/runtime/device readiness без фактической верификации.

## Constraints
- Явно разделять confidence: logic/runtime/UI/real-device.
- Never claim real-device behavior without device verification.
- Предпочитать explicit evidence (команды/артефакты) вместо narrative confidence.

## Acceptance criteria
- AC1. Существует matching task bundle и он переиспользован.
- AC2. Текущее состояние planning task честно отражено (accepted_with_conditions).
- AC3. Зафиксирован конкретный next step для перехода к реализации (Phase 1 web foundation).
- AC4. Нет ложных заявлений о runtime parity/device readiness.

## Required validation
- `test -f .agent/tasks/repo-task-proof-loot/spec.md`
- `test -f .agent/tasks/repo-task-proof-loot/acceptance.md`
- `test -f .agent/tasks/repo-task-proof-loot/evidence.md`
- `python3 -m json.tool .agent/tasks/repo-task-proof-loot/verdict.json`
