import Foundation
import Testing
@testable import DHCharList

private struct IntentionalSwiftDataBootstrapFailure: LocalizedError {
    var errorDescription: String? {
        "Intentional SwiftData bootstrap failure"
    }
}

@Test func jsonBootstrapStatusExposesJSONAsActiveBackend() async throws {
    let documentsDirectory = try makeBatch32TemporaryDirectory()
    let container = AppContainer.live(persistence: .jsonFile, documentsDirectory: documentsDirectory)

    #expect(container.persistenceStatus.requestedBackend == .jsonFile)
    #expect(container.persistenceStatus.activeBackend == .jsonFile)
    #expect(container.persistenceStatus.didFallback == false)
    #expect(container.persistenceStatus.diagnosticNote == nil)

    _ = try await container.characterUseCases.createCharacter(profile: Profile(name: "JSON Backend"))
    let characters = try await container.characterUseCases.listCharacters()
    #expect(characters.count == 1)
    #expect(characters.first?.profile.name == "JSON Backend")
}

#if canImport(SwiftData)
@available(iOS 17, macOS 14, *)
@Test func swiftDataBootstrapStatusExposesSwiftDataAsActiveBackend() async throws {
    let documentsDirectory = try makeBatch32TemporaryDirectory()
    let container = AppContainer.live(persistence: .swiftData, documentsDirectory: documentsDirectory)

    #expect(container.persistenceStatus.requestedBackend == .swiftData)
    #expect(container.persistenceStatus.activeBackend == .swiftData)
    #expect(container.persistenceStatus.didFallback == false)
    #expect(container.persistenceStatus.diagnosticNote == nil)

    _ = try await container.characterUseCases.createCharacter(profile: Profile(name: "SwiftData Backend"))
    let characters = try await container.characterUseCases.listCharacters()
    #expect(characters.count == 1)
    #expect(characters.first?.profile.name == "SwiftData Backend")
}
#endif

@Test func swiftDataBootstrapFailureFallsBackToJSONWithDiagnosticReason() async throws {
    let documentsDirectory = try makeBatch32TemporaryDirectory()
    let container = AppContainer.live(
        persistence: .swiftData,
        documentsDirectory: documentsDirectory,
        swiftDataFactory: { _ in
            throw IntentionalSwiftDataBootstrapFailure()
        }
    )

    #expect(container.persistenceStatus.requestedBackend == .swiftData)
    #expect(container.persistenceStatus.activeBackend == .jsonFile)
    #expect(container.persistenceStatus.didFallback == true)
    #expect(container.persistenceStatus.diagnosticNote?.contains("Intentional SwiftData bootstrap failure") == true)

    _ = try await container.characterUseCases.createCharacter(profile: Profile(name: "Fallback JSON"))
    let characters = try await container.characterUseCases.listCharacters()
    #expect(characters.count == 1)
    #expect(characters.first?.profile.name == "Fallback JSON")
}

private func makeBatch32TemporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "dh_charlist_batch32_\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}
