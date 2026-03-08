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
        character.resources = resources
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
        let existing = try await repository.fetchAll()
        let importedIDs = Set(imported.map(\.id))

        for character in imported {
            try await repository.save(character)
        }

        for character in existing where !importedIDs.contains(character.id) {
            try await repository.delete(id: character.id)
        }

        return imported.count
    }

    private func normalizedTags(_ tags: [String]) -> [String] {
        tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

public enum DerivedValueCalculator {
    public static func skillTarget(for skill: Skill, characteristics: CharacteristicSet, modifiers: Int = 0) -> Int {
        let base = switch skill.characteristic {
        case .weaponSkill: characteristics.weaponSkill
        case .ballisticSkill: characteristics.ballisticSkill
        case .strength: characteristics.strength
        case .toughness: characteristics.toughness
        case .agility: characteristics.agility
        case .intelligence: characteristics.intelligence
        case .perception: characteristics.perception
        case .willpower: characteristics.willpower
        case .fellowship: characteristics.fellowship
        }
        return base + skill.training.modifier + modifiers
    }
}
