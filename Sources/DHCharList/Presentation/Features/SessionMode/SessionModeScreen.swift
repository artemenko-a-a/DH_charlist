import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct SessionModeScreen: View {
    private enum Context {
        case unscoped
        case character(characterID: UUID, viewModel: CharacterListViewModel)
    }

    private let context: Context

    @State private var session: SessionState
    @State private var resources: ResourceState
    @State private var pinnedCheckDraft: PinnedCheckDraft?
    @State private var temporaryModifierDraft: TemporaryModifierDraft?
    @State private var combatConditionDraft: CombatConditionDraft?
    @State private var quickCheckSelection: QuickMechanicsSelection?
    @State private var quickCheckDetent: PresentationDetent = .large
    @State private var isShowingAttackShortcut = false
    @State private var isShowingDamageShortcut = false
    @State private var shownReactionShortcut: CombatReactionShortcutKind?

    public init() {
        context = .unscoped
        _session = State(initialValue: .init())
        _resources = State(initialValue: .init())
    }

    init(characterID: UUID, viewModel: CharacterListViewModel) {
        let character = viewModel.character(by: characterID)
        context = .character(characterID: characterID, viewModel: viewModel)
        _session = State(initialValue: character?.session ?? .init())
        _resources = State(initialValue: character?.resources ?? .init())
    }

    public var body: some View {
        Group {
            switch context {
            case .unscoped:
                ContentUnavailableView(
                    "Select a Character",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("Open Session Mode from a character detail screen to use the combat workspace, pinned checks, and temporary modifiers.")
                )
                .cogitatorEmptyStateStyle()
                .cogitatorScreenChrome()
            case .character:
                sessionForm
            }
        }
        .navigationTitle("Session")
        .onAppear(perform: refreshFromSharedState)
        .onChange(of: session) { _, updated in
            persist(updated)
        }
        .onChange(of: resources) { _, updated in
            persistResources(updated)
        }
        .sheet(item: $pinnedCheckDraft) { draft in
            PinnedCheckEditorView(
                draft: draft,
                onCancel: { pinnedCheckDraft = nil },
                onSave: { updated in
                    upsertPinnedCheck(from: updated)
                    pinnedCheckDraft = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $temporaryModifierDraft) { draft in
            TemporaryModifierEditorView(
                draft: draft,
                onCancel: { temporaryModifierDraft = nil },
                onSave: { updated in
                    upsertTemporaryModifier(from: updated)
                    temporaryModifierDraft = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $combatConditionDraft) { draft in
            CombatConditionEditorView(
                draft: draft,
                onCancel: { combatConditionDraft = nil },
                onSave: { updated in
                    upsertCombatCondition(from: updated)
                    combatConditionDraft = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $quickCheckSelection) { selection in
            QuickMechanicsHelperView(
                characteristics: characterSnapshot?.characteristics ?? .empty,
                skills: characterSnapshot?.skills ?? [],
                combatContext: sessionCombatContext,
                initialSelection: selection,
                origin: .sessionCombat
            )
            .presentationDetents([.medium, .large], selection: $quickCheckDetent)
            .presentationDragIndicator(.visible)
        }
        .onChange(of: quickCheckSelection) { _, selection in
            if selection != nil {
                quickCheckDetent = .large
            }
        }
        .sheet(isPresented: $isShowingAttackShortcut) {
            CombatAttackShortcutView(
                weapons: availableWeapons,
                combatContext: sessionCombatContext,
                characteristics: characterSnapshot?.characteristics ?? .empty,
                onCancel: { isShowingAttackShortcut = false },
                onSelectActiveWeapon: { selectedWeaponID in
                    session.activeWeaponID = selectedWeaponID
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $shownReactionShortcut) { reaction in
            CombatReactionShortcutView(
                reaction: reaction,
                combatContext: sessionCombatContext,
                characteristics: characterSnapshot?.characteristics ?? .empty,
                skills: characterSnapshot?.skills ?? [],
                onCancel: { shownReactionShortcut = nil }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingDamageShortcut) {
            CombatDamageShortcutView(
                combatContext: sessionCombatContext,
                characteristics: characterSnapshot?.characteristics ?? .empty,
                resources: resources,
                armour: availableArmour,
                onCancel: { isShowingDamageShortcut = false },
                onApply: { updatedWounds in
                    resources.currentWounds = updatedWounds
                    isShowingDamageShortcut = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var sessionForm: some View {
        Form {
            combatOverviewSection
            activeWeaponSection
            quickToggleSection
            encounterShortcutsSection
            quickActionsSection
            movementSection
            combatConditionsSection
            pinnedChecksSection
            temporaryModifiersSection
        }
        .formContentWidth()
        .formStyle(.grouped)
        .cogitatorFormRhythm()
        .cogitatorScreenChrome()
        .animation(.easeInOut(duration: 0.18), value: session.modeEnabled)
    }

    @ViewBuilder
    private var combatOverviewSection: some View {
        Section {
            Toggle("Session Mode Enabled", isOn: $session.modeEnabled)
                .accessibilityLabel("Session Mode Enabled")
                .accessibilityHint("Enable quick session-focused modifiers and checks.")
                .cogitatorPanelRow()

            HStack {
                Text("Operational State")
                Spacer()
                CogitatorStatusChip(
                    session.modeEnabled ? "ACTIVE" : "STANDBY",
                    level: session.modeEnabled ? .nominal : .caution
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Operational State")
            .accessibilityValue(session.modeEnabled ? "Active" : "Standby")
            .cogitatorPanelRow()

            combatMetricRow(
                title: "Current Wounds",
                value: resources.currentWounds,
                detail: resources.maxWounds > 0 ? "Max \(resources.maxWounds)" : "Set max wounds in Characteristics",
                identifierPrefix: "combat.wounds",
                decrement: { adjustCurrentWounds(by: -1) },
                increment: { adjustCurrentWounds(by: 1) }
            )

            combatMetricRow(
                title: "Fatigue",
                value: resources.fatigue,
                detail: "Quick live-play adjustment",
                identifierPrefix: "combat.fatigue",
                decrement: { adjustFatigue(by: -1) },
                increment: { adjustFatigue(by: 1) }
            )

            combatMetricRow(
                title: "Current Fate",
                value: resources.currentFate,
                detail: resources.maxFate > 0 ? "Max \(resources.maxFate)" : "Set max fate in Characteristics",
                identifierPrefix: "combat.fate",
                decrement: { adjustCurrentFate(by: -1) },
                increment: { adjustCurrentFate(by: 1) }
            )
        } header: {
            CogitatorSectionHeader("Combat Workspace", subtitle: "Critical State")
        } footer: {
            Text("Keep wounds, fatigue, and fate current here without leaving the active session flow.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var activeWeaponSection: some View {
        Section {
            if availableWeapons.isEmpty {
                Text("No weapons are available yet. Add weapons in Equipment to use active-weapon focus here.")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            } else {
                if let activeWeapon = sessionCombatContext.activeWeapon {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(activeWeapon.displayName)
                            .font(.headline)
                            .foregroundStyle(CogitatorPalette.textPrimary)
                            .accessibilityIdentifier("combat.active-weapon.name")

                        if !activeWeapon.primarySummary.isEmpty {
                            Text(activeWeapon.primarySummary.joined(separator: " • "))
                                .font(.subheadline)
                                .foregroundStyle(CogitatorPalette.amber)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !activeWeapon.secondarySummary.isEmpty {
                            Text(activeWeapon.secondarySummary.joined(separator: " • "))
                                .font(.caption)
                                .foregroundStyle(CogitatorPalette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .cogitatorPanelRow()
                } else if session.activeWeaponID != nil {
                    Text("The previously selected active weapon is no longer in Equipment. Choose another weapon below.")
                        .cogitatorSupportingText()
                        .cogitatorPanelRow()
                } else {
                    Text("No active weapon selected yet. Choose one below for faster reference during play.")
                        .cogitatorSupportingText()
                        .cogitatorPanelRow()
                }

                ForEach(availableWeapons) { weapon in
                    Button {
                        session.activeWeaponID = weapon.id
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(weapon.displayName)
                                    .foregroundStyle(CogitatorPalette.textPrimary)
                                if let type = weapon.type.trimmedOrNil {
                                    Text(type)
                                        .font(.caption)
                                        .foregroundStyle(CogitatorPalette.textSecondary)
                                }
                            }

                            Spacer()

                            if session.activeWeaponID == weapon.id {
                                CogitatorStatusChip("ACTIVE", level: .nominal)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .cogitatorPanelRow()
                    .accessibilityLabel("Set Active Weapon \(weapon.displayName)")
                    .accessibilityValue(session.activeWeaponID == weapon.id ? "Selected" : "Not selected")
                }
            }
        } header: {
            CogitatorSectionHeader("Active Weapon", subtitle: "Current Ordnance Focus")
        } footer: {
            Text("Use Equipment for full weapon editing. This workspace keeps the currently relevant weapon visible during play.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var encounterShortcutsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    Button {
                        isShowingAttackShortcut = true
                    } label: {
                        Label("Attack", systemImage: "scope")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(availableWeapons.isEmpty)
                    .accessibilityIdentifier("combat.shortcut.attack")

                    Button {
                        shownReactionShortcut = .dodge
                    } label: {
                        Label("Dodge", systemImage: "figure.run")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("combat.shortcut.dodge")

                    Button {
                        shownReactionShortcut = .parry
                    } label: {
                        Label("Parry", systemImage: "shield")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("combat.shortcut.parry")

                    Button {
                        isShowingDamageShortcut = true
                    } label: {
                        Label("Apply Damage", systemImage: "cross.case")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("combat.shortcut.damage")

                    if isReloadConditionActive {
                        Button {
                            toggleReloadCondition()
                        } label: {
                            Label("Reload", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(sessionCombatContext.activeWeapon == nil)
                        .accessibilityIdentifier("combat.shortcut.reload")
                    } else {
                        Button {
                            toggleReloadCondition()
                        } label: {
                            Label("Reload", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                        .disabled(sessionCombatContext.activeWeapon == nil)
                        .accessibilityIdentifier("combat.shortcut.reload")
                    }
                }

                Text(encounterShortcutSummary)
                    .cogitatorSupportingText()
            }
            .cogitatorPanelRow()
        } header: {
            CogitatorSectionHeader("Encounter Shortcuts", subtitle: "Low-Step Combat Actions")
        } footer: {
            Text("Attack, reactions, and incoming damage reuse the accepted combat context, explainable checks, and bounded damage pipeline.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var quickActionsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                    Button {
                        quickCheckSelection = .characteristic(.weaponSkill)
                    } label: {
                        Label("Weapon Skill", systemImage: "scope")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("quick-mechanics.session.weapon-skill")

                    Button {
                        quickCheckSelection = .characteristic(.ballisticSkill)
                    } label: {
                        Label("Ballistic Skill", systemImage: "scope")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("quick-mechanics.session.ballistic-skill")

                    Button {
                        quickCheckSelection = .characteristic(.weaponSkill)
                    } label: {
                        Label("Open Builder", systemImage: "square.grid.2x2")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("quick-mechanics.session")
                }

                Text(quickActionsSummary)
                    .cogitatorSupportingText()
            }
            .cogitatorPanelRow()
        } header: {
            CogitatorSectionHeader("Quick Mechanics", subtitle: "Fast Combat Checks")
        } footer: {
            Text("These actions reuse the accepted quick mechanics helper and current temporary modifiers.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var quickToggleSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Modifiers")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CogitatorPalette.textSecondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                    ForEach(CombatShortcutRegistry.quickModifierShortcuts) { shortcut in
                        if isQuickModifierActive(shortcut) {
                            Button {
                                toggleQuickModifier(shortcut)
                            } label: {
                                Label("\(shortcut.label) \(shortcut.value.signedValueLabel)", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("combat.toggle.modifier.\(shortcut.id)")
                        } else {
                            Button {
                                toggleQuickModifier(shortcut)
                            } label: {
                                Label("\(shortcut.label) \(shortcut.value.signedValueLabel)", systemImage: "circle")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("combat.toggle.modifier.\(shortcut.id)")
                        }
                    }
                }

                Text("Quick Conditions")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CogitatorPalette.textSecondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                    ForEach(CombatShortcutRegistry.quickConditionShortcuts) { shortcut in
                        if isQuickConditionActive(shortcut) {
                            Button {
                                toggleQuickCondition(shortcut)
                            } label: {
                                Label(shortcut.label, systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("combat.toggle.condition.\(shortcut.id)")
                        } else {
                            Button {
                                toggleQuickCondition(shortcut)
                            } label: {
                                Label(shortcut.label, systemImage: "circle")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("combat.toggle.condition.\(shortcut.id)")
                        }
                    }
                }
            }
            .cogitatorPanelRow()
        } header: {
            CogitatorSectionHeader("Quick Toggles", subtitle: "Fast Battlefield Context")
        } footer: {
            Text("Tap once to add an active shortcut modifier or condition. Tap again to remove it.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var movementSection: some View {
        Section {
            VStack(spacing: 8) {
                movementMetricRow("Half Move", value: movementProfile.halfMove)
                movementMetricRow("Full Move", value: movementProfile.fullMove)
                movementMetricRow("Charge", value: movementProfile.charge)
                movementMetricRow("Run", value: movementProfile.run)
            }
            .cogitatorPanelRow()
        } header: {
            CogitatorSectionHeader("Movement", subtitle: "Locomotion Reference")
        } footer: {
            Text("Movement values are pulled from Equipment and kept visible here for live play.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var combatConditionsSection: some View {
        Section {
            if session.combatConditions.isEmpty {
                Text("No combat conditions or short notes yet")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            } else {
                ForEach(Array(normalizedCombatConditions.enumerated()), id: \.offset) { index, condition in
                    Button {
                        combatConditionDraft = CombatConditionDraft(index: index, value: condition.label)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .foregroundStyle(CogitatorPalette.warning)
                                .frame(width: 14)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(condition.label)
                                    .foregroundStyle(CogitatorPalette.textPrimary)
                                Text(condition.kind.label)
                                    .font(.caption)
                                    .foregroundStyle(CogitatorPalette.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .cogitatorPanelRow()
                    .accessibilityLabel("Combat Condition: \(condition.label)")
                    .accessibilityHint("Double tap to edit combat condition.")
                }
                .onDelete(perform: deleteCombatConditions)
            }

            Button {
                combatConditionDraft = CombatConditionDraft()
            } label: {
                Label("Add Combat Condition", systemImage: "plus")
            }
            .cogitatorPanelRow()
            .accessibilityLabel("Add Combat Condition")
            .accessibilityIdentifier("combat.add-condition")
        } header: {
            CogitatorSectionHeader("Conditions", subtitle: "Visible Combat Notes")
        } footer: {
            Text("Keep this short and explicit: statuses, cover, suppression, injuries, or other immediate reminders.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var pinnedChecksSection: some View {
        Section {
            if session.pinnedChecks.isEmpty {
                Text("No pinned checks yet")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            } else {
                ForEach(Array(session.pinnedChecks.enumerated()), id: \.offset) { index, check in
                    Button {
                        pinnedCheckDraft = PinnedCheckDraft(index: index, value: check)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "pin.fill")
                                .foregroundStyle(CogitatorPalette.brass)
                                .frame(width: 14)
                            Text(check)
                                .foregroundStyle(CogitatorPalette.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .cogitatorPanelRow()
                    .accessibilityLabel("Pinned Check: \(check)")
                    .accessibilityHint("Double tap to edit pinned check.")
                }
                .onDelete(perform: deletePinnedChecks)
            }

            Button {
                pinnedCheckDraft = PinnedCheckDraft()
            } label: {
                Label("Add Pinned Check", systemImage: "plus")
            }
            .cogitatorPanelRow()
            .accessibilityLabel("Add Pinned Check")
        } header: {
            CogitatorSectionHeader("Pinned Checks", subtitle: "Rapid Invocation References")
        } footer: {
            Text("Tap a row to edit. Swipe left to remove.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var temporaryModifiersSection: some View {
        Section {
            if sortedTemporaryModifiers.isEmpty {
                Text("No temporary modifiers yet")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            } else {
                ForEach(sortedTemporaryModifiers) { modifier in
                    Button {
                        temporaryModifierDraft = TemporaryModifierDraft(
                            originalKey: modifier.label,
                            key: modifier.label,
                            valueText: String(modifier.value)
                        )
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(modifier.label)
                                    .foregroundStyle(CogitatorPalette.textPrimary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(modifier.source)
                                    .font(.caption)
                                    .foregroundStyle(CogitatorPalette.textSecondary)
                            }
                            Spacer()
                            CogitatorStatusChip(
                                modifier.value.signedValueLabel,
                                level: modifierStatusLevel(modifier.value)
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .cogitatorPanelRow()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Temporary Modifier: \(modifier.label), \(modifier.value.signedValueLabel)")
                    .accessibilityHint("Double tap to edit temporary modifier.")
                }
                .onDelete(perform: deleteTemporaryModifiers)
            }

            Button {
                temporaryModifierDraft = TemporaryModifierDraft()
            } label: {
                Label("Add Temporary Modifier", systemImage: "plus")
            }
            .cogitatorPanelRow()
            .accessibilityLabel("Add Temporary Modifier")
        } header: {
            CogitatorSectionHeader("Temporary Modifiers", subtitle: "Active Battlefield Conditions")
        } footer: {
            Text("Use signed numbers such as +10 or -20.")
                .cogitatorSupportingText()
        }
    }

    private var sortedTemporaryModifiers: [CheckModifier] {
        sessionCombatContext.temporaryModifiers
    }

    private var normalizedCombatConditions: [RuleCondition] {
        sessionCombatContext.combatConditions
    }

    private var sessionCombatContext: CombatContext {
        session.combatContext(availableWeapons: availableWeapons)
    }

    private var availableWeapons: [Weapon] {
        characterSnapshot?.equipment.weapons ?? []
    }

    private var availableArmour: [Armour] {
        characterSnapshot?.equipment.armour ?? []
    }

    private var movementProfile: MovementProfile {
        characterSnapshot?.equipment.movement ?? .init()
    }

    private var isReloadConditionActive: Bool {
        session.combatConditions.contains(reloadConditionLabel)
    }

    private var reloadConditionLabel: String {
        CombatShortcutRegistry.reloadConditionLabel(for: sessionCombatContext.activeWeapon)
    }

    private var encounterShortcutSummary: String {
        if let activeWeapon = sessionCombatContext.activeWeapon {
            let reloadSummary = activeWeapon.reload.map { "Reload \($0)" } ?? "Reload time unavailable"
            return "Attack and reload shortcuts are centered on \(activeWeapon.displayName). \(reloadSummary). Active quick modifiers are applied automatically inside shortcut sheets."
        }

        if availableWeapons.isEmpty {
            return "Add at least one weapon in Equipment to unlock the guided attack shortcut. Dodge, parry, damage, and quick toggles stay available."
        }

        return "Pick an active weapon above or inside the attack shortcut. Dodge, parry, and damage shortcuts still reuse the current combat context."
    }

    private var quickActionsSummary: String {
        let builderSummary = characterSnapshot?.skills.isEmpty == false
            ? "\(characterSnapshot?.skills.count ?? 0) skills are available in the full builder."
            : "Add skills to include skill-based checks in the full builder."
        return "\(builderSummary) \(sessionCombatContext.pinnedChecks.count) pinned checks and \(sortedTemporaryModifiers.count) temporary modifiers remain usable below."
    }

    @ViewBuilder
    private func combatMetricRow(
        title: String,
        value: Int,
        detail: String,
        identifierPrefix: String,
        decrement: @escaping () -> Void,
        increment: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(CogitatorPalette.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(CogitatorPalette.textSecondary)
            }

            Spacer()

            Button(action: decrement) {
                Image(systemName: "minus.circle.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Decrease \(title)")
            .accessibilityIdentifier("\(identifierPrefix).decrement")

            Text(String(value))
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .frame(minWidth: 32, alignment: .center)
                .accessibilityIdentifier("\(identifierPrefix).value")

            Button(action: increment) {
                Image(systemName: "plus.circle.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Increase \(title)")
            .accessibilityIdentifier("\(identifierPrefix).increment")
        }
        .cogitatorPanelRow()
    }

    @ViewBuilder
    private func movementMetricRow(_ title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(CogitatorPalette.textPrimary)
            Spacer()
            CogitatorStatusChip(String(value), level: .caution)
        }
    }

    private func refreshFromSharedState() {
        guard case let .character(characterID, viewModel) = context,
              let character = viewModel.character(by: characterID)
        else {
            return
        }
        resources = character.resources
        session = normalizeSession(character.session, availableWeapons: character.equipment.weapons)
    }

    private func persist(_ updated: SessionState) {
        guard case let .character(characterID, viewModel) = context else { return }
        Task {
            await viewModel.saveSession(characterID: characterID, session: updated)
        }
    }

    private func persistResources(_ updated: ResourceState) {
        guard case let .character(characterID, viewModel) = context else { return }
        Task {
            await viewModel.saveResources(characterID: characterID, resources: updated)
        }
    }

    private func normalizeSession(_ session: SessionState, availableWeapons: [Weapon]) -> SessionState {
        guard let activeWeaponID = session.activeWeaponID else { return session }
        guard availableWeapons.contains(where: { $0.id == activeWeaponID }) else {
            var normalized = session
            normalized.activeWeaponID = nil
            return normalized
        }
        return session
    }

    private func adjustCurrentWounds(by delta: Int) {
        let configuredUpperBound = resources.maxWounds > 0 ? resources.maxWounds : 99
        let upperBound = max(configuredUpperBound, resources.currentWounds)
        resources.currentWounds = min(max(resources.currentWounds + delta, 0), upperBound)
    }

    private func adjustFatigue(by delta: Int) {
        resources.fatigue = min(max(resources.fatigue + delta, 0), 99)
    }

    private func adjustCurrentFate(by delta: Int) {
        let configuredUpperBound = resources.maxFate > 0 ? resources.maxFate : 9
        let upperBound = max(configuredUpperBound, resources.currentFate)
        resources.currentFate = min(max(resources.currentFate + delta, 0), upperBound)
    }

    private func deletePinnedChecks(at offsets: IndexSet) {
        session.pinnedChecks.remove(atOffsets: offsets)
    }

    private func upsertPinnedCheck(from draft: PinnedCheckDraft) {
        let cleaned = draft.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if let index = draft.index, session.pinnedChecks.indices.contains(index) {
            session.pinnedChecks[index] = cleaned
        } else {
            session.pinnedChecks.append(cleaned)
        }
    }

    private func deleteTemporaryModifiers(at offsets: IndexSet) {
        let keys = sortedTemporaryModifiers.map(\.label)
        for offset in offsets where keys.indices.contains(offset) {
            session.temporaryModifiers.removeValue(forKey: keys[offset])
        }
    }

    private func toggleQuickModifier(_ shortcut: CombatModifierShortcut) {
        if session.temporaryModifiers[shortcut.label] == shortcut.value {
            session.temporaryModifiers.removeValue(forKey: shortcut.label)
        } else {
            session.temporaryModifiers[shortcut.label] = shortcut.value
        }
    }

    private func isQuickModifierActive(_ shortcut: CombatModifierShortcut) -> Bool {
        session.temporaryModifiers[shortcut.label] == shortcut.value
    }

    private func upsertTemporaryModifier(from draft: TemporaryModifierDraft) {
        let cleanedKey = draft.key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedKey.isEmpty, let value = Int(draft.valueText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return
        }

        if let originalKey = draft.originalKey, originalKey != cleanedKey {
            session.temporaryModifiers.removeValue(forKey: originalKey)
        }
        session.temporaryModifiers[cleanedKey] = value
    }

    private func deleteCombatConditions(at offsets: IndexSet) {
        session.combatConditions.remove(atOffsets: offsets)
    }

    private func toggleQuickCondition(_ shortcut: CombatConditionShortcut) {
        if let existingIndex = session.combatConditions.firstIndex(of: shortcut.label) {
            session.combatConditions.remove(at: existingIndex)
        } else {
            session.combatConditions.append(shortcut.label)
        }
    }

    private func isQuickConditionActive(_ shortcut: CombatConditionShortcut) -> Bool {
        session.combatConditions.contains(shortcut.label)
    }

    private func toggleReloadCondition() {
        if let existingIndex = session.combatConditions.firstIndex(of: reloadConditionLabel) {
            session.combatConditions.remove(at: existingIndex)
        } else {
            session.combatConditions.append(reloadConditionLabel)
        }
    }

    private func upsertCombatCondition(from draft: CombatConditionDraft) {
        let cleaned = draft.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if let index = draft.index, session.combatConditions.indices.contains(index) {
            session.combatConditions[index] = cleaned
        } else {
            session.combatConditions.append(cleaned)
        }
    }

    private func modifierStatusLevel(_ value: Int) -> CogitatorStatusLevel {
        if value <= -30 {
            return .critical
        }
        if value < 0 {
            return .warning
        }
        if value == 0 {
            return .caution
        }
        return .nominal
    }

    private var characterSnapshot: Character? {
        guard case let .character(characterID, viewModel) = context else {
            return nil
        }
        return viewModel.character(by: characterID)
    }
}

@available(iOS 17, macOS 14, *)
private struct PinnedCheckEditorView: View {
    @State private var draft: PinnedCheckDraft
    let onCancel: () -> Void
    let onSave: (PinnedCheckDraft) -> Void

    init(
        draft: PinnedCheckDraft,
        onCancel: @escaping () -> Void,
        onSave: @escaping (PinnedCheckDraft) -> Void
    ) {
        _draft = State(initialValue: draft)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Pinned Check", text: $draft.value, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Pinned Check")
                        .cogitatorInputField()
                        .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Pinned Check", subtitle: "Quick Table Reference")
                }
            }
            .cogitatorScreenChrome()
            .cogitatorFormRhythm()
            .navigationTitle(draft.isNew ? "Add Check" : "Edit Check")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                    }
                    .fontWeight(.semibold)
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct PinnedCheckDraft: Identifiable {
    let id: UUID
    let index: Int?
    var value: String

    var isNew: Bool { index == nil }

    init() {
        id = UUID()
        index = nil
        value = ""
    }

    init(index: Int, value: String) {
        id = UUID()
        self.index = index
        self.value = value
    }
}

@available(iOS 17, macOS 14, *)
private struct TemporaryModifierEditorView: View {
    @State private var draft: TemporaryModifierDraft
    let onCancel: () -> Void
    let onSave: (TemporaryModifierDraft) -> Void

    init(
        draft: TemporaryModifierDraft,
        onCancel: @escaping () -> Void,
        onSave: @escaping (TemporaryModifierDraft) -> Void
    ) {
        _draft = State(initialValue: draft)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Label", text: $draft.key)
                        .accessibilityLabel("Modifier Label")
                        .cogitatorPanelRow()
                    TextField("Modifier", text: $draft.valueText)
                        .accessibilityLabel("Modifier Value")
                        .cogitatorPanelRow()
#if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
#endif
                } header: {
                    CogitatorSectionHeader("Temporary Modifier", subtitle: "Signed Numeric Adjustment")
                } footer: {
                    Text("Examples: +10, -20, 0")
                        .cogitatorSupportingText()
                }
            }
            .cogitatorScreenChrome()
            .cogitatorFormRhythm()
            .navigationTitle(draft.isNew ? "Add Modifier" : "Edit Modifier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                    }
                    .fontWeight(.semibold)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!draft.isValid)
                }
            }
        }
    }
}

private struct TemporaryModifierDraft: Identifiable {
    let id: UUID
    let originalKey: String?
    var key: String
    var valueText: String

    var isNew: Bool { originalKey == nil }

    var isValid: Bool {
        let cleanedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedValue = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !cleanedKey.isEmpty && Int(cleanedValue) != nil
    }

    init() {
        id = UUID()
        originalKey = nil
        key = ""
        valueText = "0"
    }

    init(originalKey: String, key: String, valueText: String) {
        id = UUID()
        self.originalKey = originalKey
        self.key = key
        self.valueText = valueText
    }
}

@available(iOS 17, macOS 14, *)
private struct CombatConditionEditorView: View {
    @State private var draft: CombatConditionDraft
    let onCancel: () -> Void
    let onSave: (CombatConditionDraft) -> Void

    init(
        draft: CombatConditionDraft,
        onCancel: @escaping () -> Void,
        onSave: @escaping (CombatConditionDraft) -> Void
    ) {
        _draft = State(initialValue: draft)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Combat Condition", text: $draft.value, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Combat Condition")
                        .accessibilityIdentifier("combat.condition.text")
                        .cogitatorInputField()
                        .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Combat Condition", subtitle: "Short Visible Note")
                } footer: {
                    Text("Examples: Pinned Down, In Cover, Suppressing Fire, Leg Injury.")
                        .cogitatorSupportingText()
                }
            }
            .cogitatorScreenChrome()
            .cogitatorFormRhythm()
            .navigationTitle(draft.isNew ? "Add Condition" : "Edit Condition")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                    }
                    .fontWeight(.semibold)
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct CombatConditionDraft: Identifiable {
    let id: UUID
    let index: Int?
    var value: String

    var isNew: Bool { index == nil }

    init() {
        id = UUID()
        index = nil
        value = ""
    }

    init(index: Int, value: String) {
        id = UUID()
        self.index = index
        self.value = value
    }
}

@available(iOS 17, macOS 14, *)
private struct CombatAttackShortcutView: View {
    let weapons: [Weapon]
    let combatContext: CombatContext
    let characteristics: CharacteristicSet
    let onCancel: () -> Void
    let onSelectActiveWeapon: (UUID?) -> Void

    @State private var selectedWeaponID: UUID?
    @State private var situationalModifier = CheckModifier.preset(value: 0)
    @State private var customModifierText = "0"
    @State private var rollText = ""
    @State private var rawDamageText = ""
    @State private var targetWoundsText = "10"
    @State private var targetArmourText = "0"
    @State private var targetToughnessBonusText = "0"
    @State private var penetrationOverrideText = ""

    init(
        weapons: [Weapon],
        combatContext: CombatContext,
        characteristics: CharacteristicSet,
        onCancel: @escaping () -> Void,
        onSelectActiveWeapon: @escaping (UUID?) -> Void
    ) {
        self.weapons = weapons
        self.combatContext = combatContext
        self.characteristics = characteristics
        self.onCancel = onCancel
        self.onSelectActiveWeapon = onSelectActiveWeapon
        _selectedWeaponID = State(initialValue: combatContext.activeWeapon?.id ?? weapons.first?.id)
    }

    var body: some View {
        NavigationStack {
            Form {
                weaponSelectionSection
                if let attackFlow {
                    contextSection(flow: attackFlow)
                    rollSection(flow: attackFlow)
                    if attackOutcome?.isSuccess == true {
                        damageSection(flow: attackFlow)
                    }
                } else {
                    unavailableSection
                }
            }
            .cogitatorScreenChrome()
            .cogitatorFormRhythm()
            .navigationTitle("Attack Shortcut")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onCancel)
                }
            }
        }
        .onChange(of: selectedWeaponID) { _, updated in
            onSelectActiveWeapon(updated)
        }
    }

    @ViewBuilder
    private var weaponSelectionSection: some View {
        Section {
            if weapons.isEmpty {
                Text("Add a weapon in Equipment before using the attack shortcut.")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            } else {
                Picker("Weapon", selection: $selectedWeaponID) {
                    ForEach(weapons) { weapon in
                        Text(weapon.displayName).tag(Optional(weapon.id))
                    }
                }
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.attack.weapon")
            }
        } header: {
            CogitatorSectionHeader("Active Weapon", subtitle: "Confirm or Switch")
        } footer: {
            Text("Changing the selection also updates the current active weapon for the surrounding combat workspace.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private func contextSection(flow: CombatEncounterCheckFlow) -> some View {
        Section {
            if let activeWeapon = flow.activeWeapon {
                VStack(alignment: .leading, spacing: 8) {
                    Text(activeWeapon.displayName)
                        .font(.headline)
                        .foregroundStyle(CogitatorPalette.textPrimary)
                    if !activeWeapon.primarySummary.isEmpty {
                        Text(activeWeapon.primarySummary.joined(separator: " • "))
                            .font(.subheadline)
                            .foregroundStyle(CogitatorPalette.amber)
                    }
                    if !activeWeapon.secondarySummary.isEmpty {
                        Text(activeWeapon.secondarySummary.joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(CogitatorPalette.textSecondary)
                    }
                }
                .cogitatorPanelRow()
            }

            LabeledContent("Check", value: flow.result.checkName)
                .cogitatorReadoutStyle()
                .cogitatorPanelRow()

            HStack {
                Text("Final Target")
                    .foregroundStyle(CogitatorPalette.textPrimary)
                Spacer()
                Text(String(flow.result.finalTarget))
                    .foregroundStyle(CogitatorPalette.amber)
                    .monospacedDigit()
                    .accessibilityIdentifier("combat.attack.final-target")
            }
            .cogitatorPanelRow()

            VStack(alignment: .leading, spacing: 8) {
                Text("Situational Modifier")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CogitatorPalette.textSecondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], spacing: 8) {
                    ForEach(DifficultyPresetRegistry.standard) { preset in
                        Button(preset.value.signedValueLabel) {
                            situationalModifier = preset.normalizedModifier()
                            customModifierText = String(preset.value)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("combat.attack.modifier.\(preset.value.accessibilitySignedToken)")
                    }
                }
            }
            .cogitatorPanelRow()

            TextField("Custom Modifier", text: $customModifierText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.attack.custom-modifier")
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif

            Button("Apply Custom Modifier") {
                if let parsedCustomModifier {
                    situationalModifier = .manual(value: parsedCustomModifier)
                }
            }
            .disabled(parsedCustomModifier == nil)
            .cogitatorPanelRow()
            .accessibilityIdentifier("combat.attack.apply-custom")

            if !flow.autoAppliedModifiers.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Auto-applied active modifiers")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CogitatorPalette.textSecondary)
                    ForEach(flow.autoAppliedModifiers) { modifier in
                        HStack {
                            Text(modifier.label)
                                .foregroundStyle(CogitatorPalette.textPrimary)
                            Spacer()
                            CogitatorStatusChip(modifier.value.signedValueLabel, level: modifierStatusLevel(modifier.value))
                        }
                    }
                }
                .cogitatorPanelRow()
            }

            if !flow.visibleConditions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Visible conditions")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CogitatorPalette.textSecondary)
                    ForEach(flow.visibleConditions) { condition in
                        Text(condition.label)
                            .foregroundStyle(CogitatorPalette.textPrimary)
                    }
                }
                .cogitatorPanelRow()
            }
        } header: {
            CogitatorSectionHeader("Attack Context", subtitle: flow.subtitle)
        } footer: {
            Text("Active session temporary modifiers are applied automatically here; visible conditions stay explicit context.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private func rollSection(flow: CombatEncounterCheckFlow) -> some View {
        Section {
            TextField("Roll Result", text: $rollText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.attack.roll")
#if os(iOS)
                .keyboardType(.numberPad)
#endif

            if let attackOutcome {
                HStack {
                    Text("Outcome")
                        .foregroundStyle(CogitatorPalette.textPrimary)
                    Spacer()
                    CogitatorStatusChip(
                        attackOutcome.isSuccess ? "HIT" : "MISS",
                        level: attackOutcome.isSuccess ? .nominal : .warning
                    )
                }
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.attack.outcome")

                LabeledContent("Margin", value: attackOutcome.margin.signedValueLabel)
                    .cogitatorReadoutStyle()
                    .cogitatorPanelRow()
            } else {
                Text("Enter the final roll to resolve the bounded attack check.")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            }
        } header: {
            CogitatorSectionHeader("Roll Resolution", subtitle: "Manual Final Roll")
        }
    }

    @ViewBuilder
    private func damageSection(flow: CombatEncounterCheckFlow) -> some View {
        Section {
            TextField("Raw Damage", text: $rawDamageText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.attack.raw-damage")
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif

            TextField("Target Wounds", text: $targetWoundsText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.attack.target-wounds")
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif

            TextField("Target Armour", text: $targetArmourText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.attack.target-armour")
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif

            TextField("Target Toughness Bonus", text: $targetToughnessBonusText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.attack.target-toughness")
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif

            TextField("Penetration Override", text: $penetrationOverrideText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.attack.penetration")
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif

            if let damageResult {
                HStack {
                    Text("Applied Damage")
                        .foregroundStyle(CogitatorPalette.textPrimary)
                    Spacer()
                    Text(String(damageResult.appliedDamage))
                        .foregroundStyle(CogitatorPalette.warning)
                        .monospacedDigit()
                        .accessibilityIdentifier("combat.attack.damage.applied")
                }
                .cogitatorPanelRow()

                HStack {
                    Text("Target Wounds After")
                        .foregroundStyle(CogitatorPalette.textPrimary)
                    Spacer()
                    Text(String(damageResult.woundsAfter))
                        .foregroundStyle(CogitatorPalette.textSecondary)
                        .monospacedDigit()
                }
                .cogitatorPanelRow()
            } else {
                Text("If the attack hits, enter target mitigation manually and reuse the bounded damage pipeline below.")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            }
        } header: {
            CogitatorSectionHeader("Damage Handoff", subtitle: "Bounded Target Damage")
        }
    }

    @ViewBuilder
    private var unavailableSection: some View {
        Section {
            Text("A current active weapon is required for the attack shortcut.")
                .cogitatorSupportingText()
                .cogitatorPanelRow()
        } header: {
            CogitatorSectionHeader("Attack Context", subtitle: "Unavailable")
        }
    }

    private var selectedWeapon: Weapon? {
        guard let selectedWeaponID else { return nil }
        return weapons.first(where: { $0.id == selectedWeaponID })
    }

    private var draftCombatContext: CombatContext {
        combatContext.replacingActiveWeapon(selectedWeapon)
    }

    private var attackFlow: CombatEncounterCheckFlow? {
        CombatEncounterResolver.attackFlow(
            combatContext: draftCombatContext,
            characteristics: characteristics,
            additionalModifier: effectiveSituationalModifier
        )
    }

    private var attackOutcome: CombatCheckOutcome? {
        guard let attackFlow, let parsedRoll else { return nil }
        return CombatEncounterResolver.resolveRoll(for: attackFlow, roll: parsedRoll)
    }

    private var damageResult: DamageResult? {
        guard let attackFlow,
              attackOutcome?.isSuccess == true,
              let rawDamage = Int(rawDamageText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let targetWounds = Int(targetWoundsText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let targetArmour = Int(targetArmourText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let targetToughnessBonus = Int(targetToughnessBonusText.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return nil
        }

        let penetrationOverride = Int(penetrationOverrideText.trimmingCharacters(in: .whitespacesAndNewlines))
        return CombatEncounterResolver.resolveTargetDamage(
            for: attackFlow,
            rawDamage: rawDamage,
            targetWounds: targetWounds,
            targetArmour: targetArmour,
            targetToughnessBonus: targetToughnessBonus,
            penetrationOverride: penetrationOverride
        )
    }

    private var effectiveSituationalModifier: CheckModifier? {
        situationalModifier.value == 0 ? nil : situationalModifier
    }

    private var parsedRoll: Int? {
        Int(rollText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var parsedCustomModifier: Int? {
        Int(customModifierText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func modifierStatusLevel(_ value: Int) -> CogitatorStatusLevel {
        if value <= -30 {
            return .critical
        }
        if value < 0 {
            return .warning
        }
        if value == 0 {
            return .caution
        }
        return .nominal
    }
}

@available(iOS 17, macOS 14, *)
private struct CombatReactionShortcutView: View {
    let reaction: CombatReactionShortcutKind
    let combatContext: CombatContext
    let characteristics: CharacteristicSet
    let skills: [Skill]
    let onCancel: () -> Void

    @State private var situationalModifier = CheckModifier.preset(value: 0)
    @State private var customModifierText = "0"
    @State private var rollText = ""

    var body: some View {
        NavigationStack {
            Form {
                contextSection
                rollSection
            }
            .cogitatorScreenChrome()
            .cogitatorFormRhythm()
            .navigationTitle("\(reaction.title) Shortcut")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onCancel)
                }
            }
        }
    }

    @ViewBuilder
    private var contextSection: some View {
        Section {
            LabeledContent("Check", value: flow.result.checkName)
                .cogitatorReadoutStyle()
                .cogitatorPanelRow()

            HStack {
                Text("Final Target")
                    .foregroundStyle(CogitatorPalette.textPrimary)
                Spacer()
                Text(String(flow.result.finalTarget))
                    .foregroundStyle(CogitatorPalette.amber)
                    .monospacedDigit()
                    .accessibilityIdentifier("combat.reaction.final-target")
            }
            .cogitatorPanelRow()

            VStack(alignment: .leading, spacing: 8) {
                Text("Situational Modifier")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CogitatorPalette.textSecondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], spacing: 8) {
                    ForEach(DifficultyPresetRegistry.standard) { preset in
                        Button(preset.value.signedValueLabel) {
                            situationalModifier = preset.normalizedModifier()
                            customModifierText = String(preset.value)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("combat.reaction.modifier.\(preset.value.accessibilitySignedToken)")
                    }
                }
            }
            .cogitatorPanelRow()

            TextField("Custom Modifier", text: $customModifierText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.reaction.custom-modifier")
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif

            Button("Apply Custom Modifier") {
                if let parsedCustomModifier {
                    situationalModifier = .manual(value: parsedCustomModifier)
                }
            }
            .disabled(parsedCustomModifier == nil)
            .cogitatorPanelRow()

            if !flow.autoAppliedModifiers.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Auto-applied active modifiers")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CogitatorPalette.textSecondary)
                    ForEach(flow.autoAppliedModifiers) { modifier in
                        HStack {
                            Text(modifier.label)
                                .foregroundStyle(CogitatorPalette.textPrimary)
                            Spacer()
                            CogitatorStatusChip(modifier.value.signedValueLabel, level: modifierStatusLevel(modifier.value))
                        }
                    }
                }
                .cogitatorPanelRow()
            }

            if !flow.pinnedChecks.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pinned checks")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CogitatorPalette.textSecondary)
                    ForEach(flow.pinnedChecks) { pinnedCheck in
                        Text(pinnedCheck.label)
                            .foregroundStyle(CogitatorPalette.textPrimary)
                    }
                }
                .cogitatorPanelRow()
            }
        } header: {
            CogitatorSectionHeader(reaction.title, subtitle: reaction.subtitle)
        } footer: {
            Text("Defensive reactions reuse the explainable check engine and current combat context.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var rollSection: some View {
        Section {
            TextField("Roll Result", text: $rollText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.reaction.roll")
#if os(iOS)
                .keyboardType(.numberPad)
#endif

            if let outcome {
                HStack {
                    Text("Outcome")
                        .foregroundStyle(CogitatorPalette.textPrimary)
                    Spacer()
                    CogitatorStatusChip(
                        outcome.isSuccess ? "SUCCESS" : "FAIL",
                        level: outcome.isSuccess ? .nominal : .warning
                    )
                }
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.reaction.outcome")

                LabeledContent("Margin", value: outcome.margin.signedValueLabel)
                    .cogitatorReadoutStyle()
                    .cogitatorPanelRow()
            } else {
                Text("Enter the final defensive roll to resolve the shortcut.")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            }
        } header: {
            CogitatorSectionHeader("Roll Resolution", subtitle: "Manual Final Roll")
        }
    }

    private var flow: CombatEncounterCheckFlow {
        CombatEncounterResolver.reactionFlow(
            reaction,
            combatContext: combatContext,
            characteristics: characteristics,
            skills: skills,
            additionalModifier: effectiveSituationalModifier
        )
    }

    private var outcome: CombatCheckOutcome? {
        guard let parsedRoll = Int(rollText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        return CombatEncounterResolver.resolveRoll(for: flow, roll: parsedRoll)
    }

    private var effectiveSituationalModifier: CheckModifier? {
        situationalModifier.value == 0 ? nil : situationalModifier
    }

    private var parsedCustomModifier: Int? {
        Int(customModifierText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func modifierStatusLevel(_ value: Int) -> CogitatorStatusLevel {
        if value <= -30 {
            return .critical
        }
        if value < 0 {
            return .warning
        }
        if value == 0 {
            return .caution
        }
        return .nominal
    }
}

@available(iOS 17, macOS 14, *)
private struct CombatDamageShortcutView: View {
    let combatContext: CombatContext
    let characteristics: CharacteristicSet
    let resources: ResourceState
    let armour: [Armour]
    let onCancel: () -> Void
    let onApply: (Int) -> Void

    @State private var selectedArmourID: UUID?
    @State private var rawDamageText = "0"
    @State private var armourPointsText = "0"
    @State private var penetrationText = "0"

    init(
        combatContext: CombatContext,
        characteristics: CharacteristicSet,
        resources: ResourceState,
        armour: [Armour],
        onCancel: @escaping () -> Void,
        onApply: @escaping (Int) -> Void
    ) {
        self.combatContext = combatContext
        self.characteristics = characteristics
        self.resources = resources
        self.armour = armour
        self.onCancel = onCancel
        self.onApply = onApply
        let defaultArmour = armour.max(by: { $0.armourPoints < $1.armourPoints })
        _selectedArmourID = State(initialValue: defaultArmour?.id)
        _armourPointsText = State(initialValue: String(defaultArmour?.armourPoints ?? 0))
    }

    var body: some View {
        NavigationStack {
            Form {
                inputSection
                breakdownSection
            }
            .cogitatorScreenChrome()
            .cogitatorFormRhythm()
            .navigationTitle("Apply Damage")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onCancel)
                }
            }
        }
        .onChange(of: selectedArmourID) { _, updated in
            guard let updated, let selectedArmour = armour.first(where: { $0.id == updated }) else { return }
            armourPointsText = String(selectedArmour.armourPoints)
        }
    }

    @ViewBuilder
    private var inputSection: some View {
        Section {
            LabeledContent("Current Wounds", value: String(resources.currentWounds))
                .cogitatorReadoutStyle()
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.damage.current-wounds")

            LabeledContent("Toughness Bonus", value: String(characteristics.bonus.toughness))
                .cogitatorReadoutStyle()
                .cogitatorPanelRow()

            if !armour.isEmpty {
                Picker("Armour Reference", selection: $selectedArmourID) {
                    Text("Manual").tag(Optional<UUID>.none)
                    ForEach(armour) { armourEntry in
                        Text("\(armourEntry.location) (\(armourEntry.armourPoints))").tag(Optional(armourEntry.id))
                    }
                }
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.damage.armour-reference")
            }

            TextField("Raw Damage", text: $rawDamageText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.damage.raw")
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif

            TextField("Armour Points", text: $armourPointsText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.damage.armour")
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif

            TextField("Penetration", text: $penetrationText)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.damage.penetration")
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif
        } header: {
            CogitatorSectionHeader("Incoming Damage", subtitle: "Bounded Self-Application")
        } footer: {
            Text("This shortcut applies the accepted damage pipeline to the current character only.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var breakdownSection: some View {
        Section {
            if let damageResult {
                HStack {
                    Text("Applied Damage")
                        .foregroundStyle(CogitatorPalette.textPrimary)
                    Spacer()
                    Text(String(damageResult.appliedDamage))
                        .foregroundStyle(CogitatorPalette.warning)
                        .monospacedDigit()
                        .accessibilityIdentifier("combat.damage.applied")
                }
                .cogitatorPanelRow()

                HStack {
                    Text("Wounds After")
                        .foregroundStyle(CogitatorPalette.textPrimary)
                    Spacer()
                    Text(String(damageResult.woundsAfter))
                        .foregroundStyle(CogitatorPalette.textSecondary)
                        .monospacedDigit()
                        .accessibilityIdentifier("combat.damage.wounds-after")
                }
                .cogitatorPanelRow()

                Button("Apply to Current Wounds") {
                    onApply(damageResult.woundsAfter)
                }
                .buttonStyle(.borderedProminent)
                .cogitatorPanelRow()
                .accessibilityIdentifier("combat.damage.apply")
            } else {
                Text("Enter raw damage and mitigation to preview the bounded wound application result.")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            }
        } header: {
            CogitatorSectionHeader("Damage Breakdown", subtitle: "Explainable Mitigation")
        }
    }

    private var damageResult: DamageResult? {
        guard let rawDamage = Int(rawDamageText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let armourPoints = Int(armourPointsText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let penetration = Int(penetrationText.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return nil
        }

        let request = DamageRequest(
            source: .manual(label: "Incoming Damage"),
            rawDamage: rawDamage,
            woundsBefore: resources.currentWounds,
            mitigation: DamageMitigation(
                armour: armourPoints,
                penetration: penetration,
                toughnessBonus: characteristics.bonus.toughness
            ),
            combatContext: combatContext
        )
        return DamageResolver.resolve(request)
    }
}

private extension Weapon {
    var displayName: String {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Unnamed Weapon" : cleaned
    }
}

private extension String {
    var trimmedOrNil: String? {
        let cleaned = trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
#endif
