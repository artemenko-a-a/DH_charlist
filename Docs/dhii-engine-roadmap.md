# DHII Engine Roadmap

## 1. Current State Assessment

### Current application state
- The app is a usable local-first character companion with bounded rules helpers, not yet a full Dark Heresy II engine.
- Character data is stored as a broad `Character` snapshot with manual `profile.homeWorld`, `profile.background`, `profile.role`, and `profile.aptitudes`.
- Rules support already exists for explainable checks, modifiers/conditions, combat context, bounded damage, and bounded XP/progression.
- Web is a separate bounded representation layer and currently duplicates parts of the domain/rules behavior.

### Current architecture
- One Swift package with folder-based layers: `Domain`, `Application`, `Infrastructure`, `Presentation`, `Rules`.
- `AppContainer` is the composition root.
- `CharacterUseCases` orchestrate persistence and snapshot updates.
- `Presentation` still contains meaningful application logic, especially in `CharacterListViewModel`.
- `Rules` is the strongest existing seam for DHII Engine growth.

### Current DHII scope
- Implemented in bounded form:
  - manual character profile editing
  - characteristics/resources/skills/notes/equipment/session state
  - explainable check resolution
  - bounded progression and damage helpers
  - local persistence/import/export/templates/history
- Partial or missing:
  - true character creation pipeline
  - home world/background/role package application
  - aptitude composition across creation stages
  - first-class Influence in the saved domain model
  - migration-safe engine state for changing earlier choices

### Current architectural constraints
- `Character` is snapshot-first rather than a rich engine aggregate.
- `Influence` is absent as a first-class domain field, which blocks faithful highborn/feral creation projection.
- UI still owns too many orchestration concerns.
- Web duplicates behavior instead of consuming a shared engine surface.
- Current freeform text entry allows unsupported or partial DHII semantics without canonical validation.

## 2. Target DHII Engine Architecture

### Domain subsystems
- `Creation Engine`
  - canonical home world/background/role catalogs
  - deterministic generation modes
  - creation draft aggregate
  - explainable package composition
- `Core Character Domain`
  - stable canonical identifiers and typed choices
  - first-class resources/derived values/influence
  - invariant-preserving mutations
- `Rules / Validation Engine`
  - explainable rule application
  - prerequisite/dependency evaluation
  - invalid-state diagnostics instead of silent coercion
- `Advancement Engine`
  - advancement packages
  - aptitude-aware costs
  - transitions that remain valid after upstream changes
- `Equipment / Inventory Domain`
  - canonical detached owned items
  - equipment-driven rule contributions
- `Persistence / Migration Boundary`
  - migration-safe storage shape
  - adapters from legacy snapshots to richer engine state
- `UI Integration Boundary`
  - read models and commands
  - no rule decisions hidden in views

### Principles
- The engine is the source of truth for supported DHII rules.
- UI collects intent and displays explainable output; it does not improvise rule decisions.
- Persistence stores explicit canonical selections or stable engine state, not ambiguous freeform text alone.
- Early-stage choice changes must recompose downstream packages safely instead of leaving stale mutations behind.
- Unsupported rule areas must remain manual and explicitly labeled.
- Each phase must leave the app usable and regression-safe.

### Source of truth strategy
- Short term: typed registries + compatibility adapters over the existing snapshot model.
- Mid term: introduce a creation aggregate and projection layer while keeping legacy persistence readable.
- Long term: persist canonical DHII engine state and derive `Character` read models from it.

## 3. Roadmap

### Phase A — Foundation
- Goal: establish canonical creation catalogs and a stable engine boundary.
- Adds:
  - typed home world/background/role identifiers
  - compatibility diagnostics against the current snapshot model
  - roadmap and proof artifacts
- Risks removed:
  - freeform creation drift
  - unbounded ad hoc rule additions
- Done when:
  - home worlds are canonical and surfaced through rules-layer previews
  - background/role architecture is specified

### Phase B — Creation Catalogs and Composition
- Goal: model all stage-1/2/3 packages and aptitude composition without mutating current persistence unsafely.
- Adds:
  - background catalog
  - role catalog
  - aptitude composition rules
  - package summary read model
- Risks removed:
  - contradictory manual aptitude entry
  - incomplete package understanding
- Done when:
  - a creation selection set can be summarized deterministically and explainably

### Phase C — Deterministic Creation Aggregate
- Goal: create a real DHII creation draft that can survive upstream choice changes.
- Adds:
  - generation mode support
  - characteristic generation pipeline
  - starting wounds/fate/influence derivation
  - change propagation rules
- Risks removed:
  - stale downstream state after changing home world/background/role
- Done when:
  - a complete draft can be recomposed safely from canonical selections

### Phase D — Character Projection and Persistence Migration
- Goal: project creation output into saved character state and prepare migration.
- Adds:
  - projection layer from creation aggregate to `Character`
  - migration-safe persistence additions
  - legacy adapter path
- Risks removed:
  - divergence between engine truth and stored snapshot
- Done when:
  - the app can save and reopen engine-backed characters without data loss

