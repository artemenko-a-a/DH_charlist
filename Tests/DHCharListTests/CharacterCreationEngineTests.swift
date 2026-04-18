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

@Test func startingPackageProjectionBuildsResolvedImperialGuardWarriorPackage() throws {
    let baseDraft = DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: "Guardsman",
            homeWorld: "Hive World",
            background: "Imperial Guard",
            role: "Warrior"
        )
    )

    let generated = try baseDraft.settingPointAllocation(
        DHIICreationCharacteristicValues(
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
    )

    let resolved = generated
        .settingBackgroundAptitudeChoice("Fieldcraft")
        .settingBackgroundSkillChoice("Operate (Surface)", at: 0)
        .settingBackgroundEquipmentChoice("Lasgun", at: 0)
        .settingRoleTalentChoice("Rapid Reload")
        .settingStartingWoundsRoll(2)
        .settingStartingFateRoll(7)

    let preview = DHIICharacterCreationEngine.previewStartingPackage(for: resolved)
    let projected = try #require(preview.projectedCharacter)

    #expect(preview.isValid)
    #expect(preview.validationMessages.isEmpty)
    #expect(preview.projectedInfluence == 30)
    #expect(projected.profile.homeWorld == "Hive World")
    #expect(projected.profile.background == "Imperial Guard")
    #expect(projected.profile.role == "Warrior")
    #expect(projected.profile.aptitudes == [
        "Perception", "Fieldcraft", "Ballistic Skill", "Defence", "Offence", "Strength", "Weapon Skill"
    ])
    #expect(projected.resources == ResourceState(
        currentWounds: 10,
        maxWounds: 10,
        fatigue: 0,
        corruption: 0,
        insanity: 0,
        currentFate: 3,
        maxFate: 3,
        experienceSpent: 0,
        experienceTotal: 1_000
    ))
    #expect(projected.skills.contains {
        $0.name == "Athletics" && $0.characteristic == .strength && $0.training == .known
    })
    #expect(projected.skills.contains {
        $0.name == "Operate (Surface)" && $0.characteristic == .agility && $0.training == .known && $0.specialisations == ["Surface"]
    })
    #expect(projected.notes.talents.contains("Rapid Reload"))
    #expect(projected.notes.talents.contains("Weapon Training (Las, Low-Tech)"))
    #expect(projected.notes.specialAbilities.contains("Hammer of the Emperor: Damage dice showing 1 or 2 can be re-rolled against a target an ally attacked since the end of the character's last turn."))
    #expect(projected.notes.specialAbilities.contains("Expert at Violence: After a successful attack and before hits are determined, the character can spend a Fate point to replace attack-roll degrees of success with Weapon Skill bonus or Ballistic Skill bonus."))
    #expect(projected.equipment.weapons.map(\.name) == ["Lasgun"])
    #expect(projected.equipment.inventory.contains {
        $0.name == "Standard Ammunition for Lasgun" && $0.quantity == 2
    })
    #expect(projected.equipment.inventory.contains { $0.name == "Imperial Guard Flak Armour" })
    #expect(projected.equipment.movement == MovementProfile(halfMove: 3, fullMove: 6, charge: 9, run: 18))
}

@Test func startingPackageProjectionDoesNotGuessMissingChoicesOrRolls() throws {
    let draft = try DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: "Incomplete",
            homeWorld: "Forge World",
            background: "Adeptus Mechanicus",
            role: "Assassin"
        )
    ).settingPointAllocation(
        DHIICreationCharacteristicValues(
            weaponSkill: 5,
            ballisticSkill: 10,
            strength: 5,
            toughness: 5,
            agility: 10,
            intelligence: 10,
            perception: 5,
            willpower: 5,
            fellowship: 0,
            influence: 5
        )
    )

    let preview = DHIICharacterCreationEngine.previewStartingPackage(for: draft)

    #expect(preview.projectedCharacter == nil)
    #expect(preview.isValid == false)
    #expect(preview.validationMessages.contains { $0.contains("Adeptus Mechanicus") && $0.contains("aptitude choice") })
    #expect(preview.validationMessages.contains { $0.contains("Assassin") && $0.contains("aptitude choice") })
    #expect(preview.validationMessages.contains { $0.contains("Forge World") && $0.contains("home world talent choice") })
    #expect(preview.validationMessages.contains { $0.contains("starting equipment choice 1") })
    #expect(preview.validationMessages.contains { $0.contains("starting equipment choice 2") })
    #expect(preview.validationMessages.contains("Starting wounds require a 1d5 roll before projection."))
    #expect(preview.validationMessages.contains("Starting fate requires a 1d10 roll before projection."))
}

