# Evidence

## spec-agent
- Editable core scope frozen around character lifecycle plus profile/resources/skills/notes/equipment editing.

## build-agent
- Implemented create/select/duplicate/delete plus editable profile, characteristics/resources, skills, notes, movement, inventory, weapons, and armour in [`/Users/andrey_artemenko/repos/DH_charlist/web/src/components/App.tsx`](/Users/andrey_artemenko/repos/DH_charlist/web/src/components/App.tsx).
- Added guarded persistence/migration logic in [`/Users/andrey_artemenko/repos/DH_charlist/web/src/lib/storage.ts`](/Users/andrey_artemenko/repos/DH_charlist/web/src/lib/storage.ts).

## verify-agent
- `npm run test` covers malformed storage recovery and UI smoke around character creation and equipment flows.

## Confidence
- logic confidence: medium-high
- runtime confidence: high on the validated web toolchain
- UI confidence: medium
- real-device confidence: none
