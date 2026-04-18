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
