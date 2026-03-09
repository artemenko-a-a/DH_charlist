import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct CampaignHistoryScreen: View {
    let characterID: UUID
    @ObservedObject var viewModel: CharacterListViewModel

    @State private var searchText = ""
    @State private var selectedType: CharacterHistoryEntryType?
    @State private var expandedEntryIDs: Set<UUID> = []
    @State private var activeEditor: HistoryEditorState?
    @State private var pendingDeleteEntryID: UUID?
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        if let character = viewModel.character(by: characterID) {
            List {
                if filteredEntries.isEmpty {
                    Section {
                        ContentUnavailableView(
                            character.history.isEmpty ? "No History Entries" : "No Matching Entries",
                            systemImage: character.history.isEmpty ? "book.closed" : "magnifyingglass",
                            description: Text(character.history.isEmpty ? "Use Add to capture campaign events for this character." : "Try a different filter or search term.")
                        )
                        .cogitatorEmptyStateStyle()
                        .cogitatorPanelRow()
                    }
                } else {
                    Section {
                        ForEach(filteredEntries) { entry in
                            DisclosureGroup(
                                isExpanded: bindingForExpandedEntry(entry.id),
                                content: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if !entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            Text(entry.body)
                                                .font(.callout)
                                                .foregroundStyle(CogitatorPalette.textSecondary)
                                        }

                                        if !entry.tags.isEmpty {
                                            Text(entry.tags.map { "#\($0)" }.joined(separator: " "))
                                                .font(.caption)
                                                .foregroundStyle(CogitatorPalette.textTertiary)
                                        }
                                    }
                                    .padding(.top, 4)
                                },
                                label: {
                                    CampaignHistoryRow(entry: entry)
                                }
                            )
                            .cogitatorPanelRow()
                            .swipeActions {
                                Button("Edit") {
                                    activeEditor = HistoryEditorState.editing(entry)
                                }
                                .tint(.blue)

                                Button("Delete", role: .destructive) {
                                    pendingDeleteEntryID = entry.id
                                    isShowingDeleteConfirmation = true
                                }
                            }
                        }
                    } header: {
                        CogitatorSectionHeader(
                            sectionTitle,
                            subtitle: "Reverse Chronological"
                        )
                    }
                }
            }
            .formContentWidth()
            .platformInsetGroupedListStyle()
            .cogitatorFormRhythm()
            .cogitatorScreenChrome()
            .navigationTitle("Campaign Log")
            .searchable(text: $searchText, prompt: "Search title, text, tags")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        Picker("Entry Type", selection: $selectedType) {
                            Text("All Types").tag(nil as CharacterHistoryEntryType?)
                            ForEach(CharacterHistoryEntryType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(Optional(type))
                            }
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeEditor = .newDefault()
                    } label: {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $activeEditor) { editor in
                HistoryEntryEditorSheet(
                    title: editor.isNew ? "New Entry" : "Edit Entry",
                    initialDraft: editor.draft
                ) { savedDraft in
                    Task {
                        if editor.isNew {
                            await viewModel.addHistoryEntry(
                                characterID: characterID,
                                type: savedDraft.type,
                                title: savedDraft.title,
                                body: savedDraft.body,
                                tags: savedDraft.tags
                            )
                        } else {
                            await viewModel.updateHistoryEntry(characterID: characterID, entry: savedDraft.makeEntry(characterID: characterID))
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete History Entry?",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible,
                presenting: pendingDeleteEntryID
            ) { entryID in
                Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteHistoryEntry(characterID: characterID, entryID: entryID) }
                }
            } message: { entryID in
                Text("This permanently removes \(entryTitle(for: entryID)).")
            }
        } else {
            ContentUnavailableView(
                "Character Not Found",
                systemImage: "person.crop.circle.badge.exclamationmark",
                description: Text("This character is no longer available.")
            )
            .cogitatorEmptyStateStyle()
            .cogitatorScreenChrome()
        }
    }

    private func bindingForExpandedEntry(_ id: UUID) -> Binding<Bool> {
        Binding(
            get: { expandedEntryIDs.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedEntryIDs.insert(id)
                } else {
                    expandedEntryIDs.remove(id)
                }
            }
        )
    }

    private var sortedEntries: [CharacterHistoryEntry] {
        (viewModel.character(by: characterID)?.history ?? [])
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var filteredEntries: [CharacterHistoryEntry] {
        CharacterHistorySearch.filter(
            entries: sortedEntries,
            query: searchText,
            type: selectedType
        )
    }

    private var sectionTitle: String {
        let total = sortedEntries.count
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedType != nil else {
            return "Entries (\(total))"
        }
        return "Matches (\(filteredEntries.count) of \(total))"
    }

    private func entryTitle(for entryID: UUID) -> String {
        let value = (viewModel.character(by: characterID)?.history ?? [])
            .first(where: { $0.id == entryID })?
            .title
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "this entry" : "\"\(value)\""
    }
}