@Test func changingBackgroundPrunesStaleStartingPackageChoiceState() {
    let draft = DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: "Reselect",
            homeWorld: "Forge World",
            background: "Adeptus Mechanicus",
            role: "Warrior"
        )
    )
    .settingHomeWorldTalentChoice("Weapon-Tech")
    .settingBackgroundAptitudeChoice("Tech")
    .settingBackgroundSkillChoice("Operate (Pick One)", at: 0)
    .settingBackgroundEquipmentChoice("Hand Cannon", at: 0)
    .settingBackgroundEquipmentChoice("Optical Mechadendrite", at: 1)
    .settingRoleTalentChoice("Rapid Reload")
    .settingStartingWoundsRoll(4)
    .settingStartingFateRoll(9)

    let recomposed = draft.settingBackground(.adeptusAdministratum)

    #expect(recomposed.homeWorldTalentChoice == "Weapon-Tech")
    #expect(recomposed.backgroundAptitudeChoice == nil)
    #expect(recomposed.backgroundSkillChoices.isEmpty)
    #expect(recomposed.backgroundEquipmentChoices.isEmpty)
    #expect(recomposed.roleTalentChoice == "Rapid Reload")
    #expect(recomposed.startingWoundsRoll == 4)
    #expect(recomposed.startingFateRoll == 9)
}

@Test func startingPackageProjectionRoundTripsThroughLegacyCharacterCodableShape() throws {
    let draft = try DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: "Roundtrip",
            homeWorld: "Hive World",
            background: "Imperial Guard",
            role: "Warrior"
        )
    )
    .settingPointAllocation(
        DHIICreationCharacteristicValues(
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
    )
    .settingBackgroundAptitudeChoice("Fieldcraft")
    .settingBackgroundSkillChoice("Operate (Surface)", at: 0)
    .settingBackgroundEquipmentChoice("Lasgun", at: 0)
    .settingRoleTalentChoice("Rapid Reload")
    .settingStartingWoundsRoll(2)
    .settingStartingFateRoll(7)

    let preview = DHIICharacterCreationEngine.previewStartingPackage(for: draft)
    let projected = try #require(preview.projectedCharacter)

    let encoded = try JSONEncoder().encode(projected)
    let decoded = try JSONDecoder().decode(Character.self, from: encoded)

    #expect(decoded == projected)
}

@Test func creationDraftUsesPersistedEngineStateWhenCharacterCarriesIt() throws {
    let draft = try fullyResolvedStartingPackageDraft(
        name: "Persisted Draft",
        homeWorld: "Hive World",
        background: "Imperial Guard",
        role: "Warrior",
        backgroundAptitudeChoice: "Fieldcraft",
        backgroundSkillChoices: ["Operate (Surface)"],
        backgroundEquipmentChoices: ["Lasgun"],
        roleTalentChoice: "Rapid Reload",
        startingWoundsRoll: 2,
        startingFateRoll: 7
    )

    let character = Character(
        profile: Profile(
            name: "Conflict",
            homeWorld: "Feral World",
            background: "Outcast",
            role: "Desperado",
            aptitudes: ["Social"],
            description: "Legacy profile should not override engine state"
        ),
        dhiiEngineState: DHIICharacterCreationEngine.persistedEngineState(for: draft)
    )

    let restored = DHIICharacterCreationEngine.creationDraft(from: character)

    #expect(restored.homeWorldID == DHIIHomeWorldID.hiveWorld)
    #expect(restored.backgroundID == DHIIBackgroundID.imperialGuard)
    #expect(restored.roleID == DHIIRoleID.warrior)
    #expect(restored.backgroundAptitudeChoice == "Fieldcraft")
    #expect(restored.backgroundSkillChoices == ["Operate (Surface)"])
    #expect(restored.backgroundEquipmentChoices == ["Lasgun"])
    #expect(restored.roleTalentChoice == "Rapid Reload")
    #expect(restored.startingWoundsRoll == 2)
    #expect(restored.startingFateRoll == 7)
}

