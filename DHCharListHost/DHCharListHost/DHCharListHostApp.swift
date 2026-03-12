//
//  DHCharListHostApp.swift
//  DHCharListHost
//
//  Created by Артеменко Андрей Александрович on 07.03.2026.
//

import SwiftUI
import DHCharList

@main
struct DHCharListHostApp: App {
    private let launchConfiguration = DHCharListHostLaunchConfiguration.from()

    var body: some Scene {
        WindowGroup {
            HostBootstrapView(launchConfiguration: launchConfiguration)
        }
    }
}

private struct HostBootstrapView: View {
    let launchConfiguration: DHCharListHostLaunchConfiguration

    @State private var isReady = false
    @State private var container: AppContainer
    @State private var stagedImportPayload: Data?
    @State private var stagedWeaponCompendiumImportPayload: Data?

    init(launchConfiguration: DHCharListHostLaunchConfiguration) {
        self.launchConfiguration = launchConfiguration
        _container = State(initialValue: .live(persistence: launchConfiguration.persistence))
    }

    var body: some View {
        Group {
            if isReady {
                DHCharListAppShell(
                    container: container,
                    initialImportPayload: stagedImportPayload,
                    initialWeaponCompendiumImportPayload: stagedWeaponCompendiumImportPayload
                )
                    .accessibilityIdentifier("host.app.shell")
            } else {
                ProgressView("Preparing")
                    .accessibilityIdentifier("host.bootstrap.progress")
            }
        }
        .task {
            await bootstrapIfNeeded()
            isReady = true
        }
    }

    private func bootstrapIfNeeded() async {
        guard launchConfiguration.isUITesting else {
            return
        }

        if launchConfiguration.shouldResetData {
            await resetLocalData()
        }

        if launchConfiguration.shouldSeedSmokeData {
            await seedSmokeDataIfNeeded()
        }

        if launchConfiguration.shouldStageImportPreview {
            await stageImportPreviewIfNeeded()
        }

        if launchConfiguration.shouldStageWeaponCompendiumImport {
            stageWeaponCompendiumImportIfNeeded()
        }
    }

    private func resetLocalData() async {
        do {
            for template in try await container.templateUseCases.listTemplates() {
                try await container.templateUseCases.deleteTemplate(id: template.id)
            }

            for character in try await container.characterUseCases.listCharacters() {
                try await container.characterUseCases.deleteCharacter(id: character.id)
            }

            _ = try await container.weaponCompendiumUseCases.replaceCatalog(.demo)
        } catch {
            // Intentionally ignore reset failures during test bootstrap.
        }
    }

    private func seedSmokeDataIfNeeded() async {
        do {
            if try await !container.characterUseCases.listCharacters().isEmpty {
                return
            }

            _ = try await container.characterUseCases.createCharacter(
                profile: Profile(
                    name: "Smoke Acolyte",
                    homeWorld: "Hive World",
                    background: "Adeptus Administratum",
                    role: "Seeker",
                    aptitudes: ["Perception", "Intelligence"],
                    description: "Deterministic UI smoke seed"
                )
            )
        } catch {
            // Intentionally ignore seed failures; tests will fail visibly if data is missing.
        }
    }

    private func stageImportPreviewIfNeeded() async {
        let stagedCharacter = Character(
            profile: Profile(
                name: "Imported Preview",
                homeWorld: "Voidborn",
                background: "Imperial Navy",
                role: "Seeker",
                aptitudes: ["Perception"],
                description: "Staged replace-all preview payload"
            )
        )
        stagedImportPayload = try? container.importExportService.exportCharacters([stagedCharacter])
    }

    private func stageWeaponCompendiumImportIfNeeded() {
        stagedWeaponCompendiumImportPayload = """
        {
          "schemaVersion": 1,
          "catalog": {
            "id": "ui-imported",
            "displayName": "UI Imported Catalog",
            "definitions": [
              {
                "id": "ui-imported.mnemonic-pistol",
                "name": "Mnemonic Pistol",
                "type": "Pistol",
                "range": "25m",
                "damage": "1d10+3 E",
                "penetration": "3",
                "clip": "12",
                "reload": "Half",
                "traits": ["Compact", "Reliable"],
                "notes": "Deterministic UI import seed"
              }
            ]
          }
        }
        """.data(using: .utf8)
    }
}
