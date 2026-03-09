import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct DHCharListIOSAppHost: App {
    private let container: AppContainer
    private let initialImportPayload: Data?

    public init() {
        self.container = .live()
        self.initialImportPayload = nil
    }

    public init(container: AppContainer, initialImportPayload: Data? = nil) {
        self.container = container
        self.initialImportPayload = initialImportPayload
    }

    public var body: some Scene {
        WindowGroup {
            DHCharListAppShell(container: container, initialImportPayload: initialImportPayload)
        }
    }
}

@available(iOS 17, macOS 14, *)
public struct DHCharListAppShell: View {
    @State private var selectedTab: Int = 0
    private let container: AppContainer
    private let initialImportPayload: Data?

    public init(container: AppContainer = .live(), initialImportPayload: Data? = nil) {
        self.container = container
        self.initialImportPayload = initialImportPayload
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            CharacterListScreen(
                useCases: container.characterUseCases,
                templateUseCases: container.templateUseCases,
                importExportService: container.importExportService,
                initialImportPayload: initialImportPayload
            )
                .tabItem { Label("Characters", systemImage: "person.3") }
                .tag(0)
            SessionModeScreen()
                .tabItem { Label("Session", systemImage: "bolt.fill") }
                .tag(1)
        }
        .tint(CogitatorPalette.marsRed)
    }
}
#endif
