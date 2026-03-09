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
    @State private var pinnedCheckDraft: PinnedCheckDraft?
    @State private var temporaryModifierDraft: TemporaryModifierDraft?
    @State private var quickCheckSelection: QuickMechanicsSelection?

    public init() {
        context = .unscoped
        _session = State(initialValue: .init())
    }

    init(characterID: UUID, viewModel: CharacterListViewModel) {
        context = .character(characterID: characterID, viewModel: viewModel)
        _session = State(initialValue: viewModel.character(by: characterID)?.session ?? .init())
    }

    public var body: some View {
        Group {
            switch context {
            case .unscoped:
                ContentUnavailableView(
                    "Select a Character",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("Open Session Mode from a character detail screen to edit pinned checks and temporary modifiers.")
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
            } header: {
                CogitatorSectionHeader("Session", subtitle: "Liturgical Operations State")
            } footer: {
                Text("Enable when running live checks and temporary combat/session adjustments.")
                    .cogitatorSupportingText()
            }

            Section {
                Button {
                    quickCheckSelection = .characteristic(.weaponSkill)
                } label: {
                    Label("Open Quick Mechanics", systemImage: "scope")
                }
                .cogitatorPanelRow()
                .accessibilityLabel("Open Quick Mechanics")
                .accessibilityHint("Build a characteristic or skill check from current character data.")
                .accessibilityIdentifier("quick-mechanics.session")

                if let characterSnapshot, !characterSnapshot.skills.isEmpty {
                    Text("\(characterSnapshot.skills.count) skills are available in the builder, along with \(session.temporaryModifiers.count) active temporary modifiers.")
                        .cogitatorSupportingText()
                        .cogitatorPanelRow()
                } else {
                    Text("Open the builder for characteristic checks now, or add skills first to include skill-based checks.")
                        .cogitatorSupportingText()
                        .cogitatorPanelRow()
                }
            } header: {
                CogitatorSectionHeader("Quick Mechanics", subtitle: "Fast Session Check Builder")
            } footer: {
                Text("Use this for explicit target calculation without rolling dice or auto-resolving outcomes.")
                    .cogitatorSupportingText()
            }

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
        .formContentWidth()
        .formStyle(.grouped)
        .cogitatorFormRhythm()
        .cogitatorScreenChrome()
        .animation(.easeInOut(duration: 0.18), value: session.modeEnabled)
    }

    private var sortedTemporaryModifiers: [(String, Int)] {
        session.temporaryModifiers
            .map { ($0.key, $0.value) }
            .sorted { $0.0.localizedCaseInsensitiveCompare($1.0) == .orderedAscending }
    }

    private func refreshFromSharedState() {
        guard case let .character(characterID, viewModel) = context,
              let character = viewModel.character(by: characterID)
        else {
            return
        }
        session = character.session
    }

    private func persist(_ updated: SessionState) {
        guard case let .character(characterID, viewModel) = context else { return }
        Task {
            await viewModel.saveSession(characterID: characterID, session: updated)
        }
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
#endif
