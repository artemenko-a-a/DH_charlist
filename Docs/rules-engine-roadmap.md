# Rules Engine Roadmap

## Status

This document defines the intended staged path from the current helper-based mechanics implementation to a fuller, explainable, testable rules engine.

Important: this is a roadmap, not a claim that the project already has a full rules engine.

As of 2026-03-10, Stages 1, 2, 3, 4, 5, and 6 are now implemented in a bounded form through `Sources/DHCharList/Rules/MechanicsChecks.swift`, `Sources/DHCharList/Rules/RulesRegistries.swift`, and `Sources/DHCharList/Rules/DamagePipeline.swift`. The project still does **not** have a full rules engine.

## Goals

The long-term goal is to build a rules engine that is:

- local-first
- deterministic
- explainable
- testable
- UI-independent
- incrementally extensible

The engine should eventually be able to:

- resolve checks/tests
- apply structured modifiers and conditions
- support combat-oriented calculations
- explain how a result was produced
- remain compatible with existing character data and accepted app flows

## Non-goals (for now)

The roadmap does **not** imply immediate implementation of:

- a full combat simulator
- initiative tracking engine
- full damage/critical/perils engine in one step
- complete DH2 rules digitization in one batch
- cloud/shared rules services
- a giant custom DSL from the start

## Guiding principles

1. **Explainability first**  
   Every important calculation should eventually be able to explain:
   - base value
   - modifier sources
   - intermediate contributions
   - final result

2. **UI-independent rules**  
   Rules logic should not depend on SwiftUI or screen-specific presentation state.

3. **Small bounded sub-engines**  
   Prefer multiple focused engines over one giant opaque engine.

4. **Manual override remains valid**  
   Where rules are uncertain, incomplete, or intentionally out of scope, manual input/modifiers remain acceptable.

5. **Rules as data only where justified**  
   Do not force all logic into a DSL prematurely. Move gradually from code to structured data where it creates real value.

---

# Staged roadmap

## Stage 1 — Rules domain foundation
**Goal:** extract current mechanics logic into a dedicated rules/mechanics layer.

### Intended outcomes
- dedicated `Rules` / `Mechanics` layer
- explicit `CheckRequest`
- explicit `CheckResult`
- structured `RuleBreakdown`
- current quick mechanics helpers routed through this layer

### Notes
This stage is about formalization, not adding new gameplay scope.

### Current implemented foundation
- `Sources/DHCharList/Rules/MechanicsChecks.swift`
- explicit `CheckRequest`
- explicit `CheckResult`
- structured `RuleBreakdown`
- structured `RuleContribution`
- `MechanicsCheckResolver` for current characteristic- and skill-based target checks
- existing quick mechanics UI and `DerivedValueCalculator` routed through this layer

### Still intentionally out of scope after Stage 1
- damage resolution
- initiative/action-economy logic
- psychic subsystem automation
- combat automation beyond current accepted helpers
- rules registries/DSL

---

## Stage 2 — Modifier and condition normalization
**Goal:** stop treating modifiers as ad hoc numbers/labels.

### Implemented foundation
- structured `CheckModifier` model with:
  - id
  - kind
  - scope
  - signed value
  - label/source
  - optional note
- bounded modifier kinds for current accepted flows:
  - preset
  - manual
  - session temporary
  - condition-derived
  - equipment-derived
- bounded modifier scopes for current accepted flows:
  - all checks
  - characteristic checks
  - skill checks
  - specific characteristic
  - specific skill
  - combat/session only
- structured `RuleCondition` model with bounded current kinds:
  - pinned
  - cover
  - suppression
  - injury
  - custom
- `SessionState` normalization adapters that keep accepted persistence shape unchanged while exposing structured session temporary modifiers and combat conditions to the rules layer
- `MechanicsCheckResolver` now applies normalized modifiers by scope/origin and keeps active conditions visible in `RuleBreakdown`

### Still intentionally bounded
- combat conditions are explicit rules-layer context, not a full status engine
- conditions are not auto-translated into numeric effects unless they are explicitly modeled as modifiers
- accepted persistence still stores raw `temporaryModifiers: [String: Int]` and `combatConditions: [String]`; normalization happens in rules adapters instead of through a storage migration

### Originally intended outcomes
- structured modifier model
- modifier kind/scope
- normalized condition model
- reusable condition/modifier application rules

### Example concepts
- situational modifiers
- equipment-based modifiers
- status-condition modifiers
- custom manual modifiers

---

## Stage 3 — Explainable check engine
**Goal:** make characteristic/skill checks fully explainable and reusable.

### Implemented foundation
- current accepted characteristic-based and skill-based checks now resolve through one shared `MechanicsCheckResolver.resolve(_:)` path
- `CheckRequest` now models explicit `CheckDefinition` variants instead of leaving the variant split implicit inside helper-specific code
- current explainable outputs now include:
  - source/base value
  - derived bonus
  - training contribution where relevant
  - structured applied modifiers
  - active conditions as explicit context
  - stable ordered contribution lists
  - final target
- `QuickMechanicsHelperView` and `DerivedValueCalculator` both consume the same unified check engine path

### Still intentionally bounded
- no generic damage/attack/initiative engine
- no hidden smart automation for unresolved rule cases
- no automatic numeric condition effects unless a condition is explicitly modeled as a modifier

### Originally intended outcomes
- characteristic checks through rules layer
- skill checks through rules layer
- modifier presets and custom modifiers
- transparent breakdown for UI/history/logging

---

## Stage 4 — Combat context model
**Goal:** formalize combat-relevant context without building a full combat engine.

