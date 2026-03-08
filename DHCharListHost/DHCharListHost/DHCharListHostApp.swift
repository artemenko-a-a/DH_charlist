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

    init(launchConfiguration: DHCharListHostLaunchConfiguration) {
        self.launchConfiguration = launchConfiguration
        _container = State(initialValue: .live(persistence: launchConfiguration.persistence))
    }

    var body: some View {
        Group {
            if isReady {
                DHCharListAppShell(container: container)
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
    }

    private func resetLocalData() async {
        do {
            for template in try await container.templateUseCases.listTemplates() {
                try await container.templateUseCases.deleteTemplate(id: template.id)
            }

            for character in try await container.characterUseCases.listCharacters() {
                try await container.characterUseCases.deleteCharacter(id: character.id)
            }
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
}
