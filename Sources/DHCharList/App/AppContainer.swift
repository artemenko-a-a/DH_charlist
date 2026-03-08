import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

public struct AppContainer: Sendable {
    public enum PersistenceBackend: String, Sendable {
        case jsonFile
        case swiftData
    }

    public let characterUseCases: CharacterUseCases
    public let templateUseCases: CharacterTemplateUseCases
    public let importExportService: any CharacterImportExportService

    public init(
        characterUseCases: CharacterUseCases,
        templateUseCases: CharacterTemplateUseCases,
        importExportService: any CharacterImportExportService
    ) {
        self.characterUseCases = characterUseCases
        self.templateUseCases = templateUseCases
        self.importExportService = importExportService
    }

    public static func live(persistence: PersistenceBackend = .jsonFile) -> AppContainer {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let importExportService = CharacterJSONImportExportService()
        let repositories = makeRepositories(
            persistence: persistence,
            documentsDirectory: documentsDirectory,
            importExportService: importExportService
        )

        return AppContainer(
            characterUseCases: CharacterUseCases(repository: repositories.characterRepository),
            templateUseCases: CharacterTemplateUseCases(
                characterRepository: repositories.characterRepository,
                templateRepository: repositories.templateRepository
            ),
            importExportService: importExportService
        )
    }

    private static func makeRepositories(
        persistence: PersistenceBackend,
        documentsDirectory: URL,
        importExportService: CharacterJSONImportExportService
    ) -> (characterRepository: any CharacterRepository, templateRepository: any CharacterTemplateRepository) {
        let jsonCharacterURL = documentsDirectory.appending(path: "dh_characters.json")
        let jsonTemplateURL = documentsDirectory.appending(path: "dh_templates.json")
        let jsonCharacterRepository = JSONFileCharacterRepository(fileURL: jsonCharacterURL, importExport: importExportService)
        let jsonTemplateRepository = JSONFileCharacterTemplateRepository(fileURL: jsonTemplateURL)

        guard persistence == .swiftData else {
            return (jsonCharacterRepository, jsonTemplateRepository)
        }

#if canImport(SwiftData)
        if #available(iOS 17, macOS 14, *) {
            do {
                let swiftDataURL = documentsDirectory.appending(path: "dh_characters.store")
                let configuration = ModelConfiguration(url: swiftDataURL)
                let modelContainer = try ModelContainer(
                    for: SwiftDataCharacterRecord.self,
                    SwiftDataCharacterTemplateRecord.self,
                    configurations: configuration
                )
                return (
                    SwiftDataCharacterRepository(modelContext: ModelContext(modelContainer)),
                    SwiftDataCharacterTemplateRepository(modelContext: ModelContext(modelContainer))
                )
            } catch {
                return (jsonCharacterRepository, jsonTemplateRepository)
            }
        }
#endif

        return (jsonCharacterRepository, jsonTemplateRepository)
    }
}