### Implemented foundation
- explicit `CombatContext` model for the accepted session/combat workspace state that matters to current rules work
- explicit `ActiveWeaponContext` with bounded summary fields for the selected weapon already used by the workspace and quick-mechanics preparation
- explicit `CombatPinnedCheck` normalization for accepted pinned check entries
- explicit `CombatCheckPreparationContext` for combat-facing check preparation before it becomes a `CheckRequest`
- `SessionState` adapters that normalize accepted `activeWeaponID`, `combatConditions`, `pinnedChecks`, and `temporaryModifiers` into rules-layer combat context without changing persistence shape
- current `SessionModeScreen` and `QuickMechanicsHelperView` now consume the bounded combat context path instead of passing loose combat/session values across the rules boundary

### Still intentionally bounded
- no damage resolution
- no attack resolution
- no hit locations
- no initiative or action-economy engine
- no broader combat simulator/state machine
- accepted persistence still stores raw session combat fields; normalization happens at the rules boundary instead of through a storage redesign

### Originally intended outcomes
- active weapon context
- combat condition context
- attack/check preparation context
- session/combat workspace integration

### Out of scope for this stage
- damage resolution
- hit locations
- initiative
- full action economy

---

## Stage 5 — Rules data registries
**Goal:** move stable rules metadata into structured data.

### Implemented foundation
- `Sources/DHCharList/Rules/RulesRegistries.swift`
- bounded difficulty preset registry used by quick-mechanics preset modifiers
- bounded skill metadata registry with canonical metadata plus safe ad hoc fallback for unknown/custom skill labels
- bounded weapon type metadata registry used by `ActiveWeaponContext`
- bounded weapon trait metadata registry used by combat-context summaries
- bounded condition metadata registry used by normalized `RuleCondition` inference and labels
- current rules/combat paths consume these registries instead of repeating the same stable metadata as scattered constants

### Still intentionally bounded after Stage 5
- no full external rules dataset
- no custom rules DSL
- no exhaustive catalog of every Dark Heresy II skill, weapon trait, or condition
- unknown/custom values still fall back to explicit ad hoc metadata instead of being rejected
- no trait resolution, damage resolution, or broader combat automation

---

## Stage 6 — Damage pipeline foundation
**Goal:** introduce bounded damage resolution primitives.

### Implemented foundation
- `Sources/DHCharList/Rules/DamagePipeline.swift`
- explicit `DamageRequest`
- explicit `DamageResult`
- structured `DamageBreakdown`
- structured `DamageContribution`
- bounded mitigation model for raw damage, penetration, armour mitigation, and toughness mitigation
- bounded wound application model for pre-damage wounds, applied damage, post-damage wounds, and overflow tracking
- combat-context helper that builds damage requests from accepted `CombatContext`, `ResourceState`, and `CharacteristicSet` data without changing persistence shape

### Still out of scope
- full critical tables
- hit locations
- full attack resolution
- full weapon trait resolution
- full perils/psychic incident engine
- broad combat automation

---

## Stage 7 — Scenario and golden-rule tests
**Goal:** make rules behavior regression-resistant and trustworthy.

### Intended test types
- unit tests
- golden tests
- scenario tests
- compatibility tests against existing saved/imported state

---

## Stage 8 — Broader UI adoption
**Goal:** make the rules layer the source of truth for relevant app surfaces.

### Intended adoption areas
- quick mechanics helpers
- session/combat workspace
- rule-aware summaries in dossier/export where useful
- history/session entries where rule-generated summaries add value

---

# Proposed batch sequence

A practical implementation sequence could look like:

- **Batch 36** — Rules domain foundation
- **Batch 37** — Modifier & condition normalization
- **Batch 38** — Explainable check engine
- **Batch 39** — Combat context model
- **Batch 40** — Rules data registries
- **Batch 41** — Damage pipeline foundation
- **Batch 42** — Scenario tests & golden rules suite

This sequence is directional, not immutable.

---

# Architecture expectations

## Rules layer should:
- be deterministic
- be testable without UI
- return structured, explainable results
- avoid hidden side effects
- remain compatible with accepted local persistence paths

## Rules layer should not:
- depend on SwiftUI
- directly own persistence
- silently mutate character state without explicit action modeling
- become a dumping ground for random screen logic

---

# Risks

## 1. Premature full-engine ambition
Trying to digitize all DH2 rules too early will likely create brittle scope explosion.

## 2. UI/rules entanglement
If rules logic stays embedded in screens/view models, later engine work becomes much harder.

## 3. Opaque calculation outputs
A rules engine that cannot explain its results will be difficult to trust and debug.

## 4. Over-engineered DSL too early
A giant DSL before the bounded engines exist would add complexity without enough validated modeling knowledge.

---

# Success criteria for the roadmap

The roadmap is succeeding if, over time:

- calculations move out of UI and into explicit rules models
- breakdowns become standard output
- modifier/condition handling becomes normalized through explicit rules-layer models and session adapters
- combat-related helpers and workspace state become more structured without exploding scope
- CI/tests can validate rules behavior deterministically
- future rules work becomes easier rather than more chaotic

---

# Current reality boundary

At the time of writing:

- the project has mechanics helpers and combat-oriented helpers
- the project now has a bounded `Rules` foundation for current check-target calculations with explicit request/result/breakdown modeling
- the project now also has a bounded combat-context layer for active weapon, combat conditions, pinned checks, and combat check preparation
- the project does **not** yet have a full rules engine
- this roadmap exists to make future rules work incremental, explainable, and safe
