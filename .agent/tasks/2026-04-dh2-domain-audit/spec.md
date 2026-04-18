# Task Spec

## ID
2026-04-dh2-domain-audit

## Title
Dark Heresy II domain audit and bounded rules-correctness hardening

## Goal
Audit the actual supported business logic of the DH character builder against the Dark Heresy Second Edition core rules, fix the highest-confidence rules mismatches and domain-safety gaps within the implemented scope, and produce evidence-backed validation for a branch-ready PR.

## User value
- Reduces the chance of creating or loading characters that look plausible but are rules-incorrect within supported flows.
- Brings the app closer to being a trustworthy practical DH2 companion without pretending to cover the full rulebook.
- Hardens cross-surface behavior so iOS and web do not silently diverge on core domain semantics.

## Context
- The repo contains two user-facing frontends with different scope:
  - Swift package + iOS/macOS host app under `Sources/DHCharList`.
  - Browser-local web app under `web/`.
- The project already documents itself as a bounded helper/tooling app, not a full DH2 rules engine.
- Rulebook-backed areas that are actually implemented include:
  - characteristic and skill target helpers
  - skill training state
  - bounded XP spend/progression helpers
  - wounds/fate/XP resource storage and editing
  - profile fields for home world/background/role/aptitudes
  - detached compendium import flows
- Rulebook-backed areas that are not fully implemented include:
  - full character creation pipeline
  - automatic home world/background/role bonuses
  - full influence/requisition system
  - full combat simulator
  - full talent catalog and full advancement engine

## Supported scope map

| App feature | DH2 mechanic | Code source | Rulebook source |
| --- | --- | --- | --- |
| Profile fields store `homeWorld/background/role/aptitudes` | Character creation stages 1-3 exist in DH2, but app only stores values manually | `Sources/DHCharList/Domain/Character.swift`, `web/src/lib/types.ts` | Chapter II pages 28-29, 79-82 |
| Characteristics editing and quick checks | Characteristics, characteristic bonuses, characteristic tests | `Character.swift`, `MechanicsChecks.swift`, `web/src/lib/domain.ts` | Chapter I pages 21-24 |
| Skills editing and quick checks | Untrained penalty and ranked skill advances | `Character.swift`, `MechanicsChecks.swift`, `XPProgression.swift`, `web/src/lib/domain.ts` | Chapter I page 24, Chapter II page 81, Chapter III pages 95-96 |
| XP spending helper | Bounded advances with prerequisites and explainable spend result | `XPProgression.swift`, `ProgressionRegistries.swift`, `XPSpendScreen.swift`, `web/src/lib/domain.ts` | Chapter II pages 79-82 |
| Resources editing | Wounds, fatigue, fate, XP tracking | `Character.swift`, `SessionModeScreen.swift`, `web/src/lib/domain.ts` | Chapter II page 31, Chapter VII pages 233-234 |
| Session helpers / damage helper | Bounded combat shortcuts and wound mitigation | `MechanicsChecks.swift`, `DamagePipeline.swift`, `CombatActionShortcuts.swift`, `web/src/lib/domain.ts` | Chapter VII pages 231-234 |
| Weapon/armour compendium detached copies | Equipment support, not full requisition engine | `WeaponCompendium.swift`, `ArmourCompendium.swift`, `EquipmentScreen.swift`, `web/src/lib/domain.ts` | Chapter II page 82, Chapter V for item data context |

## In scope
- Freeze and document the actual supported domain scope across iOS and web.
- Fix verified rules mismatches that are already within supported scope, especially where the app currently computes or defaults values as though they were DH2-correct.
- Fix high-risk cross-surface domain inconsistencies that can create misleading or contradictory character state.
- Add or update regression tests for the touched domain behavior in both Swift and web code.
- Record evidence, confidence levels, and residual risks truthfully.

## Out of scope
- Building a full rule-driven DH2 character creation engine.
- Adding full home world/background/role rule automation.
- Adding missing large DH2 subsystems such as influence/requisition, psychic automation, critical tables, or complete talent coverage.
- Full frontend parity between iOS and web beyond the touched domain semantics.
- Real-device claims without an actual device pass.

## Constraints
- Do not claim full DH2 support.
- Do not silently expand scope into a full rules engine.
- Preserve accepted detached-copy semantics and replace-all confirmations.
- Keep persistence compatible unless a narrowly-scoped migration/sanitization is required and covered by tests.
- Separate facts from rulebook, facts from implementation, hypotheses, and chosen fixes in the final report.

## User-facing surfaces touched
- Web character creation / storage recovery
- Shared skill training semantics
- Quick mechanics targets
- Bounded XP progression helpers
- Potential cross-section state normalization if required by the chosen fixes

## Rules / data / trust impact
- Affects rules correctness: yes
- Affects progression correctness: yes
- Affects combat/session trust: yes
- Affects destructive data flow: no direct destructive flow change planned
- Affects import/replace semantics: only if sanitization touches imported characters
- Affects persistence observability: possibly, if recovery warnings need tightening

## Trust-critical risks
- Existing persisted characters may already encode old skill-rank semantics.
- Web recovery currently fabricates plausible defaults for missing data, which can hide corruption.
- Cross-surface changes can regress shared expectations between iOS and web.
- Simulator/test validation cannot substitute for real-device behavior.

## Candidate findings to resolve in this task
- `High`: web creation and coercion fabricate DH2-like starting stats/resources/aptitudes that are not justified by the stored character choices or the implemented scope.
- `High`: supported skill training semantics are rules-incorrect; DH2 skill ranks are `Known / Trained / Experienced / Veteran`, but the app currently models only three effective ranks beyond untrained and caps the top bonus at `+20`.
- `Medium`: domain invariants around recovered/sanitized characters may leave contradictory state undisclosed.

## Acceptance criteria
- AC1. The final audit clearly distinguishes supported, partially supported, and out-of-scope DH2 mechanics.
- AC2. At least the highest-confidence rules mismatch(es) inside supported scope are corrected in code and covered by regression tests.
- AC3. No touched supported flow regresses across local Swift and web validation.
- AC4. Proof artifacts report logic confidence, runtime confidence, UI confidence, and real-device confidence separately.

## Required validation
- `swift build`
- `swift test`
- `cd web && npm test`
- `cd web && npm run typecheck`
- `cd web && npm run build`
- Focused rulebook-to-code spot checks for the touched mechanics
- Focused regression review for affected iOS/web flows
- Screenshot/manual pass required: no dedicated visual pass planned unless UI copy/layout changes materially
- Real-device pass required: no

## Manual acceptance required
yes

If yes, list exactly what must be checked manually:
- Web create/select/edit flow still works with the corrected default character semantics.
- Skill training editing and progression still present understandable labels and targets.
- iOS XP / quick mechanics flow still behaves coherently after the shared domain change.

## Evidence expectations
The evidence bundle must include:
- exact commands actually executed
- rulebook passages used for the implemented fixes
- test commands and observed outcomes
- explicit note of anything not verified
- final recommendation: accepted / accepted_with_conditions / rejected

## Notes for implementer
- Prefer fixes that remove false precision over fixes that invent more rules.
- If exact DH2 automation is impossible with the current model, make the limitation explicit rather than faking canonical values.
- Keep final claims bounded to mechanics actually checked against the rulebook.
