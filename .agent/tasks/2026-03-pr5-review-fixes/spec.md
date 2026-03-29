# Task Spec

## ID
2026-03-pr5-review-fixes

## Role pass: spec-freezer

## Goal
Address the unresolved PR #5 review threads that can crash the web app during startup or after malformed compendium imports, while preserving an in-app recovery path when no character is selected.

## In scope
- Guard persisted character loading against malformed JSON and invalid shapes.
- Validate weapon and armour compendium import payloads before state/storage updates.
- Keep character list and create controls visible when no character is selected.
- Add automated verification for the reviewed failure modes.
- Record evidence and confidence split for this review-fix pass.

## Out of scope
- Broader UI redesign of the web app.
- New gameplay rules or progression semantics.
- Real-device browser validation.
- GitHub thread replies or resolution actions.

## Trust risks
- Corrupted persisted data can block app startup.
- Malformed import payloads can poison state and crash follow-up renders.
- An empty persisted character list can strand the user without an in-app recovery path.

## Acceptance criteria
- Malformed character storage falls back safely instead of crashing initial render.
- Invalid compendium import payloads are rejected before local state/storage mutation.
- The Create action remains visible when the selected character is missing.
- Targeted automated tests cover the three review findings.
