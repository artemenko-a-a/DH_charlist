import Foundation
#if canImport(SwiftData) && (canImport(SwiftDataMacros) || Xcode)
import SwiftData
#endif

public struct AppContainer: Sendable {
    public enum PersistenceBackend: String, Sendable {
        case jsonFile
        case swiftData
    }

    public struct PersistenceBootstrapStatus: Sendable, Equatable {
        public let requestedBackend: PersistenceBackend
        public let activeBackend: PersistenceBackend
        public let diagnosticNote: String?

        public init(
            requestedBackend: PersistenceBackend,
            activeBackend: PersistenceBackend,
            diagnosticNote: String? = nil
        ) {
            self.requestedBackend = requestedBackend
            self.activeBackend = activeBackend
            self.diagnosticNote = diagnosticNote
        }

        public var didFallback: Bool {
            requestedBackend != activeBackend
        }
    }

    typealias SwiftDataRepositoryFactory = @Sendable (URL) throws -> (
        characterRepository: any CharacterRepository,
        templateRepository: any CharacterTemplateRepository
    )

    struct PersistenceBootstrapResult: Sendable {
        let characterRepository: any CharacterRepository
        let templateRepository: any CharacterTemplateRepository
        let status: PersistenceBootstrapStatus
    }

    public let characterUseCases: CharacterUseCases
    public let templateUseCases: CharacterTemplateUseCases
    public let importExportService: any CharacterImportExportService
    public let armourCompendiumUseCases: ArmourCompendiumUseCases
    public let armourCompendiumImportService: ArmourCompendiumJSONImportService
    public let weaponCompendiumUseCases: WeaponCompendiumUseCases
    public let weaponCompendiumImportService: WeaponCompendiumJSONImportService
    public let persistenceStatus: PersistenceBootstrapStatus

    public init(
        characterUseCases: CharacterUseCases,
        templateUseCases: CharacterTemplateUseCases,
        importExportService: any CharacterImportExportService,
        armourCompendiumUseCases: ArmourCompendiumUseCases,
        armourCompendiumImportService: ArmourCompendiumJSONImportService,
        weaponCompendiumUseCases: WeaponCompendiumUseCases,
        weaponCompendiumImportService: WeaponCompendiumJSONImportService,
        persistenceStatus: PersistenceBootstrapStatus
    ) {
        self.characterUseCases = characterUseCases
        self.templateUseCases = templateUseCases
        self.importExportService = importExportService
        self.armourCompendiumUseCases = armourCompendiumUseCases
        self.armourCompendiumImportService = armourCompendiumImportService
        self.weaponCompendiumUseCases = weaponCompendiumUseCases
        self.weaponCompendiumImportService = weaponCompendiumImportService
        self.persistenceStatus = persistenceStatus
    }

    public static func live(persistence: PersistenceBackend = .jsonFile) -> AppContainer {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return live(persistence: persistence, documentsDirectory: documentsDirectory)
    }

    static func live(
        persistence: PersistenceBackend,
        documentsDirectory: URL,
        swiftDataFactory: SwiftDataRepositoryFactory? = nil
    ) -> AppContainer {
        let importExportService = CharacterJSONImportExportService()
        let armourCompendiumImportService = ArmourCompendiumJSONImportService()
        let weaponCompendiumImportService = WeaponCompendiumJSONImportService()
        let bootstrap = makePersistenceBootstrap(
            persistence: persistence,
            documentsDirectory: documentsDirectory,
            importExportService: importExportService,
            swiftDataFactory: swiftDataFactory
        )
        let armourCompendiumRepository = JSONFileArmourCompendiumRepository(
            fileURL: documentsDirectory.appending(path: "dh_armour_compendium.json")
        )
        let weaponCompendiumRepository = JSONFileWeaponCompendiumRepository(
            fileURL: documentsDirectory.appending(path: "dh_weapon_compendium.json")
        )

        return AppContainer(
            characterUseCases: CharacterUseCases(repository: bootstrap.characterRepository),
            templateUseCases: CharacterTemplateUseCases(
                characterRepository: bootstrap.characterRepository,
                templateRepository: bootstrap.templateRepository
            ),
            importExportService: importExportService,
            armourCompendiumUseCases: ArmourCompendiumUseCases(repository: armourCompendiumRepository),
            armourCompendiumImportService: armourCompendiumImportService,
            weaponCompendiumUseCases: WeaponCompendiumUseCases(repository: weaponCompendiumRepository),
            weaponCompendiumImportService: weaponCompendiumImportService,
            persistenceStatus: bootstrap.status
        )
    }

