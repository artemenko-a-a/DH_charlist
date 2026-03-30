# Web Version Spec

## Delivered stack
- React + TypeScript + Vite in `web/`
- Browser-local persistence with guarded load/migration logic
- Shared TypeScript compatibility layer for character contracts, mechanics helpers, bounded damage, XP progression, compendium parsing, and dossier composition

## Supported web flows
- Character roster: create, select, duplicate, delete
- Profile editing: name, home world, background, role, aptitudes, description
- Characteristics/resources editing with explainable quick-check helpers
- Skills editing with training-aware target summaries
- Notes/text sections editing for talents, traits, mutations, disorders, psychic powers, special abilities, and freeform notes
- Equipment editing for weapons, armour, movement, and inventory
- Weapon and armour compendium autocomplete/add flows with detached-copy semantics
- Replace-all compendium import preview and confirmation with malformed-payload rejection
- Session workspace with active weapon, temporary modifiers, pinned checks, combat conditions, bounded attack/reaction helpers, and bounded damage helper
- XP validation/apply flow for characteristic advances, skill advances, and talent unlocks with explicit prerequisites
- Browser dossier preview with print/share via `window.print()`

## Verified web evidence
- `npm run typecheck`
- `npm run test`
- `npm run build`
- Raw logs stored under `.agent/tasks/2026-03-web-final-acceptance/raw`

## Safety boundaries
- Malformed browser-local character or compendium state falls back to safe defaults with recovery warnings
- Malformed compendium imports are rejected before replace-all confirmation
- Character-owned weapon and armour entries are detached copies and are not mutated by later compendium replacement
- Session/progression helpers are intentionally bounded and explainable; they do not claim full Dark Heresy II rules coverage

## Current limitations
- Real browser/device validation was not executed in this run
- The web app remains a bounded representation layer rather than a full iOS/rules-engine parity target
