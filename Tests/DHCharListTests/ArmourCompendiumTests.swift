import Foundation
import Testing
@testable import DHCharList

@Test func armourCompendiumAutocompleteMatchesKnownArmourByName() {
    let results = ArmourCompendiumSearch.autocomplete(
        definitions: ArmourCompendiumCatalog.demo.definitions,
        query: "flak"
    )

    #expect(results.map(\.name) == ["Flak Coat"])
}

@Test func armourCompendiumAutocompleteHandlesExactContainsLimitAndBlankQueries() {
    let definitions = [
        ArmourCompendiumDefinition(id: "exact", catalogID: "test", name: "Flak Coat", armourPoints: 4),
        ArmourCompendiumDefinition(id: "short", catalogID: "test", name: "Vest", armourPoints: 3),
        ArmourCompendiumDefinition(id: "alpha", catalogID: "test", name: "Alpha Vest", armourPoints: 3),
        ArmourCompendiumDefinition(id: "beta", catalogID: "test", name: "Beta Vest", armourPoints: 3)
    ]

    let exact = ArmourCompendiumSearch.autocomplete(definitions: definitions, query: "  FLAK COAT  ")
    let contains = ArmourCompendiumSearch.autocomplete(definitions: definitions, query: "vest", limit: 2)
    let blank = ArmourCompendiumSearch.autocomplete(definitions: definitions, query: "   ")

    #expect(exact.map(\.id) == ["exact"])
    #expect(contains.map(\.id) == ["short", "beta"])
    #expect(blank.isEmpty)
    #expect(ArmourCompendiumCatalog.demo.definition(id: "missing-id") == nil)
}

@Test func armourCompendiumDefinitionCopiesIntoDetachedArmourInstances() {
    let definition = ArmourCompendiumCatalog.demo.definition(id: "local-demo.flak-coat")

    #expect(definition != nil)

    let first = definition?.makeArmourInstance()
    let second = definition?.makeArmourInstance()

    #expect(first?.id != second?.id)
    #expect(first?.location == "Flak Coat (Body, Arms)")
    #expect(first?.armourPoints == 4)
}

@Test func armourCompendiumDefinitionFormatsPreviewSupportingAndPlaceholderFields() {
    let definition = ArmourCompendiumDefinition(
        id: "custom",
        catalogID: "test",
        name: "   ",
        category: " Body Armour ",
        coverage: [" Body ", " Arms ", " "],
        armourPoints: 5,
        weight: " 8kg ",
        availability: " Scarce ",
        traits: [" Flexible ", " ", " Sealed "]
    )

    let armour = definition.makeArmourInstance(id: UUID(uuidString: "00000000-0000-0000-0000-000000000045")!)

    #expect(definition.coverageText == "Body, Arms")
    #expect(definition.traitsText == "Flexible, Sealed")
    #expect(definition.previewLine == "Body Armour • Body, Arms • AP 5")
    #expect(definition.supportingLine == "Weight 8kg • Scarce • Flexible, Sealed")
    #expect(armour.id == UUID(uuidString: "00000000-0000-0000-0000-000000000045")!)
    #expect(armour.location == "Unnamed Armour (Body, Arms)")
    #expect(armour.armourPoints == 5)
}

@Test func armourCompendiumDefinitionPreviewOmitsBlankSupportingFields() {
    let definition = ArmourCompendiumDefinition(
        id: "blank-support",
        catalogID: "test",
        name: "Guard Helm",
        category: "  ",
        coverage: [],
        armourPoints: 3,
        weight: " ",
        availability: "",
        traits: [" ", ""]
    )

    #expect(definition.previewLine == "AP 3")
    #expect(definition.supportingLine.isEmpty)
    #expect(definition.characterLocationText == "Guard Helm")
}

@Test func validArmourCompendiumCatalogReplacePersistsAndPowersFutureAutocomplete() async throws {
    let fileURL = uniqueArmourCompendiumTestFileURL("catalog-replace")
    let repository = JSONFileArmourCompendiumRepository(fileURL: fileURL)
    let useCases = ArmourCompendiumUseCases(repository: repository)
    let importedCatalog = ArmourCompendiumCatalog(
        id: "imported-armour-catalog",
        displayName: "Imported Armour Vault",
        definitions: [
            ArmourCompendiumDefinition(
                id: "imported-armour-catalog.mnemonic-mesh",
                catalogID: "imported-armour-catalog",
                name: "Mnemonic Mesh",
                category: "Body Armour",
                coverage: ["Body"],
                armourPoints: 5,
                weight: "4kg",
                availability: "Rare",
                traits: ["Flexible"]
            )
        ]
    )

    #expect(try await useCases.currentCatalog().id == ArmourCompendiumCatalog.demo.id)

    let replaced = try await useCases.replaceCatalog(importedCatalog)
    let loaded = try await useCases.currentCatalog()
    let results = ArmourCompendiumSearch.autocomplete(definitions: loaded.definitions, query: "mnem")

    #expect(replaced == importedCatalog)
    #expect(loaded == importedCatalog)
    #expect(results.map(\.name) == ["Mnemonic Mesh"])
}

@Test func editingArmourInstanceDoesNotMutateCompendiumDefinition() {
    guard let definition = ArmourCompendiumCatalog.demo.definition(id: "local-demo.flak-coat") else {
        Issue.record("Expected demo flak coat definition")
        return
    }

    var customArmour = definition.makeArmourInstance()
    customArmour.location = "Custom Flak Coat"
    customArmour.armourPoints = 5

    #expect(definition.name == "Flak Coat")
    #expect(definition.coverageText == "Body, Arms")
    #expect(definition.armourPoints == 4)
}

@Test func compendiumArmourInstancePersistsThroughAcceptedEquipmentFlow() async throws {
    let fileURL = uniqueArmourCompendiumTestFileURL("equipment-compendium-copy")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Compendium Armour"))
    guard let definition = ArmourCompendiumCatalog.demo.definition(id: "local-demo.flak-coat") else {
        Issue.record("Expected demo flak coat definition")
        return
    }

    var copiedArmour = definition.makeArmourInstance()
    copiedArmour.location = "Field-Tuned Flak Coat"
    copiedArmour.armourPoints = 5

    let updated = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(armour: [copiedArmour])
    )
    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(updated.equipment.armour == [copiedArmour])
    #expect(persisted?.equipment.armour == [copiedArmour])
    #expect(definition.name == "Flak Coat")
    #expect(definition.armourPoints == 4)
}

private func uniqueArmourCompendiumTestFileURL(_ suffix: String) -> URL {
    FileManager.default.temporaryDirectory
        .appending(path: "dh-charlist-armour-\(suffix)-\(UUID().uuidString).json")
}
