import Foundation
import Testing
@testable import DHCharList

@Test func characteristicAdvanceAppliesXPSpendAndProducesExplainableBreakdown() {
    let character = progressionSampleCharacter(name: "Advancement")
    let request = XPSpendRequest(
        character: character,
        upgrade: .characteristicAdvance(
            CharacteristicAdvance(
                characteristic: .strength,
                delta: 5,
                cost: 150,
                prerequisites: [
                    .requiredAptitude("Knowledge"),
                    .minimumCharacteristic(.toughness, 30)
                ]
            )
        )
    )

    let result = XPProgressionResolver.apply(request)

    #expect(result.isValid)
    #expect(result.cost == 150)
    #expect(result.availableExperience == 400)
    #expect(result.projectedRemainingExperience == 250)
    #expect(result.breakdown.prerequisiteEvaluations.map(\.isSatisfied) == [true, true, true])
    #expect(result.appliedCharacter?.characteristics.strength == 34)
    #expect(result.appliedCharacter?.resources.experienceSpent == 250)
    #expect(result.historyTitle == "Advancement: Strength +5")
    #expect(result.historyBody?.contains("Spent 150 XP on Strength +5.") == true)
}

@Test func xpSpendValidationRejectsInsufficientExperience() {
    let character = progressionSampleCharacter(name: "Overspend")
    let request = XPSpendRequest(
        character: character,
        upgrade: .characteristicAdvance(
            CharacteristicAdvance(characteristic: .agility, delta: 5, cost: 450)
        )
    )

    let result = XPProgressionResolver.validate(request)

    #expect(result.isValid == false)
    #expect(result.projectedRemainingExperience == -50)
    #expect(result.appliedCharacter == nil)
    #expect(result.validationErrors == [.insufficientExperience(required: 450, available: 400)])
}

@Test func xpSpendValidationExplainsUnmetPrerequisites() {
    let character = progressionSampleCharacter(name: "Blocked")
    let awareness = character.skills[0]
    let request = XPSpendRequest(
        character: character,
        upgrade: .skillAdvance(
            SkillAdvance(
                skillID: awareness.id,
                skillName: awareness.displayName,
                targetTraining: .experienced,
                cost: 100,
                prerequisites: [
                    .requiredAptitude("Offence"),
                    .requiredTalent("Rapid Reload"),
                    .requiredTrait("Unnatural Strength"),
                    .minimumCharacteristic(.ballisticSkill, 40),
                    .requiredSkill(name: "Medicae", minimumTraining: .known)
                ]
            )
        )
    )

    let result = XPProgressionResolver.validate(request)

    #expect(result.isValid == false)
    #expect(result.breakdown.prerequisiteEvaluations.count == 6)
    #expect(result.breakdown.prerequisiteEvaluations.filter(\.isSatisfied).count == 1)
    #expect(result.validationErrors.contains(.unmetPrerequisite(.requiredAptitude("Offence"))))
    #expect(result.validationErrors.contains(.unmetPrerequisite(.requiredTalent("Rapid Reload"))))
    #expect(result.validationErrors.contains(.unmetPrerequisite(.requiredTrait("Unnatural Strength"))))
    #expect(result.validationErrors.contains(.unmetPrerequisite(.minimumCharacteristic(.ballisticSkill, 40))))
    #expect(result.validationErrors.contains(.unmetPrerequisite(.requiredSkill(name: "Medicae", minimumTraining: .known))))
}

@Test func skillAdvanceRequiresHigherTrainingAndAppliesWhenValid() {
    let character = progressionSampleCharacter(name: "Skill Advance")
    let awareness = character.skills[0]
    let request = XPSpendRequest(
        character: character,
        upgrade: .skillAdvance(
            SkillAdvance(
                skillID: awareness.id,
                skillName: awareness.displayName,
                targetTraining: .experienced,
                cost: 200,
                prerequisites: [
                    .requiredSkill(name: "Awareness", minimumTraining: .trained),
                    .minimumCharacteristic(.perception, 35),
                    .requiredTalent("Meditation")
                ]
            )
        )
    )

    let result = XPProgressionResolver.apply(request)

    #expect(result.isValid)
    #expect(result.appliedCharacter?.skills.first?.training == .experienced)
    #expect(result.appliedCharacter?.resources.experienceSpent == 300)
}

