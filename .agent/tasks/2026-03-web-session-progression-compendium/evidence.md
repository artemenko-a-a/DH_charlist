# Evidence

## spec-agent
- Trust-critical scope frozen around session helpers, bounded damage, XP validation/apply, and compendium detached-copy/replace-all behavior.

## build-agent
- Added bounded mechanics, combat shortcuts, damage resolution, XP progression, compendium import parsing, and dossier composition in [`/Users/andrey_artemenko/repos/DH_charlist/web/src/lib/domain.ts`](/Users/andrey_artemenko/repos/DH_charlist/web/src/lib/domain.ts).
- Wired those helpers into the browser UI in [`/Users/andrey_artemenko/repos/DH_charlist/web/src/components/App.tsx`](/Users/andrey_artemenko/repos/DH_charlist/web/src/components/App.tsx).

## verify-agent
- Logic tests in [`/Users/andrey_artemenko/repos/DH_charlist/web/src/lib/domain.test.ts`](/Users/andrey_artemenko/repos/DH_charlist/web/src/lib/domain.test.ts) cover:
  - detached-copy semantics
  - malformed import rejection
  - bounded mechanics behavior
  - XP validation/apply
  - dossier and damage helpers
- UI smoke in [`/Users/andrey_artemenko/repos/DH_charlist/web/src/components/App.test.tsx`](/Users/andrey_artemenko/repos/DH_charlist/web/src/components/App.test.tsx) covers:
  - character creation
  - replace-all preview/confirm
  - malformed import rejection before confirmation

## Confidence
- logic confidence: high for the bounded implemented scope
- runtime confidence: high on the validated web toolchain
- UI confidence: medium
- real-device confidence: none
