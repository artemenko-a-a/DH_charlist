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
                Text("Characteristics")
            } footer: {
                Text("Bonuses are derived from characteristic tens digits.")
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
                LabeledContent("Experience Available", value: String(resources.experienceAvailable))
                    .accessibilityLabel("Experience Available")
                    .accessibilityValue(String(resources.experienceAvailable))
            } header: {
                Text("Resources")
            } footer: {
                Text("Experience Available updates from total minus spent.")
            }
        }
        .formContentWidth()
        .formStyle(.grouped)
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
            Spacer()
            TextField(title, value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .accessibilityLabel(title)
                .accessibilityValue(String(value.wrappedValue))
#if os(iOS)
                .keyboardType(.numberPad)
#endif
            Text("B: \(bonus)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), bonus \(bonus)")
    }

    @ViewBuilder
    private func intRow(_ title: String, value: Binding<Int>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
                .accessibilityLabel(title)
                .accessibilityValue(String(value.wrappedValue))
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
    }
}
#endif
