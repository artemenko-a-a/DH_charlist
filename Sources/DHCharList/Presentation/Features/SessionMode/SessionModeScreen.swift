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
                sessionModifiers: session.temporaryModifiers,
                initialSelection: selection
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
                if let activeWeapon {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(activeWeapon.displayName)
                            .font(.headline)
                            .foregroundStyle(CogitatorPalette.textPrimary)
                            .accessibilityIdentifier("combat.active-weapon.name")

                        let primaryLine = [
                            activeWeapon.type.trimmedOrNil,
                            activeWeapon.range.trimmedOrNil.map { "Range \($0)" },
                            activeWeapon.damage.trimmedOrNil.map { "Damage \($0)" },
                            activeWeapon.penetration.trimmedOrNil.map { "Pen \($0)" }
                        ]
                            .compactMap { $0 }

                        if !primaryLine.isEmpty {
                            Text(primaryLine.joined(separator: " • "))
                                .font(.subheadline)
                                .foregroundStyle(CogitatorPalette.amber)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        let secondaryLine = [
                            activeWeapon.clip.trimmedOrNil.map { "Clip \($0)" },
                            activeWeapon.reload.trimmedOrNil.map { "Reload \($0)" },
                            activeWeapon.traits.trimmedOrNil
                        ]
                            .compactMap { $0 }

                        if !secondaryLine.isEmpty {
                            Text(secondaryLine.joined(separator: " • "))
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
                ForEach(Array(session.combatConditions.enumerated()), id: \.offset) { index, condition in
                    Button {
                        combatConditionDraft = CombatConditionDraft(index: index, value: condition)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .foregroundStyle(CogitatorPalette.warning)
                                .frame(width: 14)
                            Text(condition)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .cogitatorPanelRow()
                    .accessibilityLabel("Combat Condition: \(condition)")
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
                ForEach(sortedTemporaryModifiers, id: \.0) { key, value in
                    Button {
                        temporaryModifierDraft = TemporaryModifierDraft(originalKey: key, key: key, valueText: String(value))
                    } label: {
                        HStack {
                            Text(key)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            CogitatorStatusChip(
                                value >= 0 ? "+\(value)" : "\(value)",
                                level: modifierStatusLevel(value)
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .cogitatorPanelRow()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Temporary Modifier: \(key), \(value >= 0 ? "+" : "")\(value)")
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

    private var sortedTemporaryModifiers: [(String, Int)] {
        session.temporaryModifiers
            .map { ($0.key, $0.value) }
            .sorted { $0.0.localizedCaseInsensitiveCompare($1.0) == .orderedAscending }
    }

    private var availableWeapons: [Weapon] {
        characterSnapshot?.equipment.weapons ?? []
    }

    private var activeWeapon: Weapon? {
        guard let activeWeaponID = session.activeWeaponID else { return nil }
        return availableWeapons.first(where: { $0.id == activeWeaponID })
    }

    private var movementProfile: MovementProfile {
        characterSnapshot?.equipment.movement ?? .init()
    }

    private var quickActionsSummary: String {
        let builderSummary = characterSnapshot?.skills.isEmpty == false
            ? "\(characterSnapshot?.skills.count ?? 0) skills are available in the full builder."
            : "Add skills to include skill-based checks in the full builder."
        return "\(builderSummary) \(session.pinnedChecks.count) pinned checks and \(session.temporaryModifiers.count) temporary modifiers remain usable below."
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
        let keys = sortedTemporaryModifiers.map { $0.0 }
        for offset in offsets where keys.indices.contains(offset) {
            session.temporaryModifiers.removeValue(forKey: keys[offset])
        }
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
