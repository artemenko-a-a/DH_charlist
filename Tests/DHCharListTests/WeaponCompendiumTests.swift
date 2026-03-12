import Foundation
import Testing
@testable import DHCharList

@Test func weaponCompendiumAutocompleteMatchesKnownWeaponsByName() {
    let results = WeaponCompendiumSearch.autocomplete(
        definitions: WeaponCompendiumCatalog.demo.definitions,
        query: "las"
    )

    #expect(results.map(\.name) == ["Lasgun", "Laspistol"])
}

@Test func weaponCompendiumAutocompleteHandlesExactContainsLimitAndBlankQueries() {
    let definitions = [
        WeaponCompendiumDefinition(id: "exact", catalogID: "test", name: "Laspistol"),
        WeaponCompendiumDefinition(id: "short", catalogID: "test", name: "Stub"),
        WeaponCompendiumDefinition(id: "alpha", catalogID: "test", name: "Alpha Stub"),
        WeaponCompendiumDefinition(id: "beta", catalogID: "test", name: "Beta Stub")
    ]

    let exact = WeaponCompendiumSearch.autocomplete(definitions: definitions, query: "  LASPISTOL  ")
    let contains = WeaponCompendiumSearch.autocomplete(definitions: definitions, query: "stub", limit: 2)
    let blank = WeaponCompendiumSearch.autocomplete(definitions: definitions, query: "   ")

    #expect(exact.map(\.id) == ["exact"])
    #expect(contains.map(\.id) == ["short", "beta"])
    #expect(blank.isEmpty)
    #expect(WeaponCompendiumCatalog.demo.definition(id: "missing-id") == nil)
}

@Test func weaponCompendiumDefinitionCopiesIntoDetachedWeaponInstances() {
    let definition = WeaponCompendiumCatalog.demo.definition(id: "local-demo.laspistol")

    #expect(definition != nil)

    let first = definition?.makeWeaponInstance()
    let second = definition?.makeWeaponInstance()

    #expect(first?.id != second?.id)
    #expect(first?.name == "Laspistol")
    #expect(first?.type == "Pistol")
    #expect(first?.damage == "1d10+2 E")
    #expect(first?.traits == "Reliable")
}

@Test func weaponCompendiumDefinitionFormatsPreviewSupportingAndPlaceholderFields() {
    let definition = WeaponCompendiumDefinition(
        id: "custom",
        catalogID: "test",
        name: "   ",
        type: " Pistol ",
        range: " 30m ",
        damage: " 1d10+2 E ",
        penetration: " 1 ",
        clip: " 18 ",
        reload: " Half ",
        traits: [" Reliable ", " ", " Tearing "]
    )

    let weapon = definition.makeWeaponInstance(id: UUID(uuidString: "00000000-0000-0000-0000-000000000043")!)

    #expect(definition.traitsText == "Reliable, Tearing")
    #expect(definition.previewLine == "Pistol • 30m • 1d10+2 E • Pen 1")
    #expect(definition.supportingLine == "Clip 18 • Reload Half • Reliable, Tearing")
    #expect(weapon.id == UUID(uuidString: "00000000-0000-0000-0000-000000000043")!)
    #expect(weapon.name == "Unnamed Weapon")
    #expect(weapon.type == "Pistol")
    #expect(weapon.range == "30m")
    #expect(weapon.damage == "1d10+2 E")
    #expect(weapon.penetration == "1")
    #expect(weapon.clip == "18")
    #expect(weapon.reload == "Half")
    #expect(weapon.traits == "Reliable, Tearing")
}

@Test func weaponCompendiumDefinitionPreviewOmitsBlankSupportingFields() {
    let definition = WeaponCompendiumDefinition(
        id: "blank-support",
        catalogID: "test",
        name: "Blank Support",
        type: "  ",
        range: " ",
        damage: "",
        penetration: "\n",
        clip: " ",
        reload: "",
        traits: [" ", ""]
    )

    #expect(definition.previewLine.isEmpty)
    #expect(definition.supportingLine.isEmpty)
}

