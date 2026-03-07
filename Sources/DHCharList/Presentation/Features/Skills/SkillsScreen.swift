import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct SkillsScreen: View {
    public init() {}
    public var body: some View {
        Form {
            Text("Skills with training levels and specialisations")
        }
        .navigationTitle("Skills")
    }
}
#endif
