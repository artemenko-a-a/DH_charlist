import Foundation
import Testing
@testable import DHCharList

@Test func homeWorldPreviewResolvesCanonicalNamesAndAliases() {
    let hive = try! #require(DHIICharacterCreationEngine.previewHomeWorldSelection(rawValue: "Hive"))
    let shrine = try! #require(DHIICharacterCreationEngine.previewHomeWorldSelection(rawValue: " shrine world "))

    #expect(hive.definition.id == .hiveWorld)
    #expect(hive.definition.displayName == "Hive World")
    #expect(shrine.definition.id == .shrineWorld)
    #expect(DHIICharacterCreationEngine.previewHomeWorldSelection(rawValue: "Unknown World") == nil)
}

@Test func shrineWorldPreviewCarriesRulebookBackedStartingValues() {
    let preview = try! #require(DHIICharacterCreationEngine.previewHomeWorldSelection(rawValue: "Shrine World"))

    #expect(preview.definition.characteristicModifierSummary == "+Fellowship, +Willpower, -Perception")
    #expect(preview.definition.fateThreshold == DHIIFateThresholdRule(baseThreshold: 3, emperorsBlessingTarget: 6))
    #expect(preview.definition.aptitude == "Willpower")
    #expect(preview.definition.wounds.summary == "7+1d5")
    #expect(preview.definition.homeWorldBonus.name == "Faith in the Creed")
    #expect(preview.definition.recommendedBackgrounds == ["Adeptus Administratum", "Adeptus Arbites", "Adeptus Ministorum", "Imperial Guard"])
}

@Test func influenceBasedHomeWorldEffectsAreFlaggedAsCurrentModelGap() {
    let feral = try! #require(DHIICharacterCreationEngine.previewHomeWorldSelection(rawValue: "Feral World"))
    let highborn = try! #require(DHIICharacterCreationEngine.previewHomeWorldSelection(rawValue: "Highborn"))
    let voidborn = try! #require(DHIICharacterCreationEngine.previewHomeWorldSelection(rawValue: "Voidborn"))

    #expect(feral.compatibility.unsupportedTargets == [.influence])
    #expect(highborn.compatibility.unsupportedTargets == [.influence])
    #expect(voidborn.compatibility.unsupportedTargets.isEmpty)
    #expect(feral.compatibility.warningMessages.first?.contains("Influence") == true)
}

@Test func canonicalHomeWorldCatalogStaysCompleteAndUnique() {
    let definitions = DHIICharacterCreationEngine.canonicalHomeWorlds

    #expect(definitions.count == 6)
    #expect(Set(definitions.map(\.id)).count == definitions.count)
    #expect(Set(definitions.map(\.displayName)).count == definitions.count)
}

@Test func backgroundPreviewResolvesCanonicalNamesAndAliases() {
    let arbites = try! #require(
        DHIICharacterCreationEngine.previewBackgroundSelection(
            rawValue: " arbites ",
            homeWorldRawValue: "Hive"
        )
    )
    let mechanicus = try! #require(
        DHIICharacterCreationEngine.previewBackgroundSelection(
            rawValue: "adeptus mechanicus",
            homeWorldRawValue: "Forge World"
        )
    )

    #expect(arbites.definition.id == .adeptusArbites)
    #expect(arbites.definition.displayName == "Adeptus Arbites")
    #expect(arbites.compatibility.contextualMessages.contains("Current home world preview recommends this background."))

    #expect(mechanicus.definition.id == .adeptusMechanicus)
    #expect(DHIICharacterCreationEngine.previewBackgroundSelection(rawValue: "Unknown Background") == nil)
}

