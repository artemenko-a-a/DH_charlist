# Task Spec

## ID
2026-04-dhii-engine

## Title
DHII Engine architecture freeze with Tasks 01-05 creation foundations

## Goal
Зафиксировать целевую архитектуру полноценного DHII Engine для `DH_charlist` и поэтапно реализовать первые пять безопасных вертикальных срезов: typed home-world foundation, typed background catalog foundation, typed role/aptitude-composition foundation, typed in-memory creation draft aggregate и typed characteristic-generation foundation с каноническим источником правил, compatibility diagnostics и безопасной интеграцией в текущий bounded domain.

## User value
- Пользователь получает первые rulebook-backed creation surfaces вместо полностью свободных текстовых полей без доменной опоры.
- Пользователь получает engine-backed aptitude composition там, где rulebook package slots фиксированы, без необходимости вручную дублировать эти aptitudes в профиле.
- Команда получает typed creation draft seam, через который можно безопасно менять ранние creation choices без скрытого протаскивания устаревших downstream aptitude choices.
- Пользователь получает typed, explainable characteristic-generation engine для стандартного DHII random-roll и standard point-allocation flows, без выдуманных стартовых значений и без потери rulebook-critical `Influence` внутри transient creation state.
- Команда получает согласованную архитектуру и последовательный roadmap, а не хаотичное наращивание UI.
- Риск ложных или неполных стартовых правил снижается за счёт явного catalog/preview и честной индикации текущих доменных пробелов.

## Context
- Текущая кодовая база уже имеет bounded `Rules` слой для quick checks, progression и damage foundation, но не имеет полноценного character-creation engine.
- `Character` остаётся snapshot-first aggregate с freeform `profile.homeWorld/background/role` и без first-class `Influence`.
- В проекте уже есть стратегический `Docs/rules-engine-roadmap.md`; новая работа должна расширять этот путь, а не заменять его.
- Локальный proof-loop контракт задаётся `AGENTS.md`, `Docs/task-proof-loop.md`, `.agent/tasks/TEMPLATE/*`.

## In scope
- Current-state assessment и target DHII Engine architecture в repo docs.
- Подробный phased roadmap и task decomposition для дальнейшей реализации движка.
- Task 01: канонический typed registry для всех шести DHII home worlds на основе core rulebook.
- Task 02: канонический typed registry для всех семи DHII core backgrounds с package summaries и current-model diagnostics.
- Task 03: канонический typed registry для всех восьми DHII core roles, explainable aptitude composition across home world/background/role, and safe bounded integration into progression checks.
- Task 04: typed in-memory creation draft aggregate over canonical home world/background/role selections plus explicit background/role aptitude choice state with safe recomposition and a legacy adapter from `Profile`.
- Task 05: typed characteristic-generation model over the creation draft for the standard DHII random-roll and standard point-allocation modes, including a single random-generation reroll, explicit transient `Influence`, explainable breakdowns, and safe handling of home-world recomposition or invalidation.
- Explainable home-world/background previews и compatibility diagnostics для текущей snapshot-модели.
- Explainable role preview and composed-aptitude preview for the current snapshot model.
- Typed in-memory creation draft derived from the current snapshot model, including explicit unresolved choice-slot handling and pruning of stale downstream choice state when selections change.
- Narrow, non-persistent creation-engine integration that does not change the current persistence shape.
- Safe use of composed aptitudes in bounded XP prerequisite and skill-cost helpers without rewriting persisted `profile.aptitudes`.
- Unit/regression tests на новый foundation slice.

## Out of scope
- Полный character creation pipeline.
- Автоматическое применение background/role packages.
- Typed persistence for creation-time aptitude choices.
- Typed persistence for characteristic-generation provenance.
- Полная миграция persistence shape под rich engine state.
- Experienced Acolyte / high-power characteristic-generation variant (`+25` random base, adjusted point-allocation floor/cap).
- Web parity для creation preview foundations.
- Real-device validation.

## Constraints
- Не менять persistence shape без явной необходимости.
- Не ломать accepted runtime behavior.
- Не тащить full engine / full rulebook digitization / giant DSL.
- Сохранять bounded scope и explainability.
- Явно отделять подтверждённые rulebook-факты от будущих phases.

## User-facing surfaces touched
- Profile
- Rules / creation foundation
- Other: roadmap / proof artifacts

## Rules / data / trust impact
- Affects rules correctness: yes
- Affects progression correctness: no
- Affects combat/session trust: no
- Affects destructive data flow: no
- Affects import/replace semantics: no
- Affects persistence observability: no