@Test func validWeaponCompendiumImportReplacesLocalCatalogAndPowersFutureAutocomplete() async throws {
    let fileURL = uniqueCompendiumTestFileURL("catalog-import")
    let repository = JSONFileWeaponCompendiumRepository(fileURL: fileURL)
    let useCases = WeaponCompendiumUseCases(repository: repository)
    let service = WeaponCompendiumJSONImportService()

    let importedCatalog = try service.import(
        compendiumImportData(
            catalogID: "imported-catalog",
            displayName: "Imported Cogitator Vault",
            definitions: [
                [
                    "id": "imported-catalog.mnemonic-pistol",
                    "name": "Mnemonic Pistol",
                    "type": "Pistol",
                    "range": "25m",
                    "damage": "1d10+3 E",
                    "penetration": "3",
                    "clip": "12",
                    "reload": "Half",
                    "traits": ["Compact", "Reliable"]
                ]
            ]
        )
    )

    #expect(try await useCases.currentCatalog().id == WeaponCompendiumCatalog.demo.id)

    let replaced = try await useCases.replaceCatalog(importedCatalog)
    let loaded = try await useCases.currentCatalog()
    let results = WeaponCompendiumSearch.autocomplete(definitions: loaded.definitions, query: "mnem")

    #expect(replaced == importedCatalog)
    #expect(loaded == importedCatalog)
    #expect(results.map(\.name) == ["Mnemonic Pistol"])
}

