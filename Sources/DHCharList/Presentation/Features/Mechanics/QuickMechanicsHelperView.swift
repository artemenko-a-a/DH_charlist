import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
enum QuickMechanicsSelection: Identifiable, Equatable {
    case characteristic(SkillCharacteristic)
    case skill(UUID)

    var id: String {
        switch self {
        case .characteristic(let characteristic):
            "characteristic.\(characteristic.rawValue)"
        case .skill(let skillID):
            "skill.\(skillID.uuidString)"
        }
    }

    fileprivate var category: QuickMechanicsCategory {
        switch self {
        case .characteristic:
            .characteristic
        case .skill:
            .skill
        }
    }

    fileprivate var characteristic: SkillCharacteristic? {
        guard case let .characteristic(characteristic) = self else { return nil }
        return characteristic
    }

    fileprivate var skillID: UUID? {
        guard case let .skill(skillID) = self else { return nil }
        return skillID
    }

    fileprivate static func resolvedInitialSelection(
        _ selection: QuickMechanicsSelection?,
        skills: [Skill]
    ) -> QuickMechanicsSelection {
        switch selection {
        case .characteristic, .skill:
            return selection!
        case nil:
            if let firstSkill = skills.first {
                return .skill(firstSkill.id)
            }
            return .characteristic(.weaponSkill)
        }
    }
}

@available(iOS 17, macOS 14, *)
private enum QuickMechanicsCategory: String, CaseIterable, Identifiable {
    case characteristic = "Characteristic"
    case skill = "Skill"

    var id: String { rawValue }
}

@available(iOS 17, macOS 14, *)
struct QuickMechanicsHelperView: View {
    private let characteristics: CharacteristicSet
    private let skills: [Skill]
    private let sessionModifiers: [String: Int]

    @State private var selectedCategory: QuickMechanicsCategory
    @State private var selectedCharacteristic: SkillCharacteristic
    @State private var selectedSkillID: UUID
    @State private var appliedModifier: Int
    @State private var customModifierText: String

    @Environment(\.dismiss) private var dismiss

    init(
        characteristics: CharacteristicSet,
        skills: [Skill],
        sessionModifiers: [String: Int] = [:],
        initialSelection: QuickMechanicsSelection? = nil
    ) {
        self.characteristics = characteristics
        self.skills = skills
        self.sessionModifiers = sessionModifiers

        let resolvedSelection = QuickMechanicsSelection.resolvedInitialSelection(initialSelection, skills: skills)
        _selectedCategory = State(initialValue: resolvedSelection.category)
        _selectedCharacteristic = State(initialValue: resolvedSelection.characteristic ?? .weaponSkill)
        _selectedSkillID = State(initialValue: resolvedSelection.skillID ?? skills.first?.id ?? UUID())
        _appliedModifier = State(initialValue: 0)
        _customModifierText = State(initialValue: "0")
    }

