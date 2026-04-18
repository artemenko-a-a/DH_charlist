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

            if let backgroundPreview = DHIICharacterCreationEngine.previewBackgroundSelection(
                rawValue: draft.background,
                homeWorldRawValue: draft.homeWorld
            ) {
                Section {
                    LabeledContent("Canonical background", value: backgroundPreview.definition.displayName)
                        .cogitatorPanelRow()
                    LabeledContent("Background Aptitude", value: backgroundPreview.definition.aptitudeSummary)
                        .cogitatorPanelRow()
                    LabeledContent("Starting skills", value: backgroundPreview.definition.startingSkillSummary)
                        .cogitatorPanelRow()
                    LabeledContent("Starting talents", value: backgroundPreview.definition.startingTalentSummary)
                        .cogitatorPanelRow()
                    LabeledContent("Starting traits", value: backgroundPreview.definition.startingTraitSummary)
                        .cogitatorPanelRow()
                    LabeledContent("Starting equipment", value: backgroundPreview.definition.startingEquipmentSummary)
                        .cogitatorPanelRow()
                    LabeledContent("Background Bonus", value: backgroundPreview.definition.backgroundBonus.name)
                        .cogitatorPanelRow()

                    Text(backgroundPreview.definition.backgroundBonus.summary)
                        .cogitatorSupportingText()
                        .cogitatorPanelRow()

                    LabeledContent("Recommended roles", value: backgroundPreview.definition.recommendedRoleSummary)
                        .cogitatorPanelRow()

                    ForEach(backgroundPreview.compatibility.contextualMessages, id: \.self) { message in
                        Text(message)
                            .cogitatorSupportingText()
                            .cogitatorPanelRow()
                    }

                    ForEach(backgroundPreview.compatibility.warningMessages, id: \.self) { warning in
                        Text(warning)
                            .cogitatorSupportingText()
                            .cogitatorPanelRow()
                    }
                } header: {
                    CogitatorSectionHeader("DHII Background", subtitle: "Rulebook-backed Preview")
                } footer: {
                    Text(([
                        "This preview is informational only. Background package application, role composition, and creation-time branching choices land in later DHII Engine phases."
                    ] + DHIICharacterCreationEngine.backgroundCreationNotes).joined(separator: " "))
                        .cogitatorSupportingText()
                }
            }

            if let rolePreview = DHIICharacterCreationEngine.previewRoleSelection(
                rawValue: draft.role,
                backgroundRawValue: draft.background
            ) {
                Section {
                    LabeledContent("Canonical role", value: rolePreview.definition.displayName)
                        .cogitatorPanelRow()
                    LabeledContent("Role Aptitudes", value: rolePreview.definition.aptitudeSummary)
                        .cogitatorPanelRow()
                    LabeledContent("Role talents", value: rolePreview.definition.roleTalentChoiceSummary)
                        .cogitatorPanelRow()
                    LabeledContent("Role Bonus", value: rolePreview.definition.roleBonus.name)
                        .cogitatorPanelRow()

                    Text(rolePreview.definition.roleBonus.summary)
                        .cogitatorSupportingText()
                        .cogitatorPanelRow()

                    ForEach(rolePreview.compatibility.contextualMessages, id: \.self) { message in
                        Text(message)
                            .cogitatorSupportingText()
                            .cogitatorPanelRow()
                    }

                    ForEach(rolePreview.compatibility.warningMessages, id: \.self) { warning in
                        Text(warning)
                            .cogitatorSupportingText()
                            .cogitatorPanelRow()
                    }
                } header: {
                    CogitatorSectionHeader("DHII Role", subtitle: "Rulebook-backed Preview")
                } footer: {
                    Text("This preview is informational only. Typed role choices, role bonus hooks, and creation-time elite advances land in later DHII Engine phases.")
                        .cogitatorSupportingText()
                }
            }

            if shouldShowAptitudeComposition {
                let composition = DHIICharacterCreationEngine.composeAptitudes(for: draft)

                Section {
                    if composition.resolvedAptitudes.isEmpty == false {
                        LabeledContent("Engine-resolved", value: composition.resolvedAptitudes.joined(separator: ", "))
                            .cogitatorPanelRow()
                    }

                    if composition.effectiveAptitudes.isEmpty == false {
                        LabeledContent("Effective Aptitudes", value: composition.effectiveAptitudes.joined(separator: ", "))
                            .cogitatorPanelRow()
                    }

                    if composition.legacyFallbackAptitudes.isEmpty == false {
                        Text("Legacy profile fallback: \(composition.legacyFallbackAptitudes.joined(separator: ", "))")
                            .cogitatorSupportingText()
                            .cogitatorPanelRow()
                    }

                    ForEach(composition.unresolvedChoices, id: \.self) { warning in
                        Text(warning)
                            .cogitatorSupportingText()
                            .cogitatorPanelRow()
                    }

                    ForEach(composition.compatibility.contextualMessages, id: \.self) { message in
                        Text(message)
                            .cogitatorSupportingText()
                            .cogitatorPanelRow()
                    }
                } header: {
                    CogitatorSectionHeader("DHII Aptitudes", subtitle: "Composed Creation Preview")
                } footer: {
                    Text("Fixed DHII package aptitudes are composed automatically here. Choice-driven aptitude slots still require a later typed creation state, so unresolved slots remain explicit until that engine phase lands.")
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

    private var shouldShowAptitudeComposition: Bool {
        let draftHasCreationInput =
            draft.homeWorld.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            || draft.background.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            || draft.role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            || draft.aptitudes.isEmpty == false

        guard draftHasCreationInput else {
            return false
        }

        let composition = DHIICharacterCreationEngine.composeAptitudes(for: draft)
        return composition.resolvedAptitudes.isEmpty == false
            || composition.effectiveAptitudes.isEmpty == false
            || composition.unresolvedChoices.isEmpty == false
            || composition.compatibility.contextualMessages.isEmpty == false
    }
}
#endif
