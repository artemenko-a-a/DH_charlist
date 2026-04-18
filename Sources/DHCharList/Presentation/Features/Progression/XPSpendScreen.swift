import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct XPSpendScreen: View {
    private enum UpgradeKind: String, CaseIterable, Identifiable {
        case characteristic
        case skill

        var id: String { rawValue }

        var label: String {
            switch self {
            case .characteristic:
                "Characteristic"
            case .skill:
                "Skill"
            }
        }
    }

    private let character: Character
    private let onApply: @Sendable (XPSpendRequest) async -> Character?

    @Environment(\.dismiss) private var dismiss

    @State private var upgradeKind: UpgradeKind = .characteristic
    @State private var selectedCharacteristic: SkillCharacteristic = .weaponSkill
    @State private var characteristicDelta: Int = 5
    @State private var selectedSkillID: UUID?
    @State private var targetTraining: SkillTrainingLevel = .known
    @State private var xpCost: Int = CharacteristicAdvanceCatalogRegistry
        .entry(for: .weaponSkill)
        .costModel
        .defaultCost ?? 0
    @State private var requiredAptitudesText = ""
    @State private var requiredTalent = ""
    @State private var requiredTrait = ""
    @State private var minimumCharacteristicEnabled = false
    @State private var minimumCharacteristic: SkillCharacteristic = .weaponSkill
    @State private var minimumCharacteristicValue = 30
    @State private var isApplying = false

    init(
        character: Character,
        onApply: @escaping @Sendable (XPSpendRequest) async -> Character?
    ) {
        self.character = character
        self.onApply = onApply

        let sortedSkills = character.skills.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        _selectedSkillID = State(initialValue: sortedSkills.first?.id)
        _minimumCharacteristic = State(initialValue: sortedSkills.first?.characteristic ?? .weaponSkill)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Upgrade Type", selection: $upgradeKind) {
                        ForEach(UpgradeKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("xp-spend.kind")
                } header: {
                    CogitatorSectionHeader("Advancement", subtitle: "Bounded XP Spend Validation")
                } footer: {
                    Text("This flow validates current character state plus explicit manual prerequisites. It does not claim full Dark Heresy II advancement coverage.")
                        .cogitatorSupportingText()
                }

                Section {
                    switch upgradeKind {
                    case .characteristic:
                        Picker("Characteristic", selection: $selectedCharacteristic) {
                            ForEach(SkillCharacteristic.allCases, id: \.rawValue) { characteristic in
                                Text(characteristic.label).tag(characteristic)
                            }
                        }
                        .accessibilityIdentifier("xp-spend.characteristic")

                        LabeledContent("Increase", value: "+5")
                            .accessibilityIdentifier("xp-spend.characteristic-delta")

                    case .skill:
                        if sortedSkills.isEmpty {
                            Text("This character has no saved skills yet. Add a skill first, then return here to validate a skill advance.")
                                .cogitatorSupportingText()
                                .accessibilityIdentifier("xp-spend.skill.empty")
                        } else {
                            Picker("Skill", selection: Binding(get: {
                                selectedSkillID ?? sortedSkills.first?.id
                            }, set: { selectedSkillID = $0 })) {
                                ForEach(sortedSkills) { skill in
                                    Text("\(skill.displayName) (\(skill.training.label))").tag(Optional(skill.id))
                                }
                            }
                            .accessibilityIdentifier("xp-spend.skill")

                            Picker("Target Training", selection: $targetTraining) {
                                ForEach(allowedTargetTraining, id: \.rawValue) { level in
                                    Text(level.label).tag(level)
                                }
                            }
                            .accessibilityIdentifier("xp-spend.skill.target")

                            if allowedTargetTraining == [selectedSkill?.training].compactMap({ $0 }) {
                                Text("This skill is already at the highest supported training rank.")
                                    .cogitatorSupportingText()
                            }
                        }
                    }

                    HStack {
                        Text("XP Cost")
                        Spacer()
                        TextField("XP Cost", value: $xpCost, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                            .accessibilityIdentifier("xp-spend.cost")
#if os(iOS)
                            .keyboardType(.numberPad)
#endif
                    }
                    .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Upgrade", subtitle: "Choose a bounded spend target")
                } footer: {
                    Text(upgradeGuidanceText)
                        .cogitatorSupportingText()
                }

                Section {
                    TextField("Required Aptitudes (comma separated)", text: $requiredAptitudesText)
                        .accessibilityIdentifier("xp-spend.prerequisite.aptitudes")
                    TextField("Required Talent", text: $requiredTalent)
                        .accessibilityIdentifier("xp-spend.prerequisite.talent")
                    TextField("Required Trait", text: $requiredTrait)
                        .accessibilityIdentifier("xp-spend.prerequisite.trait")
                    Toggle("Minimum Characteristic Requirement", isOn: $minimumCharacteristicEnabled)
                        .accessibilityIdentifier("xp-spend.prerequisite.minimum.toggle")

                    if minimumCharacteristicEnabled {
                        Picker("Characteristic Gate", selection: $minimumCharacteristic) {
                            ForEach(SkillCharacteristic.allCases, id: \.rawValue) { characteristic in
                                Text(characteristic.label).tag(characteristic)
                            }
                        }
                        .accessibilityIdentifier("xp-spend.prerequisite.minimum.characteristic")

                        HStack {
                            Text("Minimum Value")
                            Spacer()
                            TextField("Minimum Value", value: $minimumCharacteristicValue, format: .number)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 100)
                                .accessibilityIdentifier("xp-spend.prerequisite.minimum.value")
#if os(iOS)
                                .keyboardType(.numberPad)
#endif
                        }
                        .cogitatorPanelRow()
                    }
                } header: {
                    CogitatorSectionHeader("Prerequisites", subtitle: "Only the requirements you explicitly add are validated")
                }

                Section {
                    HStack {
                        Text("Upgrade")
                        Spacer()
                        Text(validationResult.upgrade.summary)
                            .foregroundStyle(CogitatorPalette.textPrimary)
                            .multilineTextAlignment(.trailing)
                    }
                    .cogitatorPanelRow()

                    HStack {
                        Text("Cost")
                        Spacer()
                        Text("\(validationResult.cost) XP")
                            .foregroundStyle(CogitatorPalette.textPrimary)
                    }
                    .cogitatorPanelRow()

                    HStack {
                        Text("Available")
                        Spacer()
                        Text("\(validationResult.availableExperience) XP")
                            .foregroundStyle(CogitatorPalette.textPrimary)
                    }
                    .cogitatorPanelRow()

                    HStack {
                        Text("Projected Remaining")
                        Spacer()
                        Text("\(validationResult.projectedRemainingExperience) XP")
                            .foregroundStyle(CogitatorPalette.textPrimary)
                    }
                    .cogitatorPanelRow()

                    HStack {
                        Text("Validation")
                        Spacer()
                        CogitatorStatusChip(
                            validationResult.isValid ? "Ready" : "Blocked",
                            level: validationResult.isValid ? .nominal : .warning
                        )
                    }
                    .accessibilityIdentifier("xp-spend.status")
                    .cogitatorPanelRow()

                    ForEach(Array(validationResult.breakdown.prerequisiteEvaluations.enumerated()), id: \.offset) { _, evaluation in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: evaluation.isSatisfied ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                .foregroundStyle(evaluation.isSatisfied ? CogitatorPalette.brass : CogitatorPalette.critical)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(evaluation.prerequisite.label)
                                    .foregroundStyle(CogitatorPalette.textPrimary)
                                Text(evaluation.detail)
                                    .cogitatorSupportingText()
                            }

                            Spacer()
                        }
                        .cogitatorPanelRow()
                    }

                    if validationResult.validationErrors.isEmpty == false {
                        ForEach(Array(validationResult.validationErrors.enumerated()), id: \.offset) { _, error in
                            Text(error.message)
                                .foregroundStyle(CogitatorPalette.critical)
                                .cogitatorSupportingText()
                                .accessibilityIdentifier("xp-spend.error")
                        }
                    }
                } header: {
                    CogitatorSectionHeader("Validation", subtitle: "Explainable cost and prerequisite breakdown")
                }
            }
            .formContentWidth()
            .formStyle(.grouped)
            .cogitatorFormRhythm()
            .cogitatorScreenChrome()
            .navigationTitle("XP Spending")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isApplying ? "Applying..." : "Apply") {
                        Task {
                            isApplying = true
                            defer { isApplying = false }
                            if await onApply(currentRequest) != nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(validationResult.isValid == false || isApplying)
                    .accessibilityIdentifier("xp-spend.apply")
                }
            }
        }
        .onAppear(perform: syncProgressionDefaults)
        .onChange(of: upgradeKind) { _, _ in syncProgressionDefaults() }
        .onChange(of: selectedCharacteristic) { _, _ in syncProgressionDefaults() }
        .onChange(of: selectedSkillID) { _, _ in syncProgressionDefaults() }
        .onChange(of: targetTraining) { _, _ in
            guard upgradeKind == .skill else { return }
            syncProgressionDefaults()
        }
    }

    private var sortedSkills: [Skill] {
        character.skills.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    private var currentRequest: XPSpendRequest {
        XPSpendRequest(character: character, upgrade: currentUpgrade)
    }

    private var currentUpgrade: XPSpendUpgrade {
        switch upgradeKind {
        case .characteristic:
            return .characteristicAdvance(
                CharacteristicAdvanceCatalogRegistry
                    .entry(for: selectedCharacteristic)
                    .makeAdvance(
                        deltaOverride: characteristicDelta,
                        costOverride: xpCost,
                        extraPrerequisites: manualPrerequisites
                    )
            )

        case .skill:
            let selectedSkill = selectedSkill
                ?? sortedSkills.first
                ?? Skill(name: "Unavailable Skill", characteristic: .intelligence)
            return .skillAdvance(
                SkillAdvanceCatalogRegistry
                    .entry(for: selectedSkill, targetTraining: targetTraining)
                    .makeAdvance(
                        skill: selectedSkill,
                        costOverride: xpCost,
                        extraPrerequisites: manualPrerequisites
                    )
            )
        }
    }

    private var manualPrerequisites: [XPSpendPrerequisite] {
        var prerequisites: [XPSpendPrerequisite] = []

        for aptitude in requiredAptitudesText
            .split(separator: ",")
            .map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter({ $0.isEmpty == false })
        {
            prerequisites.append(.requiredAptitude(aptitude))
        }

        if requiredTalent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            prerequisites.append(.requiredTalent(requiredTalent))
        }

        if requiredTrait.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            prerequisites.append(.requiredTrait(requiredTrait))
        }

        if minimumCharacteristicEnabled {
            prerequisites.append(.minimumCharacteristic(minimumCharacteristic, minimumCharacteristicValue))
        }

        return prerequisites
    }

    private var selectedSkill: Skill? {
        let fallback = sortedSkills.first
        guard let selectedSkillID else {
            return fallback
        }
        return sortedSkills.first(where: { $0.id == selectedSkillID }) ?? fallback
    }

    private var allowedTargetTraining: [SkillTrainingLevel] {
        guard let selectedSkill else {
            return [.known]
        }

        guard let nextLevel = nextTrainingLevel(after: selectedSkill.training) else {
            return [selectedSkill.training]
        }
        return [nextLevel]
    }

    private var validationResult: XPSpendResult {
        XPProgressionResolver.validate(currentRequest)
    }

    private var upgradeGuidanceText: String {
        switch upgradeKind {
        case .characteristic:
            "DH2 characteristic advances are purchased in single +5 steps. This bounded flow requires manual XP entry because the app does not yet track characteristic advance tiers."
        case .skill:
            "DH2 skill advances are purchased one rank at a time. When the selected skill has a verified aptitude pair, the XP field is prefilled from the next-rank rulebook cost; otherwise it remains manual."
        }
    }

    private func syncProgressionDefaults() {
        switch upgradeKind {
        case .characteristic:
            characteristicDelta = 5
            xpCost = 0

        case .skill:
            guard let selectedSkill else {
                targetTraining = .known
                xpCost = 0
                return
            }

            let nextLevel = nextTrainingLevel(after: selectedSkill.training) ?? selectedSkill.training
            if targetTraining != nextLevel {
                targetTraining = nextLevel
                return
            }

            let entry = SkillAdvanceCatalogRegistry.entry(for: selectedSkill, targetTraining: targetTraining)
            xpCost = entry.defaultCost(for: character.profile.aptitudes) ?? 0
        }
    }

    private func nextTrainingLevel(after currentTraining: SkillTrainingLevel) -> SkillTrainingLevel? {
        SkillTrainingLevel.allCases.first { $0.progressionRank == currentTraining.progressionRank + 1 }
    }
}
#endif
