import Foundation

public struct AppContainer: Sendable {
    public let characterUseCases: CharacterUseCases
    public let importExportService: any CharacterImportExportService

    public init(characterUseCases: CharacterUseCases, importExportService: any CharacterImportExportService) {
        self.characterUseCases = characterUseCases
        self.importExportService = importExportService
    }

    public static func live() -> AppContainer {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = documentsDirectory.appending(path: "dh_characters.json")
        let importExportService = CharacterJSONImportExportService()
        let repository = JSONFileCharacterRepository(fileURL: fileURL, importExport: importExportService)
        return AppContainer(
            characterUseCases: CharacterUseCases(repository: repository),
            importExportService: importExportService
        )
    }
}
