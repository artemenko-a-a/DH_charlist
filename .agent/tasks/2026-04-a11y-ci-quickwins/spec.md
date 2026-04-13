# Task Spec

## ID
2026-04-a11y-ci-quickwins

## Title
Accessibility and CI quick wins

## Goal
Устранить принудительный dark-mode барьер и закрыть web regression gap в основном CI.

## User value
- Пользовательские системные настройки темы больше не принудительно игнорируются.
- Web-ветка перестает быть "вне gate", что снижает риск сломанных PR.

## Context
- `CogitatorTheme` применял `.preferredColorScheme(.dark)` на уровне app chrome.
- Основной CI (`.github/workflows/ci.yml`) валидировал Swift/Xcode, но не `web`.

## In scope
- Удалить force dark-mode override.
- Добавить `web-validation` job в основной CI (install, typecheck, test, build).

## Out of scope
- Полный accessibility redesign.
- Рефакторинг web-приложения.

## Constraints
- Сохранять bounded scope.
- Не ломать существующие Swift CI задачи.

## User-facing surfaces touched
- Characters / app-wide chrome
- Infra / CI

## Rules / data / trust impact
- Affects rules correctness: no
- Affects progression correctness: no
- Affects combat/session trust: no
- Affects destructive data flow: no
- Affects import/replace semantics: no
- Affects persistence observability: no

## Trust-critical risks
- Theme behavior может визуально отличаться от прошлого baseline.
- Web job может падать из-за зависимостей среды GitHub runners.

## Acceptance criteria
- AC1. Приложение больше не форсирует dark color scheme глобально.
- AC2. Main CI включает web typecheck/test/build job.
- AC3. Swift package tests остаются зелеными после изменений.

## Required validation
- `swift test`

## Manual acceptance required
- no

## Evidence expectations
The evidence bundle must include:
- exact commands actually executed
- explicit unverified risks
- final recommendation: accepted / accepted_with_conditions / rejected

## Notes for implementer
- Keep scope bounded.
