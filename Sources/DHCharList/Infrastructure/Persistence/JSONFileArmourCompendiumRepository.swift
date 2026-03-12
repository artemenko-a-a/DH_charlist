import Foundation

public actor JSONFileArmourCompendiumRepository: ArmourCompendiumRepository {
    private let fileURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(fileURL: URL) {
        self.fileURL = fileURL
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func fetchCatalog() async throws -> ArmourCompendiumCatalog? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(ArmourCompendiumCatalog.self, from: data)
    }

    public func saveCatalog(_ catalog: ArmourCompendiumCatalog) async throws {
        let data = try encoder.encode(catalog)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
    }
}
