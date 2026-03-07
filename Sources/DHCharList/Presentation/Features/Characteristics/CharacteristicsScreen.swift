import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct CharacteristicsScreen: View {
    public init() {}
    public var body: some View {
        Form {
            Text("Characteristics + derived values")
            Text("Experience / Fate / Mental State")
        }
        .navigationTitle("Overview")
    }
}
#endif
