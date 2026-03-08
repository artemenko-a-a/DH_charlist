import Foundation

public actor JSONFileCharacterTemplateRepository: CharacterTemplateRepository {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func fetchAll() async throws -> [CharacterTemplate] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([CharacterTemplate].self, from: data)
    }

    public func fetch(id: UUID) async throws -> CharacterTemplate? {
        try await fetchAll().first(where: { $0.id == id })
    }

    public func save(_ template: CharacterTemplate) async throws {
        var all = try await fetchAll()
        if let index = all.firstIndex(where: { $0.id == template.id }) {
            all[index] = template
        } else {
            all.append(template)
        }
        try persist(all)
    }

    public func delete(id: UUID) async throws {
        var all = try await fetchAll()
        all.removeAll { $0.id == id }
        try persist(all)
    }

    private func persist(_ templates: [CharacterTemplate]) throws {
        let data = try encoder.encode(templates)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}
