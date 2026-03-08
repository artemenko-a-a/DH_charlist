import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct DHCharListIOSAppHost: App {
    private let container: AppContainer

    public init() {
        self.container = .live()
    }

    public init(container: AppContainer) {
        self.container = container
    }

    public var body: some Scene {
        WindowGroup {
            DHCharListAppShell(container: container)
        }
    }
}

@available(iOS 17, macOS 14, *)
public struct DHCharListAppShell: View {
    @State private var selectedTab: Int = 0
    private let container: AppContainer

    public init(container: AppContainer = .live()) {
        self.container = container
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            CharacterListScreen(
                useCases: container.characterUseCases,
                importExportService: container.importExportService
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