@Test func adeptusMechanicusBackgroundPreviewCarriesRulebookBackedPackageSummary() {
    let preview = try! #require(DHIICharacterCreationEngine.previewBackgroundSelection(rawValue: "Adeptus Mechanicus"))

    #expect(preview.definition.aptitudeOptions == ["Knowledge", "Tech"])
    #expect(preview.definition.startingSkillSummary.contains("Tech-Use"))
    #expect(preview.definition.startingTalentSummary.contains("Mechadendrite Use (Utility)"))
    #expect(preview.definition.startingTraitSummary == "Mechanicus Implants")
    #expect(preview.definition.startingEquipmentSummary.contains("Autogun or hand cannon"))
    #expect(preview.definition.backgroundBonus.name == "Replace the Weak Flesh")
    #expect(preview.definition.backgroundBonus.summary.contains("cybernetics"))
    #expect(preview.definition.recommendedRoleSummary == "Chirurgeon, Hierophant, Sage, Seeker")
}

@Test func backgroundCompatibilityFlagsUnsupportedCurrentModelRules() {
    let telepathica = try! #require(
        DHIICharacterCreationEngine.previewBackgroundSelection(
            rawValue: "Adeptus Astra Telepathica",
            homeWorldRawValue: "Voidborn"
        )
    )
    let outcast = try! #require(
        DHIICharacterCreationEngine.previewBackgroundSelection(
            rawValue: "Outcast",
            homeWorldRawValue: "Highborn"
        )
    )

    #expect(telepathica.compatibility.unsupportedRuleKeys.contains("psychic_phenomena_modifier"))
    #expect(telepathica.compatibility.unsupportedRuleKeys.contains("conditional_creation_hook"))
    #expect(telepathica.compatibility.warningMessages.contains { $0.contains("Sanctioned") })

    #expect(outcast.compatibility.unsupportedRuleKeys == ["fatigue_threshold_modifier"])
    #expect(outcast.compatibility.contextualMessages.contains("Current home world preview does not list this among its recommended backgrounds."))
}

@Test func canonicalBackgroundCatalogStaysCompleteAndUnique() {
    let definitions = DHIICharacterCreationEngine.canonicalBackgrounds

    #expect(definitions.count == 7)
    #expect(Set(definitions.map(\.id)).count == definitions.count)
    #expect(Set(definitions.map(\.displayName)).count == definitions.count)
}

@Test func rolePreviewResolvesCanonicalNamesAndAliases() {
    let seeker = try! #require(
        DHIICharacterCreationEngine.previewRoleSelection(
            rawValue: " seeker ",
            backgroundRawValue: "Adeptus Administratum"
        )
    )
    let mystic = try! #require(
        DHIICharacterCreationEngine.previewRoleSelection(
            rawValue: "Mystic",
            backgroundRawValue: "Adeptus Astra Telepathica"
        )
    )

    #expect(seeker.definition.id == .seeker)
    #expect(seeker.definition.displayName == "Seeker")
    #expect(seeker.compatibility.contextualMessages.contains("Current background preview recommends this role."))

    #expect(mystic.definition.id == .mystic)
    #expect(DHIICharacterCreationEngine.previewRoleSelection(rawValue: "Unknown Role") == nil)
}

@Test func mysticRolePreviewCarriesRulebookBackedPackageSummary() {
    let preview = try! #require(DHIICharacterCreationEngine.previewRoleSelection(rawValue: "Mystic"))

    #expect(preview.definition.aptitudeSummary == "Defence, Intelligence, Knowledge, Perception, Willpower")
    #expect(preview.definition.roleTalentChoiceSummary == "Resistance (Psychic Powers) or Warp Sense")
    #expect(preview.definition.roleBonus.name == "Stare into the Warp")
    #expect(preview.definition.roleBonus.summary.contains("Psyker elite advance"))
    #expect(preview.compatibility.unsupportedRuleKeys.contains("psyker_elite_advance_hook"))
    #expect(preview.compatibility.warningMessages.contains { $0.contains("Psyker elite advance") })
}

@Test func canonicalRoleCatalogStaysCompleteAndUnique() {
    let definitions = DHIICharacterCreationEngine.canonicalRoles

    #expect(definitions.count == 8)
    #expect(Set(definitions.map(\.id)).count == definitions.count)
    #expect(Set(definitions.map(\.displayName)).count == definitions.count)
}

