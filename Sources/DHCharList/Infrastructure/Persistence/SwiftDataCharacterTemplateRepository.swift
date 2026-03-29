#if canImport(SwiftData) && canImport(SwiftDataMacros)
import Foundation
import SwiftData

@available(iOS 17, macOS 14, *)
@Model
final class SwiftDataCharacterTemplateRecord {
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
struct SwiftDataCharacterTemplateMapper {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
        self.encoder = encoder
        self.decoder = decoder
    }

    func makeRecord(from template: CharacterTemplate) throws -> SwiftDataCharacterTemplateRecord {
        let payload = try encoder.encode(template)
        return SwiftDataCharacterTemplateRecord(id: template.id, updatedAt: template.updatedAt, payload: payload)
    }

    func update(_ record: SwiftDataCharacterTemplateRecord, from template: CharacterTemplate) throws {
        record.updatedAt = template.updatedAt
        record.payload = try encoder.encode(template)
    }

    func makeTemplate(from record: SwiftDataCharacterTemplateRecord) throws -> CharacterTemplate {
        try decoder.decode(CharacterTemplate.self, from: record.payload)
    }
}

@available(iOS 17, macOS 14, *)
public actor SwiftDataCharacterTemplateRepository: CharacterTemplateRepository {
    private let modelContext: ModelContext
    private let mapper: SwiftDataCharacterTemplateMapper

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.mapper = .init()
    }

    public func fetchAll() async throws -> [CharacterTemplate] {
        let descriptor = FetchDescriptor<SwiftDataCharacterTemplateRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let records = try modelContext.fetch(descriptor)
        return try records.map { try mapper.makeTemplate(from: $0) }
    }

    public func fetch(id: UUID) async throws -> CharacterTemplate? {
        var descriptor = FetchDescriptor<SwiftDataCharacterTemplateRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return try mapper.makeTemplate(from: record)
    }

    public func save(_ template: CharacterTemplate) async throws {
        var descriptor = FetchDescriptor<SwiftDataCharacterTemplateRecord>(
            predicate: #Predicate { $0.id == template.id }
        )
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            try mapper.update(existing, from: template)
        } else {
            modelContext.insert(try mapper.makeRecord(from: template))
        }
        try modelContext.save()
    }

    public func delete(id: UUID) async throws {
        var descriptor = FetchDescriptor<SwiftDataCharacterTemplateRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let record = try modelContext.fetch(descriptor).first else {
            return
        }
        modelContext.delete(record)
        try modelContext.save()
    }
}
#endif
