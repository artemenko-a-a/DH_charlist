import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct NotesScreen: View {
    private let characterID: UUID
    @ObservedObject private var viewModel: CharacterListViewModel

    @State private var notes: NotesState
    @State private var draft: NoteEntryDraft?

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

            Section("Freeform Notes") {
                TextEditor(text: $notes.notes)
                    .frame(minHeight: 140)
                    .accessibilityLabel("Freeform Notes")
            }
        }
        .navigationTitle("Notes")
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
        }
    }

    @ViewBuilder
    private func listSection(_ section: NotesListSection) -> some View {
        Section(section.title) {
            let entries = entries(for: section)
            if entries.isEmpty {
                Text("No entries")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(entries.enumerated()), id: \.offset) { index, value in
                    Button {
                        draft = NoteEntryDraft(section: section, index: index, value: value)
                    } label: {
                        Text(value)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(section.singularTitle): \(value)")
                    .accessibilityHint("Double tap to edit.")
                }
                .onDelete { offsets in
                    deleteEntries(at: offsets, section: section)
                }
            }

            Button {
                draft = NoteEntryDraft(section: section)
            } label: {
                Label("Add \(section.singularTitle)", systemImage: "plus")
            }
            .accessibilityLabel("Add \(section.singularTitle)")
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

    private func deleteEntries(at offsets: IndexSet, section: NotesListSection) {
        var updated = entries(for: section)
        updated.remove(atOffsets: offsets)
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
            }
            .navigationTitle(draft.isNew ? "Add \(draft.section.singularTitle)" : "Edit \(draft.section.singularTitle)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                    }
                    .disabled(draft.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private enum NotesListSection: CaseIterable {
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
