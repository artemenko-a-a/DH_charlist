import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct ProfileScreen: View {
    public init() {}
    public var body: some View {
        Form {
            Text("Profile MVP: manual character details input")
        }
        .navigationTitle("Profile")
    }
}
#endif
