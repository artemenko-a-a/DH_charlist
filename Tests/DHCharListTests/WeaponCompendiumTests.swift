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

private func uniqueCompendiumTestFileURL(_ suffix: String) -> URL {
    FileManager.default.temporaryDirectory
        .appending(path: "dh-charlist-\(suffix)-\(UUID().uuidString).json")
}