    static func makePersistenceBootstrap(
        persistence: PersistenceBackend,
        documentsDirectory: URL,
        importExportService: CharacterJSONImportExportService,
        swiftDataFactory: SwiftDataRepositoryFactory? = nil
    ) -> PersistenceBootstrapResult {
        let jsonCharacterURL = documentsDirectory.appending(path: "dh_characters.json")
        let jsonTemplateURL = documentsDirectory.appending(path: "dh_templates.json")
        let jsonCharacterRepository = JSONFileCharacterRepository(fileURL: jsonCharacterURL, importExport: importExportService)
        let jsonTemplateRepository = JSONFileCharacterTemplateRepository(fileURL: jsonTemplateURL)

        guard persistence == .swiftData else {
            return PersistenceBootstrapResult(
                characterRepository: jsonCharacterRepository,
                templateRepository: jsonTemplateRepository,
                status: PersistenceBootstrapStatus(
                    requestedBackend: .jsonFile,
                    activeBackend: .jsonFile
                )
            )
        }

#if canImport(SwiftData) && (canImport(SwiftDataMacros) || Xcode)
        if #available(iOS 17, macOS 14, *) {
            do {
                let repositories = try makeSwiftDataRepositories(
                    documentsDirectory: documentsDirectory,
                    swiftDataFactory: swiftDataFactory
                )
                return PersistenceBootstrapResult(
                    characterRepository: repositories.characterRepository,
                    templateRepository: repositories.templateRepository,
                    status: PersistenceBootstrapStatus(
                        requestedBackend: .swiftData,
                        activeBackend: .swiftData
                    )
                )
            } catch {
                return PersistenceBootstrapResult(
                    characterRepository: jsonCharacterRepository,
                    templateRepository: jsonTemplateRepository,
                    status: PersistenceBootstrapStatus(
                        requestedBackend: .swiftData,
                        activeBackend: .jsonFile,
                        diagnosticNote: "SwiftData bootstrap failed: \(bootstrapDiagnosticMessage(for: error))"
                    )
                )
            }
        }

        return PersistenceBootstrapResult(
            characterRepository: jsonCharacterRepository,
            templateRepository: jsonTemplateRepository,
            status: PersistenceBootstrapStatus(
                requestedBackend: .swiftData,
                activeBackend: .jsonFile,
                diagnosticNote: "SwiftData runtime is unavailable here; using JSON fallback."
            )
        )
#else
        return PersistenceBootstrapResult(
            characterRepository: jsonCharacterRepository,
            templateRepository: jsonTemplateRepository,
            status: PersistenceBootstrapStatus(
                requestedBackend: .swiftData,
                activeBackend: .jsonFile,
                diagnosticNote: "SwiftData is unavailable in this build; using JSON fallback."
            )
        )
#endif
    }

    static func bootstrapDiagnosticMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
           !description.isEmpty {
            return description
        }

        let localizedDescription = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localizedDescription.isEmpty {
            return localizedDescription
        }

        return String(describing: error)
    }

#if canImport(SwiftData) && (canImport(SwiftDataMacros) || Xcode)
    @available(iOS 17, macOS 14, *)
    private static func makeSwiftDataRepositories(
        documentsDirectory: URL,
        swiftDataFactory: SwiftDataRepositoryFactory?
    ) throws -> (
        characterRepository: any CharacterRepository,
        templateRepository: any CharacterTemplateRepository
    ) {
        let storeURL = documentsDirectory.appending(path: "dh_characters.store")
        if let swiftDataFactory {
            return try swiftDataFactory(storeURL)
        }

        let configuration = ModelConfiguration(url: storeURL)
        let modelContainer = try ModelContainer(
            for: SwiftDataCharacterRecord.self,
            SwiftDataCharacterTemplateRecord.self,
            configurations: configuration
        )
        return (
            SwiftDataCharacterRepository(modelContext: ModelContext(modelContainer)),
            SwiftDataCharacterTemplateRepository(modelContext: ModelContext(modelContainer))
        )
    }
#endif
}