## Trust-critical risks
- Home-world and background facts can look authoritative while current app still lacks full creation pipeline.
- Role and aptitude composition can look more authoritative than the current model really is unless unresolved choice-slots stay explicit.
- Current saved character snapshot cannot yet represent `Influence` as a first-class DHII creation field.
- Character generation can look more authoritative than the current saved snapshot really is unless transient `Influence` and unsupported projection remain explicit.
- Current saved character snapshot cannot yet project background package effects such as availability modifiers, combat-state hooks, or conditional creation grants.
- Current saved character snapshot cannot yet persist typed background/role aptitude choices or role talent choices.
- Current saved character snapshot still cannot persist typed background/role aptitude choices; Task 04 may only derive them in memory from legacy profile fields and must not introduce silent destructive writes.
- Current saved character snapshot still cannot persist characteristic-generation mode, dice provenance, point-allocation state, or transient `Influence`; Task 05 must keep these transient and must not silently flatten them into invented persisted defaults.
- UI could over-promise automation if the preview is not clearly marked informational.
- Future phases could diverge if the roadmap is not frozen before additional implementation.

## Acceptance criteria
- AC1. Repo docs record the current-state assessment, target DHII Engine architecture, phased roadmap, and ordered task decomposition.
- AC2. The rules layer exposes a canonical typed home-world catalog for all six DHII core home worlds with rulebook-backed modifiers, fate threshold, aptitude, wounds, bonus, and recommended backgrounds.
- AC3. The engine exposes a deterministic preview/compatibility API that can recognize canonical home worlds from current freeform profile text and explicitly flag unsupported current-model fields such as `Influence`.
- AC4. The existing profile flow surfaces the recognized home-world preview in read-only form without changing saved data semantics.
- AC5. The rules layer exposes a canonical typed background catalog for all seven DHII core backgrounds with rulebook-backed aptitude options, starting package summaries, background bonuses, recommended roles, and explicit unsupported-mechanics diagnostics.
- AC6. The existing profile flow surfaces the recognized background preview in read-only form without changing saved data semantics or implying automatic package application.
- AC7. The rules layer exposes a canonical typed role catalog for all eight DHII core roles with rulebook-backed aptitude/talent/bonus summaries and explicit current-model diagnostics.
- AC8. The engine exposes deterministic, explainable aptitude composition across home world, background, and role without silently guessing unresolved rulebook choice-slots.
- AC9. Bounded progression helpers can consume engine-backed composed aptitudes when canonical fixed selections resolve, without mutating persisted `profile.aptitudes`.
- AC10. The rules layer exposes a typed creation draft aggregate that can be derived from the current `Profile` snapshot without changing persistence shape.
- AC11. Changing the draft's background or role safely prunes no-longer-applicable aptitude-choice state and recomposes effective aptitudes without leaving stale engine-derived choices behind.
- AC12. Existing profile editing and persistence flows remain intact, and targeted tests plus broader regression gates pass.
- AC13. The rules layer exposes a typed creation-level characteristic model that includes all ten DHII creation characteristics, including transient `Influence`, without changing the persisted `Character` shape.
- AC14. The engine supports standard DHII random characteristic generation (`2d10 + 20`), including home-world roll modifiers and the single allowed re-roll, with deterministic test seams and explainable per-characteristic breakdowns.
- AC15. The engine supports standard DHII point allocation (`25` base, `60` discretionary points, `40` per-characteristic cap) with home-world starting-score modifiers and explicit validation errors for overspend and cap violations.
- AC16. The engine can project supported generated results into the persisted nine-characteristic snapshot while explicitly retaining unsupported `Influence` only in transient creation state.
- AC17. Home-world changes do not silently preserve stale generation semantics: point-allocation results recompose safely, and any random-generation state that is no longer rule-valid becomes explicit or is invalidated instead of being misrepresented.

## Required validation
- `make fmt`
- `make lint`
- `make typecheck`
- `make test`
- `make ci`
- `swift test`
- `swift build`
- `cd web && npm test`
- `cd web && npm run typecheck`
- `cd web && npm run build`
- Screenshot/manual pass required: no
- Real-device pass required: no

## Manual acceptance required
- no

## Evidence expectations
The evidence bundle must include:
- exact commands actually executed
- focused rules/data evidence for the creation foundations, including the typed draft recomposition contract
- explicit separation between tested behavior and future phases
- explicit separation between transient engine-only characteristic generation state and persisted snapshot projection
- confidence split across logic, runtime, UI, and real-device categories
- final recommendation: accepted / accepted_with_conditions / rejected

## Notes for implementer
- Keep Tasks 01-03 limited to catalog/preview/composition foundations and bounded progression integration.
- Task 03 may consume composed aptitudes in bounded progression flows, but must not introduce typed persistence or silent choice inference.
- Task 05 must stay on the standard DHII characteristic-generation path only; do not silently include the optional higher-power variant.
- Prefer typed domain structures over raw strings in the new rules layer.
- Treat the read-only preview as an integration seam, not as the full creation UI.
- Be explicit that `Influence` remains a known model gap.
- Represent `Influence` honestly inside transient creation state rather than dropping it from generation logic.
- Do not silently project background package mechanics the current character model cannot yet support.
