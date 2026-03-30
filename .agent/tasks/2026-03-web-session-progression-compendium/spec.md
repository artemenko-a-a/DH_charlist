# Task Spec

## ID
2026-03-web-session-progression-compendium

## Role pass
spec-agent

## Goal
Finish the trust-critical web flows that depend on explicit rules behavior: session/combat helpers, bounded damage usability, XP validation/apply, detached-copy compendium flows, and safe replace-all imports.

## In scope
- Browser session/combat workspace with active weapon, temporary modifiers, pinned checks, and combat conditions.
- Bounded attack/reaction helpers and explainable damage breakdowns derived from accepted Swift semantics.
- XP validation/apply flow for characteristic advances, skill training advances, and talent unlocks with prerequisite checks.
- Weapon and armour compendium autocomplete/add/import flows with detached-copy guarantees and explicit replace-all confirmation.
- Browser dossier preview with printable/shareable output surface.

## Out of scope
- Full Dark Heresy II rules-engine completeness.
- Cloud compendium sync or merge UI.
- Claims of physical-device verification that were not executed.

## Trust risks
- Mechanics/progression drift from accepted Swift rules behavior.
- Existing character-owned equipment mutating after compendium replacement.
- Malformed import payloads being accepted silently.

## Acceptance criteria
- Session helpers expose explainable calculations rather than opaque totals.
- XP validation blocks invalid spends and applies valid spends with history updates.
- Compendium flows reject malformed imports, require replace-all confirmation, and keep character-owned copies detached.
- Tests lock detached-copy, import rejection, replace-all, progression, and bounded mechanics behavior.
