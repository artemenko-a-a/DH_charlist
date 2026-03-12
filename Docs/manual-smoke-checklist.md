# Manual Smoke Checklist (iOS/iPadOS)

This checklist tracks the currently accepted runtime-polished implementation through Batch 34.

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
   - use `Add Weapon` and search the local compendium by name
   - pick a matching weapon and verify key fields are prefilled in the editor
   - save it and verify the weapon appears in the character equipment list
   - re-open that weapon, manually edit at least one field, save, and verify the edited values persist
   - open `Add Weapon` again, pick the same compendium entry, and verify the source definition still prefills its original values rather than the edited character copy
   - add/edit/delete one fully manual weapon entry
   - add/edit/delete one armour entry
   - edit movement values
   - add/edit/delete one inventory item
   - verify quick-add menu is available
   - verify in-screen search filters weapons/armour/inventory and filtered delete targets the correct row
   - verify persistence after navigation/re-open
11. Open `Session Mode` from character detail and treat it as the combat workspace:
    - toggle session mode
    - adjust current wounds / fatigue / current fate and verify the values update immediately
    - if at least one weapon exists, change the active weapon and verify the selected weapon summary updates
    - open quick mechanics from the workspace and verify the helper opens with a combat-relevant shortcut
    - add/edit/delete a combat condition note
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
    - import a valid JSON payload and verify the pre-confirmation step explicitly states:
      - how many characters were detected in the payload
      - the operation is replace-all, not merge
      - characters missing from the imported file will be removed
      - the action is destructive
    - cancel the import and verify current local characters remain unchanged
    - repeat with a valid JSON payload, confirm the destructive import, and verify the visible list refreshes to the imported state
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
    - verify status chips (bonuses, AP, XP available, temporary modifiers) remain legible in the dark-first app appearance and at larger Dynamic Type sizes
    - verify row background styling does not reduce swipe/edit affordances and does not obscure list separators/context
    - verify editor sheets (equipment/session) retain clear data-entry readability with themed background/chrome
20. Batch 21 deep polish sanity (coherence pass):
    - verify major screens (`Characters`, character detail, `Profile`, `Skills`, `Notes`, `Equipment`, `Session`) use consistent section rhythm and row density without clipped interactions
    - verify helper/supporting text hierarchy is consistent and readable (section footers, summaries, empty rows) in the dark-first app appearance and at larger Dynamic Type
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
- Focused simulator runtime sanity now also passes for the combat workspace via `xcodebuild test -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testCombatWorkspaceActivePlayFlow`.
- Focused simulator runtime sanity now also passes for the weapon compendium add/edit/detach flow via `xcodebuild test -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testWeaponCompendiumAutocompleteAddsDetachedEditableCopy`.
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
25. Batch 30 combat workspace helpers:
    - create or edit a weapon in `Equipment`, then open `Session Mode` and verify it appears as an active-weapon choice
    - switch the active weapon and verify the workspace shows the selected weapon name plus live-play fields
    - adjust wounds / fatigue / fate from the workspace controls and verify the displayed values update without leaving the screen
    - add at least one combat condition and verify it persists after navigating away and back
    - verify pinned checks and temporary modifiers remain usable from the same workspace
    - verify quick mechanics shortcuts from the workspace reduce taps for a common combat check
26. Batch 32 persistence diagnostics:
    - from `Characters`, open `Import/Export` -> `Persistence Status`
    - on the default JSON path, verify:
      - `Requested Backend` is `JSON File`
      - `Active Backend` is `JSON File`
      - `Fallback Active` is `No`
    - if running a SwiftData-selected host/bootstrap path, verify:
      - `Requested Backend` is `SwiftData`
      - `Active Backend` is `SwiftData` when bootstrap succeeds
      - if bootstrap falls back, `Active Backend` is `JSON File`, `Fallback Active` is `Yes`, and a diagnostic note is visible
    - when fallback is active, verify the `Characters` screen shows a persistence notice instead of silently behaving as though SwiftData were active
27. Batch 34 visual consistency + dark-theme hardening:
    - verify the app now stays in a coherent dark-first appearance across `Characters`, character detail, `Profile`, `Characteristics & Resources`, `Skills`, `Notes`, `Equipment`, `Session`, `Templates`, `Campaign Log`, `Import/Export`, `Persistence Status`, and `Quick Check`
    - verify navigation bars, tab bar, search surfaces, sheets, and editor screens no longer introduce obvious bright/white theme-breaking chrome
    - verify multiline editors (`Description`, freeform notes, history body, combat condition, pinned check, weapon traits, specialisations) render on dark readable surfaces instead of bright default editor backgrounds
    - verify readout rows (overview values, quick mechanics breakdown, skill derived values) have clear label/value contrast and remain readable at larger Dynamic Type sizes
    - verify warning/status surfaces remain visually distinct without breaking the overall dark hierarchy (for example the persistence fallback notice)
    - if using `./scripts/run_ui_screenshots.sh`, review exported attachments as a companion artifact, not a replacement for manual visual acceptance
