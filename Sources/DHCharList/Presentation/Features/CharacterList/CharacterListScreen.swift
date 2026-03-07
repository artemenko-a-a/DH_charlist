import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
public struct CharacterListScreen: View {
    public init() {}
    public var body: some View {
        NavigationStack {
            List {
                NavigationLink("Profile", destination: ProfileScreen())
                NavigationLink("Overview", destination: CharacteristicsScreen())
                NavigationLink("Skills", destination: SkillsScreen())
                NavigationLink("Talents & Traits", destination: NotesScreen())
                NavigationLink("Equipment", destination: EquipmentScreen())
            }
            .navigationTitle("Characters")
        }
    }
}
#endif
