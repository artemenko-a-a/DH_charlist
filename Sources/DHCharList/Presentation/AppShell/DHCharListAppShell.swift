import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct DHCharListIOSAppHost: App {
    private let container: AppContainer
    private let initialImportPayload: Data?
    private let initialWeaponCompendiumImportPayload: Data?

    public init() {
        self.container = .live()
        self.initialImportPayload = nil
        self.initialWeaponCompendiumImportPayload = nil
    }

    public init(
        container: AppContainer,
        initialImportPayload: Data? = nil,
        initialWeaponCompendiumImportPayload: Data? = nil
    ) {
        self.container = container
        self.initialImportPayload = initialImportPayload
        self.initialWeaponCompendiumImportPayload = initialWeaponCompendiumImportPayload
    }

    public var body: some Scene {
        WindowGroup {
            DHCharListAppShell(
                container: container,
                initialImportPayload: initialImportPayload,
                initialWeaponCompendiumImportPayload: initialWeaponCompendiumImportPayload
            )
        }
    }
}

@available(iOS 17, macOS 14, *)
public struct DHCharListAppShell: View {
    @State private var selectedTab: Int = 0
    private let container: AppContainer
    private let initialImportPayload: Data?
    private let initialWeaponCompendiumImportPayload: Data?

    public init(
        container: AppContainer = .live(),
        initialImportPayload: Data? = nil,
        initialWeaponCompendiumImportPayload: Data? = nil
    ) {
        self.container = container
        self.initialImportPayload = initialImportPayload
        self.initialWeaponCompendiumImportPayload = initialWeaponCompendiumImportPayload
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            CharacterListScreen(
                useCases: container.characterUseCases,
                templateUseCases: container.templateUseCases,
                importExportService: container.importExportService,
                weaponCompendiumUseCases: container.weaponCompendiumUseCases,
                weaponCompendiumImportService: container.weaponCompendiumImportService,
                persistenceStatus: container.persistenceStatus,
                initialImportPayload: initialImportPayload,
                initialWeaponCompendiumImportPayload: initialWeaponCompendiumImportPayload
            )
                .tabItem { Label("Characters", systemImage: "person.3") }
                .tag(0)
            SessionModeScreen()
                .tabItem { Label("Session", systemImage: "bolt.fill") }
                .tag(1)
        }
        .tint(CogitatorPalette.marsRed)
        .cogitatorAppChrome()
    }
}
#endif
