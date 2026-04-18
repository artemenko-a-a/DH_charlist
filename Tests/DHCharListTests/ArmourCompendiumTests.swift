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
    #expect(first?.armourPoints == 3)
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
    let service = ArmourCompendiumJSONImportService()
    let importedCatalog = try service.import(
        armourCompendiumImportData(
            catalogID: "imported-armour-catalog",
            displayName: "Imported Armour Vault",
            definitions: [
                [
                    "id": "imported-armour-catalog.mnemonic-mesh",
                    "name": "Mnemonic Mesh",
                    "category": "Body Armour",
                    "coverage": ["Body"],
                    "armourPoints": 5,
                    "weight": "4kg",
                    "availability": "Rare",
                    "traits": ["Flexible"]
                ]
            ]
        )
    )

    #expect(try await useCases.currentCatalog().id == ArmourCompendiumCatalog.demo.id)

    let replaced = try await useCases.replaceCatalog(importedCatalog)
    let loaded = try await useCases.currentCatalog()
    let results = ArmourCompendiumSearch.autocomplete(definitions: loaded.definitions, query: "mnem")

    #expect(replaced == importedCatalog)
    #expect(loaded == importedCatalog)
    #expect(results.map(\.name) == ["Mnemonic Mesh"])
}

@Test func armourCompendiumImportRejectsMalformedJSON() {
    let service = ArmourCompendiumJSONImportService()

    do {
        _ = try service.import(Data("{".utf8))
        Issue.record("Expected malformed JSON import to fail")
    } catch let error as ArmourCompendiumImportError {
        #expect(error == .invalidJSON)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test func armourCompendiumImportPreviewSummaryMakesReplaceAllSemanticsExplicit() {
    let summary = ArmourCompendiumImportPreviewSummary(
        importedCatalogName: "Imported Armour Vault",
        detectedArmourCount: 1,
        existingCatalogName: "Local Demo Armour Catalog",
        existingArmourCount: 2
    )

    #expect(summary.confirmationMessage.contains("Imported catalog"))
    #expect(summary.confirmationMessage.contains("1 armour definition"))
    #expect(summary.confirmationMessage.contains("2 armour definitions"))
    #expect(summary.confirmationMessage.contains("it does not merge"))
    #expect(summary.confirmationMessage.contains("Existing character-owned armour stays detached and unchanged"))
    #expect(summary.confirmationMessage.contains("destructive"))
}

@Test func armourCompendiumImportRejectsUnsupportedSchemaVersion() throws {
    let service = ArmourCompendiumJSONImportService()

    do {
        _ = try service.import(
            armourCompendiumImportData(
                schemaVersion: 2,
                catalogID: "imported-armour-catalog",
                displayName: "Imported Armour Vault"
            )
        )
        Issue.record("Expected unsupported schema version to fail")
    } catch let error as ArmourCompendiumImportError {
        #expect(error == .unsupportedSchemaVersion(2))
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test func armourCompendiumImportValidatesRequiredFieldsWithActionableDiagnostics() throws {
    let service = ArmourCompendiumJSONImportService()

    func expectImportError(
        _ data: Data,
        equals expected: ArmourCompendiumImportError,
        description expectedDescription: String
    ) {
        do {
            _ = try service.import(data)
            Issue.record("Expected armour compendium import to fail with \(expected)")
        } catch let error as ArmourCompendiumImportError {
            #expect(error == expected)
            #expect(error.errorDescription == expectedDescription)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    expectImportError(
        try armourCompendiumImportData(
            catalogID: "   ",
            displayName: "Imported Armour Vault"
        ),
        equals: .invalidCatalogID,
        description: "Armour compendium import failed: catalog id is required."
    )

    expectImportError(
        try armourCompendiumImportData(
            catalogID: "imported-armour-catalog",
            displayName: "   "
        ),
        equals: .invalidCatalogDisplayName,
        description: "Armour compendium import failed: catalog display name is required."
    )

    expectImportError(
        try armourCompendiumImportData(
            catalogID: "imported-armour-catalog",
            displayName: "Imported Armour Vault",
            definitions: [
                [
                    "id": "   ",
                    "name": "Mnemonic Mesh",
                    "armourPoints": 5
                ]
            ]
        ),
        equals: .invalidDefinitionID(index: 0),
        description: "Armour compendium import failed: definition #1 is missing an id."
    )

    expectImportError(
        try armourCompendiumImportData(
            catalogID: "imported-armour-catalog",
            displayName: "Imported Armour Vault",
            definitions: [
                [
                    "id": "imported-armour-catalog.mnemonic-mesh",
                    "name": "   ",
                    "armourPoints": 5
                ]
            ]
        ),
        equals: .invalidDefinitionName(index: 0),
        description: "Armour compendium import failed: definition #1 is missing a name."
    )

    expectImportError(
        try armourCompendiumImportData(
            catalogID: "imported-armour-catalog",
            displayName: "Imported Armour Vault",
            definitions: [
                [
                    "id": "imported-armour-catalog.mnemonic-mesh",
                    "name": "Mnemonic Mesh"
                ]
            ]
        ),
        equals: .invalidDefinitionArmourPoints(index: 0),
        description: "Armour compendium import failed: definition #1 is missing valid armour points."
    )

    expectImportError(
        try armourCompendiumImportData(
            catalogID: "imported-armour-catalog",
            displayName: "Imported Armour Vault",
            definitions: [
                [
                    "id": "imported-armour-catalog.mnemonic-mesh",
                    "name": "Mnemonic Mesh",
                    "armourPoints": -1
                ]
            ]
        ),
        equals: .invalidDefinitionArmourPoints(index: 0),
        description: "Armour compendium import failed: definition #1 is missing valid armour points."
    )
}

@Test func armourCompendiumImportRejectsDuplicateDefinitionIDs() throws {
    let service = ArmourCompendiumJSONImportService()

    do {
        _ = try service.import(
            armourCompendiumImportData(
                catalogID: "imported-armour-catalog",
                displayName: "Imported Armour Vault",
                definitions: [
                    [
                        "id": "imported-armour-catalog.mnemonic-mesh",
                        "name": "Mnemonic Mesh",
                        "armourPoints": 5
                    ],
                    [
                        "id": "imported-armour-catalog.mnemonic-mesh",
                        "name": "Mnemonic Mesh Variant",
                        "armourPoints": 6
                    ]
                ]
            )
        )
        Issue.record("Expected duplicate definition ids to fail")
    } catch let error as ArmourCompendiumImportError {
        #expect(error == .duplicateDefinitionIDs(["imported-armour-catalog.mnemonic-mesh"]))
        #expect(
            error.errorDescription ==
                "Armour compendium import failed: duplicate definition ids found (imported-armour-catalog.mnemonic-mesh)."
        )
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
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
    #expect(definition.armourPoints == 3)
}

@MainActor
@Test func cancelPendingArmourCompendiumImportLeavesCurrentCatalogUnchanged() async throws {
    let characterRepository = JSONFileCharacterRepository(fileURL: uniqueArmourCompendiumTestFileURL("characters"))
    let characterUseCases = CharacterUseCases(repository: characterRepository)
    let compendiumRepository = JSONFileArmourCompendiumRepository(fileURL: uniqueArmourCompendiumTestFileURL("catalog-cancel"))
    let compendiumUseCases = ArmourCompendiumUseCases(repository: compendiumRepository)
    let importService = ArmourCompendiumJSONImportService()
    let viewModel = CharacterListViewModel(
        useCases: characterUseCases,
        importExportService: CharacterJSONImportExportService(),
        armourCompendiumUseCases: compendiumUseCases,
        armourCompendiumImportService: importService,
        weaponCompendiumUseCases: WeaponCompendiumUseCases(
            repository: JSONFileWeaponCompendiumRepository(
                fileURL: uniqueArmourCompendiumTestFileURL("weapon-catalog-cancel")
            )
        ),
        weaponCompendiumImportService: WeaponCompendiumJSONImportService()
    )

    await viewModel.load()
    let before = try await compendiumUseCases.currentCatalog()
    let data = try armourCompendiumImportData(
        catalogID: "imported-armour-catalog",
        displayName: "Imported Armour Vault"
    )

    await viewModel.prepareArmourCompendiumImport(data)
    #expect(viewModel.pendingArmourCompendiumImportSummary?.importedCatalogName == "Imported Armour Vault")

    viewModel.cancelPendingArmourCompendiumImport()

    let after = try await compendiumUseCases.currentCatalog()
    #expect(viewModel.pendingArmourCompendiumImportSummary == nil)
    #expect(after == before)
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
    #expect(definition.armourPoints == 3)
}

@Test func replacingCompendiumDoesNotMutateExistingCharacterOwnedArmour() async throws {
    let characterFileURL = uniqueArmourCompendiumTestFileURL("equipment-detached-after-replace")
    let characterRepository = JSONFileCharacterRepository(fileURL: characterFileURL)
    let characterUseCases = CharacterUseCases(repository: characterRepository)
    let compendiumRepository = JSONFileArmourCompendiumRepository(fileURL: uniqueArmourCompendiumTestFileURL("catalog-replace-detached"))
    let compendiumUseCases = ArmourCompendiumUseCases(repository: compendiumRepository)
    let importService = ArmourCompendiumJSONImportService()

    let created = try await characterUseCases.createCharacter(profile: Profile(name: "Detached Armour Safety"))
    guard let definition = ArmourCompendiumCatalog.demo.definition(id: "local-demo.flak-coat") else {
        Issue.record("Expected demo flak coat definition")
        return
    }

    var detachedArmour = definition.makeArmourInstance()
    detachedArmour.location = "Legacy Flak Coat"
    detachedArmour.armourPoints = 5
    _ = try await characterUseCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(armour: [detachedArmour])
    )

    let importedCatalog = try importService.import(
        armourCompendiumImportData(
            catalogID: "imported-armour-catalog",
            displayName: "Imported Armour Vault",
            definitions: [
                [
                    "id": "imported-armour-catalog.mnemonic-mesh",
                    "name": "Mnemonic Mesh",
                    "category": "Body Armour",
                    "coverage": ["Body"],
                    "armourPoints": 5
                ]
            ]
        )
    )
    _ = try await compendiumUseCases.replaceCatalog(importedCatalog)

    let persistedCharacter = try await characterRepository.fetch(id: created.id)
    let currentCatalog = try await compendiumUseCases.currentCatalog()

    #expect(persistedCharacter?.equipment.armour == [detachedArmour])
    #expect(currentCatalog.displayName == "Imported Armour Vault")
    #expect(currentCatalog.definition(id: "imported-armour-catalog.mnemonic-mesh")?.name == "Mnemonic Mesh")
}

private func uniqueArmourCompendiumTestFileURL(_ suffix: String) -> URL {
    FileManager.default.temporaryDirectory
        .appending(path: "dh-charlist-armour-\(suffix)-\(UUID().uuidString).json")
}

private func armourCompendiumImportData(
    schemaVersion: Int = 1,
    catalogID: String,
    displayName: String,
    definitions: [[String: Any]] = [
        [
            "id": "imported-armour-catalog.mnemonic-mesh",
            "name": "Mnemonic Mesh",
            "category": "Body Armour",
            "coverage": ["Body"],
            "armourPoints": 5,
            "weight": "4kg",
            "availability": "Rare",
            "traits": ["Flexible"]
        ]
    ]
) throws -> Data {
    try JSONSerialization.data(
        withJSONObject: [
            "schemaVersion": schemaVersion,
            "catalog": [
                "id": catalogID,
                "displayName": displayName,
                "definitions": definitions
            ]
        ],
        options: [.prettyPrinted, .sortedKeys]
    )
}
