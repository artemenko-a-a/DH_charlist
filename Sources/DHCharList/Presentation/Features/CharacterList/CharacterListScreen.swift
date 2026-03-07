import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
@MainActor
final class CharacterListViewModel: ObservableObject {
    @Published private(set) var characters: [Character] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    let autosaveCoordinator: ProfileAutosaveCoordinator
    private let useCases: CharacterUseCases

    init(
        useCases: CharacterUseCases,
        autosaveCoordinator: ProfileAutosaveCoordinator = .init()
    ) {
        self.useCases = useCases
        self.autosaveCoordinator = autosaveCoordinator
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            characters = try await useCases.listCharacters()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createCharacter() async {
        do {
            _ = try await useCases.createCharacter(profile: Profile(name: "New Acolyte"))
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProfile(characterID: UUID, profile: Profile) async {
        do {
            let updated = try await useCases.updateProfile(characterID: characterID, profile: profile)
            replaceInMemory(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCharacteristics(characterID: UUID, characteristics: CharacteristicSet) async {
        do {
            let updated = try await useCases.updateCharacteristics(characterID: characterID, characteristics: characteristics)
            replaceInMemory(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveResources(characterID: UUID, resources: ResourceState) async {
        do {
            let updated = try await useCases.updateResources(characterID: characterID, resources: resources)
            replaceInMemory(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveSkills(characterID: UUID, skills: [Skill]) async {
        do {
            let updated = try await useCases.updateSkills(characterID: characterID, skills: skills)
            replaceInMemory(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteCharacter(id: UUID) async {
        do {
            try await useCases.deleteCharacter(id: id)
            characters.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func duplicateCharacter(id: UUID) async {
        do {
            let duplicated = try await useCases.duplicateCharacter(id: id)
            characters.insert(duplicated, at: 0)
            characters.sort { $0.updatedAt > $1.updatedAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func character(by id: UUID) -> Character? {
        characters.first(where: { $0.id == id })
    }

    private func replaceInMemory(_ updated: Character) {
        if let index = characters.firstIndex(where: { $0.id == updated.id }) {
            characters[index] = updated
        } else {
            characters.append(updated)
        }
        characters.sort { $0.updatedAt > $1.updatedAt }
    }
}

@available(iOS 17, macOS 14, *)
public struct CharacterListScreen: View {
    @StateObject private var viewModel: CharacterListViewModel

    public init(useCases: CharacterUseCases) {
        _viewModel = StateObject(wrappedValue: CharacterListViewModel(useCases: useCases))
    }

    public var body: some View {
        NavigationStack {
            List(viewModel.characters) { character in
                NavigationLink(value: character.id) {
                    CharacterRowView(character: character)
                }
                .swipeActions {
                    Button("Duplicate") {
                        Task { await viewModel.duplicateCharacter(id: character.id) }
                    }
                    .tint(.blue)

                    Button("Delete", role: .destructive) {
                        Task { await viewModel.deleteCharacter(id: character.id) }
                    }
                }
            }
            .overlay {
                if viewModel.characters.isEmpty, !viewModel.isLoading {
                    ContentUnavailableView("No Characters", systemImage: "person.crop.circle.badge.plus", description: Text("Create your first acolyte."))
                }
            }
            .navigationTitle("Characters")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.createCharacter() }
                    } label: {
                        Label("Create", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                CharacterDetailScreen(characterID: id, viewModel: viewModel)
            }
            .task {
                await viewModel.load()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK") { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
        }
    }
}

@available(iOS 17, macOS 14, *)
struct CharacterRowView: View {
    let character: Character

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(character.profile.name.isEmpty ? "Unnamed" : character.profile.name)
                .font(.headline)
            Text("\(character.profile.homeWorld) · \(character.profile.background) · \(character.profile.role)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

@available(iOS 17, macOS 14, *)
struct CharacterDetailScreen: View {
    let characterID: UUID
    @ObservedObject var viewModel: CharacterListViewModel

    var body: some View {
        if let character = viewModel.character(by: characterID) {
            List {
                Section("Overview") {
                    LabeledContent("Name", value: character.profile.name.isEmpty ? "—" : character.profile.name)
                    LabeledContent("Home world", value: character.profile.homeWorld.isEmpty ? "—" : character.profile.homeWorld)
                    LabeledContent("Background", value: character.profile.background.isEmpty ? "—" : character.profile.background)
                    LabeledContent("Role", value: character.profile.role.isEmpty ? "—" : character.profile.role)
                    LabeledContent("Updated", value: character.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }

                Section("Edit") {
                    NavigationLink("Edit Profile") {
                        ProfileScreen(characterID: characterID, viewModel: viewModel)
                    }
                    NavigationLink("Characteristics & Resources") {
                        CharacteristicsScreen(characterID: characterID, viewModel: viewModel)
                    }
                    NavigationLink("Skills") {
                        SkillsScreen(characterID: characterID, viewModel: viewModel)
                    }
                }
            }
            .navigationTitle(character.profile.name.isEmpty ? "Character" : character.profile.name)
        } else {
            Text("Character not found")
        }
    }
}
#endif
