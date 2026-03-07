# Manual Smoke Checklist (iOS/iPadOS)

Current checklist tracks the first character vertical slice only (not full MVP).

1. Launch app and confirm `Characters` + `Session` tabs open.
2. In `Characters`, create a new character.
3. Open character details and verify overview shows:
   - name
   - home world
   - background
   - role
   - updatedAt
4. Open `Edit Profile`, modify fields, return back, and verify values update.
5. Relaunch app and verify edited values persist.
6. Duplicate a character from swipe actions and verify second record appears.
7. Delete a character from swipe actions and verify it is removed.

Blocked in this container: simulator/UI runtime execution and SwiftData runtime validation.