28. Batch 35 printable/shareable dossier:
    - open any character detail and tap `Dossier`
    - verify the dossier preview opens as a readable document-style sheet rather than a copy of the dark in-app chrome
    - verify the preview includes practical structured sections from current data (identity, characteristics/resources, session snapshot, and any populated skills/notes/equipment/history)
    - verify `Printable PDF` status becomes ready
    - tap `Share PDF` and verify the native share sheet opens
    - verify the share destinations include practical export options such as `Save to Files` and `Print` when available on the device/simulator context
    - close the dossier and verify normal character detail flow is unchanged
29. Batch 36 rules domain foundation:
    - repeat the Batch 29 quick-mechanics paths from `Characteristics & Resources`, `Skills`, and `Session Mode`
    - verify the helper still shows an explicit breakdown rather than only a final value:
      - check name
      - source characteristic or skill
      - base value
      - derived bonus
      - training contribution when relevant
      - applied modifier
      - final target
    - verify applying a preset modifier and a custom signed modifier still updates the final target without leaving the helper
    - verify the session entry path still opens the same helper surface and does not diverge from the characteristic/skill flows
    - this step is a regression pass for the new `Rules` foundation, not a claim that the app now has a full rules engine
30. Batch 37 modifier and condition normalization:
    - from `Characteristics & Resources`, open a characteristic quick check and apply a preset modifier; verify the final target still updates and the breakdown remains explicit
    - from `Skills`, open a skill quick check and apply a custom signed modifier; verify the final target updates without changing the accepted helper flow
    - from `Session Mode`, add at least one temporary modifier and one combat condition, then open `Open Builder`
    - verify the helper now shows session temporary modifiers as reusable actions and active combat conditions as explicit context
    - verify session temporary modifiers can still be applied from the helper without changing the accepted player-facing target behavior
    - verify combat conditions are visible/readable context only unless a numeric modifier is explicitly applied elsewhere
    - this step validates normalized mechanics inputs, not a full combat status engine or automatic condition rules
31. Batch 43 weapon compendium autocomplete:
    - open `Equipment` for an existing character and tap `Add Weapon`
    - in the `Weapon Compendium` section, search a known local entry such as `las`
    - verify autocomplete rows show readable key fields before selection
    - select a match and verify the editor prefills weapon fields
    - edit at least one prefilled value before saving and verify the saved row reflects the manual override
    - re-open `Add Weapon`, select the same compendium entry again, and verify the original source values are still offered
    - verify the existing saved weapon remains unchanged, proving the character-owned instance is detached from the source definition
32. Batch 44 local weapon compendium import:
    - open `Equipment` for an existing character and tap `Import Local Compendium`
    - choose a local JSON file matching `Docs/weapon-compendium-format.md`
    - verify the confirmation step explicitly states:
      - the imported catalog name
      - detected weapon count
      - the current local compendium will be replaced
      - the operation is replace-all, not merge
      - existing character-owned weapons stay detached and unchanged
      - the action is destructive
    - cancel once and verify the current autocomplete catalog remains unchanged
    - repeat, confirm the destructive replace, and verify imported definitions now appear in `Add Weapon` autocomplete
    - verify a previously saved character-owned weapon still shows its original manually edited values after the compendium replacement
33. Batch 46 local armour compendium import:
    - open `Equipment` for an existing character and tap `Import Local Armour Compendium`
    - choose a local JSON file matching `Docs/armour-compendium-format.md`
    - verify the confirmation step explicitly states:
      - the imported catalog name
      - detected armour definition count
      - the current local armour compendium will be replaced
      - the operation is replace-all, not merge
      - existing character-owned armour stays detached and unchanged
      - the action is destructive
    - cancel once and verify the current armour autocomplete catalog remains unchanged
    - repeat, confirm the destructive replace, and verify imported definitions now appear in `Add Armour` autocomplete
    - verify a previously saved character-owned armour entry still shows its original manually edited values after the compendium replacement
34. Batch 47 combat action shortcuts + encounter flow:
    - open `Session Mode` for an existing character with at least one weapon equipped
    - verify the workspace now exposes explicit shortcut buttons for `Attack`, `Dodge`, `Parry`, `Apply Damage`, and `Reload`
    - tap at least one quick modifier toggle and one quick condition toggle; verify each can be turned on and off without leaving the screen
    - launch `Attack`, confirm the active weapon is shown, apply a preset or custom modifier, enter a roll, and verify the check outcome is visible and uses the accepted explainable check path
    - if the attack hits, enter raw damage plus target mitigation inputs and verify the bounded damage readout appears before dismissing the sheet
    - launch `Apply Damage`, enter incoming raw damage, armour, and toughness context, then apply it; verify current wounds update in the workspace
    - launch `Dodge` and `Parry`, enter rolls, and verify the reaction sheets show bounded check outcomes without claiming full opposed-roll resolution
    - verify `Reload` and the quick toggles remain explicit convenience actions only; there should still be no initiative tracker, hit-location flow, or critical table automation
