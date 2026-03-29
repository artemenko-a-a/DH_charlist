# Task Spec

## ID
2026-03-web-readonly-vertical-slice

## Role pass
spec-agent

## Goal
Establish a browser-usable read-focused character detail experience that mirrors the accepted iOS information architecture closely enough to support safe viewing and navigation before deeper editing and rules actions.

## In scope
- Expand web character contracts to cover profile, characteristics, resources, skills, notes, equipment, session, and history.
- Render a stable character list and selected-character workspace with clear section navigation.
- Show read-only summaries for skills, notes, equipment, session state, progression/history, and dossier structure.
- Keep empty states and malformed-storage recovery explicit and safe.
- Align displayed terminology with current iOS/domain semantics.

## Out of scope
- Editing beyond what is needed to keep the shell coherent.
- Final session/progression application flows.
- Real browser/device cross-platform sign-off.

## Trust risks
- Read-only web models drifting from the accepted Swift contracts.
- Hidden load failures when persisted browser data is malformed.
- Misleading summaries in dossier/session panels.

## Acceptance criteria
- The web app loads from browser-local state without crashing on malformed persisted data.
- A user can create/select a character and browse all major data sections in one usable workspace.
- Read-only dossier/session summaries reflect the same conceptual structure as the iOS app.
- Evidence and verdict files distinguish model confidence from runtime/UI/device confidence.