@Test func aptitudeCompositionUsesCanonicalSelectionsAndLegacyFallbackForChoiceSlots() {
    let profile = Profile(
        name: "Resolver",
        homeWorld: "Hive World",
        background: "Adeptus Administratum",
        role: "Seeker",
        aptitudes: ["Knowledge"],
        description: ""
    )

    let composition = DHIICharacterCreationEngine.composeAptitudes(for: profile)

    #expect(composition.resolvedAptitudes == ["Perception", "Knowledge", "Fellowship", "Intelligence", "Social", "Tech"])
    #expect(composition.effectiveAptitudes == ["Perception", "Knowledge", "Fellowship", "Intelligence", "Social", "Tech"])
    #expect(composition.isFullyResolved)
    #expect(composition.unresolvedChoices.isEmpty)
    #expect(composition.compatibility.warningMessages.isEmpty)
}

@Test func aptitudeCompositionFlagsUnresolvedChoiceSlotsWhenSelectionsNeedTypedChoices() {
    let profile = Profile(
        name: "Partial",
        homeWorld: "Hive World",
        background: "Adeptus Administratum",
        role: "Assassin",
        aptitudes: [],
        description: ""
    )

    let composition = DHIICharacterCreationEngine.composeAptitudes(for: profile)

    #expect(composition.resolvedAptitudes == ["Perception", "Agility", "Fieldcraft", "Finesse"])
    #expect(composition.effectiveAptitudes == ["Perception", "Agility", "Fieldcraft", "Finesse"])
    #expect(composition.isFullyResolved == false)
    #expect(composition.unresolvedChoices.count == 2)
    #expect(composition.unresolvedChoices.contains { $0.contains("Adeptus Administratum") })
    #expect(composition.unresolvedChoices.contains { $0.contains("Assassin") })
    #expect(composition.compatibility.warningMessages.count == 2)
}

@Test func creationDraftInfersCanonicalSelectionsAndSeparatesChoiceProvenanceFromLegacyFallback() {
    let profile = Profile(
        name: "Drafted",
        homeWorld: "Hive World",
        background: "Administratum",
        role: "Assassin",
        aptitudes: ["Social", "Weapon Skill", "Tech"],
        description: "Legacy snapshot"
    )

    let draft = DHIICharacterCreationEngine.creationDraft(from: profile)

    #expect(draft.homeWorldID == .hiveWorld)
    #expect(draft.backgroundID == .adeptusAdministratum)
    #expect(draft.roleID == .assassin)
    #expect(draft.backgroundAptitudeChoice == "Social")
    #expect(draft.roleAptitudeChoice == "Weapon Skill")
    #expect(draft.legacyFallbackAptitudes == ["Tech"])
    #expect(draft.aptitudeComposition.resolvedAptitudes == ["Perception", "Social", "Agility", "Weapon Skill", "Fieldcraft", "Finesse"])
    #expect(draft.aptitudeComposition.effectiveAptitudes == ["Perception", "Social", "Agility", "Weapon Skill", "Fieldcraft", "Finesse", "Tech"])
    #expect(draft.aptitudeComposition.isFullyResolved)
}

@Test func changingBackgroundPrunesNoLongerApplicableChoiceStateWithoutReconsumingLegacyFallback() {
    let original = DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: "Shifted",
            homeWorld: "Hive World",
            background: "Administratum",
            role: "Assassin",
            aptitudes: ["Social", "Weapon Skill", "Tech"]
        )
    )

    let recomposed = original.settingBackground(.adeptusMechanicus)

    #expect(recomposed.backgroundID == .adeptusMechanicus)
    #expect(recomposed.backgroundAptitudeChoice == nil)
    #expect(recomposed.roleID == .assassin)
    #expect(recomposed.roleAptitudeChoice == "Weapon Skill")
    #expect(recomposed.legacyFallbackAptitudes == ["Tech"])
    #expect(recomposed.aptitudeComposition.resolvedAptitudes == ["Perception", "Agility", "Weapon Skill", "Fieldcraft", "Finesse"])
    #expect(recomposed.aptitudeComposition.effectiveAptitudes == ["Perception", "Agility", "Weapon Skill", "Fieldcraft", "Finesse", "Tech"])
    #expect(recomposed.aptitudeComposition.unresolvedChoices == [
        "Adeptus Mechanicus: requires an explicit aptitude choice (Knowledge or Tech) that the current typed creation state does not yet store."
    ])
}

