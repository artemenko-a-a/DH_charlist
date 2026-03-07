import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct EquipmentScreen: View {
    private let characterID: UUID
    @ObservedObject private var viewModel: CharacterListViewModel

    @State private var equipment: EquipmentState
    @State private var weaponDraft: WeaponDraft?
    @State private var armourDraft: ArmourDraft?
    @State private var inventoryDraft: InventoryItemDraft?

    init(characterID: UUID, viewModel: CharacterListViewModel) {
        self.characterID = characterID
        self.viewModel = viewModel
        _equipment = State(initialValue: viewModel.character(by: characterID)?.equipment ?? .init())
    }

    var body: some View {
        Form {
            weaponsSection
            armourSection
            movementSection
            inventorySection
        }
        .navigationTitle("Equipment")
        .onAppear(perform: refreshFromSharedState)
        .onChange(of: equipment) { _, updated in
            Task {
                await viewModel.saveEquipment(characterID: characterID, equipment: updated)
            }
        }
        .sheet(item: $weaponDraft) { value in
            WeaponEditorView(
                draft: value,
                onCancel: { weaponDraft = nil },
                onSave: { updated in
                    upsertWeapon(from: updated)
                    weaponDraft = nil
                }
            )
        }
        .sheet(item: $armourDraft) { value in
            ArmourEditorView(
                draft: value,
                onCancel: { armourDraft = nil },
                onSave: { updated in
                    upsertArmour(from: updated)
                    armourDraft = nil
                }
            )
        }
        .sheet(item: $inventoryDraft) { value in
            InventoryItemEditorView(
                draft: value,
                onCancel: { inventoryDraft = nil },
                onSave: { updated in
                    upsertInventoryItem(from: updated)
                    inventoryDraft = nil
                }
            )
        }
    }

    @ViewBuilder
    private var weaponsSection: some View {
        Section("Weapons") {
            if equipment.weapons.isEmpty {
                Text("No weapons")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(equipment.weapons) { weapon in
                    Button {
                        weaponDraft = WeaponDraft(weapon: weapon)
                    } label: {
                        WeaponRowView(weapon: weapon)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteWeapons)
            }

            Button {
                weaponDraft = WeaponDraft()
            } label: {
                Label("Add Weapon", systemImage: "plus")
            }
        }
    }

    @ViewBuilder
    private var armourSection: some View {
        Section("Armour") {
            if equipment.armour.isEmpty {
                Text("No armour entries")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(equipment.armour) { armour in
                    Button {
                        armourDraft = ArmourDraft(armour: armour)
                    } label: {
                        HStack {
                            Text(armour.location.isEmpty ? "Unnamed Location" : armour.location)
                            Spacer()
                            Text("AP \(armour.armourPoints)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteArmourEntries)
            }

            Button {
                armourDraft = ArmourDraft()
            } label: {
                Label("Add Armour", systemImage: "plus")
            }
        }
    }

    @ViewBuilder
    private var movementSection: some View {
        Section("Movement") {
            intRow("Half Move", value: $equipment.movement.halfMove)
            intRow("Full Move", value: $equipment.movement.fullMove)
            intRow("Charge", value: $equipment.movement.charge)
            intRow("Run", value: $equipment.movement.run)
        }
    }

    @ViewBuilder
    private var inventorySection: some View {
        Section("Inventory") {
            if equipment.inventory.isEmpty {
                Text("No inventory items")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(equipment.inventory) { item in
                    Button {
                        inventoryDraft = InventoryItemDraft(item: item)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                                Text("Weight \(item.weight.formatted(.number.precision(.fractionLength(0...2))))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("x\(item.quantity)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteInventoryItems)
            }

            Button {
                inventoryDraft = InventoryItemDraft()
            } label: {
                Label("Add Item", systemImage: "plus")
            }
        }
    }

    @ViewBuilder
    private func intRow(_ title: String, value: Binding<Int>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: value, format: .number)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
        }
    }

    private func refreshFromSharedState() {
        guard let character = viewModel.character(by: characterID) else { return }
        equipment = character.equipment
    }

    private func deleteWeapons(at offsets: IndexSet) {
        equipment.weapons.remove(atOffsets: offsets)
    }

    private func upsertWeapon(from draft: WeaponDraft) {
        let updated = draft.asWeapon()
        if let index = equipment.weapons.firstIndex(where: { $0.id == updated.id }) {
            equipment.weapons[index] = updated
        } else {
            equipment.weapons.append(updated)
        }
    }

    private func deleteArmourEntries(at offsets: IndexSet) {
        equipment.armour.remove(atOffsets: offsets)
    }

    private func upsertArmour(from draft: ArmourDraft) {
        let updated = draft.asArmour()
        if let index = equipment.armour.firstIndex(where: { $0.id == updated.id }) {
            equipment.armour[index] = updated
        } else {
            equipment.armour.append(updated)
        }
    }

    private func deleteInventoryItems(at offsets: IndexSet) {
        equipment.inventory.remove(atOffsets: offsets)
    }

    private func upsertInventoryItem(from draft: InventoryItemDraft) {
        let updated = draft.asInventoryItem()
        if let index = equipment.inventory.firstIndex(where: { $0.id == updated.id }) {
            equipment.inventory[index] = updated
        } else {
            equipment.inventory.append(updated)
        }
    }
}

@available(iOS 17, macOS 14, *)
private struct WeaponRowView: View {
    let weapon: Weapon

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(weapon.name.isEmpty ? "Unnamed Weapon" : weapon.name)
                .font(.headline)

            let detail = [
                weapon.type,
                weapon.range,
                weapon.damage,
                weapon.penetration
            ]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            if !detail.isEmpty {
                Text(detail.joined(separator: " • "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            let extra = [
                weapon.clip.isEmpty ? nil : "Clip \(weapon.clip)",
                weapon.reload.isEmpty ? nil : "Reload \(weapon.reload)",
                weapon.traits.isEmpty ? nil : weapon.traits
            ]
                .compactMap { $0 }

            if !extra.isEmpty {
                Text(extra.joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

@available(iOS 17, macOS 14, *)
private struct WeaponEditorView: View {
    @State private var draft: WeaponDraft
    let onCancel: () -> Void
    let onSave: (WeaponDraft) -> Void

    init(draft: WeaponDraft, onCancel: @escaping () -> Void, onSave: @escaping (WeaponDraft) -> Void) {
        _draft = State(initialValue: draft)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $draft.name)
                TextField("Type", text: $draft.type)
                TextField("Range", text: $draft.range)
                TextField("Damage", text: $draft.damage)
                TextField("Penetration", text: $draft.penetration)
                TextField("Clip", text: $draft.clip)
                TextField("Reload", text: $draft.reload)
                TextField("Traits", text: $draft.traits, axis: .vertical)
                    .lineLimit(2...4)
            }
            .navigationTitle(draft.isNew ? "Add Weapon" : "Edit Weapon")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                    }
                }
            }
        }
    }
}

private struct WeaponDraft: Identifiable {
    let id: UUID
    var name: String
    var type: String
    var range: String
    var damage: String
    var penetration: String
    var clip: String
    var reload: String
    var traits: String
    let isNew: Bool

    init() {
        id = UUID()
        name = ""
        type = ""
        range = ""
        damage = ""
        penetration = ""
        clip = ""
        reload = ""
        traits = ""
        isNew = true
    }

    init(weapon: Weapon) {
        id = weapon.id
        name = weapon.name
        type = weapon.type
        range = weapon.range
        damage = weapon.damage
        penetration = weapon.penetration
        clip = weapon.clip
        reload = weapon.reload
        traits = weapon.traits
        isNew = false
    }

    func asWeapon() -> Weapon {
        Weapon(
            id: id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type.trimmingCharacters(in: .whitespacesAndNewlines),
            range: range.trimmingCharacters(in: .whitespacesAndNewlines),
            damage: damage.trimmingCharacters(in: .whitespacesAndNewlines),
            penetration: penetration.trimmingCharacters(in: .whitespacesAndNewlines),
            clip: clip.trimmingCharacters(in: .whitespacesAndNewlines),
            reload: reload.trimmingCharacters(in: .whitespacesAndNewlines),
            traits: traits.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

@available(iOS 17, macOS 14, *)
private struct ArmourEditorView: View {
    @State private var draft: ArmourDraft
    let onCancel: () -> Void
    let onSave: (ArmourDraft) -> Void

    init(draft: ArmourDraft, onCancel: @escaping () -> Void, onSave: @escaping (ArmourDraft) -> Void) {
        _draft = State(initialValue: draft)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Location", text: $draft.location)
                TextField("Armour Points", value: $draft.armourPoints, format: .number)
            }
            .navigationTitle(draft.isNew ? "Add Armour" : "Edit Armour")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                    }
                }
            }
        }
    }
}

private struct ArmourDraft: Identifiable {
    let id: UUID
    var location: String
    var armourPoints: Int
    let isNew: Bool

    init() {
        id = UUID()
        location = ""
        armourPoints = 0
        isNew = true
    }

    init(armour: Armour) {
        id = armour.id
        location = armour.location
        armourPoints = armour.armourPoints
        isNew = false
    }

    func asArmour() -> Armour {
        Armour(
            id: id,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            armourPoints: armourPoints
        )
    }
}

@available(iOS 17, macOS 14, *)
private struct InventoryItemEditorView: View {
    @State private var draft: InventoryItemDraft
    let onCancel: () -> Void
    let onSave: (InventoryItemDraft) -> Void

    init(
        draft: InventoryItemDraft,
        onCancel: @escaping () -> Void,
        onSave: @escaping (InventoryItemDraft) -> Void
    ) {
        _draft = State(initialValue: draft)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $draft.name)
                TextField("Quantity", value: $draft.quantity, format: .number)
                TextField("Weight", value: $draft.weight, format: .number)
            }
            .navigationTitle(draft.isNew ? "Add Item" : "Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                    }
                }
            }
        }
    }
}

private struct InventoryItemDraft: Identifiable {
    let id: UUID
    var name: String
    var quantity: Int
    var weight: Double
    let isNew: Bool

    init() {
        id = UUID()
        name = ""
        quantity = 1
        weight = 0
        isNew = true
    }

    init(item: InventoryItem) {
        id = item.id
        name = item.name
        quantity = item.quantity
        weight = item.weight
        isNew = false
    }

    func asInventoryItem() -> InventoryItem {
        InventoryItem(
            id: id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: quantity,
            weight: weight
        )
    }
}
#endif