### Phase E — Progression and Dependency Hardening
- Goal: connect creation-state truth to advances, talents, traits, and validations.
- Adds:
  - stronger aptitude-aware progression
  - dependency checks backed by canonical choices
  - invalid-state diagnostics
- Risks removed:
  - progression costs/prerequisites detached from character origin
- Done when:
  - supported advancement flows read from engine state rather than freeform profile text

### Phase F — UI Flow Integration and Web Hardening
- Goal: replace manual creation illusions with an engine-backed flow.
- Adds:
  - staged creation UI
  - edit/respec behavior for earlier choices
  - web parity strategy or explicit web limitation
- Risks removed:
  - user-visible mismatch between UI and engine truth
- Done when:
  - supported creation/edit flows are engine-backed and regression-covered

## 4. Task Decomposition

### T01 — Home-world engine foundation
- Description: Add canonical typed home-world catalog, rulebook-backed preview, current-model compatibility diagnostics, and read-only profile integration.
- Dependencies: none
- Acceptance criteria:
  - six home worlds modeled canonically
  - preview recognizes current freeform text
  - unsupported `Influence` projection is explicit
  - profile flow remains intact
- Test requirements:
  - registry coverage
  - preview scenario tests
  - compatibility diagnostics tests
  - full Swift/web regression gates
- Manual validation: none
- Status: completed

### T02 — Background catalog foundation
- Description: Add canonical background identifiers, package metadata, and compatibility diagnostics.
- Dependencies: T01
- Acceptance criteria:
  - all seven DH2 core backgrounds modeled canonically
  - rulebook-backed package summaries available
  - no persistence mutation yet
- Test requirements:
  - catalog coverage
  - alias recognition
  - package summary assertions
- Manual validation: none
- Status: completed

### T03 — Role catalog and aptitude composition
- Description: Add role catalog and compose aptitudes from home world, background, and role selections.
- Dependencies: T02
- Acceptance criteria:
  - all eight roles modeled
  - aptitude composition deterministic and explainable
  - manual aptitudes no longer required for engine-backed selections
- Test requirements:
  - role catalog coverage
  - aptitude composition scenarios
  - regression suite
- Manual validation: none
- Status: pending

### T04 — Creation draft aggregate
- Description: Introduce a typed creation aggregate with canonical selections and safe recomposition.
- Dependencies: T03
- Acceptance criteria:
  - upstream choice changes invalidate/recompose downstream outputs safely
  - no stale engine state survives choice changes
- Test requirements:
  - aggregate mutation tests
  - recomposition scenarios
  - persistence adapter regression tests
- Manual validation: lightweight create/edit smoke
- Status: pending

### T05 — Characteristic generation modes
- Description: Implement random-roll and point-allocation generation with explainable output.
- Dependencies: T04
- Acceptance criteria:
  - supported generation modes follow rulebook-backed formulas
  - home-world modifiers apply correctly
  - explainable breakdowns are available
- Test requirements:
  - deterministic random-source tests
  - point-buy scenarios
  - edge-case bounds tests
- Manual validation: lightweight creation smoke
- Status: pending

### T06 — Starting package projection
- Description: Project creation aggregate into starting resources, influence, wounds, fate, aptitudes, and other supported packages.
- Dependencies: T05
- Acceptance criteria:
  - engine-backed starting character package is derivable end-to-end
  - unsupported rules remain explicit
  - legacy `Character` projection remains safe
- Test requirements:
  - end-to-end creation projection tests
  - migration safety tests
- Manual validation: save/reload smoke
- Status: pending

### T07 — Persistence and migration path
- Description: Introduce storage-safe engine state and legacy adapters.
- Dependencies: T06
- Acceptance criteria:
  - existing saved data still opens
  - new engine-backed data round-trips safely
  - no silent destructive migration
- Test requirements:
  - round-trip migration fixtures
  - import/export integrity
  - regression suite
- Manual validation: import/export smoke
- Status: pending

### T08 — Engine-backed creation flow
- Description: Replace manual creation illusions with a staged engine-backed UI flow.
- Dependencies: T07
- Acceptance criteria:
  - supported creation flow uses the DHII Engine
  - early-stage edits safely recompose later stages
  - no contradictory user-visible state remains
- Test requirements:
  - flow tests
  - regression tests
  - UI smoke where available
- Manual validation: create/edit/save/reopen flow
- Status: pending

## 5. Execution Log

### Current task in work
- T01 — Home-world engine foundation

### What is done so far
- Current repository architecture and local process rules audited.
- Existing rules roadmap and decision log aligned with the new DHII Engine direction.
- Rulebook-backed facts for all six home worlds extracted for the first catalog slice.
- Task 01 implementation started with a typed home-world catalog and read-only profile preview seam.

### Gate status
- Acceptance gate for T01: pending validation.
- Next task remains blocked until T01 passes.

## 6. Final Delivery Summary

This roadmap defines a practical path from the existing bounded rules helper application to a genuine DHII Engine. The critical path is:

1. Canonical catalogs
2. Package composition
3. Creation aggregate
4. Projection/migration
5. Progression hardening
6. Engine-backed UI flows

The first implementation slice intentionally stays small and safe: home worlds only, read-only projection only, and no persistence migration yet.
