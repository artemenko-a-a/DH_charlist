import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct SkillsScreen: View {
    private let characterID: UUID
    @ObservedObject private var viewModel: CharacterListViewModel

    @State private var skills: [Skill]
    @State private var characteristics: CharacteristicSet
    @State private var draft: SkillDraft?
    @State private var quickCheckSelection: QuickMechanicsSelection?
    @State private var quickCheckDetent: PresentationDetent = .large
    @State private var searchText = ""

    init(characterID: UUID, viewModel: CharacterListViewModel) {
        self.characterID = characterID
        self.viewModel = viewModel
        let character = viewModel.character(by: characterID)
        _skills = State(initialValue: character?.skills ?? [])
        _characteristics = State(initialValue: character?.characteristics ?? .empty)
    }

    var body: some View {
        List {
            skillsListContent
        }
        .formContentWidth()
        .platformInsetGroupedListStyle()
        .cogitatorFormRhythm()
        .cogitatorScreenChrome()
        .navigationTitle("Skills")
        .searchable(text: $searchText, prompt: "Search skill, characteristic, training")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    draft = SkillDraft()
                } label: {
                    Label("Add Skill", systemImage: "plus")
                }
                .accessibilityLabel("Add Skill")
            }
        }
        .onAppear(perform: refreshFromSharedState)
        .onChange(of: skills) { _, updated in
            Task {
                await viewModel.saveSkills(characterID: characterID, skills: updated)
            }
        }
        .sheet(item: $draft) { value in
            SkillEditorView(
                draft: value,
                characteristics: characteristics,
                onCancel: { draft = nil },
                onSave: { updatedDraft in
                    upsertSkill(from: updatedDraft)
                    draft = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $quickCheckSelection) { selection in
            QuickMechanicsHelperView(
                characteristics: characteristics,
                skills: skills,
                initialSelection: selection
            )
            .presentationDetents([.medium, .large], selection: $quickCheckDetent)
            .presentationDragIndicator(.visible)
        }
        .onChange(of: quickCheckSelection) { _, selection in
            if selection != nil {
                quickCheckDetent = .large
            }
        }
    }

    @ViewBuilder
    private var skillsListContent: some View {
        if skills.isEmpty {
            ContentUnavailableView(
                "No Skills",
                systemImage: "list.bullet.rectangle",
                description: Text("Add skills to track training level, specialisations, and derived targets.")
            )
            .cogitatorEmptyStateStyle()
        } else if filteredSkills.isEmpty {
            ContentUnavailableView(
                "No Matching Skills",
                systemImage: "magnifyingglass",
                description: Text("Try a different skill name, specialisation, characteristic, or training level.")
            )
            .cogitatorEmptyStateStyle()
        } else {
            Section {
                ForEach(filteredSkills) { skill in
                    HStack(spacing: 12) {
                        Button {
                            draft = SkillDraft(skill: skill)
                        } label: {
                            SkillRowView(skill: skill, target: target(for: skill))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .buttonStyle(.plain)

                        Button {
                            quickCheckSelection = .skill(skill.id)
                        } label: {
                            Image(systemName: "scope")
                                .foregroundStyle(CogitatorPalette.amber)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Quick Check \(skill.displayName)")
                        .accessibilityHint("Open a quick skill-based check builder.")
                        .accessibilityIdentifier("quick-check.skill.\(skill.id.uuidString)")
                    }
                    .cogitatorPanelRow()
                }
                .onDelete(perform: deleteFilteredSkills)
            } header: {
                CogitatorSectionHeader(skillsSectionTitle, subtitle: "Training Registry")
            } footer: {
                Text("Swipe left on a skill row to delete it.")
                    .cogitatorSupportingText()
            }
        }
    }

    private func refreshFromSharedState() {
        guard let character = viewModel.character(by: characterID) else { return }
        skills = character.skills
        characteristics = character.characteristics
    }

    private func deleteFilteredSkills(at offsets: IndexSet) {
        let idsToDelete = offsets.compactMap { index in
            filteredSkills.indices.contains(index) ? filteredSkills[index].id : nil
        }
        skills.removeAll { idsToDelete.contains($0.id) }
    }

    private func upsertSkill(from draft: SkillDraft) {
        let updated = draft.asSkill()
        if let index = skills.firstIndex(where: { $0.id == updated.id }) {
            skills[index] = updated
        } else {
            skills.append(updated)
        }
    }

    private func target(for skill: Skill) -> Int {
        DerivedValueCalculator.skillTarget(for: skill, characteristics: characteristics)
    }

    private var filteredSkills: [Skill] {
        SkillsSearch.filter(skills: skills, query: searchText)
    }

    private var skillsSectionTitle: String {
        let total = skills.count
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Skills (\(total))"
        }
        return "Matches (\(filteredSkills.count) of \(total))"
    }
}

@available(iOS 17, macOS 14, *)
private struct SkillRowView: View {
    let skill: Skill
    let target: Int

    var body: some View {
        let trainingModifier = skill.training.modifier
        let trainingSummary = "\(skill.characteristic.label) · \(skill.training.label) (\(trainingModifier.signedValueLabel))"

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(skill.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(CogitatorPalette.textPrimary)
                Spacer()
                Text("Target \(target)")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(CogitatorPalette.amber)
            }
            Text(trainingSummary)
                .font(.callout)
                .foregroundStyle(CogitatorPalette.textSecondary)
            if !skill.specialisations.isEmpty {
                Text(skill.specialisations.joined(separator: ", "))
                    .cogitatorSupportingText()
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Double tap to edit skill.")
    }

    private var accessibilitySummary: String {
        let name = skill.displayName
        let characteristic = skill.characteristic.label
        let training = skill.training.label
        if skill.specialisations.isEmpty {
            return "\(name). Target \(target). \(characteristic). \(training)."
        }
        return "\(name). Target \(target). \(characteristic). \(training). Specialisations: \(skill.specialisations.joined(separator: ", "))."
    }
}

@available(iOS 17, macOS 14, *)
private struct SkillEditorView: View {
    @State private var draft: SkillDraft
    let characteristics: CharacteristicSet
    let onCancel: () -> Void
    let onSave: (SkillDraft) -> Void

    init(
        draft: SkillDraft,
        characteristics: CharacteristicSet,
        onCancel: @escaping () -> Void,
        onSave: @escaping (SkillDraft) -> Void
    ) {
        _draft = State(initialValue: draft)
        self.characteristics = characteristics
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Skill name", text: $draft.name)
                        .accessibilityLabel("Skill Name")
                        .cogitatorPanelRow()
                    Picker("Characteristic", selection: $draft.characteristic) {
                        ForEach(SkillCharacteristic.allCases, id: \.self) { characteristic in
                            Text(characteristic.label).tag(characteristic)
                        }
                    }
                    .cogitatorPanelRow()
                    Picker("Training", selection: $draft.training) {
                        ForEach(SkillTrainingLevel.allCases, id: \.self) { training in
                            Text(training.label).tag(training)
                        }
                    }
                    .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Details", subtitle: "Skill Identity and Training")
                }

                Section {
                    TextField("Comma-separated", text: $draft.specialisationsText, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Specialisations")
                        .accessibilityHint("Separate items with commas, semicolons, or line breaks.")
                        .cogitatorInputField()
                        .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Specialisations", subtitle: "Optional Focus Areas")
                }

                Section {
                    LabeledContent("Target", value: String(draft.target(with: characteristics)))
                        .cogitatorReadoutStyle()
                        .cogitatorPanelRow()
                    LabeledContent("Training Modifier", value: "\(draft.training.modifier >= 0 ? "+" : "")\(draft.training.modifier)")
                        .cogitatorReadoutStyle()
                        .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Derived", subtitle: "Computed Check Data")
                }
            }
            .cogitatorScreenChrome()
            .cogitatorFormRhythm()
            .navigationTitle(draft.isNew ? "Add Skill" : "Edit Skill")
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
                    .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct SkillDraft: Identifiable {
    let id: UUID
    var name: String
    var characteristic: SkillCharacteristic
    var training: SkillTrainingLevel
    var specialisationsText: String
    let isNew: Bool

    init() {
        id = UUID()
        name = ""
        characteristic = .agility
        training = .untrained
        specialisationsText = ""
        isNew = true
    }

    init(skill: Skill) {
        id = skill.id
        name = skill.name
        characteristic = skill.characteristic
        training = skill.training
        specialisationsText = skill.specialisations.joined(separator: ", ")
        isNew = false
    }

    func asSkill() -> Skill {
        let cleaned = specialisationsText
            .split(whereSeparator: { $0 == "," || $0 == "\n" || $0 == ";" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Skill(
            id: id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            characteristic: characteristic,
            training: training,
            specialisations: cleaned
        )
    }

    func target(with characteristics: CharacteristicSet) -> Int {
        DerivedValueCalculator.skillTarget(for: asSkill(), characteristics: characteristics)
    }
}

struct SkillsSearch {
    static func filter(skills: [Skill], query: String) -> [Skill] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return skills }
        return skills.filter { matches($0, query: normalized) }
    }

    static func matches(_ skill: Skill, query: String) -> Bool {
        let fields = [
            skill.name,
            skill.characteristic.label,
            skill.training.label,
            skill.specialisations.joined(separator: " ")
        ]
        return fields.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}
#endif