@Test func registryBackedCharacteristicAdvanceUsesStructuredCatalogDefaults() {
    let character = progressionSampleCharacter(name: "Registry Characteristic")
    let upgrade = CharacteristicAdvanceCatalogRegistry
        .entry(for: .agility)
        .makeAdvance(
            costOverride: 100,
            extraPrerequisites: [.minimumCharacteristic(.agility, 40)]
        )

    let result = XPProgressionResolver.apply(
        XPSpendRequest(character: character, upgrade: .characteristicAdvance(upgrade))
    )

    #expect(result.isValid)
    #expect(result.cost == 100)
    #expect(result.appliedCharacter?.characteristics.agility == 46)
    #expect(result.appliedCharacter?.resources.experienceSpent == 200)
    #expect(result.breakdown.prerequisiteEvaluations.map(\.isSatisfied) == [true, true])
}

@Test func registryBackedTalentUnlockAppliesAndProducesExplainableHistory() throws {
    let character = progressionSampleCharacter(name: "Talent Unlock")
    let rapidReload = try #require(TalentCatalogRegistry.lookup(id: "rapid-reload"))
    let request = XPSpendRequest(
        character: character,
        upgrade: .talentUnlock(rapidReload.makeUnlock())
    )

    let result = XPProgressionResolver.apply(request)

    #expect(result.isValid)
    #expect(result.cost == 100)
    #expect(result.appliedCharacter?.notes.talents == ["Meditation", "Rapid Reload"])
    #expect(result.appliedCharacter?.resources.experienceSpent == 200)
    #expect(result.historyTitle == "Advancement: Talent: Rapid Reload")
    #expect(result.historyBody?.contains("Spent 100 XP on Talent: Rapid Reload.") == true)
}

@Test func registryBackedTalentUnlockValidationExplainsMissingPrerequisitesAndDuplicateTalent() throws {
    let character = progressionSampleCharacter(name: "Talent Validation")
    let weaponTech = try #require(TalentCatalogRegistry.lookup(id: "weapon-tech"))
    let missingPrerequisite = XPProgressionResolver.validate(
        XPSpendRequest(character: character, upgrade: .talentUnlock(weaponTech.makeUnlock()))
    )
    let meditation = try #require(TalentCatalogRegistry.lookup(id: "meditation"))
    let duplicateTalent = XPProgressionResolver.validate(
        XPSpendRequest(
            character: character,
            upgrade: .talentUnlock(meditation.makeUnlock())
        )
    )

    #expect(missingPrerequisite.isValid == false)
    #expect(
        missingPrerequisite.validationErrors
            == [.unmetPrerequisite(.requiredSkill(name: "Tech-Use", minimumTraining: .trained))]
    )
    #expect(
        missingPrerequisite.breakdown.prerequisiteEvaluations.map(\.detail)
            == [
                "400 XP currently available.",
                "Intelligence is currently 43.",
                "Tech-Use is currently Untrained."
            ]
    )

    #expect(duplicateTalent.isValid == false)
    #expect(
        duplicateTalent.validationErrors
            == [.invalidUpgrade("Talent unlocks must add a talent the character does not already know.")]
    )
}

@Test @MainActor func viewModelApplyXPSpendPersistsTalentUnlockAndAdvancementHistory() async throws {
    let fileURL = progressionUniqueTestFileURL("batch49-viewmodel-talent-unlock")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)
    let importService = CharacterJSONImportExportService()
    let source = progressionSampleCharacter(name: "ViewModel Talent Progression")

    try await useCases.upsertCharacter(source)

    let viewModel = progressionViewModel(useCases: useCases, importExportService: importService)
    await viewModel.load()

    let rapidReload = try #require(TalentCatalogRegistry.lookup(id: "rapid-reload"))
    let request = XPSpendRequest(
        character: source,
        upgrade: .talentUnlock(rapidReload.makeUnlock())
    )

    let updated = await viewModel.applyXPSpend(request)
    let persisted = try await useCases.fetchCharacter(id: source.id)

    #expect(updated?.notes.talents == ["Meditation", "Rapid Reload"])
    #expect(updated?.resources.experienceSpent == 200)
    #expect(updated?.history.first?.title == "Advancement: Talent: Rapid Reload")
    #expect(persisted?.history.first?.title == "Advancement: Talent: Rapid Reload")
    #expect(viewModel.character(by: source.id)?.notes.talents == ["Meditation", "Rapid Reload"])
}

