import Foundation

#if canImport(SwiftUI)
import SwiftUI
import UniformTypeIdentifiers

@available(iOS 17, macOS 14, *)
private struct CharacterExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CharacterRepositoryError.invalidData("Missing JSON file contents")
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

@available(iOS 17, macOS 14, *)
@MainActor
final class CharacterListViewModel: ObservableObject {
    @Published private(set) var characters: [Character] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    let autosaveCoordinator: ProfileAutosaveCoordinator
    private let useCases: CharacterUseCases
    private let importExportService: any CharacterImportExportService

    init(
        useCases: CharacterUseCases,
        importExportService: any CharacterImportExportService,
        autosaveCoordinator: ProfileAutosaveCoordinator = .init()
    ) {
        self.useCases = useCases
        self.importExportService = importExportService
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

    func saveNotes(characterID: UUID, notes: NotesState) async {
        do {
            let updated = try await useCases.updateNotes(characterID: characterID, notes: notes)
            replaceInMemory(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveEquipment(characterID: UUID, equipment: EquipmentState) async {
        do {
            let updated = try await useCases.updateEquipment(characterID: characterID, equipment: equipment)
            replaceInMemory(updated)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveSession(characterID: UUID, session: SessionState) async {
        do {
            let updated = try await useCases.updateSession(characterID: characterID, session: session)
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

    func exportPayload() async -> Data? {
        do {
            return try await useCases.exportCharacters(using: importExportService)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func importPayload(_ data: Data) async {
        do {
            _ = try await useCases.importCharacters(from: data, using: importExportService)
            await load()
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
    @State private var isShowingImportPicker = false
    @State private var isShowingExportPicker = false
    @State private var exportDocument: CharacterExportDocument?
    @State private var exportFileName = "dh_characters"

    public init(useCases: CharacterUseCases, importExportService: any CharacterImportExportService) {
        _viewModel = StateObject(
            wrappedValue: CharacterListViewModel(
                useCases: useCases,
                importExportService: importExportService
            )
        )
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
                ToolbarItem(placement: .automatic) {
                    Menu("Import/Export", systemImage: "arrow.up.arrow.down.circle") {
                        Button("Import JSON", systemImage: "square.and.arrow.down") {
                            isShowingImportPicker = true
                        }

                        Button("Export JSON", systemImage: "square.and.arrow.up") {
                            Task {
                                guard let data = await viewModel.exportPayload() else { return }
                                exportDocument = CharacterExportDocument(data: data)
                                exportFileName = exportFilename()
                                isShowingExportPicker = true
                            }
                        }
                    }
                }

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
            .fileImporter(
                isPresented: $isShowingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let sourceURL = urls.first else { return }
                    let hadAccess = sourceURL.startAccessingSecurityScopedResource()
                    defer {
                        if hadAccess {
                            sourceURL.stopAccessingSecurityScopedResource()
                        }
                    }

                    do {
                        let data = try Data(contentsOf: sourceURL)
                        Task { await viewModel.importPayload(data) }
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isShowingExportPicker,
                document: exportDocument,
                contentType: .json,
                defaultFilename: exportFileName
            ) { result in
                if case .failure(let error) = result {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK") { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
        }
    }

    private func exportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let stamp = formatter.string(from: .now)
        return "dh_characters_\(stamp)"
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
                    NavigationLink("Notes") {
                        NotesScreen(characterID: characterID, viewModel: viewModel)
                    }
                    NavigationLink("Equipment") {
                        EquipmentScreen(characterID: characterID, viewModel: viewModel)
                    }
                    NavigationLink("Session Mode") {
                        SessionModeScreen(characterID: characterID, viewModel: viewModel)
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
