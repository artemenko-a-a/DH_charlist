import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct NotesScreen: View {
    public init() {}
    public var body: some View {
        Form {
            Text("Talents / Traits / Mutations / Disorders / Psy / Abilities")
        }
        .navigationTitle("Notes")
    }
}
#endif