@Test func invalidSkillAdvanceDoesNotAllowSameTrainingLevel() {
    let character = progressionSampleCharacter(name: "No Change")
    let awareness = character.skills[0]
    let request = XPSpendRequest(
        character: character,
        upgrade: .skillAdvance(
            SkillAdvance(
                skillID: awareness.id,
                skillName: awareness.displayName,
                targetTraining: .trained,
                cost: 50
            )
        )
    )

    let result = XPProgressionResolver.validate(request)

    #expect(result.isValid == false)
    #expect(result.validationErrors == [.invalidUpgrade("Skill advances in DH2 must be purchased one rank at a time.")])
}

@Test func xpSpendMessagesAndLabelsRemainExplainableForEdgeCases() {
    #expect(
        XPSpendValidationError.insufficientExperience(required: 200, available: 120).message
            == "Requires 200 XP but only 120 XP is currently available."
    )
    #expect(
        XPSpendValidationError.missingUpgradeTarget("Missing target").message
            == "Missing target"
    )
    #expect(
        XPSpendValidationError.invalidUpgrade("Bad upgrade").message
            == "Bad upgrade"
    )
    #expect(
        XPSpendValidationError.unmetPrerequisite(.requiredAptitude("")).message
            == "Requires aptitude Unnamed Aptitude."
    )

    #expect(XPSpendPrerequisite.availableExperience(150).label == "Available XP 150+")
    #expect(XPSpendPrerequisite.availableExperience(150).failureLabel == "Available XP 150+")
    #expect(
        XPSpendPrerequisite.minimumCharacteristic(.weaponSkill, 35).label
            == "Weapon Skill 35+"
    )
    #expect(
        XPSpendPrerequisite.requiredSkill(name: "", minimumTraining: .known).label
            == "Unnamed Skill Known+"
    )
    #expect(
        XPSpendPrerequisite.requiredSkill(name: "", minimumTraining: .known).failureLabel
            == "Requires Unnamed Skill at Known or higher."
    )
    #expect(
        XPSpendPrerequisite.requiredTalent("").failureLabel
            == "Requires talent Unnamed Talent."
    )
    #expect(
        XPSpendPrerequisite.requiredTrait("").failureLabel
            == "Requires trait Unnamed Trait."
    )
}

@Test func characteristicAdvanceValidationRejectsNegativeDeltaAndNegativeCost() {
    let character = progressionSampleCharacter(name: "Negative Advance")

    let negativeDelta = XPProgressionResolver.validate(
        XPSpendRequest(
            character: character,
            upgrade: .characteristicAdvance(
                CharacteristicAdvance(characteristic: .weaponSkill, delta: -5, cost: 100)
            )
        )
    )
    let negativeCost = XPProgressionResolver.validate(
        XPSpendRequest(
            character: character,
            upgrade: .characteristicAdvance(
                CharacteristicAdvance(characteristic: .weaponSkill, delta: 5, cost: -1)
            )
        )
    )

    #expect(negativeDelta.isValid == false)
    #expect(
        negativeDelta.validationErrors
            == [.invalidUpgrade("Characteristic advances must increase the selected characteristic.")]
    )
    #expect(negativeCost.isValid == false)
    #expect(
        negativeCost.validationErrors
            == [.invalidUpgrade("XP cost must be greater than 0.")]
    )
}

@Test func characteristicAdvanceValidationRejectsSkippingPastSingleDh2Step() {
    let character = progressionSampleCharacter(name: "Skip Characteristic")

    let result = XPProgressionResolver.validate(
        XPSpendRequest(
            character: character,
            upgrade: .characteristicAdvance(
                CharacteristicAdvance(characteristic: .weaponSkill, delta: 10, cost: 250)
            )
        )
    )

    #expect(result.isValid == false)
    #expect(
        result.validationErrors
            == [.invalidUpgrade("Characteristic advances in DH2 must be purchased as single +5 steps.")]
    )
}

@Test func skillAdvanceValidationRejectsSkippingIntermediateRanks() {
    let character = progressionSampleCharacter(name: "Skip Skill")
    let awareness = character.skills[0]

    let result = XPProgressionResolver.validate(
        XPSpendRequest(
            character: character,
            upgrade: .skillAdvance(
                SkillAdvance(
                    skillID: awareness.id,
                    skillName: awareness.displayName,
                    targetTraining: .veteran,
                    cost: 300
                )
            )
        )
    )

    #expect(result.isValid == false)
    #expect(
        result.validationErrors
            == [.invalidUpgrade("Skill advances in DH2 must be purchased one rank at a time.")]
    )
}

