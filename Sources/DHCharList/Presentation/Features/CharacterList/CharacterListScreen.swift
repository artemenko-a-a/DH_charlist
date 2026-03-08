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
    @Published private(set) var templates: [CharacterTemplate] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    let autosaveCoordinator: ProfileAutosaveCoordinator
    private let useCases: CharacterUseCases
    private let templateUseCases: CharacterTemplateUseCases?
    private let importExportService: any CharacterImportExportService

    init(
        useCases: CharacterUseCases,
        templateUseCases: CharacterTemplateUseCases? = nil,
        importExportService: any CharacterImportExportService,
        autosaveCoordinator: ProfileAutosaveCoordinator = .init()
    ) {
        self.useCases = useCases
        self.templateUseCases = templateUseCases
        self.importExportService = importExportService
        self.autosaveCoordinator = autosaveCoordinator
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            characters = try await useCases.listCharacters()
            if let templateUseCases {
                templates = try await templateUseCases.listTemplates()
            } else {
                templates = []
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createBlankCharacter() async {
        do {
            _ = try await useCases.createCharacter(profile: Profile(name: "New Acolyte"))
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createCharacter(fromTemplateID templateID: UUID) async {
        guard let templateUseCases else {
            errorMessage = "Template support is unavailable."
            return
        }

        do {
            _ = try await templateUseCases.createCharacterFromTemplate(templateID: templateID)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCharacterAsTemplate(characterID: UUID, name: String? = nil) async {
        guard let templateUseCases else {
            errorMessage = "Template support is unavailable."
            return
        }

        do {
            let saved = try await templateUseCases.saveCharacterAsTemplate(characterID: characterID, name: name)
            replaceTemplateInMemory(saved)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func renameTemplate(id: UUID, name: String) async {
        guard let templateUseCases else {
            errorMessage = "Template support is unavailable."
            return
        }

        do {
            let updated = try await templateUseCases.renameTemplate(id: id, name: name)
            replaceTemplateInMemory(updated)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func duplicateTemplate(id: UUID) async {
        guard let templateUseCases else {
            errorMessage = "Template support is unavailable."
            return
        }

        do {
            let duplicated = try await templateUseCases.duplicateTemplate(id: id)
            templates.insert(duplicated, at: 0)
            templates.sort { $0.updatedAt > $1.updatedAt }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTemplate(id: UUID) async {
        guard let templateUseCases else {
            errorMessage = "Template support is unavailable."
            return
        }

        do {
            try await templateUseCases.deleteTemplate(id: id)
            templates.removeAll { $0.id == id }
            errorMessage = nil
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

    func addHistoryEntry(
        characterID: UUID,
        type: CharacterHistoryEntryType,
        title: String,
        body: String,
        tags: [String]
    ) async {
        do {
            _ = try await useCases.addHistoryEntry(characterID: characterID, type: type, title: title, body: body, tags: tags)
            await loadCharacter(id: characterID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateHistoryEntry(characterID: UUID, entry: CharacterHistoryEntry) async {
        do {
            _ = try await useCases.updateHistoryEntry(characterID: characterID, entry: entry)
            await loadCharacter(id: characterID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteHistoryEntry(characterID: UUID, entryID: UUID) async {
        do {
            try await useCases.deleteHistoryEntry(characterID: characterID, entryID: entryID)
            await loadCharacter(id: characterID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func quickAddHistoryEntry(characterID: UUID) async {
        await addHistoryEntry(
            characterID: characterID,
            type: .sessionNote,
            title: "Quick Note",
            body: "",
            tags: []
        )
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

    private func replaceTemplateInMemory(_ updated: CharacterTemplate) {
        if let index = templates.firstIndex(where: { $0.id == updated.id }) {
            templates[index] = updated
        } else {
            templates.append(updated)
        }
        templates.sort { $0.updatedAt > $1.updatedAt }
    }

    private func loadCharacter(id: UUID) async {
        do {
            guard let character = try await useCases.fetchCharacter(id: id) else {
                return
            }
            replaceInMemory(character)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@available(iOS 17, macOS 14, *)
public struct CharacterListScreen: View {
    @StateObject private var viewModel: CharacterListViewModel
    @State private var isShowingImportPicker = false
    @State private var isShowingExportPicker = false
    @State private var isShowingQuickStart = false
    @State private var isShowingTemplateManager = false
    @State private var exportDocument: CharacterExportDocument?
    @State private var exportFileName = "dh_characters"
    @State private var pendingDeleteCharacterID: UUID?
    @State private var isShowingDeleteConfirmation = false
    @State private var searchText = ""

    public init(
        useCases: CharacterUseCases,
        templateUseCases: CharacterTemplateUseCases? = nil,
        importExportService: any CharacterImportExportService
    ) {
        _viewModel = StateObject(
            wrappedValue: CharacterListViewModel(
                useCases: useCases,
                templateUseCases: templateUseCases,
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
                        .cogitatorEmptyStateStyle()
                        .cogitatorPanelRow()
                    }
                } else {
                    Section {
                        ForEach(filteredCharacters) { character in
                            NavigationLink(value: character.id) {
                                CharacterRowView(character: character)
                            }
                            .cogitatorPanelRow()
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
                    } header: {
                        CogitatorSectionHeader(sectionTitle, subtitle: "Personnel Registry")
                    }
                }
            }
            .overlay {
                if viewModel.characters.isEmpty, !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Characters",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Use Create to start from a blank character or a saved template.")
                    )
                    .cogitatorEmptyStateStyle()
                }
            }
            .formContentWidth()
            .platformInsetGroupedListStyle()
            .cogitatorFormRhythm()
            .cogitatorScreenChrome()
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

                ToolbarItem(placement: .automatic) {
                    Button {
                        isShowingTemplateManager = true
                    } label: {
                        Label("Templates", systemImage: "bookmark")
                    }
                    .accessibilityLabel("Manage Templates")
                    .accessibilityHint("Open the template manager to rename, duplicate, or delete templates.")
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingQuickStart = true
                    } label: {
                        Label("Create", systemImage: "plus")
                    }
                    .accessibilityLabel("Create Character")
                    .accessibilityHint("Choose blank character or start from template.")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                CharacterDetailScreen(characterID: id, viewModel: viewModel)
            }
            .task {
                await viewModel.load()
            }
            .sheet(isPresented: $isShowingQuickStart) {
                TemplateQuickStartSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $isShowingTemplateManager) {
                TemplateManagementScreen(viewModel: viewModel)
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
private struct TemplateQuickStartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CharacterListViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        Task { await viewModel.createBlankCharacter() }
                        dismiss()
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundStyle(CogitatorPalette.brass)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Blank Character")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(CogitatorPalette.textPrimary)
                                Text("Start with default empty sections.")
                                    .cogitatorSupportingText()
                            }
                        }
                    }
                    .accessibilityIdentifier("quickstart.blank-character")
                    .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Quick Start", subtitle: "Creation Mode")
                }

                Section {
                    if viewModel.templates.isEmpty {
                        Text("No templates yet. Open a character and use Save as Template.")
                            .cogitatorSupportingText()
                            .cogitatorPanelRow()
                    } else {
                        ForEach(viewModel.templates) { template in
                            Button {
                                Task { await viewModel.createCharacter(fromTemplateID: template.id) }
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(CogitatorPalette.textPrimary)
                                    Text(CharacterTemplateSummary.preview(for: template))
                                        .cogitatorSupportingText()
                                }
                            }
                            .cogitatorPanelRow()
                        }
                    }
                } header: {
                    CogitatorSectionHeader("Templates", subtitle: "Reusable Presets")
                }
            }
            .formContentWidth()
            .platformInsetGroupedListStyle()
            .cogitatorFormRhythm()
            .cogitatorScreenChrome()
            .navigationTitle("Create Character")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

@available(iOS 17, macOS 14, *)
private struct TemplateManagementScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CharacterListViewModel

    @State private var pendingDeleteTemplateID: UUID?
    @State private var isShowingDeleteConfirmation = false
    @State private var renameDraft: TemplateRenameDraft?

    var body: some View {
        NavigationStack {
            List {
                if viewModel.templates.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Templates",
                            systemImage: "bookmark",
                            description: Text("Save a character as a template from its detail screen.")
                        )
                        .cogitatorEmptyStateStyle()
                        .cogitatorPanelRow()
                    }
                } else {
                    Section {
                        ForEach(viewModel.templates) { template in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(CogitatorPalette.textPrimary)
                                Text(CharacterTemplateSummary.preview(for: template))
                                    .cogitatorSupportingText()
                                Text("Updated \(template.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(CogitatorPalette.textTertiary)
                            }
                            .cogitatorPanelRow()
                            .swipeActions {
                                Button("Rename") {
                                    renameDraft = TemplateRenameDraft(id: template.id, name: template.name)
                                }
                                .tint(.blue)

                                Button("Duplicate") {
                                    Task { await viewModel.duplicateTemplate(id: template.id) }
                                }
                                .tint(.indigo)

                                Button("Delete", role: .destructive) {
                                    pendingDeleteTemplateID = template.id
                                    isShowingDeleteConfirmation = true
                                }
                            }
                        }
                    } header: {
                        CogitatorSectionHeader("Templates (\(viewModel.templates.count))", subtitle: "Local Presets")
                    } footer: {
                        Text("Swipe a template row to rename, duplicate, or delete it.")
                            .cogitatorSupportingText()
                    }
                }
            }
            .formContentWidth()
            .platformInsetGroupedListStyle()
            .cogitatorFormRhythm()
            .cogitatorScreenChrome()
            .navigationTitle("Manage Templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $renameDraft) { draft in
                TemplateRenameSheet(
                    currentName: draft.name,
                    onSave: { newName in
                        Task { await viewModel.renameTemplate(id: draft.id, name: newName) }
                    }
                )
            }
            .confirmationDialog(
                "Delete Template?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible,
                presenting: pendingDeleteTemplateID
            ) { templateID in
                Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteTemplate(id: templateID) }
                }
            } message: { templateID in
                Text("This permanently removes \(templateName(for: templateID)).")
            }
        }
    }

    private func templateName(for id: UUID) -> String {
        let value = viewModel.templates.first(where: { $0.id == id })?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "this template" : value
    }
}

@available(iOS 17, macOS 14, *)
private struct TemplateRenameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nameDraft: String
    let onSave: (String) -> Void

    init(currentName: String, onSave: @escaping (String) -> Void) {
        _nameDraft = State(initialValue: currentName)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Template Name", text: $nameDraft)
                }
            }
            .formContentWidth()
            .platformInsetGroupedListStyle()
            .cogitatorFormRhythm()
            .cogitatorScreenChrome()
            .navigationTitle("Rename Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(nameDraft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
    }
}

private struct TemplateRenameDraft: Identifiable {
    let id: UUID
    let name: String
}

private enum CharacterTemplateSummary {
    static func preview(for template: CharacterTemplate) -> String {
        let profileParts = [
            template.profile.homeWorld,
            template.profile.background,
            template.profile.role
        ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let profileSummary = profileParts.isEmpty ? "Profile skeleton" : profileParts.joined(separator: " · ")
        return "\(profileSummary) · Skills \(template.skills.count) · Items \(template.equipment.inventory.count)"
    }
}

@available(iOS 17, macOS 14, *)
struct CharacterRowView: View {
    let character: Character

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(character.profile.name.isEmpty ? "Unnamed" : character.profile.name)
                .font(.body.weight(.semibold))
                .foregroundStyle(CogitatorPalette.textPrimary)
            Text(summaryLine)
                .font(.callout)
                .foregroundStyle(CogitatorPalette.textSecondary)
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
                Section {
                    LabeledContent("Name", value: character.profile.name.isEmpty ? "—" : character.profile.name)
                        .cogitatorPanelRow()
                    LabeledContent("Home world", value: character.profile.homeWorld.isEmpty ? "—" : character.profile.homeWorld)
                        .cogitatorPanelRow()
                    LabeledContent("Background", value: character.profile.background.isEmpty ? "—" : character.profile.background)
                        .cogitatorPanelRow()
                    LabeledContent("Role", value: character.profile.role.isEmpty ? "—" : character.profile.role)
                        .cogitatorPanelRow()
                    LabeledContent("Updated", value: character.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Overview", subtitle: "Dossier Snapshot")
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
                    .cogitatorPanelRow()
                    NavigationLink {
                        CharacteristicsScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Characteristics & Resources",
                            summary: "Characteristics, wounds, fate, and experience.",
                            systemImage: "chart.bar.doc.horizontal"
                        )
                    }
                    .cogitatorPanelRow()
                    NavigationLink {
                        SkillsScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Skills",
                            summary: "Track skill training, specialisations, and targets.",
                            systemImage: "list.bullet.rectangle"
                        )
                    }
                    .cogitatorPanelRow()
                    NavigationLink {
                        NotesScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Notes",
                            summary: "Talents, traits, mutations, disorders, and powers.",
                            systemImage: "note.text"
                        )
                    }
                    .cogitatorPanelRow()
                    NavigationLink {
                        EquipmentScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Equipment",
                            summary: "Weapons, armour, movement, and inventory.",
                            systemImage: "shippingbox"
                        )
                    }
                    .cogitatorPanelRow()
                    NavigationLink {
                        SessionModeScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Session Mode",
                            summary: "Track active session values and checks.",
                            systemImage: "bolt.fill"
                        )
                    }
                    .cogitatorPanelRow()
                    NavigationLink {
                        CampaignHistoryScreen(characterID: characterID, viewModel: viewModel)
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Campaign Log & History",
                            summary: "Session notes, injuries, advancements, and story events.",
                            systemImage: "book.closed"
                        )
                    }
                    .cogitatorPanelRow()
                    Button {
                        Task { await viewModel.quickAddHistoryEntry(characterID: characterID) }
                    } label: {
                        CharacterSectionLinkRow(
                            title: "Quick Add Session Note",
                            summary: "Adds a timestamped note you can refine later.",
                            systemImage: "plus.bubble"
                        )
                    }
                    .buttonStyle(.plain)
                    .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Edit", subtitle: "Subsystem Access")
                } footer: {
                    Text("Open each section to edit and save values automatically.")
                        .cogitatorSupportingText()
                }
            }
            .formContentWidth()
            .platformInsetGroupedListStyle()
            .cogitatorFormRhythm()
            .cogitatorScreenChrome()
            .navigationTitle(character.profile.name.isEmpty ? "Character" : character.profile.name)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await viewModel.saveCharacterAsTemplate(characterID: characterID) }
                    } label: {
                        Label("Save as Template", systemImage: "bookmark")
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "Character Not Found",
                systemImage: "person.crop.circle.badge.exclamationmark",
                description: Text("This character is no longer available.")
            )
            .cogitatorEmptyStateStyle()
            .cogitatorScreenChrome()
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
                .foregroundStyle(CogitatorPalette.brass)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(CogitatorPalette.textPrimary)
                Text(summary)
                    .cogitatorSupportingText()
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
#endif
