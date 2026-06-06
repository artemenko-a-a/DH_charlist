# 2026-06 Raibos iPad Deploy Spec

## Original task

User asked: "Выкачай акутальный мэйн, убедись, что в него добавлен мой персонаж Райбос и задеплой сборку на подключенный айпад."

## Scope

- Update local `main` from `origin/main`.
- Verify whether the current app includes the user's character "Райбос".
- If the iOS app does not include "Райбос", add the smallest safe seed/merge behavior needed so the character is present without destructive roster replacement.
- Build and deploy the iOS host app to the connected iPad.
- Commit intentional repo changes.

## Acceptance criteria

- AC1: Local `main` is updated from `origin/main` with no uncommitted pre-existing local changes overwritten.
- AC2: The iOS app roster path includes a "Райбос" character, including when an existing persisted roster lacks that character.
- AC3: Relevant automated checks pass for the changed behavior and app build path.
- AC4: The app is installed on the connected physical iPad using the current local build.
- AC5: Proof artifacts record commands, results, and any limitations; git ends clean after the commit unless deployment tooling creates external state only.

## Constraints

- Keep changes inside this repository.
- Avoid destructive persistence behavior; do not replace existing user rosters just to add the seed character.
- Do not claim real-device behavior unless the physical iPad deployment actually succeeds.
- Use existing project style and repo commands where possible.

## Non-goals

- No broad UI redesign.
- No unrelated Dark Heresy rules/data expansion.
- No TestFlight/archive distribution.
- No migration of web-only code beyond what is needed for iOS seed parity.

## Assumptions

- "Райбос" refers to the existing web seed named `Райбос-2 Д-2`.
- The target device is already connected, trusted, and available to Xcode command line tooling.
- Debug deployment is acceptable unless the user specifically asks for Release/TestFlight.

## Verification plan

- Inspect git state and pull `origin/main` with `--ff-only`.
- Search source for "Райбос"/"Raibos" and inspect the iOS roster persistence/load path.
- Add focused Swift tests for seed merge behavior if code changes are required.
- Run repo checks: at minimum `make test`; prefer `make ci` if practical after focused tests.
- Use `xcrun devicectl`/`xcodebuild` physical-device flow when XcodeBuildMCP physical-device tools are unavailable.
- Record evidence and verdict after fresh verification.
