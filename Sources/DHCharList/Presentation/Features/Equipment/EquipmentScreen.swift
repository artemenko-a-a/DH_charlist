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
    @State private var searchText = ""

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
        .formContentWidth()
        .formStyle(.grouped)
        .cogitatorScreenChrome()
        .navigationTitle("Equipment")
        .searchable(text: $searchText, prompt: "Search weapons, armour, inventory")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Quick Add", systemImage: "plus.circle") {
                    Button("Add Weapon") {
                        weaponDraft = WeaponDraft()
                    }
                    Button("Add Armour") {
                        armourDraft = ArmourDraft()
                    }
                    Button("Add Item") {
                        inventoryDraft = InventoryItemDraft()
                    }
                }
            }
        }
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
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var weaponsSection: some View {
        Section {
            if equipment.weapons.isEmpty {
                Text("No weapons yet")
                    .foregroundStyle(.secondary)
                    .cogitatorPanelRow()
            } else if filteredWeapons.isEmpty {
                Text("No matching weapons")
                    .foregroundStyle(.secondary)
                    .cogitatorPanelRow()
            } else {
                ForEach(filteredWeapons) { weapon in
                    Button {
                        weaponDraft = WeaponDraft(weapon: weapon)
                    } label: {
                        WeaponRowView(weapon: weapon)
                    }
                    .buttonStyle(.plain)
                    .cogitatorPanelRow()
                }
                .onDelete(perform: deleteFilteredWeapons)
            }

            Button {
                weaponDraft = WeaponDraft()
            } label: {
                Label("Add Weapon", systemImage: "plus")
            }
            .cogitatorPanelRow()
            .accessibilityLabel("Add Weapon")
        } header: {
            CogitatorSectionHeader(weaponsSectionTitle, subtitle: "Ordnance Registry")
        } footer: {
            Text("Tap a weapon to edit it. Swipe left to delete.")
        }
    }

    @ViewBuilder
    private var armourSection: some View {
        Section {
            if equipment.armour.isEmpty {
                Text("No armour entries yet")
                    .foregroundStyle(.secondary)
                    .cogitatorPanelRow()
            } else if filteredArmour.isEmpty {
                Text("No matching armour")
                    .foregroundStyle(.secondary)
                    .cogitatorPanelRow()
            } else {
                ForEach(filteredArmour) { armour in
                    Button {
                        armourDraft = ArmourDraft(armour: armour)
                    } label: {
                        HStack {
                            Text(armour.location.isEmpty ? "Unnamed Location" : armour.location)
                            Spacer()
                            CogitatorStatusChip("AP \(armour.armourPoints)", level: .caution)
                        }
                    }
                    .buttonStyle(.plain)
                    .cogitatorPanelRow()
                    .accessibilityLabel("\(armour.location.isEmpty ? "Unnamed Location" : armour.location), armour points \(armour.armourPoints)")
                    .accessibilityHint("Double tap to edit armour.")
                }
                .onDelete(perform: deleteFilteredArmourEntries)
            }

            Button {
                armourDraft = ArmourDraft()
            } label: {
                Label("Add Armour", systemImage: "plus")
            }
            .cogitatorPanelRow()
            .accessibilityLabel("Add Armour")
        } header: {
            CogitatorSectionHeader(armourSectionTitle, subtitle: "Protection Matrix")
        } footer: {
            Text("Use one entry per body location.")
        }
    }

    @ViewBuilder
    private var movementSection: some View {
        Section {
            intRow("Half Move", value: $equipment.movement.halfMove)
            intRow("Full Move", value: $equipment.movement.fullMove)
            intRow("Charge", value: $equipment.movement.charge)
            intRow("Run", value: $equipment.movement.run)
        } header: {
            CogitatorSectionHeader("Movement", subtitle: "Locomotion Profile")
        } footer: {
            Text("Movement values are used during session checks and combat.")
        }
    }

    @ViewBuilder
    private var inventorySection: some View {
        Section {
            if equipment.inventory.isEmpty {
                Text("No inventory items yet")
                    .foregroundStyle(.secondary)
                    .cogitatorPanelRow()
            } else if filteredInventory.isEmpty {
                Text("No matching inventory items")
                    .foregroundStyle(.secondary)
                    .cogitatorPanelRow()
            } else {
                ForEach(filteredInventory) { item in
                    Button {
                        inventoryDraft = InventoryItemDraft(item: item)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                                Text("Weight \(item.weight.formatted(.number.precision(.fractionLength(0...2))))")
                                    .font(.caption)
                                    .foregroundStyle(CogitatorPalette.amber)
                                    .lineLimit(1)
                            }
                            Spacer()
                            CogitatorStatusChip("x\(item.quantity)", level: .nominal)
                        }
                    }
                    .buttonStyle(.plain)
                    .cogitatorPanelRow()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(item.name.isEmpty ? "Unnamed Item" : item.name), quantity \(item.quantity), weight \(item.weight.formatted(.number.precision(.fractionLength(0...2))))")
                    .accessibilityHint("Double tap to edit inventory item.")
                }
                .onDelete(perform: deleteFilteredInventoryItems)
            }

            Button {
                inventoryDraft = InventoryItemDraft()
            } label: {
                Label("Add Item", systemImage: "plus")
            }
            .cogitatorPanelRow()
            .accessibilityLabel("Add Item")
        } header: {
            CogitatorSectionHeader(inventorySectionTitle, subtitle: "Field Inventory Ledger")
        } footer: {
            Text("Tap an item to edit quantity/weight. Swipe left to delete.")
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
                .accessibilityLabel(title)
                .accessibilityValue(String(value.wrappedValue))
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
        .cogitatorPanelRow()
    }

    private func refreshFromSharedState() {
        guard let character = viewModel.character(by: characterID) else { return }
        equipment = character.equipment
    }

    private func deleteFilteredWeapons(at offsets: IndexSet) {
        let idsToDelete = offsets.compactMap { index in
            filteredWeapons.indices.contains(index) ? filteredWeapons[index].id : nil
        }
        equipment.weapons.removeAll { idsToDelete.contains($0.id) }
    }

    private func upsertWeapon(from draft: WeaponDraft) {
        let updated = draft.asWeapon()
        if let index = equipment.weapons.firstIndex(where: { $0.id == updated.id }) {
            equipment.weapons[index] = updated
        } else {
            equipment.weapons.append(updated)
        }
    }

    private func deleteFilteredArmourEntries(at offsets: IndexSet) {
        let idsToDelete = offsets.compactMap { index in
            filteredArmour.indices.contains(index) ? filteredArmour[index].id : nil
        }
        equipment.armour.removeAll { idsToDelete.contains($0.id) }
    }

    private func upsertArmour(from draft: ArmourDraft) {
        let updated = draft.asArmour()
        if let index = equipment.armour.firstIndex(where: { $0.id == updated.id }) {
            equipment.armour[index] = updated
        } else {
            equipment.armour.append(updated)
        }
    }

    private func deleteFilteredInventoryItems(at offsets: IndexSet) {
        let idsToDelete = offsets.compactMap { index in
            filteredInventory.indices.contains(index) ? filteredInventory[index].id : nil
        }
        equipment.inventory.removeAll { idsToDelete.contains($0.id) }
    }

    private func upsertInventoryItem(from draft: InventoryItemDraft) {
        let updated = draft.asInventoryItem()
        if let index = equipment.inventory.firstIndex(where: { $0.id == updated.id }) {
            equipment.inventory[index] = updated
        } else {
            equipment.inventory.append(updated)
        }
    }

    private var filteredWeapons: [Weapon] {
        EquipmentSearch.filter(weapons: equipment.weapons, query: searchText)
    }

    private var filteredArmour: [Armour] {
        EquipmentSearch.filter(armour: equipment.armour, query: searchText)
    }

    private var filteredInventory: [InventoryItem] {
        EquipmentSearch.filter(inventory: equipment.inventory, query: searchText)
    }

    private var weaponsSectionTitle: String {
        sectionTitle(base: "Weapons", matches: filteredWeapons.count, total: equipment.weapons.count)
    }

    private var armourSectionTitle: String {
        sectionTitle(base: "Armour", matches: filteredArmour.count, total: equipment.armour.count)
    }

    private var inventorySectionTitle: String {
        sectionTitle(base: "Inventory", matches: filteredInventory.count, total: equipment.inventory.count)
    }

    private func sectionTitle(base: String, matches: Int, total: Int) -> String {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "\(base) (\(total))"
        }

        return "\(base) (\(matches) of \(total))"
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
                    .foregroundStyle(CogitatorPalette.amber)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
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
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Double tap to edit weapon.")
    }

    private var accessibilitySummary: String {
        let name = weapon.name.isEmpty ? "Unnamed Weapon" : weapon.name
        let base = "\(name). Type \(weapon.type.isEmpty ? "Unknown" : weapon.type). Range \(weapon.range.isEmpty ? "Unknown" : weapon.range). Damage \(weapon.damage.isEmpty ? "Unknown" : weapon.damage). Penetration \(weapon.penetration.isEmpty ? "Unknown" : weapon.penetration)."
        let clipReload = [weapon.clip.isEmpty ? nil : "Clip \(weapon.clip)", weapon.reload.isEmpty ? nil : "Reload \(weapon.reload)"]
            .compactMap { $0 }
            .joined(separator: ". ")
        if clipReload.isEmpty {
            return base
        }
        return "\(base) \(clipReload)."
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
                    .accessibilityLabel("Weapon Name")
                    .cogitatorPanelRow()
                TextField("Type", text: $draft.type)
                    .accessibilityLabel("Weapon Type")
                    .cogitatorPanelRow()
                TextField("Range", text: $draft.range)
                    .accessibilityLabel("Weapon Range")
                    .cogitatorPanelRow()
                TextField("Damage", text: $draft.damage)
                    .accessibilityLabel("Weapon Damage")
                    .cogitatorPanelRow()
                TextField("Penetration", text: $draft.penetration)
                    .accessibilityLabel("Weapon Penetration")
                    .cogitatorPanelRow()
                TextField("Clip", text: $draft.clip)
                    .accessibilityLabel("Weapon Clip")
                    .cogitatorPanelRow()
                TextField("Reload", text: $draft.reload)
                    .accessibilityLabel("Weapon Reload")
                    .cogitatorPanelRow()
                TextField("Traits", text: $draft.traits, axis: .vertical)
                    .lineLimit(2...4)
                    .accessibilityLabel("Weapon Traits")
                    .cogitatorPanelRow()
            }
            .cogitatorScreenChrome()
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
                    .accessibilityLabel("Armour Location")
                    .cogitatorPanelRow()
                TextField("Armour Points", value: $draft.armourPoints, format: .number)
                    .accessibilityLabel("Armour Points")
                    .cogitatorPanelRow()
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
            }
            .cogitatorScreenChrome()
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
                    .accessibilityLabel("Item Name")
                    .cogitatorPanelRow()
                TextField("Quantity", value: $draft.quantity, format: .number)
                    .accessibilityLabel("Item Quantity")
                    .cogitatorPanelRow()
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
                TextField("Weight", value: $draft.weight, format: .number)
                    .accessibilityLabel("Item Weight")
                    .cogitatorPanelRow()
#if os(iOS)
                    .keyboardType(.decimalPad)
#endif
            }
            .cogitatorScreenChrome()
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

struct EquipmentSearch {
    static func filter(weapons: [Weapon], query: String) -> [Weapon] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return weapons }
        return weapons.filter { weapon in
            [
                weapon.name,
                weapon.type,
                weapon.range,
                weapon.damage,
                weapon.penetration,
                weapon.clip,
                weapon.reload,
                weapon.traits
            ].contains { $0.localizedCaseInsensitiveContains(normalized) }
        }
    }

    static func filter(armour: [Armour], query: String) -> [Armour] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return armour }
        return armour.filter { armour in
            armour.location.localizedCaseInsensitiveContains(normalized)
                || String(armour.armourPoints).localizedCaseInsensitiveContains(normalized)
        }
    }

    static func filter(inventory: [InventoryItem], query: String) -> [InventoryItem] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return inventory }
        return inventory.filter { item in
            item.name.localizedCaseInsensitiveContains(normalized)
                || String(item.quantity).localizedCaseInsensitiveContains(normalized)
                || item.weight.formatted(.number.precision(.fractionLength(0...2))).localizedCaseInsensitiveContains(normalized)
        }
    }
}

#endif
