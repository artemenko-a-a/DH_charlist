# Task Spec

## ID
2026-03-web-editable-core

## Role pass
spec-agent

## Goal
Deliver the browser-editable core character-management flows required for day-to-day use while preserving local-first behavior and avoiding divergence from accepted iOS data semantics.

## In scope
- Character create/select/duplicate/delete flows.
- Editable profile, characteristics/resources, skills, notes/textual sections, movement, inventory, weapons, and armour.
- Robust empty states, save feedback, and recovery behavior for browser-local persistence.
- Shared update paths that keep all edits explicit and testable.

## Out of scope
- Full visual parity with SwiftUI styling.
- Multiplayer/cloud sync.
- Non-local export/publishing systems.

## Trust risks
- Silent persistence corruption from malformed browser data.
- Editing flows that mutate the wrong character or wrong item instance.
- Divergence from accepted field semantics for notes/equipment/resources.

## Acceptance criteria
- Users can perform the required character-management edits locally in the browser.
- Duplicate/delete behavior remains bounded and explicit.
- Equipment and notes edits preserve character-owned instance boundaries.
- Tests cover core edit persistence and malformed-startup recovery.