@Test func skillAdvanceValidationRejectsMissingSkillAndNegativeCost() {
    let character = progressionSampleCharacter(name: "Missing Skill")

    let missingSkill = XPProgressionResolver.validate(
        XPSpendRequest(
            character: character,
            upgrade: .skillAdvance(
                SkillAdvance(
                    skillID: UUID(),
                    skillName: "Forbidden Lore",
                    targetTraining: .known,
                    cost: 100
                )
            )
        )
    )
    let negativeCost = XPProgressionResolver.validate(
        XPSpendRequest(
            character: character,
            upgrade: .skillAdvance(
                SkillAdvance(
                    skillID: character.skills[0].id,
                    skillName: character.skills[0].displayName,
                    targetTraining: .veteran,
                    cost: -50
                )
            )
        )
    )

    #expect(missingSkill.isValid == false)
    #expect(
        missingSkill.validationErrors
            == [.missingUpgradeTarget("The selected skill no longer exists on this character.")]
    )
    #expect(negativeCost.isValid == false)
    #expect(
        negativeCost.validationErrors
            == [.invalidUpgrade("XP cost must be greater than 0.")]
    )
}

@Test func prerequisiteEvaluationMatchesNormalizedTokensAndAllTrainingRanks() {
    var character = progressionSampleCharacter(name: "Normalization")
    character.skills = [
        Skill(
            id: character.skills[0].id,
            name: "Tech-Use",
            characteristic: .intelligence,
            training: .veteran,
            specialisations: []
        )
    ]
    character.profile.aptitudes = [" Fieldcraft "]
    character.notes = NotesState(
        talents: ["Rapid-Reload"],
        traits: ["Dark Sight"],
        mutations: [],
        disorders: [],
        psychicPowers: [],
        specialAbilities: [],
        notes: ""
    )

    let request = XPSpendRequest(
        character: character,
        upgrade: .characteristicAdvance(
            CharacteristicAdvance(
                characteristic: .fellowship,
                delta: 5,
                cost: 50,
                prerequisites: [
                    .requiredAptitude("fieldcraft"),
                    .requiredTalent(" rapid reload "),
                    .requiredTrait("dark-sight"),
                    .requiredSkill(name: "tech use", minimumTraining: .untrained),
                    .requiredSkill(name: "tech use", minimumTraining: .known),
                    .requiredSkill(name: "tech use", minimumTraining: .trained),
                    .requiredSkill(name: "tech use", minimumTraining: .veteran)
                ]
            )
        )
    )

    let result = XPProgressionResolver.validate(request)

    #expect(result.isValid)
    #expect(result.breakdown.prerequisiteEvaluations.allSatisfy { $0.isSatisfied })
    #expect(result.breakdown.prerequisiteEvaluations[2].detail == "Character already knows rapid reload.")
    #expect(result.breakdown.prerequisiteEvaluations[3].detail == "Character already has dark-sight.")
    #expect(result.breakdown.prerequisiteEvaluations[4].detail == "tech use is currently Veteran.")
    #expect(result.breakdown.prerequisiteEvaluations[7].detail == "tech use is currently Veteran.")
}

@Test func requiredAptitudeUsesEngineBackedCompositionBeforeRawProfileFallback() {
    var character = progressionSampleCharacter(name: "Engine Aptitudes")
    character.profile.homeWorld = "Hive World"
    character.profile.background = "Adeptus Administratum"
    character.profile.role = "Seeker"
    character.profile.aptitudes = ["Knowledge"]

    let result = XPProgressionResolver.validate(
        XPSpendRequest(
            character: character,
            upgrade: .characteristicAdvance(
                CharacteristicAdvance(
                    characteristic: .fellowship,
                    delta: 5,
                    cost: 50,
                    prerequisites: [.requiredAptitude("Tech")]
                )
            )
        )
    )

    #expect(result.isValid)
    #expect(result.breakdown.prerequisiteEvaluations[1].detail == "Character already has Tech via DHII creation composition.")
}

@Test func characteristicAdvanceCanApplyAcrossAllCharacteristics() {
    let character = progressionSampleCharacter(name: "All Characteristics")
    let expectations: [(SkillCharacteristic, KeyPath<CharacteristicSet, Int>)] = [
        (.weaponSkill, \.weaponSkill),
        (.ballisticSkill, \.ballisticSkill),
        (.strength, \.strength),
        (.toughness, \.toughness),
        (.agility, \.agility),
        (.intelligence, \.intelligence),
        (.perception, \.perception),
        (.willpower, \.willpower),
        (.fellowship, \.fellowship)
    ]

    for (characteristic, keyPath) in expectations {
        let result = XPProgressionResolver.apply(
            XPSpendRequest(
                character: character,
                upgrade: .characteristicAdvance(
                    CharacteristicAdvance(characteristic: characteristic, delta: 5, cost: 1)
                )
            )
        )

        #expect(result.isValid)
        #expect(result.appliedCharacter?.characteristics[keyPath: keyPath] == character.characteristics[keyPath: keyPath] + 5)
    }
}

