import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct NotesScreen: View {
    private let characterID: UUID
    @ObservedObject private var viewModel: CharacterListViewModel

    @State private var notes: NotesState
    @State private var draft: NoteEntryDraft?
    @State private var searchText = ""

    init(characterID: UUID, viewModel: CharacterListViewModel) {
        self.characterID = characterID
        self.viewModel = viewModel
        _notes = State(initialValue: viewModel.character(by: characterID)?.notes ?? .init())
    }

    var body: some View {
        Form {
            listSection(.talents)
            listSection(.traits)
            listSection(.mutations)
            listSection(.disorders)
            listSection(.psychicPowers)
            listSection(.specialAbilities)

            Section {
                TextEditor(text: $notes.notes)
                    .frame(minHeight: 140)
                    .accessibilityLabel("Freeform Notes")
                    .accessibilityHint("Use this area for longer unstructured session notes.")
                    .cogitatorPanelRow()
            } header: {
                CogitatorSectionHeader("Freeform Notes", subtitle: "Unstructured Field Record")
            } footer: {
                Text("List sections are for short tagged entries. Use Freeform Notes for long text.")
                    .cogitatorSupportingText()
            }
        }
        .formContentWidth()
        .formStyle(.grouped)
        .cogitatorFormRhythm()
        .cogitatorScreenChrome()
        .navigationTitle("Notes")
        .searchable(text: $searchText, prompt: "Search list notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Quick Add", systemImage: "plus.circle") {
                    ForEach(NotesListSection.allCases, id: \.self) { section in
                        Button("Add \(section.singularTitle)") {
                            draft = NoteEntryDraft(section: section)
                        }
                    }
                }
            }
        }
        .onAppear(perform: refreshFromSharedState)
        .onChange(of: notes) { _, updated in
            Task {
                await viewModel.saveNotes(characterID: characterID, notes: updated)
            }
        }
        .sheet(item: $draft) { value in
            NoteEntryEditorView(
                draft: value,
                onCancel: { draft = nil },
                onSave: { updated in
                    upsert(updated)
                    draft = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func listSection(_ section: NotesListSection) -> some View {
        Section {
            let allEntries = entries(for: section)
            let matches = NotesSearch.matches(notes: notes, section: section, query: searchText)
            if allEntries.isEmpty {
                Text("No \(section.title.lowercased()) yet")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            } else if matches.isEmpty {
                Text("No matching \(section.title.lowercased())")
                    .cogitatorSupportingText()
                    .cogitatorPanelRow()
            } else {
                ForEach(matches, id: \.originalIndex) { match in
                    Button {
                        draft = NoteEntryDraft(section: section, index: match.originalIndex, value: match.value)
                    } label: {
                        Text(match.value)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .buttonStyle(.plain)
                    .cogitatorPanelRow()
                    .accessibilityLabel("\(section.singularTitle): \(match.value)")
                    .accessibilityHint("Double tap to edit.")
                }
                .onDelete { offsets in
                    deleteMatches(at: offsets, from: matches, section: section)
                }
            }

            Button {
                draft = NoteEntryDraft(section: section)
            } label: {
                Label("Add \(section.singularTitle)", systemImage: "plus")
            }
            .cogitatorPanelRow()
            .accessibilityLabel("Add \(section.singularTitle)")
        } header: {
            CogitatorSectionHeader(sectionTitle(for: section), subtitle: "\(section.singularTitle) Entries")
        } footer: {
            Text("Tap an entry to edit it. Swipe left to delete.")
                .cogitatorSupportingText()
        }
    }

    private func refreshFromSharedState() {
        guard let character = viewModel.character(by: characterID) else { return }
        notes = character.notes
    }

    private func entries(for section: NotesListSection) -> [String] {
        switch section {
        case .talents: notes.talents
        case .traits: notes.traits
        case .mutations: notes.mutations
        case .disorders: notes.disorders
        case .psychicPowers: notes.psychicPowers
        case .specialAbilities: notes.specialAbilities
        }
    }

    private func setEntries(_ entries: [String], for section: NotesListSection) {
        switch section {
        case .talents: notes.talents = entries
        case .traits: notes.traits = entries
        case .mutations: notes.mutations = entries
        case .disorders: notes.disorders = entries
        case .psychicPowers: notes.psychicPowers = entries
        case .specialAbilities: notes.specialAbilities = entries
        }
    }

    private func deleteMatches(at offsets: IndexSet, from matches: [NoteEntryMatch], section: NotesListSection) {
        let originalOffsets = offsets
            .compactMap { index in
                matches.indices.contains(index) ? matches[index].originalIndex : nil
            }
            .sorted(by: >)

        var updated = entries(for: section)
        for index in originalOffsets where updated.indices.contains(index) {
            updated.remove(at: index)
        }
        setEntries(updated, for: section)
    }

    private func upsert(_ draft: NoteEntryDraft) {
        var updated = entries(for: draft.section)
        let cleaned = draft.value.trimmingCharacters(in: .whitespacesAndNewlines)

        if let index = draft.index, updated.indices.contains(index) {
            updated[index] = cleaned
        } else {
            updated.append(cleaned)
        }

        setEntries(updated, for: draft.section)
    }

    private func sectionTitle(for section: NotesListSection) -> String {
        let total = entries(for: section).count
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "\(section.title) (\(total))"
        }

        let matchCount = NotesSearch.matches(notes: notes, section: section, query: searchText).count
        return "\(section.title) (\(matchCount) of \(total))"
    }
}

@available(iOS 17, macOS 14, *)
private struct NoteEntryEditorView: View {
    @State private var draft: NoteEntryDraft
    let onCancel: () -> Void
    let onSave: (NoteEntryDraft) -> Void

    init(
        draft: NoteEntryDraft,
        onCancel: @escaping () -> Void,
        onSave: @escaping (NoteEntryDraft) -> Void
    ) {
        _draft = State(initialValue: draft)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(draft.section.singularTitle, text: $draft.value, axis: .vertical)
                    .lineLimit(2...4)
                    .accessibilityLabel(draft.section.singularTitle)
                    .accessibilityHint("Enter a short note for this section.")
                    .cogitatorPanelRow()
            }
            .cogitatorScreenChrome()
            .cogitatorFormRhythm()
            .navigationTitle(draft.isNew ? "Add \(draft.section.singularTitle)" : "Edit \(draft.section.singularTitle)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                    }
                    .fontWeight(.semibold)
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

enum NotesListSection: CaseIterable {
    case talents
    case traits
    case mutations
    case disorders
    case psychicPowers
    case specialAbilities

    var title: String {
        switch self {
        case .talents: "Talents"
        case .traits: "Traits"
        case .mutations: "Mutations"
        case .disorders: "Disorders"
        case .psychicPowers: "Psychic Powers"
        case .specialAbilities: "Special Abilities"
        }
    }

    var singularTitle: String {
        switch self {
        case .talents: "Talent"
        case .traits: "Trait"
        case .mutations: "Mutation"
        case .disorders: "Disorder"
        case .psychicPowers: "Psychic Power"
        case .specialAbilities: "Special Ability"
        }
    }
}

struct NoteEntryMatch: Equatable {
    let originalIndex: Int
    let value: String
}

struct NotesSearch {
    static func matches(notes: NotesState, section: NotesListSection, query: String) -> [NoteEntryMatch] {
        let values: [String]
        switch section {
        case .talents: values = notes.talents
        case .traits: values = notes.traits
        case .mutations: values = notes.mutations
        case .disorders: values = notes.disorders
        case .psychicPowers: values = notes.psychicPowers
        case .specialAbilities: values = notes.specialAbilities
        }

        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty {
            return Array(values.enumerated()).map { NoteEntryMatch(originalIndex: $0.offset, value: $0.element) }
        }

        return Array(values.enumerated())
            .filter { $0.element.localizedCaseInsensitiveContains(normalized) }
            .map { NoteEntryMatch(originalIndex: $0.offset, value: $0.element) }
    }
}

private struct NoteEntryDraft: Identifiable {
    let id: UUID
    let section: NotesListSection
    let index: Int?
    var value: String

    var isNew: Bool { index == nil }

    init(section: NotesListSection) {
        self.id = UUID()
        self.section = section
        self.index = nil
        self.value = ""
    }

    init(section: NotesListSection, index: Int, value: String) {
        self.id = UUID()
        self.section = section
        self.index = index
        self.value = value
    }
}
#endif
