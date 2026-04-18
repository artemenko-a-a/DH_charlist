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