    var body: some View {
        NavigationStack {
            Form {
                selectionSection
                modifierSection

                if !sortedSessionModifiers.isEmpty {
                    sessionModifiersSection
                }

                breakdownSection
            }
            .formContentWidth(maxWidth: 720)
            .formStyle(.grouped)
            .cogitatorFormRhythm()
            .cogitatorScreenChrome()
            .navigationTitle("Quick Check")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
    }

    @ViewBuilder
    private var selectionSection: some View {
        Section {
            Picker("Check Type", selection: $selectedCategory) {
                ForEach(QuickMechanicsCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .cogitatorPanelRow()

            if selectedCategory == .characteristic {
                Picker("Characteristic", selection: $selectedCharacteristic) {
                    ForEach(SkillCharacteristic.allCases, id: \.self) { characteristic in
                        Text(characteristic.label).tag(characteristic)
                    }
                }
                .cogitatorPanelRow()
                .accessibilityLabel("Characteristic Check Source")
            } else if skills.isEmpty {
                Text("No skills are available on this character yet. Switch to Characteristic to build a quick check.")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            } else {
                Picker("Skill", selection: $selectedSkillID) {
                    ForEach(skills) { skill in
                        Text(skill.displayName).tag(skill.id)
                    }
                }
                .cogitatorPanelRow()
                .accessibilityLabel("Skill Check Source")
            }
        } header: {
            CogitatorSectionHeader("Check Builder", subtitle: "Source Selection")
        } footer: {
            Text("Build a transparent target from existing character data without hidden rule automation.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var modifierSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Standard Modifiers")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CogitatorPalette.textSecondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], spacing: 8) {
                    ForEach(QuickMechanicsModifierPreset.standard) { preset in
                        if appliedModifier == preset.value {
                            Button(preset.value.signedValueLabel) {
                                applyModifier(preset.value)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("quick-check.modifier.\(preset.value.accessibilitySignedToken)")
                        } else {
                            Button(preset.value.signedValueLabel) {
                                applyModifier(preset.value)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("quick-check.modifier.\(preset.value.accessibilitySignedToken)")
                        }
                    }
                }
            }
            .cogitatorPanelRow()

            TextField("Custom Modifier", text: $customModifierText)
                .accessibilityLabel("Custom Modifier")
                .accessibilityIdentifier("quick-check.custom-modifier")
                .cogitatorPanelRow()
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif

            Button("Apply Custom Modifier") {
                applyCustomModifier()
            }
            .disabled(parsedCustomModifier == nil)
            .cogitatorPanelRow()
            .accessibilityIdentifier("quick-check.apply-custom")
        } header: {
            CogitatorSectionHeader("Modifier", subtitle: "Preset or Manual Adjustment")
        } footer: {
            Text("Preset buttons apply immediately. Custom input applies only when you confirm it.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var sessionModifiersSection: some View {
        Section {
            ForEach(sortedSessionModifiers, id: \.0) { label, value in
                Button {
                    applyModifier(value)
                } label: {
                    HStack {
                        Text(label)
                            .foregroundStyle(CogitatorPalette.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        CogitatorStatusChip(value.signedValueLabel, level: modifierStatusLevel(value))
                    }
                }
                .buttonStyle(.plain)
                .cogitatorPanelRow()
                .accessibilityLabel("Apply Session Modifier \(label)")
                .accessibilityValue(value.signedValueLabel)
            }
        } header: {
            CogitatorSectionHeader("Session Conditions", subtitle: "Reuse Active Temporary Modifiers")
        } footer: {
            Text("These values come from the current character's Session Mode temporary modifiers.")
                .cogitatorSupportingText()
        }
    }

    @ViewBuilder
    private var breakdownSection: some View {
        Section {
            if let breakdown {
                LabeledContent("Check Name", value: breakdown.checkName)
                    .cogitatorReadoutStyle()
                    .cogitatorPanelRow()
                LabeledContent("Source", value: breakdown.sourceName)
                    .cogitatorReadoutStyle()
                    .cogitatorPanelRow()
                LabeledContent("Base Value", value: String(breakdown.baseValue))
                    .cogitatorReadoutStyle()
                    .cogitatorPanelRow()
                if let derivedBonus = breakdown.derivedBonus {
                    LabeledContent("Derived Bonus", value: String(derivedBonus))
                        .cogitatorReadoutStyle()
                        .cogitatorPanelRow()
                }
                if let trainingModifier = breakdown.trainingModifier {
                    LabeledContent("Training Contribution", value: trainingModifier.signedValueLabel)
                        .cogitatorReadoutStyle()
                        .cogitatorPanelRow()
                }
                LabeledContent("Applied Modifier", value: breakdown.appliedModifier.signedValueLabel)
                    .cogitatorReadoutStyle()
                    .cogitatorPanelRow()

                HStack {
                    Text("Final Target")
                    Spacer()
                    Text(String(breakdown.finalTarget))
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(finalTargetLevel(breakdown.finalTarget).foreground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background {
                            Capsule(style: .continuous)
                                .fill(CogitatorPalette.panelRaised)
                                .overlay {
                                    Capsule(style: .continuous)
                                        .stroke(finalTargetLevel(breakdown.finalTarget).foreground.opacity(0.45), lineWidth: 1)
                                }
                        }
                        .accessibilityIdentifier("quick-check.final-target")
                }
                .cogitatorPanelRow()
            } else {
                Text("Select a valid source to build a quick check.")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            }
        } header: {
            CogitatorSectionHeader("Breakdown", subtitle: "Transparent Target Calculation")
        } footer: {
            Text("This helper does not roll dice or persist results automatically.")
                .cogitatorSupportingText()
        }
    }

    private var selectedSkill: Skill? {
        skills.first(where: { $0.id == selectedSkillID }) ?? skills.first
    }

    private var breakdown: QuickMechanicsCheckBreakdown? {
        switch selectedCategory {
        case .characteristic:
            return QuickMechanicsCheckBuilder.characteristicCheck(
                for: selectedCharacteristic,
                characteristics: characteristics,
                modifier: appliedModifier
            )
        case .skill:
            guard let selectedSkill else { return nil }
            return QuickMechanicsCheckBuilder.skillCheck(
                for: selectedSkill,
                characteristics: characteristics,
                modifier: appliedModifier
            )
        }
    }

    private var sortedSessionModifiers: [(String, Int)] {
        sessionModifiers
            .map { ($0.key, $0.value) }
            .sorted { $0.0.localizedCaseInsensitiveCompare($1.0) == .orderedAscending }
    }

    private var parsedCustomModifier: Int? {
        Int(customModifierText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func applyModifier(_ value: Int) {
        appliedModifier = value
        customModifierText = String(value)
    }

    private func applyCustomModifier() {
        guard let parsedCustomModifier else { return }
        appliedModifier = parsedCustomModifier
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

    private func finalTargetLevel(_ value: Int) -> CogitatorStatusLevel {
        if value < 20 {
            return .critical
        }
        if value < 40 {
            return .warning
        }
        if value < 60 {
            return .caution
        }
        return .nominal
    }
}
#endif
