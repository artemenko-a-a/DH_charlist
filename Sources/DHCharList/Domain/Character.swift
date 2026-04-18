import Foundation

public struct Character: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var profile: Profile
    public var characteristics: CharacteristicSet
    public var resources: ResourceState
    public var skills: [Skill]
    public var notes: NotesState
    public var equipment: EquipmentState
    public var session: SessionState
    public var history: [CharacterHistoryEntry]
    var dhiiEngineState: DHIICharacterEngineState?
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        profile: Profile,
        characteristics: CharacteristicSet = .empty,
        resources: ResourceState = .init(),
        skills: [Skill] = [],
        notes: NotesState = .init(),
        equipment: EquipmentState = .init(),
        session: SessionState = .init(),
        history: [CharacterHistoryEntry] = [],
        updatedAt: Date = .now
    ) {
        self.id = id
        self.profile = profile
        self.characteristics = characteristics
        self.resources = resources
        self.skills = skills
        self.notes = notes
        self.equipment = equipment
        self.session = session
        self.history = history
        dhiiEngineState = nil
        self.updatedAt = updatedAt
    }

    init(
        id: UUID = UUID(),
        profile: Profile,
        characteristics: CharacteristicSet = .empty,
        resources: ResourceState = .init(),
        skills: [Skill] = [],
        notes: NotesState = .init(),
        equipment: EquipmentState = .init(),
        session: SessionState = .init(),
        history: [CharacterHistoryEntry] = [],
        dhiiEngineState: DHIICharacterEngineState? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.profile = profile
        self.characteristics = characteristics
        self.resources = resources
        self.skills = skills
        self.notes = notes
        self.equipment = equipment
        self.session = session
        self.history = history
        self.dhiiEngineState = dhiiEngineState
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case profile
        case characteristics
        case resources
        case skills
        case notes
        case equipment
        case session
        case history
        case dhiiEngineState
        case updatedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        profile = try container.decode(Profile.self, forKey: .profile)
        characteristics = try container.decode(CharacteristicSet.self, forKey: .characteristics)
        resources = try container.decode(ResourceState.self, forKey: .resources)
        skills = try container.decode([Skill].self, forKey: .skills)
        notes = try container.decode(NotesState.self, forKey: .notes)
        equipment = try container.decode(EquipmentState.self, forKey: .equipment)
        session = try container.decode(SessionState.self, forKey: .session)
        history = try container.decodeIfPresent([CharacterHistoryEntry].self, forKey: .history) ?? []
        dhiiEngineState = try container.decodeIfPresent(DHIICharacterEngineState.self, forKey: .dhiiEngineState)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(profile, forKey: .profile)
        try container.encode(characteristics, forKey: .characteristics)
        try container.encode(resources, forKey: .resources)
        try container.encode(skills, forKey: .skills)
        try container.encode(notes, forKey: .notes)
        try container.encode(equipment, forKey: .equipment)
        try container.encode(session, forKey: .session)
        try container.encode(history, forKey: .history)
        try container.encodeIfPresent(dhiiEngineState, forKey: .dhiiEngineState)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

public struct CharacterHistoryEntry: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var characterID: UUID
    public var createdAt: Date
    public var title: String
    public var type: CharacterHistoryEntryType
    public var body: String
    public var tags: [String]

    public init(
        id: UUID = UUID(),
        characterID: UUID,
        createdAt: Date = .now,
        title: String,
        type: CharacterHistoryEntryType,
        body: String = "",
        tags: [String] = []
    ) {
        self.id = id
        self.characterID = characterID
        self.createdAt = createdAt
        self.title = title
        self.type = type
        self.body = body
        self.tags = tags
    }
}

public enum CharacterHistoryEntryType: String, Codable, CaseIterable, Sendable {
    case sessionNote
    case advancement
    case injury
    case corruptionOrInsanity
    case equipmentChange
    case storyNote
    case custom
}

public struct Profile: Codable, Equatable, Sendable {
    public var name: String
    public var homeWorld: String
    public var background: String
    public var role: String
    public var aptitudes: [String]
    public var description: String

