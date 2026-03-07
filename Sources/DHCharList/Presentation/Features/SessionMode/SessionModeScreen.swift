import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct SessionModeScreen: View {
    public init() {}
    public var body: some View {
        Form {
            Text("Session Mode")
            Text("Pin checks and temporary modifiers")
        }
        .navigationTitle("Session")
    }
}
#endif
