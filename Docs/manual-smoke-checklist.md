# Manual Smoke Checklist (iOS/iPadOS)

This checklist tracks the currently accepted runtime-polished implementation through Batch 15.

1. Launch app and confirm `Characters` + `Session` tabs open.
2. In `Characters`, create a new character and open detail.
3. Verify overview section displays name/home world/background/role/updated timestamp.
4. Open `Edit Profile`, edit fields, navigate back, and verify overview updates.
5. Re-open the same character and verify profile edits persisted.
6. Open `Characteristics & Resources`, edit several values, go back, re-open, and verify persistence and derived values:
   - characteristic bonuses reflect edited base values
   - `Experience Available` reflects total minus spent
7. Open `Skills`:
   - add a skill
   - edit the same skill (characteristic/training/specialisations)
   - delete a skill
   - verify `Target` updates with edited characteristic/training
8. Open `Notes`:
   - add/edit/delete one list entry in at least one notes section
   - edit freeform notes
   - verify values persist after back navigation and re-open
9. Open `Equipment`:
   - add/edit/delete one weapon
   - add/edit/delete one armour entry
   - edit movement values
   - add/edit/delete one inventory item
   - verify persistence after navigation/re-open
10. Open `Session Mode` from character detail:
    - toggle session mode
    - add/edit/delete a pinned check
    - add/edit/delete a temporary modifier
    - verify persistence after navigation/re-open
11. Back on character list, duplicate a character and verify:
    - duplicated record appears
    - original character remains unchanged
12. Delete a character from swipe actions and verify a destructive confirmation appears before removal.
13. Confirm delete and verify the character is removed.
14. Import/Export flow:
    - export JSON from toolbar menu
    - import a valid JSON payload
    - verify visible list refreshes to imported state
    - import an invalid payload and verify error alert is shown
    - import a valid payload immediately after a failed import and verify stale error alert is cleared
15. Accessibility sanity:
    - with VoiceOver enabled, verify key controls/rows announce meaningful labels
    - verify row summaries read useful values (not fragmented decorative text)
    - from a removed/deleted character detail route, verify `Character Not Found` screen provides a clear way back (`Back to Characters`)
16. Dynamic Type sanity:
    - run with larger text sizes and verify major forms/screens remain usable for data entry and navigation.
17. iPad sanity:
    - run the same major flows on an iPad-size simulator/device and verify forms/lists are centered with readable width
    - verify editor sheets (skills/notes/equipment/session) support cancel/save and feel stable on larger width
    - verify long row values wrap rather than clipping on notes/equipment/session rows

Latest local validation status (2026-03-07):
- Host app compiles successfully in Xcode (`BuildProject`).
- SwiftPM regression/build validation passes (`swift test`, `swift build`).
- Simulator interaction could not be executed in this environment because `CoreSimulatorService` was unavailable; manual runtime execution should be recorded per run (pass/fail + notes).
