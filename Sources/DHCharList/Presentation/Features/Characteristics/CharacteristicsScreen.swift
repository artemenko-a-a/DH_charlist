import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct CharacteristicsScreen: View {
    private let characterID: UUID
    @ObservedObject private var viewModel: CharacterListViewModel

    @State private var characteristics: CharacteristicSet
    @State private var resources: ResourceState

    init(characterID: UUID, viewModel: CharacterListViewModel) {
        self.characterID = characterID
        self.viewModel = viewModel
        let character = viewModel.character(by: characterID)
        _characteristics = State(initialValue: character?.characteristics ?? .empty)
        _resources = State(initialValue: character?.resources ?? .init())
    }

    var body: some View {
        Form {
            Section {
                characteristicRow("Weapon Skill", value: $characteristics.weaponSkill, bonus: characteristics.bonus.weaponSkill)
                characteristicRow("Ballistic Skill", value: $characteristics.ballisticSkill, bonus: characteristics.bonus.ballisticSkill)
                characteristicRow("Strength", value: $characteristics.strength, bonus: characteristics.bonus.strength)
                characteristicRow("Toughness", value: $characteristics.toughness, bonus: characteristics.bonus.toughness)
                characteristicRow("Agility", value: $characteristics.agility, bonus: characteristics.bonus.agility)
                characteristicRow("Intelligence", value: $characteristics.intelligence, bonus: characteristics.bonus.intelligence)
                characteristicRow("Perception", value: $characteristics.perception, bonus: characteristics.bonus.perception)
                characteristicRow("Willpower", value: $characteristics.willpower, bonus: characteristics.bonus.willpower)
                characteristicRow("Fellowship", value: $characteristics.fellowship, bonus: characteristics.bonus.fellowship)
            } header: {
                CogitatorSectionHeader("Characteristics", subtitle: "Primary Aptitude Matrix")
            } footer: {
                Text("Bonuses are derived from characteristic tens digits.")
                    .cogitatorSupportingText()
            }

            Section {
                intRow("Current Wounds", value: $resources.currentWounds)
                intRow("Max Wounds", value: $resources.maxWounds)
                intRow("Fatigue", value: $resources.fatigue)
                intRow("Corruption", value: $resources.corruption)
                intRow("Insanity", value: $resources.insanity)
                intRow("Current Fate", value: $resources.currentFate)
                intRow("Max Fate", value: $resources.maxFate)
                intRow("Experience Spent", value: $resources.experienceSpent)
                intRow("Experience Total", value: $resources.experienceTotal)
                HStack {
                    Text("Experience Available")
                    Spacer()
                    CogitatorStatusChip(
                        String(resources.experienceAvailable),
                        level: experienceStatusLevel
                    )
                }
                .accessibilityElement(children: .combine)
                    .accessibilityLabel("Experience Available")
                    .accessibilityValue(String(resources.experienceAvailable))
                    .cogitatorPanelRow()
            } header: {
                CogitatorSectionHeader("Resources", subtitle: "Survival and Advancement Ledger")
            } footer: {
                Text("Experience Available updates from total minus spent.")
                    .cogitatorSupportingText()
            }
        }
        .formContentWidth()
        .formStyle(.grouped)
        .cogitatorFormRhythm()
        .cogitatorScreenChrome()
        .navigationTitle("Characteristics")
        .onAppear {
            if let character = viewModel.character(by: characterID) {
                characteristics = character.characteristics
                resources = character.resources
            }
        }
        .onChange(of: characteristics) { _, updated in
            Task {
                await viewModel.saveCharacteristics(characterID: characterID, characteristics: updated)
            }
        }
        .onChange(of: resources) { _, updated in
            Task {
                await viewModel.saveResources(characterID: characterID, resources: updated)
            }
        }
    }

    @ViewBuilder
    private func characteristicRow(_ title: String, value: Binding<Int>, bonus: Int) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(CogitatorPalette.textPrimary)
            Spacer()
            TextField(title, value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .foregroundStyle(CogitatorPalette.textPrimary)
                .accessibilityLabel(title)
                .accessibilityValue(String(value.wrappedValue))
#if os(iOS)
                .keyboardType(.numberPad)
#endif
            CogitatorStatusChip("B: \(bonus)", level: .nominal)
                .accessibilityHidden(true)
        }
        .cogitatorPanelRow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), bonus \(bonus)")
    }

    @ViewBuilder
    private func intRow(_ title: String, value: Binding<Int>) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(CogitatorPalette.textPrimary)
            Spacer()
            TextField(title, value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .foregroundStyle(CogitatorPalette.textPrimary)
                .accessibilityLabel(title)
                .accessibilityValue(String(value.wrappedValue))
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
        .cogitatorPanelRow()
    }

    private var experienceStatusLevel: CogitatorStatusLevel {
        if resources.experienceAvailable < 0 {
            return .critical
        }
        if resources.experienceAvailable == 0 {
            return .warning
        }
        if resources.experienceAvailable <= 100 {
            return .caution
        }
        return .nominal
    }
}
#endif