    public init(name: String = "", homeWorld: String = "", background: String = "", role: String = "", aptitudes: [String] = [], description: String = "") {
        self.name = name
        self.homeWorld = homeWorld
        self.background = background
        self.role = role
        self.aptitudes = aptitudes
        self.description = description
    }
}

public struct CharacteristicSet: Codable, Equatable, Sendable {
    public var weaponSkill: Int
    public var ballisticSkill: Int
    public var strength: Int
    public var toughness: Int
    public var agility: Int
    public var intelligence: Int
    public var perception: Int
    public var willpower: Int
    public var fellowship: Int

    public static let empty = CharacteristicSet(weaponSkill: 0, ballisticSkill: 0, strength: 0, toughness: 0, agility: 0, intelligence: 0, perception: 0, willpower: 0, fellowship: 0)

    public var bonus: CharacteristicBonus {
        CharacteristicBonus(
            weaponSkill: weaponSkill / 10,
            ballisticSkill: ballisticSkill / 10,
            strength: strength / 10,
            toughness: toughness / 10,
            agility: agility / 10,
            intelligence: intelligence / 10,
            perception: perception / 10,
            willpower: willpower / 10,
            fellowship: fellowship / 10
        )
    }

    public init(weaponSkill: Int, ballisticSkill: Int, strength: Int, toughness: Int, agility: Int, intelligence: Int, perception: Int, willpower: Int, fellowship: Int) {
        self.weaponSkill = weaponSkill
        self.ballisticSkill = ballisticSkill
        self.strength = strength
        self.toughness = toughness
        self.agility = agility
        self.intelligence = intelligence
        self.perception = perception
        self.willpower = willpower
        self.fellowship = fellowship
    }
}

public struct CharacteristicBonus: Codable, Equatable, Sendable {
    public var weaponSkill: Int
    public var ballisticSkill: Int
    public var strength: Int
    public var toughness: Int
    public var agility: Int
    public var intelligence: Int
    public var perception: Int
    public var willpower: Int
    public var fellowship: Int
}

public struct ResourceState: Codable, Equatable, Sendable {
    public var currentWounds: Int
    public var maxWounds: Int
    public var fatigue: Int
    public var corruption: Int
    public var insanity: Int
    public var currentFate: Int
    public var maxFate: Int
    public var experienceSpent: Int
    public var experienceTotal: Int

    public init(currentWounds: Int = 0, maxWounds: Int = 0, fatigue: Int = 0, corruption: Int = 0, insanity: Int = 0, currentFate: Int = 0, maxFate: Int = 0, experienceSpent: Int = 0, experienceTotal: Int = 0) {
        self.currentWounds = currentWounds
        self.maxWounds = maxWounds
        self.fatigue = fatigue
        self.corruption = corruption
        self.insanity = insanity
        self.currentFate = currentFate
        self.maxFate = maxFate
        self.experienceSpent = experienceSpent
        self.experienceTotal = experienceTotal
    }

    public var experienceAvailable: Int { max(0, experienceTotal - experienceSpent) }
}

public enum SkillTrainingLevel: String, Codable, CaseIterable, Sendable {
    case untrained
    case known
    case trained
    case experienced
    case veteran

    public var modifier: Int {
        switch self {
        case .untrained: return -20
        case .known: return 0
        case .trained: return 10
        case .experienced: return 20
        case .veteran: return 30
        }
    }
}

public struct Skill: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var characteristic: SkillCharacteristic
    public var training: SkillTrainingLevel
    public var specialisations: [String]

    public init(id: UUID = UUID(), name: String, characteristic: SkillCharacteristic, training: SkillTrainingLevel = .untrained, specialisations: [String] = []) {
        self.id = id
        self.name = name
        self.characteristic = characteristic
        self.training = training
        self.specialisations = specialisations
    }
}

public enum SkillCharacteristic: String, Codable, CaseIterable, Sendable {
    case weaponSkill, ballisticSkill, strength, toughness, agility, intelligence, perception, willpower, fellowship
}

public struct NotesState: Codable, Equatable, Sendable {
    public var talents: [String]
    public var traits: [String]
    public var mutations: [String]
    public var disorders: [String]
    public var psychicPowers: [String]
    public var specialAbilities: [String]
    public var notes: String

