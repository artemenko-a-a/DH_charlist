import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct ProfileScreen: View {
    private let characterID: UUID
    @ObservedObject private var viewModel: CharacterListViewModel

    @State private var draft: Profile

    init(characterID: UUID, viewModel: CharacterListViewModel) {
        self.characterID = characterID
        self.viewModel = viewModel
        _draft = State(initialValue: viewModel.character(by: characterID)?.profile ?? .init())
    }

    public var body: some View {
        Form {
            TextField("Name", text: $draft.name)
            TextField("Home world", text: $draft.homeWorld)
            TextField("Background", text: $draft.background)
            TextField("Role", text: $draft.role)
            TextField("Description", text: $draft.description, axis: .vertical)
                .lineLimit(3...6)
        }
        .navigationTitle("Profile")
        .onAppear {
            if let latest = viewModel.character(by: characterID)?.profile {
                draft = latest
            }
        }
        .onChange(of: draft) { _, newValue in
            viewModel.autosaveCoordinator.scheduleSave(characterID: characterID, profile: newValue) { id, profile in
                await viewModel.saveProfile(characterID: id, profile: profile)
            }
        }
    }
}
#endif