@Test func changingRolePrunesStaleRoleChoiceAndKeepsOtherValidSelections() {
    let original = DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: "Shifted",
            homeWorld: "Hive World",
            background: "Administratum",
            role: "Assassin",
            aptitudes: ["Social", "Weapon Skill", "Tech"]
        )
    )

    let recomposed = original.settingRole(.sage)

    #expect(recomposed.backgroundID == .adeptusAdministratum)
    #expect(recomposed.backgroundAptitudeChoice == "Social")
    #expect(recomposed.roleID == .sage)
    #expect(recomposed.roleAptitudeChoice == nil)
    #expect(recomposed.legacyFallbackAptitudes == ["Tech"])
    #expect(recomposed.aptitudeComposition.resolvedAptitudes == ["Perception", "Social", "Intelligence", "Knowledge", "Tech", "Willpower"])
    #expect(recomposed.aptitudeComposition.effectiveAptitudes == ["Perception", "Social", "Intelligence", "Knowledge", "Tech", "Willpower"])
    #expect(recomposed.aptitudeComposition.unresolvedChoices.isEmpty)
}

@Test func creationDraftKeepsUnknownFreeformSelectionsExplicitInsteadOfPretendingTheyAreCanonical() {
    let draft = DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: "Unknown",
            homeWorld: "Dust Bowl",
            background: "Street Mystic",
            role: "Sniper",
            aptitudes: ["Warpcraft"]
        )
    )

    #expect(draft.homeWorldID == nil)
    #expect(draft.backgroundID == nil)
    #expect(draft.roleID == nil)
    #expect(draft.legacyFallbackAptitudes == ["Warpcraft"])
    #expect(draft.aptitudeComposition.effectiveAptitudes == ["Warpcraft"])
    #expect(draft.aptitudeComposition.compatibility.contextualMessages == [
        "Home world is not yet a canonical DHII selection, so its aptitude could not be composed.",
        "Background is not yet a canonical DHII selection, so its aptitude choice could not be composed.",
        "Role is not yet a canonical DHII selection, so its aptitudes could not be composed."
    ])
}

@Test func creationDraftLeavesAmbiguousLegacyChoiceMatchesUnresolved() {
    let draft = DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: "Ambiguous",
            homeWorld: "Hive World",
            background: "Adeptus Administratum",
            role: "Assassin",
            aptitudes: ["Knowledge", "Social", "Weapon Skill", "Ballistic Skill"]
        )
    )

    #expect(draft.backgroundAptitudeChoice == nil)
    #expect(draft.roleAptitudeChoice == nil)
    #expect(draft.legacyFallbackAptitudes == ["Knowledge", "Social", "Weapon Skill", "Ballistic Skill"])
    #expect(draft.aptitudeComposition.unresolvedChoices == [
        "Adeptus Administratum: requires an explicit aptitude choice (Knowledge or Social) that the current typed creation state does not yet store.",
        "Assassin: requires an explicit aptitude choice (Ballistic Skill or Weapon Skill) that the current typed creation state does not yet store."
    ])
}

