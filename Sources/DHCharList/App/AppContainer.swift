import Foundation

public struct AppContainer: Sendable {
    public let characterUseCases: CharacterUseCases

    public init(characterUseCases: CharacterUseCases) {
        self.characterUseCases = characterUseCases
    }

    public static func live() -> AppContainer {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileURL = documentsDirectory.appending(path: "dh_characters.json")
        let repository = JSONFileCharacterRepository(fileURL: fileURL)
        return AppContainer(characterUseCases: CharacterUseCases(repository: repository))
    }
}
