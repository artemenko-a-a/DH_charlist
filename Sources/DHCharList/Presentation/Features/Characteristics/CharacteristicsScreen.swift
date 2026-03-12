import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct CharacteristicsScreen: View {
    private let characterID: UUID
    @ObservedObject private var viewModel: CharacterListViewModel

    @State private var characteristics: CharacteristicSet
    @State private var resources: ResourceState
    @State private var quickCheckSelection: QuickMechanicsSelection?
    @State private var showingXPSpend = false

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
                characteristicRow("Weapon Skill", characteristic: .weaponSkill, value: $characteristics.weaponSkill, bonus: characteristics.bonus.weaponSkill)
                characteristicRow("Ballistic Skill", characteristic: .ballisticSkill, value: $characteristics.ballisticSkill, bonus: characteristics.bonus.ballisticSkill)
                characteristicRow("Strength", characteristic: .strength, value: $characteristics.strength, bonus: characteristics.bonus.strength)
                characteristicRow("Toughness", characteristic: .toughness, value: $characteristics.toughness, bonus: characteristics.bonus.toughness)
                characteristicRow("Agility", characteristic: .agility, value: $characteristics.agility, bonus: characteristics.bonus.agility)
                characteristicRow("Intelligence", characteristic: .intelligence, value: $characteristics.intelligence, bonus: characteristics.bonus.intelligence)
                characteristicRow("Perception", characteristic: .perception, value: $characteristics.perception, bonus: characteristics.bonus.perception)
                characteristicRow("Willpower", characteristic: .willpower, value: $characteristics.willpower, bonus: characteristics.bonus.willpower)
                characteristicRow("Fellowship", characteristic: .fellowship, value: $characteristics.fellowship, bonus: characteristics.bonus.fellowship)
            } header: {
                CogitatorSectionHeader("Characteristics", subtitle: "Primary Aptitude Matrix")
            } footer: {
                Text("Bonuses are derived from characteristic tens digits. Use the scope button on a row to open a quick check builder.")
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

            Section {
                Button {
                    showingXPSpend = true
                } label: {
                    Label("Validate XP Spend", systemImage: "seal.text.page")
                }
                .accessibilityIdentifier("xp-spend.open")
            } header: {
                CogitatorSectionHeader("Advancement", subtitle: "Bounded XP and prerequisite validation")
            } footer: {
                Text("Use this to validate and apply explicit characteristic or skill advances without entering a full character builder flow.")
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
        .sheet(item: $quickCheckSelection) { selection in
            QuickMechanicsHelperView(
                characteristics: characteristics,
                skills: viewModel.character(by: characterID)?.skills ?? [],
                initialSelection: selection
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingXPSpend) {
            if let snapshot = characterSnapshot {
                XPSpendScreen(character: snapshot) { request in
                    let updated = await viewModel.applyXPSpend(request)
                    if let updated {
                        characteristics = updated.characteristics
                        resources = updated.resources
                    }
                    return updated
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private func characteristicRow(
        _ title: String,
        characteristic: SkillCharacteristic,
        value: Binding<Int>,
        bonus: Int
    ) -> some View {
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
            Button {
                quickCheckSelection = .characteristic(characteristic)
            } label: {
                Image(systemName: "scope")
                    .foregroundStyle(CogitatorPalette.amber)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Quick Check \(title)")
            .accessibilityHint("Open a quick characteristic-based check builder.")
            .accessibilityIdentifier("quick-check.characteristic.\(characteristic.rawValue)")
        }
        .cogitatorPanelRow()
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
                .accessibilityIdentifier("characteristics.resource.\(title.accessibilityResourceToken)")
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

    private var characterSnapshot: Character? {
        guard var character = viewModel.character(by: characterID) else {
            return nil
        }
        character.characteristics = characteristics
        character.resources = resources
        return character
    }
}

private extension String {
    var accessibilityResourceToken: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
    }
}
#endif
