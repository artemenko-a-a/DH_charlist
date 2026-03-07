import SwiftUI
import DHCharList

@main
struct DHCharListHostApp: App {
    var body: some Scene {
        WindowGroup {
            DHCharListAppShell(container: .live())
        }
    }
}
