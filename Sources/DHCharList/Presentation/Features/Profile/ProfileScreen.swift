import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct ProfileScreen: View {
    private let characterID: UUID
    @ObservedObject private var viewModel: CharacterListViewModel

    @State private var draft: Profile

    init(characterID: UUID, viewModel: CharacterListViewModel) {
        self.characterID = characterID
        self.viewModel = viewModel
        _draft = State(initialValue: viewModel.character(by: characterID)?.profile ?? .init())
    }

    public var body: some View {
        Form {
            Section {
                TextField("Name", text: $draft.name)
                    .accessibilityLabel("Character Name")
                    .cogitatorPanelRow()
                TextField("Home world", text: $draft.homeWorld)
                    .accessibilityLabel("Home World")
                    .cogitatorPanelRow()
                TextField("Background", text: $draft.background)
                    .accessibilityLabel("Background")
                    .cogitatorPanelRow()
                TextField("Role", text: $draft.role)
                    .accessibilityLabel("Role")
                    .cogitatorPanelRow()
            } header: {
                CogitatorSectionHeader("Identity", subtitle: "Primary Dossier Fields")
            }

            if let homeWorldPreview = DHIICharacterCreationEngine.previewHomeWorldSelection(rawValue: draft.homeWorld) {
                Section {
                    LabeledContent("Canonical home world", value: homeWorldPreview.definition.displayName)
                        .cogitatorPanelRow()
                    LabeledContent("Characteristic modifiers", value: homeWorldPreview.definition.characteristicModifierSummary)
                        .cogitatorPanelRow()
                    LabeledContent("Fate Threshold", value: homeWorldPreview.definition.fateThreshold.summary)
                        .cogitatorPanelRow()
                    LabeledContent("Home World Aptitude", value: homeWorldPreview.definition.aptitude)
                        .cogitatorPanelRow()
                    LabeledContent("Wounds", value: homeWorldPreview.definition.wounds.summary)
                        .cogitatorPanelRow()
                    LabeledContent("Home World Bonus", value: homeWorldPreview.definition.homeWorldBonus.name)
                        .cogitatorPanelRow()

                    Text(homeWorldPreview.definition.homeWorldBonus.summary)
                        .cogitatorSupportingText()
                        .cogitatorPanelRow()

                    LabeledContent("Recommended backgrounds", value: homeWorldPreview.definition.recommendedBackgroundSummary)
                        .cogitatorPanelRow()

                    if !homeWorldPreview.compatibility.warningMessages.isEmpty {
                        ForEach(homeWorldPreview.compatibility.warningMessages, id: \.self) { warning in
                            Text(warning)
                                .cogitatorSupportingText()
                                .cogitatorPanelRow()
                        }
                    }
                } header: {
                    CogitatorSectionHeader("DHII Home World", subtitle: "Rulebook-backed Preview")
                } footer: {
                    Text("This preview is informational only. Background, role, aptitude composition, and starting package automation land in later DHII Engine phases.")
                        .cogitatorSupportingText()
                }
            }

            Section {
                TextField("Description", text: $draft.description, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityLabel("Description")
                    .accessibilityHint("Brief notes about origin, personality, and appearance.")
                    .cogitatorInputField()
                    .cogitatorPanelRow()
            } header: {
                CogitatorSectionHeader("Description", subtitle: "Narrative Notes")
            } footer: {
                Text("Changes save automatically while you edit.")
                    .cogitatorSupportingText()
            }
        }
        .formContentWidth()
        .formStyle(.grouped)
        .cogitatorFormRhythm()
        .cogitatorScreenChrome()
        .navigationTitle("Profile")
        .onAppear {
            if let latest = viewModel.character(by: characterID)?.profile {
                draft = latest
            }
        }
        .onChange(of: draft) { _, newValue in
            Task {
                await viewModel.autosaveCoordinator.scheduleSave(characterID: characterID, profile: newValue) { id, profile in
                    await viewModel.saveProfile(characterID: id, profile: profile)
                }
            }
        }
    }
}
#endif
