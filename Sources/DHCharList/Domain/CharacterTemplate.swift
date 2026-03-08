import Foundation

public struct CharacterTemplate: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var profile: Profile
    public var characteristics: CharacteristicSet
    public var resources: ResourceState
    public var skills: [Skill]
    public var notes: NotesState
    public var equipment: EquipmentState
    public var session: SessionState
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        profile: Profile,
        characteristics: CharacteristicSet = .empty,
        resources: ResourceState = .init(),
        skills: [Skill] = [],
        notes: NotesState = .init(),
        equipment: EquipmentState = .init(),
        session: SessionState = .init(),
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.profile = profile
        self.characteristics = characteristics
        self.resources = resources
        self.skills = skills
        self.notes = notes
        self.equipment = equipment
        self.session = session
        self.updatedAt = updatedAt
    }

    public init(name: String, source character: Character) {
        self.init(
            name: name,
            profile: character.profile,
            characteristics: character.characteristics,
            resources: character.resources,
            skills: character.skills,
            notes: character.notes,
            equipment: character.equipment,
            session: character.session
        )
    }

    public func makeCharacter(profileNameOverride: String? = nil) -> Character {
        var profile = self.profile
        if let override = profileNameOverride {
            profile.name = override
        }

        return Character(
            profile: profile,
            characteristics: characteristics,
            resources: resources,
            skills: skills,
            notes: notes,
            equipment: equipment,
            session: session,
            updatedAt: .now
        )
    }
}
