import Foundation
import Testing
@testable import DHCharList

@Test func derivedValueCalculatorUsesCharacteristicAndTraining() {
    let characteristics = CharacteristicSet(weaponSkill: 40, ballisticSkill: 30, strength: 35, toughness: 32, agility: 45, intelligence: 28, perception: 31, willpower: 37, fellowship: 26)
    let skill = Skill(name: "Awareness", characteristic: .perception, training: .trained)

    #expect(DerivedValueCalculator.skillTarget(for: skill, characteristics: characteristics) == 41)
}

@Test func importExportRoundtrip() throws {
    let service = CharacterJSONImportExportService()
    let source = Character(profile: Profile(name: "Raibos"), skills: [Skill(name: "Stealth", characteristic: .agility, training: .known)])

    let data = try service.exportCharacters([source])
    let decoded = try service.import(data)

    #expect(decoded.count == 1)
    #expect(decoded.first?.profile.name == "Raibos")
}

@Test func importRejectsUnsupportedSchema() throws {
    let envelope = CharacterExportEnvelope(schemaVersion: 999, exportedAt: .now, characters: [])
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601

    let data = try encoder.encode(envelope)
    let service = CharacterJSONImportExportService()

    #expect(throws: CharacterRepositoryError.self) {
        _ = try service.import(data)
    }
}

@Test func jsonRepositoryCRUD() async throws {
    let fileURL = URL(filePath: NSTemporaryDirectory()).appending(path: "dh_charlist_tests.json")
    try? FileManager.default.removeItem(at: fileURL)

    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let character = Character(profile: Profile(name: "Acolyte"))

    try await repository.save(character)
    let listed = try await repository.fetchAll()
    #expect(listed.count == 1)

    try await repository.delete(id: character.id)
    let deleted = try await repository.fetchAll()
    #expect(deleted.isEmpty)
}