    public init(talents: [String] = [], traits: [String] = [], mutations: [String] = [], disorders: [String] = [], psychicPowers: [String] = [], specialAbilities: [String] = [], notes: String = "") {
        self.talents = talents
        self.traits = traits
        self.mutations = mutations
        self.disorders = disorders
        self.psychicPowers = psychicPowers
        self.specialAbilities = specialAbilities
        self.notes = notes
    }
}

public struct EquipmentState: Codable, Equatable, Sendable {
    public var weapons: [Weapon]
    public var armour: [Armour]
    public var movement: MovementProfile
    public var inventory: [InventoryItem]

    public init(weapons: [Weapon] = [], armour: [Armour] = [], movement: MovementProfile = .init(), inventory: [InventoryItem] = []) {
        self.weapons = weapons
        self.armour = armour
        self.movement = movement
        self.inventory = inventory
    }
}

public struct Weapon: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var type: String
    public var range: String
    public var damage: String
    public var penetration: String
    public var clip: String
    public var reload: String
    public var traits: String

    public init(id: UUID = UUID(), name: String, type: String = "", range: String = "", damage: String = "", penetration: String = "", clip: String = "", reload: String = "", traits: String = "") {
        self.id = id
        self.name = name
        self.type = type
        self.range = range
        self.damage = damage
        self.penetration = penetration
        self.clip = clip
        self.reload = reload
        self.traits = traits
    }
}

public struct Armour: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var location: String
    public var armourPoints: Int

    public init(id: UUID = UUID(), location: String, armourPoints: Int) {
        self.id = id
        self.location = location
        self.armourPoints = armourPoints
    }
}

public struct MovementProfile: Codable, Equatable, Sendable {
    public var halfMove: Int
    public var fullMove: Int
    public var charge: Int
    public var run: Int

    public init(halfMove: Int = 0, fullMove: Int = 0, charge: Int = 0, run: Int = 0) {
        self.halfMove = halfMove
        self.fullMove = fullMove
        self.charge = charge
        self.run = run
    }
}

public struct InventoryItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var quantity: Int
    public var weight: Double

    public init(id: UUID = UUID(), name: String, quantity: Int = 1, weight: Double = 0) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.weight = weight
    }
}

public struct SessionState: Codable, Equatable, Sendable {
    public var modeEnabled: Bool
    public var pinnedChecks: [String]
    public var temporaryModifiers: [String: Int]
    public var activeWeaponID: UUID?
    public var combatConditions: [String]

    public init(
        modeEnabled: Bool = false,
        pinnedChecks: [String] = [],
        temporaryModifiers: [String: Int] = [:],
        activeWeaponID: UUID? = nil,
        combatConditions: [String] = []
    ) {
        self.modeEnabled = modeEnabled
        self.pinnedChecks = pinnedChecks
        self.temporaryModifiers = temporaryModifiers
        self.activeWeaponID = activeWeaponID
        self.combatConditions = combatConditions
    }

    private enum CodingKeys: String, CodingKey {
        case modeEnabled
        case pinnedChecks
        case temporaryModifiers
        case activeWeaponID
        case combatConditions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modeEnabled = try container.decodeIfPresent(Bool.self, forKey: .modeEnabled) ?? false
        pinnedChecks = try container.decodeIfPresent([String].self, forKey: .pinnedChecks) ?? []
        temporaryModifiers = try container.decodeIfPresent([String: Int].self, forKey: .temporaryModifiers) ?? [:]
        activeWeaponID = try container.decodeIfPresent(UUID.self, forKey: .activeWeaponID)
        combatConditions = try container.decodeIfPresent([String].self, forKey: .combatConditions) ?? []
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(modeEnabled, forKey: .modeEnabled)
        try container.encode(pinnedChecks, forKey: .pinnedChecks)
        try container.encode(temporaryModifiers, forKey: .temporaryModifiers)
        try container.encodeIfPresent(activeWeaponID, forKey: .activeWeaponID)
        try container.encode(combatConditions, forKey: .combatConditions)
    }
}
