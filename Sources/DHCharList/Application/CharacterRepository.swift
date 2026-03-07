import Foundation

public protocol CharacterRepository: Sendable {
    func fetchAll() async throws -> [Character]
    func fetch(id: UUID) async throws -> Character?
    func save(_ character: Character) async throws
    func delete(id: UUID) async throws
}

public protocol CharacterImportExportService: Sendable {
    func exportCharacters(_ characters: [Character]) throws -> Data
    func `import`(_ data: Data) throws -> [Character]
}

public enum CharacterRepositoryError: Error, Equatable {
    case notFound
    case persistenceFailure(String)
    case invalidData(String)
}
