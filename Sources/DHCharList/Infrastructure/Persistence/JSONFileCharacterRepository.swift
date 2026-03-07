import Foundation

public actor JSONFileCharacterRepository: CharacterRepository {
    private let fileURL: URL
    private let importExport: CharacterJSONImportExportService

    public init(fileURL: URL, importExport: CharacterJSONImportExportService = .init()) {
        self.fileURL = fileURL
        self.importExport = importExport
    }

    public func fetchAll() async throws -> [Character] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try importExport.import(data)
    }

    public func fetch(id: UUID) async throws -> Character? {
        try await fetchAll().first(where: { $0.id == id })
    }

    public func save(_ character: Character) async throws {
        var all = try await fetchAll()
        if let idx = all.firstIndex(where: { $0.id == character.id }) {
            all[idx] = character
        } else {
            all.append(character)
        }
        try persist(all)
    }

    public func delete(id: UUID) async throws {
        var all = try await fetchAll()
        all.removeAll { $0.id == id }
        try persist(all)
    }

    private func persist(_ characters: [Character]) throws {
        let data = try importExport.exportCharacters(characters)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}
