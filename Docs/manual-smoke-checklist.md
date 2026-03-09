# Manual Smoke Checklist (iOS/iPadOS)

This checklist tracks the currently accepted runtime-polished implementation through Batch 29.

1. Launch app and confirm `Characters` + `Session` tabs open.
2. In `Characters`, create a new character and open detail.
3. Verify overview section displays name/home world/background/role/updated timestamp.
4. Open `Edit Profile`, edit fields, navigate back, and verify overview updates.
5. Re-open the same character and verify profile edits persisted.
6. Open `Characteristics & Resources`, edit several values, go back, re-open, and verify persistence and derived values:
   - characteristic bonuses reflect edited base values
   - `Experience Available` reflects total minus spent
7. In `Characters`, verify list search:
   - search by name
   - search by home world/background/role
   - verify zero-match state is clear and create/open/duplicate/delete still work with filtering active
8. Open `Skills`:
   - add a skill
   - edit the same skill (characteristic/training/specialisations)
   - delete a skill
   - verify in-screen search filters by name/specialisation/characteristic/training
   - verify filtered zero-match state is clear
   - verify `Target` updates with edited characteristic/training
9. Open `Notes`:
   - add/edit/delete one list entry in at least one notes section
   - verify quick-add menu is available
   - verify in-screen search filters list sections and filtered edit/delete still target the correct entry
   - edit freeform notes
   - verify values persist after back navigation and re-open
10. Open `Equipment`:
   - add/edit/delete one weapon
   - add/edit/delete one armour entry
   - edit movement values
   - add/edit/delete one inventory item
   - verify quick-add menu is available
   - verify in-screen search filters weapons/armour/inventory and filtered delete targets the correct row
   - verify persistence after navigation/re-open
11. Open `Session Mode` from character detail:
    - toggle session mode
    - add/edit/delete a pinned check
    - add/edit/delete a temporary modifier
    - verify persistence after navigation/re-open
12. Back on character list, duplicate a character and verify:
    - duplicated record appears
    - original character remains unchanged
13. Delete a character from swipe actions and verify a destructive confirmation appears before removal.
14. Confirm delete and verify the character is removed.
15. Import/Export flow:
    - export JSON from toolbar menu
    - import a valid JSON payload
    - verify visible list refreshes to imported state
    - import an invalid payload and verify error alert is shown
    - import a valid payload immediately after a failed import and verify stale error alert is cleared
16. Accessibility sanity:
    - with VoiceOver enabled, verify key controls/rows announce meaningful labels
    - verify row summaries read useful values (not fragmented decorative text)
    - from a removed/deleted character detail route, verify `Character Not Found` screen provides a clear way back (`Back to Characters`)
17. Dynamic Type sanity:
    - run with larger text sizes and verify major forms/screens remain usable for data entry and navigation.
18. iPad sanity:
    - run the same major flows on an iPad-size simulator/device and verify forms/lists are centered with readable width
    - verify editor sheets (skills/notes/equipment/session) support cancel/save and feel stable on larger width
    - verify long row values wrap rather than clipping on notes/equipment/session rows
19. Batch 20 visual theme sanity (Adeptus Mechanicus-inspired foundation):
    - verify high-visibility screens (`Character` detail overview, `Characteristics & Resources`, `Equipment`, `Session Mode`) use the same palette and panel styling
    - verify section headers are readable and consistent (technical/dossier tone without obscuring plain language)
    - verify status chips (bonuses, AP, XP available, temporary modifiers) remain legible in Light/Dark appearance and at larger Dynamic Type sizes
    - verify row background styling does not reduce swipe/edit affordances and does not obscure list separators/context
    - verify editor sheets (equipment/session) retain clear data-entry readability with themed background/chrome
20. Batch 21 deep polish sanity (coherence pass):
    - verify major screens (`Characters`, character detail, `Profile`, `Skills`, `Notes`, `Equipment`, `Session`) use consistent section rhythm and row density without clipped interactions
    - verify helper/supporting text hierarchy is consistent and readable (section footers, summaries, empty rows) in Light/Dark and larger Dynamic Type
    - verify existing editor sheets keep consistent Cancel/Save placement and that Save remains clearly primary when valid
    - verify `Session` screen operational state readability (`ACTIVE`/`STANDBY`) and pinned/modifier editing clarity without behavior change
    - verify iPad layout uses wider readable content width without creating narrow content islands or excessive line length
21. Batch 22 template quick-start sanity:
    - from `Characters`, open `Create` and verify quick-start supports:
      - `Blank Character`
      - at least one saved template (after creating one)
    - open any existing character detail and trigger `Save as Template`
    - open `Templates` manager from the character list toolbar and verify:
      - template list/preview text is visible
      - rename persists after closing/reopening manager
      - duplicate creates a second template with distinct identity
      - delete removes template after confirmation
    - create a new character from a template and verify:
      - a new character record is created
      - profile/skills/notes/equipment/session defaults from template are copied
      - editing the new character does not mutate the source template or original character
22. Batch 23 campaign log/history sanity:
    - open a character and navigate to `Campaign Log & History`
    - add at least one history entry and verify it appears at the top (reverse chronological order)
    - edit that entry and verify updated title/body/tags persist after closing/reopening the screen
    - delete an entry and verify confirmation + removal
    - verify search (title/body/tags) and entry-type filter both narrow results correctly
    - from character detail, use `Quick Add Session Note` and verify a new entry appears in history
    - duplicate a character and verify duplicate starts with empty history while original history remains intact
    - create a character from a template and verify created character history starts empty

Latest local validation status (2026-03-09):
- Host app compiles successfully in Xcode (`BuildProject`).
- SwiftPM regression/build validation passes (`swift test`, `swift build`).
- Focused simulator runtime sanity now passes for quick mechanics via `xcodebuild test -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testQuickMechanicsHelpersAcrossCharacteristicSkillAndSessionFlows`.
- Canonical smoke automation also passes via `./scripts/run_ui_smoke.sh`.
- Continue to record manual runtime execution per run (pass/fail + notes), especially for visual/ergonomic review.

23. Batch 24 UI automation companion (not a replacement for manual acceptance):
    - run canonical UI smoke suite: `./scripts/run_ui_smoke.sh`
    - run canonical screenshot capture/export: `./scripts/run_ui_screenshots.sh`
    - launch hooks used by automation:
      - `-dh-uitesting`
      - `-dh-ui-reset-data`
      - `-dh-ui-seed-smoke`
      - `-dh-ui-persistence-json` or `-dh-ui-persistence-swiftdata`
    - expected screenshot export location: `DHCharListHost/artifacts/ui-screenshots/<timestamp>/attachments`
    - continue to perform final visual/manual review using this checklist; automated screenshots are only a fast regression aid.
24. Batch 29 quick mechanics helpers:
    - open `Characteristics & Resources`, tap a characteristic quick-check scope button, and verify the helper opens with the selected characteristic source
    - apply at least one preset modifier and verify the breakdown/final target updates transparently
    - apply a custom signed modifier (for example `-10`) and verify the final target updates again
    - open `Skills`, create or select a skill, open its quick check, and verify training contribution plus final target are shown
    - open `Session Mode`, tap `Open Quick Mechanics`, and verify the helper opens from the session-oriented flow
    - if temporary session modifiers exist, verify they appear as reusable helper shortcuts
    - on compact sheet sizes, scroll within the helper if needed to reach the breakdown and final target rows
