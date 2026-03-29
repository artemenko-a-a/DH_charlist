# Task Spec

## ID
2026-03-web-foundation

## Role pass: spec-freezer

## Goal
Create a runnable web shell in-repo (React + TypeScript + Vite), establish local-first persistence baseline, and prove detached-copy/replace-all semantics can be represented in web presentation without touching iOS code.

## In scope
- Add `web/` app scaffold and runnable scripts.
- Implement core shell: list/create/select character.
- Implement bounded editable profile/resources fields.
- Implement bounded quick mechanics target display.
- Implement weapon/armour compendium detached-copy add flow.
- Implement replace-all compendium import confirmation path.
- Provide dossier preview JSON surface.
- Add docs for web strategy and roadmap.

## Out of scope
- Full parity with all iOS screens.
- Real-device validation.
- Xcode/macOS-only validation execution.

## Trust risks
- Divergence from iOS rules/progression semantics.
- Silent destructive import behavior.
- Detached-copy mutation bugs.

## Acceptance criteria
- Web app builds and runs with `npm run build`.
- Web unit smoke passes (`npm test`).
- iOS source tree remains unchanged.
- Evidence records unverified areas truthfully.