@Test func creationDraftSelectionSettersValidateChoicesAndClearUnknownInputs() {
    let unknownDraft = DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: "Unknown",
            homeWorld: "Dust Bowl",
            background: "Street Mystic",
            role: "Sniper",
            aptitudes: ["Warpcraft"]
        )
    )

    let resolved = unknownDraft
        .settingHomeWorld(.forgeWorld)
        .settingBackground(.adeptusMechanicus)
        .settingBackgroundAptitudeChoice("Tech")
        .settingRole(.assassin)
        .settingRoleAptitudeChoice("Weapon Skill")

    #expect(resolved.homeWorldID == .forgeWorld)
    #expect(resolved.backgroundID == .adeptusMechanicus)
    #expect(resolved.backgroundAptitudeChoice == "Tech")
    #expect(resolved.roleID == .assassin)
    #expect(resolved.roleAptitudeChoice == "Weapon Skill")
    #expect(resolved.aptitudeComposition.resolvedAptitudes == ["Intelligence", "Tech", "Agility", "Weapon Skill", "Fieldcraft", "Finesse", "Perception"])
    #expect(resolved.aptitudeComposition.compatibility.contextualMessages.isEmpty)

    let invalidated = resolved
        .settingBackgroundAptitudeChoice("Social")
        .settingRoleAptitudeChoice("Willpower")

    #expect(invalidated.backgroundAptitudeChoice == nil)
    #expect(invalidated.roleAptitudeChoice == nil)
    #expect(invalidated.aptitudeComposition.unresolvedChoices == [
        "Adeptus Mechanicus: requires an explicit aptitude choice (Knowledge or Tech) that the current typed creation state does not yet store.",
        "Assassin: requires an explicit aptitude choice (Ballistic Skill or Weapon Skill) that the current typed creation state does not yet store."
    ])
}

@Test func randomCharacteristicGenerationSupportsHomeWorldModifiersSingleRerollAndTransientInfluence() throws {
    let draft = DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: "Rolled",
            homeWorld: "Hive World",
            background: "Adeptus Administratum",
            role: "Seeker"
        )
    )

    let generated = try DHIICharacterCreationEngine.generateRandomCharacteristics(
        for: draft,
        rolls: [
            4, 7,
            5, 6,
            2, 9,
            1, 8,
            3, 4, 6,
            5, 7,
            2, 2, 9,
            8, 8, 8,
            4, 4,
            6, 6,
            10, 1, 1
        ],
        rerolling: .willpower
    )

    let preview = try #require(generated.characteristicGeneration)

    #expect(preview.mode == .randomRoll)
    #expect(preview.isValid)
    #expect(preview.rerolledCharacteristic == .willpower)
    #expect(preview.values?.weaponSkill == 31)
    #expect(preview.values?.ballisticSkill == 31)
    #expect(preview.values?.strength == 31)
    #expect(preview.values?.toughness == 29)
    #expect(preview.values?.agility == 30)
    #expect(preview.values?.intelligence == 32)
    #expect(preview.values?.perception == 31)
    #expect(preview.values?.willpower == 22)
    #expect(preview.values?.fellowship == 28)
    #expect(preview.values?.influence == 32)
    #expect(preview.projectedCharacteristics == CharacteristicSet(
        weaponSkill: 31,
        ballisticSkill: 31,
        strength: 31,
        toughness: 29,
        agility: 30,
        intelligence: 32,
        perception: 31,
        willpower: 22,
        fellowship: 28
    ))
    #expect(preview.compatibility.unsupportedTargets == [.influence])

    let agility = try #require(preview.breakdown(for: .agility))
    #expect(agility.rolledDice == [3, 4, 6])
    #expect(agility.keptDice == [6, 4])
    #expect(agility.finalValue == 30)

    let willpower = try #require(preview.breakdown(for: .willpower))
    #expect(willpower.rolledDice == [10, 1, 1])
    #expect(willpower.keptDice == [1, 1])
    #expect(willpower.finalValue == 22)
}

