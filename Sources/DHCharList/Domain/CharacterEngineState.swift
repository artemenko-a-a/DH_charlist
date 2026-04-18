import Foundation

struct DHIICharacterEngineState: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var creation: DHIICreationPersistedState?

    init(schemaVersion: Int = currentSchemaVersion, creation: DHIICreationPersistedState? = nil) {
        self.schemaVersion = schemaVersion
        self.creation = creation
    }
}

struct DHIICreationPersistedState: Codable, Equatable, Sendable {
    var homeWorldID: DHIIHomeWorldID?
    var backgroundID: DHIIBackgroundID?
    var roleID: DHIIRoleID?
    var backgroundAptitudeChoice: String?
    var roleAptitudeChoice: String?
    var homeWorldTalentChoice: String?
    var backgroundSkillChoices: [String]
    var backgroundTalentChoice: String?
    var backgroundEquipmentChoices: [String]
    var roleTalentChoice: String?
    var startingWoundsRoll: Int?
    var startingFateRoll: Int?
    var legacyFallbackAptitudes: [String]
    var characteristicGenerationState: DHIIPersistedCharacteristicGenerationState?
}

struct DHIIPersistedRandomCharacteristicRoll: Codable, Equatable, Sendable {
    var characteristic: DHIICreationCharacteristic
    var rolls: [Int]
}

struct DHIIPersistedRandomCharacteristicGenerationState: Codable, Equatable, Sendable {
    var generatedForHomeWorldID: DHIIHomeWorldID?
    var rollsByCharacteristic: [DHIIPersistedRandomCharacteristicRoll]
    var rerolledCharacteristic: DHIICreationCharacteristic?
}

struct DHIIPersistedPointAllocationCharacteristicGenerationState: Codable, Equatable, Sendable {
    var allocations: DHIICreationCharacteristicValues
}

enum DHIIPersistedCharacteristicGenerationState: Codable, Equatable, Sendable {
    case randomRoll(DHIIPersistedRandomCharacteristicGenerationState)
    case pointAllocation(DHIIPersistedPointAllocationCharacteristicGenerationState)

    private enum CodingKeys: String, CodingKey {
        case kind
        case randomRoll
        case pointAllocation
    }

    private enum Kind: String, Codable {
        case randomRoll
        case pointAllocation
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .randomRoll:
            self = .randomRoll(try container.decode(DHIIPersistedRandomCharacteristicGenerationState.self, forKey: .randomRoll))
        case .pointAllocation:
            self = .pointAllocation(try container.decode(DHIIPersistedPointAllocationCharacteristicGenerationState.self, forKey: .pointAllocation))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .randomRoll(let state):
            try container.encode(Kind.randomRoll, forKey: .kind)
            try container.encode(state, forKey: .randomRoll)
        case .pointAllocation(let state):
            try container.encode(Kind.pointAllocation, forKey: .kind)
            try container.encode(state, forKey: .pointAllocation)
        }
    }
}
