import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct DHCharListAppShell: View {
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            CharacterListScreen()
                .tabItem { Label("Characters", systemImage: "person.3") }
                .tag(0)
            SessionModeScreen()
                .tabItem { Label("Session", systemImage: "bolt.fill") }
                .tag(1)
        }
    }
}
#endif