@Test func pointAllocationGenerationTracksRemainingPointsAndProjectsSupportedCharacteristics() throws {
    let draft = DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: "Allocated",
            homeWorld: "Shrine World",
            background: "Adeptus Administratum",
            role: "Hierophant"
        )
    )

    let allocated = try draft.settingPointAllocation(
        DHIICreationCharacteristicValues(
            weaponSkill: 5,
            ballisticSkill: 5,
            strength: 5,
            toughness: 5,
            agility: 5,
            intelligence: 5,
            perception: 5,
            willpower: 10,
            fellowship: 10,
            influence: 5
        )
    )

    let preview = try #require(allocated.characteristicGeneration)

    #expect(preview.mode == .pointAllocation)
    #expect(preview.isValid)
    #expect(preview.spentPoints == 60)
    #expect(preview.remainingPoints == 0)
    #expect(preview.values?.perception == 25)
    #expect(preview.values?.willpower == 40)
    #expect(preview.values?.fellowship == 40)
    #expect(preview.values?.influence == 30)
    #expect(preview.projectedCharacteristics == CharacteristicSet(
        weaponSkill: 30,
        ballisticSkill: 30,
        strength: 30,
        toughness: 30,
        agility: 30,
        intelligence: 30,
        perception: 25,
        willpower: 40,
        fellowship: 40
    ))
    #expect(preview.compatibility.unsupportedTargets == [.influence])

    let fellowship = try #require(preview.breakdown(for: .fellowship))
    #expect(fellowship.finalValue == 40)
    #expect(fellowship.contributions.map(\.label) == ["Base Value", "Home World Modifier", "Allocated Points"])
    #expect(fellowship.contributions.map(\.value) == [25, 5, 10])
}

@Test func pointAllocationRejectsOverspendAndCapViolations() {
    let neutralDraft = DHIICharacterCreationEngine.creationDraft(from: Profile(name: "Overspend"))
    let shrineDraft = DHIICharacterCreationEngine.creationDraft(
        from: Profile(name: "Cap", homeWorld: "Shrine World")
    )

    #expect(throws: DHIICharacteristicGenerationValidationError.self) {
        _ = try neutralDraft.settingPointAllocation(
            DHIICreationCharacteristicValues(
                weaponSkill: 6,
                ballisticSkill: 6,
                strength: 6,
                toughness: 6,
                agility: 6,
                intelligence: 6,
                perception: 6,
                willpower: 6,
                fellowship: 6,
                influence: 7
            )
        )
    }

    #expect(throws: DHIICharacteristicGenerationValidationError.self) {
        _ = try shrineDraft.settingPointAllocation(
            DHIICreationCharacteristicValues(
                weaponSkill: 5,
                ballisticSkill: 5,
                strength: 5,
                toughness: 5,
                agility: 5,
                intelligence: 5,
                perception: 5,
                willpower: 11,
                fellowship: 9,
                influence: 5
            )
        )
    }
}

@Test func pointAllocationRecomposesAcrossHomeWorldChangesAndCanBecomeInvalid() throws {
    let neutralDraft = DHIICharacterCreationEngine.creationDraft(from: Profile(name: "Recompose"))
    let allocated = try neutralDraft.settingPointAllocation(
        DHIICreationCharacteristicValues(
            weaponSkill: 5,
            ballisticSkill: 5,
            strength: 5,
            toughness: 5,
            agility: 5,
            intelligence: 5,
            perception: 15,
            willpower: 5,
            fellowship: 5,
            influence: 5
        )
    )

    let hiveShifted = allocated.settingHomeWorld(.hiveWorld)
    let preview = try #require(hiveShifted.characteristicGeneration)

    #expect(preview.mode == .pointAllocation)
    #expect(preview.isValid == false)
    #expect(preview.values?.perception == 45)
    #expect(preview.validationMessages.contains {
        $0.contains("Perception") && $0.contains("40")
    })
}

@Test func randomCharacteristicGenerationBecomesInvalidWhenHomeWorldChangesAfterRolling() throws {
    let hiveDraft = DHIICharacterCreationEngine.creationDraft(
        from: Profile(name: "Shifted", homeWorld: "Hive World")
    )
    let generated = try DHIICharacterCreationEngine.generateRandomCharacteristics(
        for: hiveDraft,
        rolls: [
            4, 7,
            5, 6,
            2, 9,
            1, 8,
            3, 4, 6,
            5, 7,
            2, 2, 9,
            8, 8, 8,
            4, 4,
            6, 6
        ]
    )

    let shifted = generated.settingHomeWorld(.forgeWorld)
    let preview = try #require(shifted.characteristicGeneration)

    #expect(preview.mode == .randomRoll)
    #expect(preview.isValid == false)
    #expect(preview.projectedCharacteristics == nil)
    #expect(preview.validationMessages.contains {
        $0.contains("Hive World") && $0.contains("Forge World")
    })
}
