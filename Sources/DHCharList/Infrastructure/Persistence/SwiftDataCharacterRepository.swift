#if canImport(SwiftData) && (canImport(SwiftDataMacros) || Xcode)
import Foundation
import SwiftData

@available(iOS 17, macOS 14, *)
@Model
final class SwiftDataCharacterRecord {
    @Attribute(.unique) var id: UUID
    var updatedAt: Date
    var payload: Data

    init(id: UUID, updatedAt: Date, payload: Data) {
        self.id = id
        self.updatedAt = updatedAt
        self.payload = payload
    }
}

@available(iOS 17, macOS 14, *)
struct SwiftDataCharacterMapper {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
        self.encoder = encoder
        self.decoder = decoder
    }

    func makeRecord(from character: Character) throws -> SwiftDataCharacterRecord {
        let payload = try encoder.encode(character)
        return SwiftDataCharacterRecord(id: character.id, updatedAt: character.updatedAt, payload: payload)
    }

    func update(_ record: SwiftDataCharacterRecord, from character: Character) throws {
        record.updatedAt = character.updatedAt
        record.payload = try encoder.encode(character)
    }

    func makeCharacter(from record: SwiftDataCharacterRecord) throws -> Character {
        try decoder.decode(Character.self, from: record.payload)
    }
}

@available(iOS 17, macOS 14, *)
public actor SwiftDataCharacterRepository: CharacterRepository {
    private let modelContext: ModelContext
    private let mapper: SwiftDataCharacterMapper

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.mapper = .init()
    }

    public func fetchAll() async throws -> [Character] {
        let descriptor = FetchDescriptor<SwiftDataCharacterRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let records = try modelContext.fetch(descriptor)
        return try records.map { try mapper.makeCharacter(from: $0) }
    }

    public func fetch(id: UUID) async throws -> Character? {
        var descriptor = FetchDescriptor<SwiftDataCharacterRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return try mapper.makeCharacter(from: record)
    }

    public func save(_ character: Character) async throws {
        var descriptor = FetchDescriptor<SwiftDataCharacterRecord>(
            predicate: #Predicate { $0.id == character.id }
        )
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            try mapper.update(existing, from: character)
        } else {
            modelContext.insert(try mapper.makeRecord(from: character))
        }
        try modelContext.save()
    }

    public func delete(id: UUID) async throws {
        var descriptor = FetchDescriptor<SwiftDataCharacterRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else {
            return
        }
        modelContext.delete(record)
        try modelContext.save()
    }

    public func replaceAll(with characters: [Character]) async throws {
        let existingRecords = try modelContext.fetch(FetchDescriptor<SwiftDataCharacterRecord>())
        let incomingByID = Dictionary(uniqueKeysWithValues: characters.map { ($0.id, $0) })

        for record in existingRecords {
            if let incoming = incomingByID[record.id] {
                try mapper.update(record, from: incoming)
            } else {
                modelContext.delete(record)
            }
        }

        let existingIDs = Set(existingRecords.map(\.id))
        for character in characters where !existingIDs.contains(character.id) {
            modelContext.insert(try mapper.makeRecord(from: character))
        }

        try modelContext.save()
    }
}
#endif