@Test @MainActor func viewModelApplyXPSpendPersistsCharacterAndAdvancementHistory() async throws {
    let fileURL = progressionUniqueTestFileURL("batch48-viewmodel-apply")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)
    let importService = CharacterJSONImportExportService()
    let source = progressionSampleCharacter(name: "ViewModel Progression")

    try await useCases.upsertCharacter(source)

    let viewModel = progressionViewModel(useCases: useCases, importExportService: importService)
    await viewModel.load()

    let request = XPSpendRequest(
        character: source,
        upgrade: .characteristicAdvance(
            CharacteristicAdvance(
                characteristic: .intelligence,
                delta: 5,
                cost: 100,
                prerequisites: [.requiredAptitude("Knowledge")]
            )
        )
    )

    let updated = await viewModel.applyXPSpend(request)
    let persisted = try await useCases.fetchCharacter(id: source.id)

    #expect(updated?.characteristics.intelligence == 48)
    #expect(updated?.resources.experienceSpent == 200)
    #expect(updated?.history.count == 1)
    #expect(updated?.history.first?.type == .advancement)
    #expect(updated?.history.first?.title == "Advancement: Intelligence +5")
    #expect(persisted?.history.first?.title == "Advancement: Intelligence +5")
    #expect(viewModel.character(by: source.id)?.resources.experienceSpent == 200)
}

@MainActor
private func progressionViewModel(
    useCases: CharacterUseCases,
    importExportService: CharacterJSONImportExportService
) -> CharacterListViewModel {
    CharacterListViewModel(
        useCases: useCases,
        importExportService: importExportService,
        armourCompendiumUseCases: ArmourCompendiumUseCases(
            repository: JSONFileArmourCompendiumRepository(
                fileURL: progressionUniqueTestFileURL("batch48-armour-compendium")
            )
        ),
        armourCompendiumImportService: ArmourCompendiumJSONImportService(),
        weaponCompendiumUseCases: WeaponCompendiumUseCases(
            repository: JSONFileWeaponCompendiumRepository(
                fileURL: progressionUniqueTestFileURL("batch48-weapon-compendium")
            )
        ),
        weaponCompendiumImportService: WeaponCompendiumJSONImportService()
    )
}

private func progressionUniqueTestFileURL(_ suffix: String) -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("dh-charlist-\(suffix)-\(UUID().uuidString).json")
}

private func progressionSampleCharacter(name: String) -> Character {
    let awareness = Skill(
        id: UUID(),
        name: "Awareness",
        characteristic: .perception,
        training: .trained,
        specialisations: ["Sight"]
    )
    let weapon = Weapon(
        id: UUID(),
        name: "Laspistol",
        type: "Pistol",
        range: "30m",
        damage: "1d10+2 E",
        penetration: "0",
        clip: "30",
        reload: "Half",
        traits: "Reliable"
    )

    return Character(
        id: UUID(),
        profile: Profile(
            name: name,
            homeWorld: "Hive World",
            background: "Adeptus Administratum",
            role: "Seeker",
            aptitudes: ["Knowledge", "Intelligence"],
            description: "Progression foundation fixture"
        ),
        characteristics: CharacteristicSet(
            weaponSkill: 31,
            ballisticSkill: 37,
            strength: 29,
            toughness: 34,
            agility: 41,
            intelligence: 43,
            perception: 38,
            willpower: 36,
            fellowship: 28
        ),
        resources: ResourceState(
            currentWounds: 10,
            maxWounds: 14,
            fatigue: 0,
            corruption: 0,
            insanity: 0,
            currentFate: 2,
            maxFate: 3,
            experienceSpent: 100,
            experienceTotal: 500
        ),
        skills: [awareness],
        notes: NotesState(
            talents: ["Meditation"],
            traits: ["Dark Sight"],
            mutations: [],
            disorders: [],
            psychicPowers: [],
            specialAbilities: [],
            notes: ""
        ),
        equipment: EquipmentState(
            weapons: [weapon],
            armour: [Armour(id: UUID(), location: "Body", armourPoints: 4)],
            movement: MovementProfile(halfMove: 3, fullMove: 6, charge: 9, run: 18),
            inventory: []
        ),
        session: SessionState(),
        history: [],
        updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
}
