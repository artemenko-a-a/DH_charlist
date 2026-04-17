import Foundation
import Testing
@testable import DHCharList

private struct IntentionalSwiftDataBootstrapFailure: LocalizedError {
    var errorDescription: String? {
        "Intentional SwiftData bootstrap failure"
    }
}

private struct BlankLocalizedBootstrapError: LocalizedError, CustomStringConvertible {
    var errorDescription: String? { "   " }
    var description: String { "BlankLocalizedBootstrapError(description fallback)" }
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

#if canImport(SwiftData) && (canImport(SwiftDataMacros) || Xcode)
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
#if canImport(SwiftData) && (canImport(SwiftDataMacros) || Xcode)
    #expect(container.persistenceStatus.diagnosticNote?.contains("Intentional SwiftData bootstrap failure") == true)
#else
    #expect(container.persistenceStatus.diagnosticNote?.contains("SwiftData is unavailable in this build") == true)
#endif

    _ = try await container.characterUseCases.createCharacter(profile: Profile(name: "Fallback JSON"))
    let characters = try await container.characterUseCases.listCharacters()
    #expect(characters.count == 1)
    #expect(characters.first?.profile.name == "Fallback JSON")
}

@Test func bootstrapDiagnosticMessagePrefersLocalizedErrorDescription() {
    let message = AppContainer.bootstrapDiagnosticMessage(for: IntentionalSwiftDataBootstrapFailure())

    #expect(message == "Intentional SwiftData bootstrap failure")
}

@Test func bootstrapDiagnosticMessageFallsBackToNSErrorLocalizedDescription() {
    let error = NSError(
        domain: "DHCharList.Tests",
        code: 42,
        userInfo: [NSLocalizedDescriptionKey: "  NSError-provided bootstrap note  "]
    )

    let message = AppContainer.bootstrapDiagnosticMessage(for: error)

    #expect(message == "NSError-provided bootstrap note")
}

@Test func bootstrapDiagnosticMessageUsesStringDescriptionWhenDescriptionsAreBlank() {
    let message = AppContainer.bootstrapDiagnosticMessage(for: BlankLocalizedBootstrapError())

    #expect(message == "BlankLocalizedBootstrapError(description fallback)")
}

private func makeBatch32TemporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "dh_charlist_batch32_\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}
