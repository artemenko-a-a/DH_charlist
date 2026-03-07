import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct EquipmentScreen: View {
    public init() {}
    public var body: some View {
        Form {
            Text("Weapons / Armour / Movement / Inventory")
        }
        .navigationTitle("Equipment")
    }
}
#endif