@Test func startingPackageProjectionPersistsDhiiEngineStateIntoProjectedCharacter() throws {
    let draft = try fullyResolvedStartingPackageDraft(
        name: "Projected Persisted",
        homeWorld: "Hive World",
        background: "Imperial Guard",
        role: "Warrior",
        backgroundAptitudeChoice: "Fieldcraft",
        backgroundSkillChoices: ["Operate (Surface)"],
        backgroundEquipmentChoices: ["Lasgun"],
        roleTalentChoice: "Rapid Reload",
        startingWoundsRoll: 2,
        startingFateRoll: 7
    )

    let preview = DHIICharacterCreationEngine.previewStartingPackage(for: draft)
    let projected = try #require(preview.projectedCharacter)

    #expect(projected.dhiiEngineState == DHIICharacterCreationEngine.persistedEngineState(for: draft))
}

@Test func startingPackageProjectionSupportsEveryBackgroundBranchWithResolvedSelections() throws {
    struct Scenario {
        let homeWorld: String
        let background: String
        let role: String
        let homeWorldTalentChoice: String?
        let backgroundAptitudeChoice: String?
        let roleAptitudeChoice: String?
        let backgroundSkillChoices: [String]
        let backgroundTalentChoice: String?
        let backgroundEquipmentChoices: [String]
        let roleTalentChoice: String?
        let startingWoundsRoll: Int
        let startingFateRoll: Int
        let expectedWeapons: [String]
        let expectedInventoryItems: [String]
        let expectedTalents: [String]
        let expectedTraits: [String]
        let expectedSkillNames: [String]
        let expectedSpecialAbilityNames: [String]
    }

    let scenarios: [Scenario] = [
        Scenario(
            homeWorld: "Hive World",
            background: "Adeptus Administratum",
            role: "Seeker",
            homeWorldTalentChoice: nil,
            backgroundAptitudeChoice: "Social",
            roleAptitudeChoice: nil,
            backgroundSkillChoices: ["Medicae"],
            backgroundTalentChoice: nil,
            backgroundEquipmentChoices: ["Stub Automatic"],
            roleTalentChoice: "Disarm",
            startingWoundsRoll: 2,
            startingFateRoll: 5,
            expectedWeapons: ["Stub Automatic"],
            expectedInventoryItems: ["Imperial Robes", "Medi-kit", "Standard Ammunition for Stub Automatic"],
            expectedTalents: ["Weapon Training (Las or Solid Projectile)", "Disarm"],
            expectedTraits: [],
            expectedSkillNames: ["Medicae", "Common Lore", "Linguistics", "Logic", "Scholastic Lore"],
            expectedSpecialAbilityNames: ["Master of Paperwork", "Nothing Escapes My Sight", "Teeming Masses in Metal Mountains"]
        ),
        Scenario(
            homeWorld: "Feral World",
            background: "Adeptus Arbites",
            role: "Warrior",
            homeWorldTalentChoice: nil,
            backgroundAptitudeChoice: "Defence",
            roleAptitudeChoice: nil,
            backgroundSkillChoices: ["Interrogation"],
            backgroundTalentChoice: nil,
            backgroundEquipmentChoices: ["Shock Maul", "Carapace Chestplate"],
            roleTalentChoice: "Iron Jaw",
            startingWoundsRoll: 5,
            startingFateRoll: 2,
            expectedWeapons: ["Shock Maul"],
            expectedInventoryItems: ["Carapace Chestplate", "3 Doses of Stimm"],
            expectedTalents: ["Weapon Training (Shock or Solid Projectile)", "Iron Jaw"],
            expectedTraits: [],
            expectedSkillNames: ["Awareness", "Common Lore", "Interrogation", "Intimidate", "Scrutiny"],
            expectedSpecialAbilityNames: ["The Face of the Law", "Expert at Violence", "The Old Ways"]
        ),
        Scenario(
            homeWorld: "Voidborn",
            background: "Adeptus Astra Telepathica",
            role: "Mystic",
            homeWorldTalentChoice: nil,
            backgroundAptitudeChoice: "Psyker",
            roleAptitudeChoice: nil,
            backgroundSkillChoices: ["Interrogation", "Scrutiny"],
            backgroundTalentChoice: nil,
            backgroundEquipmentChoices: ["Whip", "Flak Vest"],
            roleTalentChoice: "Warp Sense",
            startingWoundsRoll: 1,
            startingFateRoll: 9,
            expectedWeapons: ["Laspistol", "Whip"],
            expectedInventoryItems: ["Flak Vest", "Micro-bead", "Standard Ammunition for Laspistol"],
            expectedTalents: ["Weapon Training (Las, Low-Tech)", "Warp Sense", "Strong Minded"],
            expectedTraits: [],
            expectedSkillNames: ["Awareness", "Common Lore", "Interrogation", "Forbidden Lore", "Scrutiny"],
            expectedSpecialAbilityNames: ["The Constant Threat / Tested on Terra", "Stare into the Warp", "Child of the Dark"]
        ),
        Scenario(
            homeWorld: "Forge World",
            background: "Adeptus Mechanicus",
            role: "Sage",
            homeWorldTalentChoice: "Weapon-Tech",
            backgroundAptitudeChoice: "Tech",
            roleAptitudeChoice: nil,
            backgroundSkillChoices: ["Operate (Pick One)"],
            backgroundTalentChoice: nil,
            backgroundEquipmentChoices: ["Hand Cannon", "Optical Mechadendrite"],
            roleTalentChoice: "Clues from the Crowds",
            startingWoundsRoll: 3,
            startingFateRoll: 10,
            expectedWeapons: ["Hand Cannon"],
            expectedInventoryItems: ["Optical Mechadendrite", "2 Vials of Sacred Unguents", "Standard Ammunition for Hand Cannon"],
            expectedTalents: ["Mechadendrite Use (Utility)", "Weapon Training (Solid Projectile)", "Weapon-Tech", "Clues from the Crowds"],
            expectedTraits: ["Mechanicus Implants"],
            expectedSkillNames: ["Operate (Pick One)", "Common Lore", "Logic", "Security", "Tech-Use"],
            expectedSpecialAbilityNames: ["Replace the Weak Flesh", "Quest for Knowledge", "Omnissiah's Chosen"]
        ),
        Scenario(
            homeWorld: "Shrine World",
            background: "Adeptus Ministorum",
            role: "Hierophant",
            homeWorldTalentChoice: nil,
            backgroundAptitudeChoice: "Leadership",
            roleAptitudeChoice: nil,
            backgroundSkillChoices: ["Scrutiny"],
            backgroundTalentChoice: "Weapon Training (Low-Tech, Solid Projectile)",
            backgroundEquipmentChoices: ["Warhammer and Stub Revolver", "Flak Vest"],
            roleTalentChoice: "Hatred (Pick One)",
            startingWoundsRoll: 4,
            startingFateRoll: 2,
            expectedWeapons: ["Warhammer", "Stub Revolver"],
            expectedInventoryItems: ["Flak Vest", "Monotask Servo-Skull (Laud Hailer)", "Standard Ammunition for Stub Revolver"],
            expectedTalents: ["Weapon Training (Low-Tech, Solid Projectile)", "Hatred (Pick One)"],
            expectedTraits: [],
            expectedSkillNames: ["Charm", "Command", "Common Lore", "Scrutiny", "Linguistics"],
            expectedSpecialAbilityNames: ["Faith is All", "Sway the Masses", "Faith in the Creed"]
        ),
        Scenario(
            homeWorld: "Hive World",
            background: "Imperial Guard",
            role: "Assassin",
            homeWorldTalentChoice: nil,
            backgroundAptitudeChoice: "Leadership",
            roleAptitudeChoice: "Weapon Skill",
            backgroundSkillChoices: ["Medicae"],
            backgroundTalentChoice: nil,
            backgroundEquipmentChoices: ["Laspistol and Sword"],
            roleTalentChoice: "Leap Up",
            startingWoundsRoll: 2,
            startingFateRoll: 4,
            expectedWeapons: ["Laspistol", "Sword"],
            expectedInventoryItems: ["Imperial Guard Flak Armour", "Standard Ammunition for Laspistol"],
            expectedTalents: ["Weapon Training (Las, Low-Tech)", "Leap Up"],
            expectedTraits: [],
            expectedSkillNames: ["Athletics", "Command", "Common Lore", "Medicae", "Navigate"],
            expectedSpecialAbilityNames: ["Hammer of the Emperor", "Sure Kill", "Teeming Masses in Metal Mountains"]
        ),
        Scenario(
            homeWorld: "Highborn",
            background: "Outcast",
            role: "Desperado",
            homeWorldTalentChoice: nil,
            backgroundAptitudeChoice: "Social",
            roleAptitudeChoice: nil,
            backgroundSkillChoices: ["Sleight of Hand"],
            backgroundTalentChoice: nil,
            backgroundEquipmentChoices: ["Laspistol", "Flak Vest", "Slaught"],
            roleTalentChoice: "Quick Draw",
            startingWoundsRoll: 3,
            startingFateRoll: 9,
            expectedWeapons: ["Laspistol", "Chainsword"],
            expectedInventoryItems: ["Flak Vest", "2 Doses of Slaught", "Standard Ammunition for Laspistol"],
            expectedTalents: ["Weapon Training (Chain, and Las or Solid Projectile)", "Quick Draw"],
            expectedTraits: [],
            expectedSkillNames: ["Sleight of Hand", "Common Lore", "Deceive", "Dodge", "Stealth"],
            expectedSpecialAbilityNames: ["Never Quit", "Move and Shoot", "Breeding Counts"]
        )
    ]

    for scenario in scenarios {
        let draft = try fullyResolvedStartingPackageDraft(
            name: scenario.background,
            homeWorld: scenario.homeWorld,
            background: scenario.background,
            role: scenario.role,
            homeWorldTalentChoice: scenario.homeWorldTalentChoice,
            backgroundAptitudeChoice: scenario.backgroundAptitudeChoice,
            roleAptitudeChoice: scenario.roleAptitudeChoice,
            backgroundSkillChoices: scenario.backgroundSkillChoices,
            backgroundTalentChoice: scenario.backgroundTalentChoice,
            backgroundEquipmentChoices: scenario.backgroundEquipmentChoices,
            roleTalentChoice: scenario.roleTalentChoice,
            startingWoundsRoll: scenario.startingWoundsRoll,
            startingFateRoll: scenario.startingFateRoll
        )

        let preview = DHIICharacterCreationEngine.previewStartingPackage(for: draft)
        let projected = try #require(preview.projectedCharacter)

        #expect(preview.isValid)
        #expect(projected.equipment.weapons.map(\.name) == scenario.expectedWeapons)
        for item in scenario.expectedInventoryItems {
            if projected.equipment.inventory.contains(where: { $0.name == item }) == false {
                Issue.record("Missing inventory item \(item) for \(scenario.background)")
            }
        }
        for talent in scenario.expectedTalents {
            if projected.notes.talents.contains(talent) == false {
                Issue.record("Missing talent \(talent) for \(scenario.background)")
            }
        }
        #expect(projected.notes.traits == scenario.expectedTraits)
        for skillName in scenario.expectedSkillNames {
            if projected.skills.contains(where: { $0.name == skillName }) == false {
                Issue.record("Missing skill \(skillName) for \(scenario.background)")
            }
        }
        for fragment in scenario.expectedSpecialAbilityNames {
            if projected.notes.specialAbilities.contains(where: { $0.contains(fragment) }) == false {
                Issue.record("Missing special ability fragment \(fragment) for \(scenario.background): \(projected.notes.specialAbilities)")
            }
        }
    }
}

