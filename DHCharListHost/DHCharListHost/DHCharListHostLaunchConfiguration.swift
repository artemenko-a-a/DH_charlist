import Foundation
import DHCharList

struct DHCharListHostLaunchConfiguration {
    static let uiTestingArgument = "-dh-uitesting"
    static let resetDataArgument = "-dh-ui-reset-data"
    static let seedSmokeDataArgument = "-dh-ui-seed-smoke"
    static let stageImportPreviewArgument = "-dh-ui-stage-import-preview"
    static let stageWeaponCompendiumImportArgument = "-dh-ui-stage-weapon-compendium-import"
    static let persistenceJSONArgument = "-dh-ui-persistence-json"
    static let persistenceSwiftDataArgument = "-dh-ui-persistence-swiftdata"

    let isUITesting: Bool
    let shouldResetData: Bool
    let shouldSeedSmokeData: Bool
    let shouldStageImportPreview: Bool
    let shouldStageWeaponCompendiumImport: Bool
    let persistence: AppContainer.PersistenceBackend

    static func from(processInfo: ProcessInfo = .processInfo) -> DHCharListHostLaunchConfiguration {
        from(arguments: processInfo.arguments)
    }

    static func from(arguments: [String]) -> DHCharListHostLaunchConfiguration {
        let argumentSet = Set(arguments)

        let isUITesting = argumentSet.contains(uiTestingArgument)
        let shouldResetData = argumentSet.contains(resetDataArgument)
        let shouldSeedSmokeData = argumentSet.contains(seedSmokeDataArgument)
        let shouldStageImportPreview = argumentSet.contains(stageImportPreviewArgument)
        let shouldStageWeaponCompendiumImport = argumentSet.contains(stageWeaponCompendiumImportArgument)

        let persistence: AppContainer.PersistenceBackend
        if argumentSet.contains(persistenceSwiftDataArgument) {
            persistence = .swiftData
        } else {
            persistence = .jsonFile
        }

        return DHCharListHostLaunchConfiguration(
            isUITesting: isUITesting,
            shouldResetData: shouldResetData,
            shouldSeedSmokeData: shouldSeedSmokeData,
            shouldStageImportPreview: shouldStageImportPreview,
            shouldStageWeaponCompendiumImport: shouldStageWeaponCompendiumImport,
            persistence: persistence
        )
    }
}
