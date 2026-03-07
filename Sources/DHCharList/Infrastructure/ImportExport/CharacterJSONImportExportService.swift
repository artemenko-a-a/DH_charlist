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
        updatedAt = character.updatedAt
    }

    public var domain: Character {
        Character(id: id, profile: profile, characteristics: characteristics, resources: resources, skills: skills, notes: notes, equipment: equipment, session: session, updatedAt: updatedAt)
    }
}

public struct CharacterJSONImportExportService: CharacterImportExportService {
    public static let supportedSchema = 1

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
        let envelope = CharacterExportEnvelope(characters: characters.map(CharacterDTO.init(character:)))
        return try encoder.encode(envelope)
    }

    public func `import`(_ data: Data) throws -> [Character] {
        let envelope = try decoder.decode(CharacterExportEnvelope.self, from: data)
        guard envelope.schemaVersion == Self.supportedSchema else {
            throw CharacterRepositoryError.invalidData("Unsupported schema version: \(envelope.schemaVersion)")
        }
        return envelope.characters.map(\.domain)
    }
}
