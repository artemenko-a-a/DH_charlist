import Foundation
import Testing
@testable import DHCharList

@Test func raibosSeedContainsExpectedProfileAndPlayableData() {
    let character = RaibosCharacterSeed.character

    #expect(character.id == RaibosCharacterSeed.characterID)
    #expect(character.profile.name == "Райбос-2 Д-2")
    #expect(character.profile.homeWorld == "Мир-кузница Райбос")
    #expect(character.profile.role == "Хирургеон")
    #expect(character.characteristics.intelligence == 52)
    #expect(character.resources.currentWounds == 14)
    #expect(character.skills.contains { $0.name == "Медика" && $0.training == .veteran })
    #expect(character.equipment.weapons.contains { $0.name == "Лазган" })
    #expect(character.session.pinnedChecks.contains("Технопользование"))
}

@Test func raibosSeedBootstrapAddsCharacterWhenRosterLacksIt() async throws {
    let repository = JSONFileCharacterRepository(fileURL: uniqueTestFileURL("raibos-seed-missing"))
    let useCases = CharacterUseCases(repository: repository)
    let existing = try await useCases.createCharacter(profile: Profile(name: "Existing Acolyte"))
    let marker = RaibosSeedMarker()
    let bootstrap = RaibosCharacterSeedBootstrap(
        isSeeded: { marker.isSeeded },
        markSeeded: { marker.isSeeded = true }
    )

    try await bootstrap.seedIfNeeded(useCases: useCases)

    let characters = try await useCases.listCharacters()
    #expect(marker.isSeeded)
    #expect(characters.contains { $0.id == existing.id && $0.profile.name == "Existing Acolyte" })
    #expect(characters.contains { $0.id == RaibosCharacterSeed.characterID && $0.profile.name == "Райбос-2 Д-2" })
    #expect(characters.count == 2)
}

@Test func raibosSeedBootstrapDoesNotDuplicateExistingRaibos() async throws {
    let repository = JSONFileCharacterRepository(fileURL: uniqueTestFileURL("raibos-seed-present"))
    let useCases = CharacterUseCases(repository: repository)
    var existingRaibos = RaibosCharacterSeed.character
    existingRaibos.resources.currentWounds = 9
    try await useCases.upsertCharacter(existingRaibos)
    let marker = RaibosSeedMarker()
    let bootstrap = RaibosCharacterSeedBootstrap(
        isSeeded: { marker.isSeeded },
        markSeeded: { marker.isSeeded = true }
    )

    try await bootstrap.seedIfNeeded(useCases: useCases)

    let characters = try await useCases.listCharacters()
    let raibosCharacters = characters.filter(RaibosCharacterSeed.matches)
    #expect(marker.isSeeded)
    #expect(raibosCharacters.count == 1)
    #expect(raibosCharacters.first?.resources.currentWounds == 9)
}

@Test func raibosSeedBootstrapSkipsRepositoryWhenMarkerIsAlreadySet() async throws {
    let repository = JSONFileCharacterRepository(fileURL: uniqueTestFileURL("raibos-seed-marker"))
    let useCases = CharacterUseCases(repository: repository)
    let marker = RaibosSeedMarker(isSeeded: true)
    let bootstrap = RaibosCharacterSeedBootstrap(
        isSeeded: { marker.isSeeded },
        markSeeded: { marker.isSeeded = true }
    )

    try await bootstrap.seedIfNeeded(useCases: useCases)

    let characters = try await useCases.listCharacters()
    #expect(characters.isEmpty)
}

private final class RaibosSeedMarker {
    var isSeeded: Bool

    init(isSeeded: Bool = false) {
        self.isSeeded = isSeeded
    }
}

private func uniqueTestFileURL(_ suffix: String) -> URL {
    FileManager.default.temporaryDirectory
        .appending(path: "dh_charlist_\(suffix)_\(UUID().uuidString).json")
}