@Test func startingPackageProjectionRequiresCanonicalSelectionsAndSanitizesChoiceHelpers() {
    let blank = DHIICharacterCreationEngine.previewStartingPackage(
        for: DHIICharacterCreationEngine.creationDraft(from: Profile(name: "Blank"))
    )

    #expect(blank.projectedCharacter == nil)
    #expect(blank.validationMessages.contains("A canonical home world is required before projecting a starting package."))
    #expect(blank.validationMessages.contains("A canonical background is required before projecting a starting package."))
    #expect(blank.validationMessages.contains("A canonical role is required before projecting a starting package."))
    #expect(blank.validationMessages.contains("Characteristic generation must be resolved before projecting a starting package."))
    #expect(blank.validationMessages.contains("Starting wounds require a 1d5 roll before projection."))
    #expect(blank.validationMessages.contains("Starting fate requires a 1d10 roll before projection."))

    let groups = [["Inquiry", "Interrogation"], ["Psyniscience", "Scrutiny"]]
    #expect(validatedIndexedChoices(["Interrogation", "Bogus"], optionGroups: groups) == ["Interrogation"])
    #expect(
        replacingIndexedChoice(["Interrogation"], with: "Scrutiny", at: 1, optionGroups: groups)
            == ["Interrogation", "Scrutiny"]
    )
    #expect(
        replacingIndexedChoice(["Interrogation", "Scrutiny"], with: "Bogus", at: 0, optionGroups: groups)
            == ["Scrutiny"]
    )
    #expect(
        replacingIndexedChoice(["Interrogation"], with: "Bogus", at: 9, optionGroups: groups)
            == ["Interrogation"]
    )
    #expect(validatedStartingRoll(3, allowedRange: 1 ... 5) == 3)
    #expect(validatedStartingRoll(0, allowedRange: 1 ... 5) == nil)
}

