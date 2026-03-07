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
    public let importExportService: any CharacterImportExportService

    public init(characterUseCases: CharacterUseCases, importExportService: any CharacterImportExportService) {
        self.characterUseCases = characterUseCases
        self.importExportService = importExportService
    }

    public static func live(persistence: PersistenceBackend = .jsonFile) -> AppContainer {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let importExportService = CharacterJSONImportExportService()
        let repository = makeRepository(
            persistence: persistence,
            documentsDirectory: documentsDirectory,
            importExportService: importExportService
        )

        return AppContainer(
            characterUseCases: CharacterUseCases(repository: repository),
            importExportService: importExportService
        )
    }

    private static func makeRepository(
        persistence: PersistenceBackend,
        documentsDirectory: URL,
        importExportService: CharacterJSONImportExportService
    ) -> any CharacterRepository {
        let jsonFileURL = documentsDirectory.appending(path: "dh_characters.json")
        let jsonRepository = JSONFileCharacterRepository(fileURL: jsonFileURL, importExport: importExportService)

        guard persistence == .swiftData else {
            return jsonRepository
        }

#if canImport(SwiftData)
        if #available(iOS 17, macOS 14, *) {
            do {
                let swiftDataURL = documentsDirectory.appending(path: "dh_characters.store")
                let configuration = ModelConfiguration(url: swiftDataURL)
                let modelContainer = try ModelContainer(for: SwiftDataCharacterRecord.self, configurations: configuration)
                return SwiftDataCharacterRepository(modelContext: ModelContext(modelContainer))
            } catch {
                return jsonRepository
            }
        }
#endif

        return jsonRepository
    }
}
