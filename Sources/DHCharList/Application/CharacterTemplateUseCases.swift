import Foundation

public struct CharacterTemplateUseCases: Sendable {
    private let characterRepository: CharacterRepository
    private let templateRepository: CharacterTemplateRepository

    public init(characterRepository: CharacterRepository, templateRepository: CharacterTemplateRepository) {
        self.characterRepository = characterRepository
        self.templateRepository = templateRepository
    }

    public func listTemplates() async throws -> [CharacterTemplate] {
        try await templateRepository.fetchAll().sorted { $0.updatedAt > $1.updatedAt }
    }

    public func createCharacterFromTemplate(templateID: UUID) async throws -> Character {
        guard let template = try await templateRepository.fetch(id: templateID) else {
            throw CharacterRepositoryError.notFound
        }
        let character = template.makeCharacter()
        try await characterRepository.save(character)
        return character
    }

    public func saveCharacterAsTemplate(characterID: UUID, name: String? = nil) async throws -> CharacterTemplate {
        guard let character = try await characterRepository.fetch(id: characterID) else {
            throw CharacterRepositoryError.notFound
        }

        let templateName = resolvedTemplateName(
            explicitName: name,
            fallbackCharacterName: character.profile.name
        )
        var template = CharacterTemplate(name: templateName, source: character)
        template.updatedAt = .now
        try await templateRepository.save(template)
        return template
    }

    public func renameTemplate(id: UUID, name: String) async throws -> CharacterTemplate {
        guard var template = try await templateRepository.fetch(id: id) else {
            throw CharacterRepositoryError.notFound
        }
        template.name = normalizedTemplateName(name)
        template.updatedAt = .now
        try await templateRepository.save(template)
        return template
    }

    public func duplicateTemplate(id: UUID) async throws -> CharacterTemplate {
        guard var duplicate = try await templateRepository.fetch(id: id) else {
            throw CharacterRepositoryError.notFound
        }
        duplicate.id = UUID()
        duplicate.updatedAt = .now
        duplicate.name = duplicate.name.isEmpty ? "Template Copy" : "\(duplicate.name) Copy"
        try await templateRepository.save(duplicate)
        return duplicate
    }

    public func deleteTemplate(id: UUID) async throws {
        try await templateRepository.delete(id: id)
    }

    private func resolvedTemplateName(explicitName: String?, fallbackCharacterName: String) -> String {
        let explicit = explicitName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !explicit.isEmpty {
            return explicit
        }

        let characterName = fallbackCharacterName.trimmingCharacters(in: .whitespacesAndNewlines)
        return characterName.isEmpty ? "New Template" : "\(characterName) Template"
    }

    private func normalizedTemplateName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Template" : trimmed
    }
}