private func fullyResolvedStartingPackageDraft(
    name: String,
    homeWorld: String,
    background: String,
    role: String,
    homeWorldTalentChoice: String? = nil,
    backgroundAptitudeChoice: String? = nil,
    roleAptitudeChoice: String? = nil,
    backgroundSkillChoices: [String] = [],
    backgroundTalentChoice: String? = nil,
    backgroundEquipmentChoices: [String] = [],
    roleTalentChoice: String? = nil,
    startingWoundsRoll: Int = 3,
    startingFateRoll: Int = 5
) throws -> DHIICreationDraft {
    let baseDraft = DHIICharacterCreationEngine.creationDraft(
        from: Profile(
            name: name,
            homeWorld: homeWorld,
            background: background,
            role: role
        )
    )

    var resolved = try baseDraft.settingPointAllocation(
        DHIICreationCharacteristicValues(
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
    )

    if resolved.homeWorldTalentOptions.isEmpty == false {
        resolved = resolved.settingHomeWorldTalentChoice(homeWorldTalentChoice ?? resolved.homeWorldTalentOptions.first)
    }

    if let firstBackgroundChoice = resolved.backgroundDefinition?.aptitudeOptions.first {
        resolved = resolved.settingBackgroundAptitudeChoice(backgroundAptitudeChoice ?? firstBackgroundChoice)
    }

    if let firstRoleChoice = resolved.roleDefinition?.aptitudeRules.compactMap({ rule -> String? in
        if case .choice(let first, _) = rule {
            return first
        }
        return nil
    }).first {
        resolved = resolved.settingRoleAptitudeChoice(roleAptitudeChoice ?? firstRoleChoice)
    }

    for (index, options) in resolved.backgroundSkillOptionGroups.enumerated() {
        resolved = resolved.settingBackgroundSkillChoice(backgroundSkillChoices[safe: index] ?? options.first, at: index)
    }

    if resolved.backgroundTalentOptions.isEmpty == false {
        resolved = resolved.settingBackgroundTalentChoice(backgroundTalentChoice ?? resolved.backgroundTalentOptions.first)
    }

    for (index, options) in resolved.backgroundEquipmentOptionGroups.enumerated() {
        resolved = resolved.settingBackgroundEquipmentChoice(backgroundEquipmentChoices[safe: index] ?? options.first, at: index)
    }

    if resolved.roleTalentOptions.isEmpty == false {
        resolved = resolved.settingRoleTalentChoice(roleTalentChoice ?? resolved.roleTalentOptions.first)
    }

    return resolved
        .settingStartingWoundsRoll(startingWoundsRoll)
        .settingStartingFateRoll(startingFateRoll)
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
