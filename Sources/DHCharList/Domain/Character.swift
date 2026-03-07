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
        self.updatedAt = updatedAt
    }
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
    case veteran

    public var modifier: Int {
        switch self {
        case .untrained: return -20
        case .known: return 0
        case .trained: return 10
        case .veteran: return 20
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

    public init(modeEnabled: Bool = false, pinnedChecks: [String] = [], temporaryModifiers: [String: Int] = [:]) {
        self.modeEnabled = modeEnabled
        self.pinnedChecks = pinnedChecks
        self.temporaryModifiers = temporaryModifiers
    }
}
