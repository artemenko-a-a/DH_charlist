import Foundation

public struct CharacterUseCases: Sendable {
    private let repository: CharacterRepository

    public init(repository: CharacterRepository) {
        self.repository = repository
    }

    public func listCharacters() async throws -> [Character] {
        try await repository.fetchAll().sorted { $0.updatedAt > $1.updatedAt }
    }

    public func fetchCharacter(id: UUID) async throws -> Character? {
        try await repository.fetch(id: id)
    }

    public func upsertCharacter(_ character: Character) async throws {
        var mutable = character
        mutable.updatedAt = .now
        try await repository.save(mutable)
    }

    public func createCharacter(profile: Profile = .init()) async throws -> Character {
        let character = Character(profile: profile)
        try await repository.save(character)
        return character
    }

    public func updateProfile(characterID: UUID, profile: Profile) async throws -> Character {
        guard var character = try await repository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }
        character.profile = profile
        character.updatedAt = .now
        try await repository.save(character)
        return character
    }

    public func updateCharacteristics(characterID: UUID, characteristics: CharacteristicSet) async throws -> Character {
        guard var character = try await repository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }
        character.characteristics = characteristics
        character.updatedAt = .now
        try await repository.save(character)
        return character
    }

    public func updateResources(characterID: UUID, resources: ResourceState) async throws -> Character {
        guard var character = try await repository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }
        character.resources = normalizedResources(resources)
        character.updatedAt = .now
        try await repository.save(character)
        return character
    }

    public func updateSkills(characterID: UUID, skills: [Skill]) async throws -> Character {
        guard var character = try await repository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }
        character.skills = skills
        character.updatedAt = .now
        try await repository.save(character)
        return character
    }

    public func updateNotes(characterID: UUID, notes: NotesState) async throws -> Character {
        guard var character = try await repository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }
        character.notes = notes
        character.updatedAt = .now
        try await repository.save(character)
        return character
    }

    public func updateEquipment(characterID: UUID, equipment: EquipmentState) async throws -> Character {
        guard var character = try await repository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }
        character.equipment = equipment
        character.updatedAt = .now
        try await repository.save(character)
        return character
    }

    public func updateSession(characterID: UUID, session: SessionState) async throws -> Character {
        guard var character = try await repository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }
        character.session = session
        character.updatedAt = .now
        try await repository.save(character)
        return character
    }

    public func listHistory(characterID: UUID) async throws -> [CharacterHistoryEntry] {
        guard let character = try await repository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }
        return character.history.sorted { $0.createdAt > $1.createdAt }
    }

    public func addHistoryEntry(
        characterID: UUID,
        type: CharacterHistoryEntryType,
        title: String,
        body: String,
        tags: [String] = []
    ) async throws -> CharacterHistoryEntry {
        guard var character = try await repository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }

        let entry = CharacterHistoryEntry(
            characterID: characterID,
            title: title,
            type: type,
            body: body,
            tags: normalizedTags(tags)
        )
        character.history.append(entry)
        character.updatedAt = .now
        try await repository.save(character)
        return entry
    }

    public func updateHistoryEntry(characterID: UUID, entry: CharacterHistoryEntry) async throws -> CharacterHistoryEntry {
        guard var character = try await repository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }
        guard entry.characterID == characterID else {
            throw CharacterRepositoryError.invalidData("History entry character mismatch")
        }

        guard let index = character.history.firstIndex(where: { $0.id == entry.id }) else {
            throw CharacterRepositoryError.notFound
        }

        var updated = entry
        updated.tags = normalizedTags(entry.tags)
        character.history[index] = updated
        character.updatedAt = .now
        try await repository.save(character)
        return updated
    }

    public func deleteHistoryEntry(characterID: UUID, entryID: UUID) async throws {
        guard var character = try await repository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }
        character.history.removeAll { $0.id == entryID }
        character.updatedAt = .now
        try await repository.save(character)
    }

    public func deleteCharacter(id: UUID) async throws {
        try await repository.delete(id: id)
    }

    public func duplicateCharacter(id: UUID) async throws -> Character {
        guard var character = try await repository.fetch(id: id) else {
            throw CharacterRepositoryError.notFound
        }
        character.id = UUID()
        character.history = []
        character.updatedAt = .now
        character.profile.name = character.profile.name.isEmpty ? "Copy" : "\(character.profile.name) Copy"
        try await repository.save(character)
        return character
    }

    public func exportCharacters(using service: any CharacterImportExportService) async throws -> Data {
        let characters = try await repository.fetchAll()
        return try service.exportCharacters(characters)
    }

    @discardableResult
    public func importCharacters(from data: Data, using service: any CharacterImportExportService) async throws -> Int {
        let imported = try service.import(data)
        try await repository.replaceAll(with: imported)

        return imported.count
    }

    private func normalizedTags(_ tags: [String]) -> [String] {
        tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func normalizedResources(_ resources: ResourceState) -> ResourceState {
        let maxWounds = max(0, resources.maxWounds)
        let maxFate = max(0, resources.maxFate)
        let experienceTotal = max(0, resources.experienceTotal)
        let experienceSpent = min(max(0, resources.experienceSpent), experienceTotal)

        return ResourceState(
            currentWounds: min(max(0, resources.currentWounds), maxWounds),
            maxWounds: maxWounds,
            fatigue: max(0, resources.fatigue),
            corruption: max(0, resources.corruption),
            insanity: max(0, resources.insanity),
            currentFate: min(max(0, resources.currentFate), maxFate),
            maxFate: maxFate,
            experienceSpent: experienceSpent,
            experienceTotal: experienceTotal
        )
    }
}

public enum DerivedValueCalculator {
    public static func characteristicTarget(
        for characteristic: SkillCharacteristic,
        characteristics: CharacteristicSet,
        modifiers: Int = 0
    ) -> Int {
        MechanicsCheckResolver
            .resolve(.characteristic(characteristic, characteristics: characteristics, modifier: modifiers))
            .finalTarget
    }

    public static func skillTarget(for skill: Skill, characteristics: CharacteristicSet, modifiers: Int = 0) -> Int {
        MechanicsCheckResolver
            .resolve(.skill(skill, characteristics: characteristics, modifier: modifiers))
            .finalTarget
    }
}
