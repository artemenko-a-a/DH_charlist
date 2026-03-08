import Foundation

public protocol CharacterTemplateRepository: Sendable {
    func fetchAll() async throws -> [CharacterTemplate]
    func fetch(id: UUID) async throws -> CharacterTemplate?
    func save(_ template: CharacterTemplate) async throws
    func delete(id: UUID) async throws
}
