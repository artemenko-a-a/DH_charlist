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
        .navigationTitle("Skills")
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
    }

    @ViewBuilder
    private var skillsListContent: some View {
        if skills.isEmpty {
            ContentUnavailableView(
                "No Skills",
                systemImage: "list.bullet.rectangle",
                description: Text("Add skills to track training level, specialisations, and derived targets.")
            )
        } else {
            Section {
                ForEach(skills) { skill in
                    Button {
                        draft = SkillDraft(skill: skill)
                    } label: {
                        SkillRowView(skill: skill, target: target(for: skill))
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteSkills)
            } header: {
                Text("Skills")
            } footer: {
                Text("Swipe left on a skill row to delete it.")
            }
        }
    }

    private func refreshFromSharedState() {
        guard let character = viewModel.character(by: characterID) else { return }
        skills = character.skills
        characteristics = character.characteristics
    }

    private func deleteSkills(at offsets: IndexSet) {
        skills.remove(atOffsets: offsets)
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
}

@available(iOS 17, macOS 14, *)
private struct SkillRowView: View {
    let skill: Skill
    let target: Int

    var body: some View {
        let trainingModifier = skill.training.modifier
        let trainingSummary = "\(skill.characteristic.label) · \(skill.training.label) (\(trainingModifier >= 0 ? "+" : "")\(trainingModifier))"

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(skill.name.isEmpty ? "Unnamed Skill" : skill.name)
                    .font(.headline)
                Spacer()
                Text("Target \(target)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(trainingSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !skill.specialisations.isEmpty {
                Text(skill.specialisations.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Double tap to edit skill.")
    }

    private var accessibilitySummary: String {
        let name = skill.name.isEmpty ? "Unnamed Skill" : skill.name
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
                Section("Details") {
                    TextField("Skill name", text: $draft.name)
                        .accessibilityLabel("Skill Name")
                    Picker("Characteristic", selection: $draft.characteristic) {
                        ForEach(SkillCharacteristic.allCases, id: \.self) { characteristic in
                            Text(characteristic.label).tag(characteristic)
                        }
                    }
                    Picker("Training", selection: $draft.training) {
                        ForEach(SkillTrainingLevel.allCases, id: \.self) { training in
                            Text(training.label).tag(training)
                        }
                    }
                }

                Section("Specialisations") {
                    TextField("Comma-separated", text: $draft.specialisationsText, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Specialisations")
                        .accessibilityHint("Separate items with commas, semicolons, or line breaks.")
                }

                Section("Derived") {
                    LabeledContent("Target", value: String(draft.target(with: characteristics)))
                    LabeledContent("Training Modifier", value: "\(draft.training.modifier >= 0 ? "+" : "")\(draft.training.modifier)")
                }
            }
            .navigationTitle(draft.isNew ? "Add Skill" : "Edit Skill")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                    }
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

private extension SkillCharacteristic {
    var label: String {
        switch self {
        case .weaponSkill: "Weapon Skill"
        case .ballisticSkill: "Ballistic Skill"
        case .strength: "Strength"
        case .toughness: "Toughness"
        case .agility: "Agility"
        case .intelligence: "Intelligence"
        case .perception: "Perception"
        case .willpower: "Willpower"
        case .fellowship: "Fellowship"
        }
    }
}

private extension SkillTrainingLevel {
    var label: String {
        switch self {
        case .untrained: "Untrained"
        case .known: "Known"
        case .trained: "Trained"
        case .veteran: "Veteran"
        }
    }
}
#endif
