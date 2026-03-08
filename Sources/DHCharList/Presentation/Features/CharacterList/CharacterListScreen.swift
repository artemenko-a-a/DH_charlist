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
            errorMessage = nil
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
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCharacteristics(characterID: UUID, characteristics: CharacteristicSet) async {
        do {
            let updated = try await useCases.updateCharacteristics(characterID: characterID, characteristics: characteristics)
            replaceInMemory(updated)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveResources(characterID: UUID, resources: ResourceState) async {
        do {
            let updated = try await useCases.updateResources(characterID: characterID, resources: resources)
            replaceInMemory(updated)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveSkills(characterID: UUID, skills: [Skill]) async {
        do {
            let updated = try await useCases.updateSkills(characterID: characterID, skills: skills)
            replaceInMemory(updated)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveNotes(characterID: UUID, notes: NotesState) async {
        do {
            let updated = try await useCases.updateNotes(characterID: characterID, notes: notes)
            replaceInMemory(updated)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveEquipment(characterID: UUID, equipment: EquipmentState) async {
        do {
            let updated = try await useCases.updateEquipment(characterID: characterID, equipment: equipment)
            replaceInMemory(updated)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveSession(characterID: UUID, session: SessionState) async {
        do {
            let updated = try await useCases.updateSession(characterID: characterID, session: session)
            replaceInMemory(updated)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteCharacter(id: UUID) async {
        do {
            try await useCases.deleteCharacter(id: id)
            characters.removeAll { $0.id == id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func duplicateCharacter(id: UUID) async {
        do {
            let duplicated = try await useCases.duplicateCharacter(id: id)
            characters.insert(duplicated, at: 0)
            characters.sort { $0.updatedAt > $1.updatedAt }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportPayload() async -> Data? {
        do {
            let payload = try await useCases.exportCharacters(using: importExportService)
            errorMessage = nil
            return payload
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func importPayload(_ data: Data) async {
        do {
            _ = try await useCases.importCharacters(from: data, using: importExportService)
            await load()
            errorMessage = nil
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
    @State private var pendingDeleteCharacterID: UUID?
    @State private var isShowingDeleteConfirmation = false
    @State private var searchText = ""

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
            List {
                if filteredCharacters.isEmpty, !viewModel.characters.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Matching Characters",
                            systemImage: "magnifyingglass",
                            description: Text("Try a different name, home world, background, or role.")
                        )
                    }
                } else {
                    Section(sectionTitle) {
                        ForEach(filteredCharacters) { character in
                            NavigationLink(value: character.id) {
                                CharacterRowView(character: character)
                            }
                            .swipeActions {
                                Button("Duplicate") {
                                    Task { await viewModel.duplicateCharacter(id: character.id) }
                                }
                                .tint(.blue)

                                Button("Delete", role: .destructive) {
                                    pendingDeleteCharacterID = character.id
                                    isShowingDeleteConfirmation = true
                                }
                            }
                            .accessibilityHint("Opens character details. Swipe for duplicate or delete actions.")
                        }
                    }
                }
            }
            .overlay {
                if viewModel.characters.isEmpty, !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Characters",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Create your first acolyte from the plus button, then open it to fill profile, skills, notes, equipment, and session data.")
                    )
                }
            }
            .formContentWidth()
            .platformInsetGroupedListStyle()
            .navigationTitle("Characters")
            .searchable(text: $searchText, prompt: "Search name, world, background, role")
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
                    .accessibilityLabel("Import or Export Characters")
                    .accessibilityHint("Import characters from JSON or export all characters to JSON.")
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.createCharacter() }
                    } label: {
                        Label("Create", systemImage: "plus")
                    }
                    .accessibilityLabel("Create Character")
                    .accessibilityHint("Creates a new character.")
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
                    if let cocoaError = error as? CocoaError, cocoaError.code == .userCancelled {
                        return
                    }
                    viewModel.errorMessage = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isShowingExportPicker,
                document: exportDocument,
                contentType: .json,
                defaultFilename: exportFileName
            ) { result in
                switch result {
                case .success:
                    viewModel.errorMessage = nil
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                }
            }
            .confirmationDialog(
                "Delete Character?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible,
                presenting: pendingDeleteCharacterID
            ) { characterID in
                Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteCharacter(id: characterID) }
                }
            } message: { characterID in
                Text("This permanently removes \(characterName(for: characterID)).")
            }
            .alert("Error", isPresented: isShowingErrorAlert, actions: {
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

    private func characterName(for id: UUID) -> String {
        let name = viewModel.character(by: id)?.profile.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "this character" : name
    }
}

@available(iOS 17, macOS 14, *)
struct CharacterRowView: View {
    let character: Character

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(character.profile.name.isEmpty ? "Unnamed" : character.profile.name)
                .font(.headline)
            Text(summaryLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens character details.")
    }

    private var summaryLine: String {
        let details = [
            character.profile.homeWorld,
            character.profile.background,
            character.profile.role
        ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return details.isEmpty ? "No profile details yet" : details.joined(separator: " · ")
    }

    private var accessibilitySummary: String {
        let name = character.profile.name.isEmpty ? "Unnamed" : character.profile.name
        let details = summaryLine == "No profile details yet" ? "No profile details yet." : "\(summaryLine)."
        return "\(name). \(details)"
    }
}

@available(iOS 17, macOS 14, *)
struct CharacterDetailScreen: View {
    let characterID: UUID
    @ObservedObject var viewModel: CharacterListViewModel
    @Environment(\.dismiss) private var dismiss

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

                Section {
                    NavigationLink {
                        ProfileScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Edit Profile",
                            summary: "Name, world, background, role, aptitudes, and description.",
                            systemImage: "person.text.rectangle"
                        )
                    }
                    NavigationLink {
                        CharacteristicsScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Characteristics & Resources",
                            summary: "Characteristics, wounds, fate, and experience.",
                            systemImage: "chart.bar.doc.horizontal"
                        )
                    }
                    NavigationLink {
                        SkillsScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Skills",
                            summary: "Track skill training, specialisations, and targets.",
                            systemImage: "list.bullet.rectangle"
                        )
                    }
                    NavigationLink {
                        NotesScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Notes",
                            summary: "Talents, traits, mutations, disorders, and powers.",
                            systemImage: "note.text"
                        )
                    }
                    NavigationLink {
                        EquipmentScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Equipment",
                            summary: "Weapons, armour, movement, and inventory.",
                            systemImage: "shippingbox"
                        )
                    }
                    NavigationLink {
                        SessionModeScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Session Mode",
                            summary: "Track active session values and checks.",
                            systemImage: "bolt.fill"
                        )
                    }
                } header: {
                    Text("Edit")
                } footer: {
                    Text("Open each section to edit and save values automatically.")
                }
            }
            .formContentWidth()
            .platformInsetGroupedListStyle()
            .navigationTitle(character.profile.name.isEmpty ? "Character" : character.profile.name)
        } else {
            ContentUnavailableView(
                "Character Not Found",
                systemImage: "person.crop.circle.badge.exclamationmark",
                description: Text("This character is no longer available.")
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Back to Characters") {
                        dismiss()
                    }
                }
            }
        }
    }
}

@available(iOS 17, macOS 14, *)
private extension CharacterListScreen {
    var isShowingErrorAlert: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    var filteredCharacters: [Character] {
        CharacterListSearch.filter(characters: viewModel.characters, query: searchText)
    }

    var sectionTitle: String {
        let total = viewModel.characters.count
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "All Characters (\(total))"
        }

        return "Matches (\(filteredCharacters.count) of \(total))"
    }
}

struct CharacterListSearch {
    static func filter(characters: [Character], query: String) -> [Character] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return characters }
        return characters.filter { matches($0, query: normalized) }
    }

    static func matches(_ character: Character, query: String) -> Bool {
        let fields = [
            character.profile.name,
            character.profile.homeWorld,
            character.profile.background,
            character.profile.role
        ]

        return fields.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

@available(iOS 17, macOS 14, *)
private struct CharacterSectionLinkRow: View {
    let title: String
    let summary: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
#endif
