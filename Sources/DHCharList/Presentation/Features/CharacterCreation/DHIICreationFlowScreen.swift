import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct DHIICreationFlowScreen: View {
    enum Mode: Equatable {
        case create
        case edit(UUID)
    }

    private enum Stage: Int, CaseIterable {
        case origin
        case choices
        case characteristics
        case review

        var title: String {
            switch self {
            case .origin: "Origin"
            case .choices: "Choices"
            case .characteristics: "Characteristics"
            case .review: "Review"
            }
        }
    }

    private enum GenerationMode: String, CaseIterable, Identifiable {
        case pointAllocation
        case randomRoll

        var id: String { rawValue }

        var title: String {
            switch self {
            case .pointAllocation: "Point Allocation"
            case .randomRoll: "Random Roll"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    private let mode: Mode
    @ObservedObject private var viewModel: CharacterListViewModel
    private let onComplete: (() -> Void)?

    @State private var name: String
    @State private var descriptionText: String
    @State private var draft: DHIICreationDraft
    @State private var stage: Stage = .origin
    @State private var generationMode: GenerationMode
    @State private var pointAllocationValues: DHIICreationCharacteristicValues
    @State private var rerollCharacteristic: DHIICreationCharacteristic?
    @State private var localErrorMessage: String?

    init(mode: Mode, viewModel: CharacterListViewModel, onComplete: (() -> Void)? = nil) {
        self.mode = mode
        self.viewModel = viewModel
        self.onComplete = onComplete

        let initialCharacter: Character? = switch mode {
        case .create:
            nil
        case .edit(let characterID):
            viewModel.character(by: characterID)
        }

        let initialDraft = initialCharacter.map(DHIICharacterCreationEngine.creationDraft(from:)) ?? DHIICharacterCreationEngine.creationDraft(from: .init())
        let initialGenerationMode: GenerationMode = switch initialDraft.characteristicGenerationState {
        case .randomRoll:
            .randomRoll
        case .pointAllocation, nil:
            .pointAllocation
        }
        let initialPointAllocation: DHIICreationCharacteristicValues = switch initialDraft.characteristicGenerationState {
        case .pointAllocation(let state):
            state.allocations
        default:
            .zero
        }
        let initialReroll = initialDraft.characteristicGeneration?.rerolledCharacteristic

        _name = State(initialValue: initialCharacter?.profile.name ?? "New Acolyte")
        _descriptionText = State(initialValue: initialCharacter?.profile.description ?? "")
        _draft = State(initialValue: initialDraft)
        _generationMode = State(initialValue: initialGenerationMode)
        _pointAllocationValues = State(initialValue: initialPointAllocation)
        _rerollCharacteristic = State(initialValue: initialReroll)
    }

    private var preview: DHIICreationStartingPackagePreview {
        switch mode {
        case .create:
            return DHIICharacterCreationEngine.previewStartingPackage(
                for: draft,
                baseCharacter: Character(
                    profile: Profile(
                        name: name,
                        description: descriptionText
                    )
                ),
                weaponCatalog: viewModel.weaponCompendiumCatalog,
                armourCatalog: viewModel.armourCompendiumCatalog
            )
        case .edit(let characterID):
            guard let character = viewModel.character(by: characterID) else {
                return DHIICreationStartingPackagePreview(
                    projectedCharacter: nil,
                    projectedInfluence: nil,
                    compatibility: .init(),
                    validationMessages: ["Character not found."]
                )
            }
            return DHIICharacterCreationEngine.reprojectExistingCharacter(
                character,
                with: draft,
                weaponCatalog: viewModel.weaponCompendiumCatalog,
                armourCatalog: viewModel.armourCompendiumCatalog
            )
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("Stage", selection: $stage) {
                    ForEach(Stage.allCases, id: \.self) { value in
                        Text(value.title).tag(value)
                    }
                }
                .accessibilityIdentifier("dhii-creation.stage-picker")
                .pickerStyle(.segmented)
                .cogitatorPanelRow()

                HStack {
                    Button("Back") {
                        guard let previousStage else { return }
                        stage = previousStage
                    }
                    .disabled(previousStage == nil)
                    .accessibilityIdentifier("dhii-creation.previous-stage")

                    Spacer()

                    Button(nextStage?.title ?? "Review") {
                        guard let nextStage else { return }
                        stage = nextStage
                    }
                    .disabled(nextStage == nil)
                    .accessibilityIdentifier("dhii-creation.next-stage")
                }
                .cogitatorPanelRow()
            } header: {
                CogitatorSectionHeader("DHII Creation", subtitle: modeSubtitle)
            } footer: {
                Text("The DHII Engine is the source of truth for supported creation rules here. Unsupported mechanics remain explicit instead of being guessed.")
                    .cogitatorSupportingText()
            }

            switch stage {
            case .origin:
                originStage
            case .choices:
                choicesStage
            case .characteristics:
                characteristicsStage
            case .review:
                reviewStage
            }

            if let localErrorMessage, localErrorMessage.isEmpty == false {
                Section {
                    Text(localErrorMessage)
                        .cogitatorSupportingText()
                        .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Validation", subtitle: "Needs Attention")
                }
            }
        }
        .formContentWidth()
        .formStyle(.grouped)
        .cogitatorFormRhythm()
        .cogitatorScreenChrome()
        .navigationTitle(mode == .create ? "DHII Creation" : "Edit DHII Creation")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(saveButtonTitle) {
                    Task { await save() }
                }
                .disabled(canSave == false)
                .accessibilityIdentifier("dhii-creation.save")
            }
        }
    }

    private var modeSubtitle: String {
        switch mode {
        case .create:
            "Guided Engine-backed Flow"
        case .edit:
            "Safe Reprojection"
        }
    }

    private var saveButtonTitle: String {
        switch mode {
        case .create:
            "Create"
        case .edit:
            "Save"
        }
    }

    private var canSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            && preview.projectedCharacter != nil
            && preview.validationMessages.isEmpty
    }

    private var previousStage: Stage? {
        guard let currentIndex = Stage.allCases.firstIndex(of: stage), currentIndex > 0 else {
            return nil
        }
        return Stage.allCases[currentIndex - 1]
    }

    private var nextStage: Stage? {
        guard let currentIndex = Stage.allCases.firstIndex(of: stage), currentIndex < Stage.allCases.count - 1 else {
            return nil
        }
        return Stage.allCases[currentIndex + 1]
    }

    private var originStage: some View {
        Group {
            Section {
                TextField("Character Name", text: $name)
                    .accessibilityIdentifier("dhii-creation.name")
                    .cogitatorPanelRow()
                TextField("Description", text: $descriptionText, axis: .vertical)
                    .lineLimit(2...4)
                    .accessibilityIdentifier("dhii-creation.description")
                    .cogitatorInputField()
                    .cogitatorPanelRow()
            } header: {
                CogitatorSectionHeader("Identity", subtitle: "Dossier Fields")
            }

            selectionSection(
                title: "Home World",
                subtitle: "Choose One",
                options: DHIICharacterCreationEngine.canonicalHomeWorlds.map { ($0.displayName, draft.homeWorldID == $0.id, "dhii-creation.home-world.\($0.id.rawValue)") },
                select: { label in
                    guard let selected = DHIICharacterCreationEngine.canonicalHomeWorlds.first(where: { $0.displayName == label }) else {
                        return
                    }
                    draft = draft.settingHomeWorld(selected.id)
                }
            )

            selectionSection(
                title: "Background",
                subtitle: "Choose One",
                options: DHIICharacterCreationEngine.canonicalBackgrounds.map { ($0.displayName, draft.backgroundID == $0.id, "dhii-creation.background.\($0.id.rawValue)") },
                select: { label in
                    guard let selected = DHIICharacterCreationEngine.canonicalBackgrounds.first(where: { $0.displayName == label }) else {
                        return
                    }
                    draft = draft.settingBackground(selected.id)
                }
            )

            selectionSection(
                title: "Role",
                subtitle: "Choose One",
                options: DHIICharacterCreationEngine.canonicalRoles.map { ($0.displayName, draft.roleID == $0.id, "dhii-creation.role.\($0.id.rawValue)") },
                select: { label in
                    guard let selected = DHIICharacterCreationEngine.canonicalRoles.first(where: { $0.displayName == label }) else {
                        return
                    }
                    draft = draft.settingRole(selected.id)
                }
            )

            Section {
                Button("Continue to Choices") {
                    stage = .choices
                }
                .accessibilityIdentifier("dhii-creation.advance-to-choices")
                .cogitatorPanelRow()
            }
        }
    }

    private var choicesStage: some View {
        Group {
            if draft.homeWorldTalentOptions.isEmpty == false {
                selectionSection(
                    title: "Home World Talent",
                    subtitle: "Explicit Choice",
                    options: draft.homeWorldTalentOptions.map { ($0, draft.homeWorldTalentChoice == $0, "dhii-creation.home-world-talent.\(normalizedID($0))") },
                    select: { draft = draft.settingHomeWorldTalentChoice($0) }
                )
            }

            if let backgroundDefinition = draft.backgroundDefinition, backgroundDefinition.aptitudeOptions.isEmpty == false {
                selectionSection(
                    title: "Background Aptitude",
                    subtitle: backgroundDefinition.displayName,
                    options: backgroundDefinition.aptitudeOptions.map { ($0, draft.backgroundAptitudeChoice == $0, "dhii-creation.background-aptitude.\(normalizedID($0))") },
                    select: { draft = draft.settingBackgroundAptitudeChoice($0) }
                )
            }

            if let roleDefinition = draft.roleDefinition {
                let roleChoices = roleDefinition.aptitudeRules.compactMap { rule -> String? in
                    if case .choice(let first, let second) = rule {
                        return [first, second].joined(separator: " / ")
                    }
                    return nil
                }
                if roleChoices.isEmpty == false {
                    selectionSection(
                        title: "Role Aptitude",
                        subtitle: roleDefinition.displayName,
                        options: roleChoices.flatMap { $0.components(separatedBy: " / ") }.map { ($0, draft.roleAptitudeChoice == $0, "dhii-creation.role-aptitude.\(normalizedID($0))") },
                        select: { draft = draft.settingRoleAptitudeChoice($0) }
                    )
                }
            }

            ForEach(Array(draft.backgroundSkillOptionGroups.enumerated()), id: \.offset) { index, group in
                selectionSection(
                    title: "Background Skill \(index + 1)",
                    subtitle: "Explicit Choice",
                    options: group.map { ($0, draft.backgroundSkillChoices[safe: index] == $0, "dhii-creation.background-skill.\(index).\(normalizedID($0))") },
                    select: { draft = draft.settingBackgroundSkillChoice($0, at: index) }
                )
            }

            if draft.backgroundTalentOptions.isEmpty == false {
                selectionSection(
                    title: "Background Talent",
                    subtitle: "Explicit Choice",
                    options: draft.backgroundTalentOptions.map { ($0, draft.backgroundTalentChoice == $0, "dhii-creation.background-talent.\(normalizedID($0))") },
                    select: { draft = draft.settingBackgroundTalentChoice($0) }
                )
            }

            ForEach(Array(draft.backgroundEquipmentOptionGroups.enumerated()), id: \.offset) { index, group in
                selectionSection(
                    title: "Background Equipment \(index + 1)",
                    subtitle: "Explicit Choice",
                    options: group.map { ($0, draft.backgroundEquipmentChoices[safe: index] == $0, "dhii-creation.background-equipment.\(index).\(normalizedID($0))") },
                    select: { draft = draft.settingBackgroundEquipmentChoice($0, at: index) }
                )
            }

            if draft.roleTalentOptions.isEmpty == false {
                selectionSection(
                    title: "Role Talent",
                    subtitle: "Explicit Choice",
                    options: draft.roleTalentOptions.map { ($0, draft.roleTalentChoice == $0, "dhii-creation.role-talent.\(normalizedID($0))") },
                    select: { draft = draft.settingRoleTalentChoice($0) }
                )
            }

            Section {
                Button("Roll Starting Wounds (1d5)") {
                    draft = draft.settingStartingWoundsRoll(Int.random(in: 1 ... 5))
                }
                .accessibilityIdentifier("dhii-creation.roll-wounds")
                .cogitatorPanelRow()

                LabeledContent("Current wounds roll", value: draft.startingWoundsRoll.map(String.init) ?? "—")
                    .cogitatorPanelRow()

                Button("Roll Starting Fate (1d10)") {
                    draft = draft.settingStartingFateRoll(Int.random(in: 1 ... 10))
                }
                .accessibilityIdentifier("dhii-creation.roll-fate")
                .cogitatorPanelRow()

                LabeledContent("Current fate roll", value: draft.startingFateRoll.map(String.init) ?? "—")
                    .cogitatorPanelRow()
            } header: {
                CogitatorSectionHeader("Starting Rolls", subtitle: "Explicit Gate")
            }

            Section {
                Button("Continue to Characteristics") {
                    stage = .characteristics
                }
                .accessibilityIdentifier("dhii-creation.advance-to-characteristics")
                .cogitatorPanelRow()
            }
        }
    }

    private var characteristicsStage: some View {
        Group {
            Section {
                Picker("Generation Mode", selection: $generationMode) {
                    ForEach(GenerationMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .cogitatorPanelRow()
            } header: {
                CogitatorSectionHeader("Generation", subtitle: "Choose a Supported Mode")
            }

            switch generationMode {
            case .pointAllocation:
                pointAllocationStage
            case .randomRoll:
                randomRollStage
            }

            Section {
                Button("Continue to Review") {
                    stage = .review
                }
                .accessibilityIdentifier("dhii-creation.advance-to-review")
                .cogitatorPanelRow()
            }
        }
    }

    private var pointAllocationStage: some View {
        let characteristicPreview = draft.characteristicGeneration

        return Group {
            Section {
                Button("Use Balanced Allocation") {
                    applyBalancedAllocation()
                }
                .accessibilityIdentifier("dhii-creation.point-allocation.balanced")
                .cogitatorPanelRow()

                ForEach(DHIICreationCharacteristic.allCases, id: \.self) { characteristic in
                    Stepper(
                        value: pointAllocationBinding(for: characteristic),
                        in: 0 ... pointAllocationCap(for: characteristic)
                    ) {
                        let value = pointAllocationValues[characteristic]
                        Text("\(characteristic.displayName): +\(value)")
                            .foregroundStyle(CogitatorPalette.textPrimary)
                    }
                    .accessibilityIdentifier("dhii-creation.point.\(characteristic.rawValue)")
                    .cogitatorPanelRow()
                }
            } header: {
                CogitatorSectionHeader("Point Allocation", subtitle: "60 Points, 40 Cap")
            } footer: {
                Text("Spent: \(pointAllocationValues.totalAllocatedPoints) / 60")
                    .cogitatorSupportingText()
            }

            if let characteristicPreview {
                Section {
                    LabeledContent("Remaining Points", value: characteristicPreview.remainingPoints.map(String.init) ?? "—")
                        .cogitatorPanelRow()
                    ForEach(DHIICreationCharacteristic.allCases, id: \.self) { characteristic in
                        if let breakdown = characteristicPreview.breakdown(for: characteristic) {
                            LabeledContent(characteristic.displayName, value: String(breakdown.finalValue))
                                .cogitatorPanelRow()
                        }
                    }
                } header: {
                    CogitatorSectionHeader("Preview", subtitle: "Explainable Totals")
                }
            }
        }
    }

    private var randomRollStage: some View {
        let characteristicPreview = draft.characteristicGeneration

        return Group {
            Section {
                Picker("Reroll", selection: Binding(
                    get: { rerollCharacteristic },
                    set: { rerollCharacteristic = $0 }
                )) {
                    Text("No Reroll").tag(Optional<DHIICreationCharacteristic>.none)
                    ForEach(DHIICreationCharacteristic.allCases, id: \.self) { characteristic in
                        Text(characteristic.displayName).tag(Optional(characteristic))
                    }
                }
                .cogitatorPanelRow()

                Button("Generate Random Characteristics") {
                    applyRandomGeneration()
                }
                .accessibilityIdentifier("dhii-creation.random-roll.generate")
                .cogitatorPanelRow()
            } header: {
                CogitatorSectionHeader("Random Roll", subtitle: "Standard DHII Formula")
            }

            if let characteristicPreview {
                Section {
                    ForEach(DHIICreationCharacteristic.allCases, id: \.self) { characteristic in
                        if let breakdown = characteristicPreview.breakdown(for: characteristic) {
                            let diceSummary = breakdown.rolledDice.map(String.init).joined(separator: ", ")
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(characteristic.displayName): \(breakdown.finalValue)")
                                    .foregroundStyle(CogitatorPalette.textPrimary)
                                Text("Rolled: \(diceSummary)")
                                    .cogitatorSupportingText()
                            }
                            .cogitatorPanelRow()
                        }
                    }
                } header: {
                    CogitatorSectionHeader("Preview", subtitle: "Rolled Breakdown")
                }
            }
        }
    }

    private var reviewStage: some View {
        Group {
            Section {
                LabeledContent("Name", value: name)
                    .cogitatorPanelRow()
                LabeledContent("Home World", value: draft.homeWorldDefinition?.displayName ?? "—")
                    .cogitatorPanelRow()
                LabeledContent("Background", value: draft.backgroundDefinition?.displayName ?? "—")
                    .cogitatorPanelRow()
                LabeledContent("Role", value: draft.roleDefinition?.displayName ?? "—")
                    .cogitatorPanelRow()
            } header: {
                CogitatorSectionHeader("Selection Summary", subtitle: "Canonical Picks")
            }

            if let projected = preview.projectedCharacter {
                Section {
                    LabeledContent("Aptitudes", value: projected.profile.aptitudes.joined(separator: ", "))
                        .cogitatorPanelRow()
                    LabeledContent("Wounds", value: "\(projected.resources.currentWounds) / \(projected.resources.maxWounds)")
                        .cogitatorPanelRow()
                    LabeledContent("Fate", value: "\(projected.resources.currentFate) / \(projected.resources.maxFate)")
                        .cogitatorPanelRow()
                    LabeledContent("Skills", value: "\(projected.skills.count)")
                        .cogitatorPanelRow()
                    LabeledContent("Weapons", value: "\(projected.equipment.weapons.count)")
                        .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Projected Character", subtitle: "Engine-backed Output")
                }
            }

            if preview.validationMessages.isEmpty == false {
                Section {
                    ForEach(preview.validationMessages, id: \.self) { message in
                        Text(message)
                            .cogitatorSupportingText()
                            .cogitatorPanelRow()
                    }
                } header: {
                    CogitatorSectionHeader("Missing Inputs", subtitle: "Projection Blockers")
                }
            }

            if preview.compatibility.warningMessages.isEmpty == false || preview.compatibility.contextualMessages.isEmpty == false {
                Section {
                    ForEach(preview.compatibility.contextualMessages, id: \.self) { message in
                        Text(message)
                            .cogitatorSupportingText()
                            .cogitatorPanelRow()
                    }
                    ForEach(preview.compatibility.warningMessages, id: \.self) { warning in
                        Text(warning)
                            .cogitatorSupportingText()
                            .cogitatorPanelRow()
                    }
                } header: {
                    CogitatorSectionHeader("Compatibility", subtitle: "Explicit Limits")
                }
            }
        }
    }

    @ViewBuilder
    private func selectionSection(
        title: String,
        subtitle: String,
        options: [(label: String, selected: Bool, identifier: String)],
        select: @escaping (String) -> Void
    ) -> some View {
        Section {
            ForEach(options, id: \.identifier) { option in
                Button {
                    select(option.label)
                } label: {
                    HStack {
                        Text(option.label)
                            .foregroundStyle(CogitatorPalette.textPrimary)
                        Spacer()
                        if option.selected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(CogitatorPalette.amber)
                        }
                    }
                }
                .accessibilityIdentifier(option.identifier)
                .cogitatorPanelRow()
            }
        } header: {
            CogitatorSectionHeader(title, subtitle: subtitle)
        }
    }

    private func pointAllocationBinding(for characteristic: DHIICreationCharacteristic) -> Binding<Int> {
        Binding(
            get: { pointAllocationValues[characteristic] },
            set: { newValue in
                var next = pointAllocationValues
                next[characteristic] = newValue
                do {
                    draft = try draft.settingPointAllocation(next)
                    pointAllocationValues = next
                    localErrorMessage = nil
                } catch {
                    localErrorMessage = error.localizedDescription
                }
            }
        )
    }

    private func pointAllocationCap(for characteristic: DHIICreationCharacteristic) -> Int {
        let base = DHIICharacterCreationEngine.pointAllocationBaseValue(
            for: characteristic,
            homeWorld: draft.homeWorldDefinition
        )
        return max(0, 40 - base)
    }

    private func applyBalancedAllocation() {
        let balanced = DHIICreationCharacteristicValues(
            weaponSkill: 10,
            ballisticSkill: 10,
            strength: 5,
            toughness: 5,
            agility: 5,
            intelligence: 5,
            perception: 5,
            willpower: 5,
            fellowship: 5,
            influence: 5
        )

        do {
            draft = try draft.settingPointAllocation(balanced)
            pointAllocationValues = balanced
            localErrorMessage = nil
        } catch {
            localErrorMessage = error.localizedDescription
        }
    }

    private func applyRandomGeneration() {
        let requiredRolls = DHIICreationCharacteristic.allCases.reduce(into: [Int]()) { partialResult, characteristic in
            let count = DHIICharacterCreationEngine.randomRollCount(
                for: characteristic,
                homeWorld: draft.homeWorldDefinition
            )
            partialResult.append(contentsOf: (0..<count).map { _ in Int.random(in: 1 ... 10) })
        }

        let rerollRolls: [Int]
        if let rerollCharacteristic {
            let count = DHIICharacterCreationEngine.randomRollCount(
                for: rerollCharacteristic,
                homeWorld: draft.homeWorldDefinition
            )
            rerollRolls = (0..<count).map { _ in Int.random(in: 1 ... 10) }
        } else {
            rerollRolls = []
        }

        do {
            draft = try DHIICharacterCreationEngine.generateRandomCharacteristics(
                for: draft,
                rolls: requiredRolls + rerollRolls,
                rerolling: rerollCharacteristic
            )
            localErrorMessage = nil
        } catch {
            localErrorMessage = error.localizedDescription
        }
    }

    private func save() async {
        switch mode {
        case .create:
            if await viewModel.createDHIICharacter(name: name, description: descriptionText, draft: draft) != nil {
                if let onComplete {
                    onComplete()
                } else {
                    dismiss()
                }
            }
        case .edit(let characterID):
            if await viewModel.updateDHIICharacter(characterID: characterID, name: name, description: descriptionText, draft: draft) != nil {
                if let onComplete {
                    onComplete()
                } else {
                    dismiss()
                }
            }
        }
    }

    private func normalizedID(_ value: String) -> String {
        value
            .lowercased()
            .map { $0.isLetter || $0.isNumber ? String($0) : "-" }
            .joined()
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
#endif
