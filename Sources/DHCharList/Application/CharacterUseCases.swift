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

    public func createCharacter(named name: String) async throws -> Character {
        let character = Character(profile: Profile(name: name))
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