@Test func weaponCompendiumImportRejectsMalformedJSON() {
    let service = WeaponCompendiumJSONImportService()

    do {
        _ = try service.import(Data("{".utf8))
        Issue.record("Expected malformed JSON import to fail")
    } catch let error as WeaponCompendiumImportError {
        #expect(error == .invalidJSON)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test func weaponCompendiumImportPreviewSummaryMakesReplaceAllSemanticsExplicit() {
    let summary = WeaponCompendiumImportPreviewSummary(
        importedCatalogName: "Imported Cogitator Vault",
        detectedWeaponCount: 1,
        existingCatalogName: "Local Demo Catalog",
        existingWeaponCount: 2
    )

    #expect(summary.confirmationMessage.contains("Imported catalog"))
    #expect(summary.confirmationMessage.contains("1 weapon definition"))
    #expect(summary.confirmationMessage.contains("2 weapon definitions"))
    #expect(summary.confirmationMessage.contains("it does not merge"))
    #expect(summary.confirmationMessage.contains("Existing character-owned weapons stay detached and unchanged"))
    #expect(summary.confirmationMessage.contains("destructive"))
}

@Test func weaponCompendiumImportRejectsUnsupportedSchemaVersion() throws {
    let service = WeaponCompendiumJSONImportService()

    do {
        _ = try service.import(
            compendiumImportData(
                schemaVersion: 2,
                catalogID: "imported-catalog",
                displayName: "Imported Cogitator Vault"
            )
        )
        Issue.record("Expected unsupported schema version to fail")
    } catch let error as WeaponCompendiumImportError {
        #expect(error == .unsupportedSchemaVersion(2))
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test func weaponCompendiumImportValidatesRequiredFieldsWithActionableDiagnostics() throws {
    let service = WeaponCompendiumJSONImportService()

    func expectImportError(
        _ data: Data,
        equals expected: WeaponCompendiumImportError,
        description expectedDescription: String
    ) {
        do {
            _ = try service.import(data)
            Issue.record("Expected compendium import to fail with \(expected)")
        } catch let error as WeaponCompendiumImportError {
            #expect(error == expected)
            #expect(error.errorDescription == expectedDescription)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    expectImportError(
        try compendiumImportData(
            catalogID: "   ",
            displayName: "Imported Cogitator Vault"
        ),
        equals: .invalidCatalogID,
        description: "Weapon compendium import failed: catalog id is required."
    )

    expectImportError(
        try compendiumImportData(
            catalogID: "imported-catalog",
            displayName: "   "
        ),
        equals: .invalidCatalogDisplayName,
        description: "Weapon compendium import failed: catalog display name is required."
    )

    expectImportError(
        try compendiumImportData(
            catalogID: "imported-catalog",
            displayName: "Imported Cogitator Vault",
            definitions: [
                [
                    "id": "   ",
                    "name": "Mnemonic Pistol"
                ]
            ]
        ),
        equals: .invalidDefinitionID(index: 0),
        description: "Weapon compendium import failed: definition #1 is missing an id."
    )

    expectImportError(
        try compendiumImportData(
            catalogID: "imported-catalog",
            displayName: "Imported Cogitator Vault",
            definitions: [
                [
                    "id": "imported-catalog.mnemonic-pistol",
                    "name": "   "
                ]
            ]
        ),
        equals: .invalidDefinitionName(index: 0),
        description: "Weapon compendium import failed: definition #1 is missing a name."
    )
}

@Test func weaponCompendiumImportRejectsDuplicateDefinitionIDs() throws {
    let service = WeaponCompendiumJSONImportService()

    do {
        _ = try service.import(
            compendiumImportData(
                catalogID: "imported-catalog",
                displayName: "Imported Cogitator Vault",
                definitions: [
                    [
                        "id": "imported-catalog.mnemonic-pistol",
                        "name": "Mnemonic Pistol"
                    ],
                    [
                        "id": "imported-catalog.mnemonic-pistol",
                        "name": "Mnemonic Pistol Variant"
                    ]
                ]
            )
        )
        Issue.record("Expected duplicate definition ids to fail")
    } catch let error as WeaponCompendiumImportError {
        #expect(error == .duplicateDefinitionIDs(["imported-catalog.mnemonic-pistol"]))
        #expect(
            error.errorDescription ==
                "Weapon compendium import failed: duplicate definition ids found (imported-catalog.mnemonic-pistol)."
        )
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test func editingWeaponInstanceDoesNotMutateCompendiumDefinition() {
    guard let definition = WeaponCompendiumCatalog.demo.definition(id: "local-demo.laspistol") else {
        Issue.record("Expected demo laspistol definition")
        return
    }

    var customWeapon = definition.makeWeaponInstance()
    customWeapon.name = "Custom Laspistol"
    customWeapon.penetration = "1"
    customWeapon.traits = "Reliable, Custom Sight"

    #expect(definition.name == "Laspistol")
    #expect(definition.penetration == "0")
    #expect(definition.traitsText == "Reliable")
}

@MainActor
@Test func cancelPendingWeaponCompendiumImportLeavesCurrentCatalogUnchanged() async throws {
    let characterRepository = JSONFileCharacterRepository(fileURL: uniqueCompendiumTestFileURL("characters"))
    let characterUseCases = CharacterUseCases(repository: characterRepository)
    let compendiumRepository = JSONFileWeaponCompendiumRepository(fileURL: uniqueCompendiumTestFileURL("catalog-cancel"))
    let compendiumUseCases = WeaponCompendiumUseCases(repository: compendiumRepository)
    let importService = WeaponCompendiumJSONImportService()
    let viewModel = CharacterListViewModel(
        useCases: characterUseCases,
        importExportService: CharacterJSONImportExportService(),
        armourCompendiumUseCases: ArmourCompendiumUseCases(
            repository: JSONFileArmourCompendiumRepository(
                fileURL: uniqueCompendiumTestFileURL("armour-catalog-cancel")
            )
        ),
        weaponCompendiumUseCases: compendiumUseCases,
        weaponCompendiumImportService: importService
    )

    await viewModel.load()
    let before = try await compendiumUseCases.currentCatalog()
    let data = try compendiumImportData(
        catalogID: "imported-catalog",
        displayName: "Imported Cogitator Vault"
    )

    await viewModel.prepareWeaponCompendiumImport(data)
    #expect(viewModel.pendingWeaponCompendiumImportSummary?.importedCatalogName == "Imported Cogitator Vault")

    viewModel.cancelPendingWeaponCompendiumImport()

    let after = try await compendiumUseCases.currentCatalog()
    #expect(viewModel.pendingWeaponCompendiumImportSummary == nil)
    #expect(after == before)
}

@Test func compendiumWeaponInstancePersistsThroughAcceptedEquipmentFlow() async throws {
    let fileURL = uniqueCompendiumTestFileURL("equipment-compendium-copy")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Compendium Weapon"))
    guard let definition = WeaponCompendiumCatalog.demo.definition(id: "local-demo.autogun") else {
        Issue.record("Expected demo autogun definition")
        return
    }

    var copiedWeapon = definition.makeWeaponInstance()
    copiedWeapon.name = "Field-Tuned Autogun"
    copiedWeapon.traits = "Reliable, Sling"

    let updated = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(weapons: [copiedWeapon])
    )
    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(updated.equipment.weapons == [copiedWeapon])
    #expect(persisted?.equipment.weapons == [copiedWeapon])
    #expect(definition.name == "Autogun")
    #expect(definition.traitsText == "Reliable")
}

@Test func replacingCompendiumDoesNotMutateExistingCharacterOwnedWeapons() async throws {
    let characterFileURL = uniqueCompendiumTestFileURL("equipment-detached-after-replace")
    let characterRepository = JSONFileCharacterRepository(fileURL: characterFileURL)
    let characterUseCases = CharacterUseCases(repository: characterRepository)
    let compendiumRepository = JSONFileWeaponCompendiumRepository(fileURL: uniqueCompendiumTestFileURL("catalog-replace"))
    let compendiumUseCases = WeaponCompendiumUseCases(repository: compendiumRepository)
    let importService = WeaponCompendiumJSONImportService()

    let created = try await characterUseCases.createCharacter(profile: Profile(name: "Detached Weapon Safety"))
    guard let definition = WeaponCompendiumCatalog.demo.definition(id: "local-demo.laspistol") else {
        Issue.record("Expected demo laspistol definition")
        return
    }

    var detachedWeapon = definition.makeWeaponInstance()
    detachedWeapon.name = "Legacy Laspistol"
    detachedWeapon.penetration = "1"
    _ = try await characterUseCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(weapons: [detachedWeapon])
    )

    let importedCatalog = try importService.import(
        compendiumImportData(
            catalogID: "imported-catalog",
            displayName: "Imported Cogitator Vault",
            definitions: [
                [
                    "id": "imported-catalog.mnemonic-pistol",
                    "name": "Mnemonic Pistol",
                    "penetration": "3"
                ]
            ]
        )
    )
    _ = try await compendiumUseCases.replaceCatalog(importedCatalog)

    let persistedCharacter = try await characterRepository.fetch(id: created.id)
    let currentCatalog = try await compendiumUseCases.currentCatalog()

    #expect(persistedCharacter?.equipment.weapons == [detachedWeapon])
    #expect(currentCatalog.displayName == "Imported Cogitator Vault")
    #expect(currentCatalog.definition(id: "imported-catalog.mnemonic-pistol")?.name == "Mnemonic Pistol")
}

private func uniqueCompendiumTestFileURL(_ suffix: String) -> URL {
    FileManager.default.temporaryDirectory
        .appending(path: "dh-charlist-\(suffix)-\(UUID().uuidString).json")
}

private func compendiumImportData(
    schemaVersion: Int = 1,
    catalogID: String,
    displayName: String,
    definitions: [[String: Any]] = [
        [
            "id": "imported-catalog.mnemonic-pistol",
            "name": "Mnemonic Pistol",
            "type": "Pistol",
            "range": "25m",
            "damage": "1d10+3 E",
            "penetration": "3",
            "clip": "12",
            "reload": "Half",
            "traits": ["Compact", "Reliable"]
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