@available(iOS 17, macOS 14, *)
private struct CampaignHistoryRow: View {
    let entry: CharacterHistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: entry.type.systemImageName)
                    .foregroundStyle(CogitatorPalette.brass)
                    .frame(width: 16)
                Text(displayTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(CogitatorPalette.textPrimary)
            }
            Text("\(entry.type.displayName) · \(entry.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(CogitatorPalette.textTertiary)
        }
    }

    private var displayTitle: String {
        let trimmed = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Entry" : trimmed
    }
}

@available(iOS 17, macOS 14, *)
private struct HistoryEntryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: HistoryEntryDraft

    let title: String
    let onSave: (HistoryEntryDraft) -> Void

    init(title: String, initialDraft: HistoryEntryDraft, onSave: @escaping (HistoryEntryDraft) -> Void) {
        self.title = title
        _draft = State(initialValue: initialDraft)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $draft.type) {
                        ForEach(CharacterHistoryEntryType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .cogitatorPanelRow()
                    TextField("Title", text: $draft.title)
                        .cogitatorPanelRow()
                    TextField("Tags (comma separated)", text: $draft.tagsText)
                        .cogitatorPanelRow()
                    TextEditor(text: $draft.body)
                        .frame(minHeight: 140)
                        .cogitatorInputField()
                        .cogitatorPanelRow()
                } header: {
                    CogitatorSectionHeader("Entry", subtitle: "Type, Title, and Notes")
                }
            }
            .formContentWidth()
            .platformInsetGroupedListStyle()
            .cogitatorFormRhythm()
            .cogitatorScreenChrome()
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft.normalized())
                        dismiss()
                    }
                    .disabled(!draft.canSave)
                    .fontWeight(.semibold)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
    }
}

private struct HistoryEditorState: Identifiable {
    let id: UUID
    let isNew: Bool
    let draft: HistoryEntryDraft

    static func newDefault() -> HistoryEditorState {
        .init(id: UUID(), isNew: true, draft: .newDefault())
    }

    static func editing(_ entry: CharacterHistoryEntry) -> HistoryEditorState {
        .init(id: entry.id, isNew: false, draft: .init(entry: entry))
    }
}

private struct HistoryEntryDraft {
    var id: UUID?
    var createdAt: Date
    var title: String
    var type: CharacterHistoryEntryType
    var body: String
    var tagsText: String

    static func newDefault() -> HistoryEntryDraft {
        .init(
            id: nil,
            createdAt: .now,
            title: "",
            type: .sessionNote,
            body: "",
            tagsText: ""
        )
    }

    init(entry: CharacterHistoryEntry) {
        self.id = entry.id
        self.createdAt = entry.createdAt
        self.title = entry.title
        self.type = entry.type
        self.body = entry.body
        self.tagsText = entry.tags.joined(separator: ", ")
    }

    init(id: UUID?, createdAt: Date, title: String, type: CharacterHistoryEntryType, body: String, tagsText: String) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.type = type
        self.body = body
        self.tagsText = tagsText
    }

    var tags: [String] {
        tagsText
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var canSave: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty || !trimmedBody.isEmpty
    }

    func normalized() -> HistoryEntryDraft {
        .init(
            id: id,
            createdAt: createdAt,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            body: body.trimmingCharacters(in: .whitespacesAndNewlines),
            tagsText: tags.joined(separator: ", ")
        )
    }

    func makeEntry(characterID: UUID) -> CharacterHistoryEntry {
        CharacterHistoryEntry(
            id: id ?? UUID(),
            characterID: characterID,
            createdAt: createdAt,
            title: title,
            type: type,
            body: body,
            tags: tags
        )
    }
}

struct CharacterHistorySearch {
    static func filter(entries: [CharacterHistoryEntry], query: String, type: CharacterHistoryEntryType?) -> [CharacterHistoryEntry] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return entries.filter { entry in
            if let type, entry.type != type {
                return false
            }
            guard !normalizedQuery.isEmpty else {
                return true
            }
            return matches(entry, query: normalizedQuery)
        }
    }

    static func matches(_ entry: CharacterHistoryEntry, query: String) -> Bool {
        if entry.title.localizedCaseInsensitiveContains(query) {
            return true
        }
        if entry.body.localizedCaseInsensitiveContains(query) {
            return true
        }
        if entry.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) }) {
            return true
        }
        return false
    }
}

private extension CharacterHistoryEntryType {
    var displayName: String {
        switch self {
        case .sessionNote:
            return "Session Note"
        case .advancement:
            return "Advancement"
        case .injury:
            return "Injury"
        case .corruptionOrInsanity:
            return "Corruption / Insanity"
        case .equipmentChange:
            return "Equipment Change"
        case .storyNote:
            return "Story Note"
        case .custom:
            return "Custom"
        }
    }

    var systemImageName: String {
        switch self {
        case .sessionNote:
            return "text.book.closed"
        case .advancement:
            return "arrow.up.circle"
        case .injury:
            return "cross.case"
        case .corruptionOrInsanity:
            return "exclamationmark.triangle"
        case .equipmentChange:
            return "shippingbox"
        case .storyNote:
            return "book"
        case .custom:
            return "tag"
        }
    }
}
#endif
