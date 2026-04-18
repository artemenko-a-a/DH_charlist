# Acceptance Checklist

## Functional correctness
- [x] Current-state assessment and target architecture are documented in-repo
- [x] Home-world preview works as described in the spec
- [x] Background preview works as described in the spec
- [x] Role preview works as described in the spec
- [x] Explainable aptitude composition works as described in the spec
- [x] Typed creation draft can be derived from the current profile snapshot
- [x] Draft recomposition safely prunes stale background/role choice state
- [x] Existing accepted profile editing flow remains intact
- [x] Out-of-scope creation automation was not silently introduced
- [x] Typed characteristic generation works as described in the spec
- [x] Random-roll generation includes the standard DHII reroll rule
- [x] Point-allocation generation works as described in the spec
- [x] Starting-package projection derives a bounded engine-backed character package end-to-end
- [x] Starting-package projection refuses unresolved or unsupported selections instead of guessing
- [x] Existing saved data still opens after additive engine-state persistence lands
- [x] Engine-backed characters round-trip through codable/import-export paths with persisted creation state intact
- [x] Staged DHII create flow uses the engine-backed draft and projection path instead of manual origin/profile editing
- [x] Staged DHII edit flow restores persisted engine state and can safely resave an engine-backed character
- [x] Early-stage edits in the staged flow safely recompose later stages before save

## Rules / logic correctness
- [x] Home-world facts are backed by the DH2 core rulebook
- [x] Typed catalog covers all six core home worlds
- [x] Background facts are backed by the DH2 core rulebook
- [x] Typed catalog covers all seven core backgrounds
- [x] Role facts are backed by the DH2 core rulebook
- [x] Typed catalog covers all eight core roles
- [x] Composed aptitudes are deterministic where the current model has enough information
- [x] Unresolved rulebook choice-slots remain explicit instead of being silently guessed
- [x] Legacy profile aptitudes are separated into inferred choice provenance vs fallback leftovers when possible
- [x] Unknown freeform selections remain explicit instead of being misrepresented as canonical
- [x] Compatibility diagnostics explicitly flag unsupported current-model effects
- [x] No new silent calculation path bypasses the accepted rules layer
- [x] Generation logic uses a typed 10-character creation model, including transient Influence
- [x] Random-roll generation follows the standard DHII formula and home-world roll modifiers
- [x] Point allocation follows the standard DHII formula, pool, and cap
- [x] Unsupported Influence projection remains explicit instead of being silently dropped
- [x] Home-world changes recompose or invalidate generation state honestly
- [x] Starting-package projection requires explicit resolution of supported choice slots and roll gates
- [x] Starting-package projection keeps unsupported rule effects explicit through compatibility diagnostics
- [x] Persisted engine state restores canonical selections and characteristic-generation state through a sanitizing adapter
- [x] Projected engine-backed characters persist bounded creation state explicitly instead of relying on legacy inference alone
- [x] Engine-backed create/edit UI paths do not bypass the rules layer when composing or reprojecting characters
- [x] Reprojecting an existing engine-backed character preserves identity and supported player-authored deltas

## Data safety
- [x] Existing saved characters are not silently mutated
- [x] Persistence shape change is additive and legacy-compatible
- [x] Import/export migration path remains backward-compatible for legacy schema `1`
- [x] Exported payloads migrate to schema `2` when engine state is present
- [x] Current freeform profile fields continue to round-trip
- [x] No persisted background identifier or dual source of truth was introduced
- [x] No persisted role identifier or typed aptitude-choice state was introduced prematurely
- [x] Draft-only state is persisted only through explicit `dhiiEngineState`, not by mutating legacy freeform fields silently
- [x] Characteristic-generation provenance is persisted only through explicit engine state, not flattened into invented legacy defaults
- [x] Typed starting-package engine state is persisted only through explicit engine state, not by shadow-writing conflicting legacy fields
- [x] Projected legacy `Character` remains codable and safe to round-trip
- [x] No silent destructive migration path was introduced
- [x] Missing `dhiiEngineState` still decodes safely as `nil`
- [x] Engine-backed edit flow preserves character identity while updating the projected legacy snapshot
- [x] Engine-owned origin selections are no longer expected to be hand-edited in the legacy profile form

## Runtime confidence
- [x] Focused host/runtime sanity passed
- [x] Relevant smoke path remains green
- [x] No newly observed blocker in profile flow
- [x] Web regression set remains green
- [x] New generation-specific regression set is green
- [x] New starting-package projection regression set is green
- [x] Import/export smoke remains green with additive engine-state persistence
- [x] Guided DHII creation/create-edit smoke remains green
- [x] Engine-backed create/edit regression set is green

## UI / UX
- [x] Preview is clearly informational and does not imply full automation
- [x] No obvious unreadable state introduced in profile flow
- [x] Compatibility warnings are explicit where the engine cannot yet project full DHII state
- [x] No obvious compact-screen blocker introduced
- [x] Composed aptitudes do not falsely imply that unresolved choices were auto-resolved
- [x] Profile flow now reads composed aptitudes through the typed draft seam
- [x] Any surfaced generation output stays explicitly informational until a later engine-backed creation flow lands
- [x] No UI surface falsely implies that unsupported starting-package mechanics are fully automated
- [x] Engine-backed characters are explicitly redirected to the DHII Creation flow for origin edits
- [x] Guided flow exposes stage-local progression controls that remain reachable on compact screens

## Automation / quality gates
- [x] `make fmt` passed
- [x] `make lint` passed
- [x] `make typecheck` passed
- [x] `make test` passed
- [x] `make ci` passed
- [x] targeted DHII Engine tests passed
- [x] worktree is ready for intentional follow-up after commit/push
- [x] T05 targeted DHII Engine tests passed
- [x] T06 targeted DHII Engine tests passed
- [x] T07 targeted DHII Engine tests passed
- [x] T08 targeted DHII Engine tests passed

## Documentation / truthfulness
- [x] DHII Engine roadmap doc added or updated
- [x] Progress log updated
- [x] Evidence clearly distinguishes tested vs unverified behavior
- [x] Confidence is split into logic/runtime/UI/real-device categories

## Final decision
- [ ] Accepted
- [x] Accepted with conditions
- [ ] Rejected

## Remaining conditions / follow-up
- Background package application
- Progression and dependency hardening against persisted engine state
- First-class persisted `Influence`
- Web parity or explicit long-term web limitation for the new DHII creation engine surface
