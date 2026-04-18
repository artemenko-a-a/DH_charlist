import Foundation

public struct CharacterExportEnvelope: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let exportedAt: Date
    public let characters: [CharacterDTO]

    public init(schemaVersion: Int = 1, exportedAt: Date = .now, characters: [CharacterDTO]) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.characters = characters
    }
}

public struct CharacterDTO: Codable, Equatable, Sendable {
    public let id: UUID
    public let profile: Profile
    public let characteristics: CharacteristicSet
    public let resources: ResourceState
    public let skills: [Skill]
    public let notes: NotesState
    public let equipment: EquipmentState
    public let session: SessionState
    public let history: [CharacterHistoryEntry]
    let dhiiEngineState: DHIICharacterEngineState?
    public let updatedAt: Date

    public init(character: Character) {
        id = character.id
        profile = character.profile
        characteristics = character.characteristics
        resources = character.resources
        skills = character.skills
        notes = character.notes
        equipment = character.equipment
        session = character.session
        history = character.history
        dhiiEngineState = character.dhiiEngineState
        updatedAt = character.updatedAt
    }

    public var domain: Character {
        Character(
            id: id,
            profile: profile,
            characteristics: characteristics,
            resources: resources,
            skills: skills,
            notes: notes,
            equipment: equipment,
            session: session,
            history: history,
            dhiiEngineState: dhiiEngineState,
            updatedAt: updatedAt
        )
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
}

public struct CharacterJSONImportExportService: CharacterImportExportService {
    public static let supportedSchema = 2
    // Older builds intentionally reject envelopes emitted by newer schema
    // versions. Within supported schemas, additive fields remain tolerant via
    // decodeIfPresent-based DTO decoding.
    static let supportedSchemas: Set<Int> = [1, 2]

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    public func exportCharacters(_ characters: [Character]) throws -> Data {
        let envelope = CharacterExportEnvelope(
            schemaVersion: Self.supportedSchema,
            characters: characters.map(CharacterDTO.init(character:))
        )
        return try encoder.encode(envelope)
    }

    public func `import`(_ data: Data) throws -> [Character] {
        let envelope = try decoder.decode(CharacterExportEnvelope.self, from: data)
        guard Self.supportedSchemas.contains(envelope.schemaVersion) else {
            throw CharacterRepositoryError.invalidData("Unsupported schema version: \(envelope.schemaVersion)")
        }
        return envelope.characters.map(\.domain)
    }
}
