# Manual Smoke Checklist (iOS/iPadOS)

1. Launch app and confirm `Characters` + `Session` tabs open.
2. Create a new character from list, open profile, edit basic fields.
3. Open characteristics screen and verify values persist after app relaunch.
4. Add/update skills with training levels and specialisations.
5. Add notes across talents/traits/mutations/disorders/psy/abilities.
6. Add weapon/armour/inventory entries and movement values.
7. Toggle session mode and set temporary modifiers.
8. Export to JSON, delete local data, import JSON back, verify same character state.
9. Try importing invalid schema JSON and verify graceful error.
10. Basic accessibility pass:
    - Dynamic Type scaling on key forms
    - VoiceOver focus order across tabs
    - Sufficient color contrast in default appearance
