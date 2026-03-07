import Foundation

public struct CharacterUseCases: Sendable {
    private let repository: CharacterRepository

    public init(repository: CharacterRepository) {
        self.repository = repository
    }

    public func listCharacters() async throws -> [Character] {
        try await repository.fetchAll().sorted { $0.updatedAt > $1.updatedAt }
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

    public func deleteCharacter(id: UUID) async throws {
        try await repository.delete(id: id)
    }

    public func duplicateCharacter(id: UUID) async throws -> Character {
        guard var character = try await repository.fetch(id: id) else {
            throw CharacterRepositoryError.notFound
        }
        character.id = UUID()
        character.updatedAt = .now
        character.profile.name = character.profile.name.isEmpty ? "Copy" : "\(character.profile.name) Copy"
        try await repository.save(character)
        return character
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
