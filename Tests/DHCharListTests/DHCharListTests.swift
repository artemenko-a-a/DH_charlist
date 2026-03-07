import Foundation
import Testing
@testable import DHCharList

@Test func derivedValueCalculatorUsesCharacteristicAndTraining() {
    let characteristics = CharacteristicSet(weaponSkill: 40, ballisticSkill: 30, strength: 35, toughness: 32, agility: 45, intelligence: 28, perception: 31, willpower: 37, fellowship: 26)
    let skill = Skill(name: "Awareness", characteristic: .perception, training: .trained)

    #expect(DerivedValueCalculator.skillTarget(for: skill, characteristics: characteristics) == 41)
}

@Test func importExportRoundtrip() throws {
    let service = CharacterJSONImportExportService()
    let source = Character(profile: Profile(name: "Raibos"), skills: [Skill(name: "Stealth", characteristic: .agility, training: .known)])

    let data = try service.exportCharacters([source])
    let decoded = try service.import(data)

    #expect(decoded.count == 1)
    #expect(decoded.first?.profile.name == "Raibos")
}

@Test func importRejectsUnsupportedSchema() throws {
    let envelope = CharacterExportEnvelope(schemaVersion: 999, exportedAt: .now, characters: [])
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601

    let data = try encoder.encode(envelope)
    let service = CharacterJSONImportExportService()

    #expect(throws: CharacterRepositoryError.self) {
        _ = try service.import(data)
    }
}

@Test func profileUpdatePersistsDataAndUpdatesTimestamp() async throws {
    let fileURL = uniqueTestFileURL("update-roundtrip")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Before"))
    let originalUpdatedAt = created.updatedAt
    try? await Task.sleep(nanoseconds: 5_000_000)

    let edited = Profile(name: "After", homeWorld: "Hive", background: "Adeptus", role: "Sage", aptitudes: ["Knowledge"], description: "Edited profile")
    let updated = try await useCases.updateProfile(characterID: created.id, profile: edited)

    let reloadedRepository = JSONFileCharacterRepository(fileURL: fileURL)
    let persisted = try await reloadedRepository.fetch(id: created.id)

    #expect(updated.profile == edited)
    #expect(updated.updatedAt > originalUpdatedAt)
    #expect(persisted?.profile == edited)
}

@Test func characteristicUpdatePersistsAndBonusReflectsEditedValues() async throws {
    let fileURL = uniqueTestFileURL("characteristics-update")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Stats"))
    let edited = CharacteristicSet(
        weaponSkill: 47,
        ballisticSkill: 31,
        strength: 39,
        toughness: 42,
        agility: 28,
        intelligence: 50,
        perception: 33,
        willpower: 44,
        fellowship: 25
    )

    let updated = try await useCases.updateCharacteristics(characterID: created.id, characteristics: edited)
    let reloadedRepository = JSONFileCharacterRepository(fileURL: fileURL)
    let persisted = try await reloadedRepository.fetch(id: created.id)

    #expect(updated.characteristics == edited)
    #expect(updated.characteristics.bonus.weaponSkill == 4)
    #expect(updated.characteristics.bonus.intelligence == 5)
    #expect(updated.characteristics.bonus.fellowship == 2)
    #expect(persisted?.characteristics == edited)
}

@Test func resourceUpdatePersistsAndExperienceAvailableReflectsEditedValues() async throws {
    let fileURL = uniqueTestFileURL("resources-update")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Resources"))
    let edited = ResourceState(
        currentWounds: 9,
        maxWounds: 13,
        fatigue: 2,
        corruption: 1,
        insanity: 4,
        currentFate: 2,
        maxFate: 3,
        experienceSpent: 650,
        experienceTotal: 1000
    )

    let updated = try await useCases.updateResources(characterID: created.id, resources: edited)
    let reloadedRepository = JSONFileCharacterRepository(fileURL: fileURL)
    let persisted = try await reloadedRepository.fetch(id: created.id)

    #expect(updated.resources == edited)
    #expect(updated.resources.experienceAvailable == 350)
    #expect(persisted?.resources == edited)
    #expect(persisted?.resources.experienceAvailable == 350)
}

@Test func addSkillPersistsCorrectly() async throws {
    let fileURL = uniqueTestFileURL("skills-add")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Skills Add"))
    let added = Skill(name: "Awareness", characteristic: .perception, training: .known)

    let updated = try await useCases.updateSkills(characterID: created.id, skills: [added])
    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(updated.skills == [added])
    #expect(persisted?.skills == [added])
}

@Test func editSkillPersistsCorrectly() async throws {
    let fileURL = uniqueTestFileURL("skills-edit")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Skills Edit"))
    let original = Skill(name: "Stealth", characteristic: .agility, training: .known)
    _ = try await useCases.updateSkills(characterID: created.id, skills: [original])

    var edited = original
    edited.name = "Stealth Advanced"
    edited.characteristic = .intelligence
    edited.training = .veteran
    edited.specialisations = ["Urban", "Low-light"]

    let updated = try await useCases.updateSkills(characterID: created.id, skills: [edited])
    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(updated.skills == [edited])
    #expect(persisted?.skills == [edited])
}

@Test func deleteSkillPersistsCorrectly() async throws {
    let fileURL = uniqueTestFileURL("skills-delete")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Skills Delete"))
    let first = Skill(name: "Charm", characteristic: .fellowship, training: .known)
    let second = Skill(name: "Dodge", characteristic: .agility, training: .trained)
    _ = try await useCases.updateSkills(characterID: created.id, skills: [first, second])

    let updated = try await useCases.updateSkills(characterID: created.id, skills: [second])
    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(updated.skills == [second])
    #expect(persisted?.skills == [second])
}

@Test func derivedSkillTargetReflectsEditedCharacteristicValuesAndTrainingLevel() async throws {
    let fileURL = uniqueTestFileURL("skills-derived")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Skills Derived"))
    let initialCharacteristics = CharacteristicSet(
        weaponSkill: 30,
        ballisticSkill: 30,
        strength: 30,
        toughness: 30,
        agility: 30,
        intelligence: 30,
        perception: 35,
        willpower: 30,
        fellowship: 30
    )
    let editedCharacteristics = CharacteristicSet(
        weaponSkill: 30,
        ballisticSkill: 30,
        strength: 30,
        toughness: 30,
        agility: 30,
        intelligence: 30,
        perception: 42,
        willpower: 30,
        fellowship: 30
    )

    _ = try await useCases.updateCharacteristics(characterID: created.id, characteristics: initialCharacteristics)
    let baselineSkill = Skill(name: "Awareness", characteristic: .perception, training: .untrained)
    let baselineCharacter = try await useCases.updateSkills(characterID: created.id, skills: [baselineSkill])
    let baselineTarget = DerivedValueCalculator.skillTarget(for: baselineCharacter.skills[0], characteristics: baselineCharacter.characteristics)

    _ = try await useCases.updateCharacteristics(characterID: created.id, characteristics: editedCharacteristics)
    let editedSkill = Skill(id: baselineSkill.id, name: baselineSkill.name, characteristic: .perception, training: .veteran)
    let editedCharacter = try await useCases.updateSkills(characterID: created.id, skills: [editedSkill])
    let editedTarget = DerivedValueCalculator.skillTarget(for: editedCharacter.skills[0], characteristics: editedCharacter.characteristics)

    #expect(baselineTarget == 15)
    #expect(editedTarget == 62)
}

@Test func skillSpecialisationsPersistCorrectly() async throws {
    let fileURL = uniqueTestFileURL("skills-specialisations")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Skills Specs"))
    let skill = Skill(
        name: "Linguistics",
        characteristic: .intelligence,
        training: .trained,
        specialisations: ["High Gothic", "Techna-Lingua", "Underworld Cant"]
    )

    _ = try await useCases.updateSkills(characterID: created.id, skills: [skill])
    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(persisted?.skills.first?.specialisations == ["High Gothic", "Techna-Lingua", "Underworld Cant"])
}

@Test func addNotesListEntryPersistsCorrectly() async throws {
    let fileURL = uniqueTestFileURL("notes-add")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Notes Add"))
    let editedNotes = NotesState(talents: ["Rapid Reload"])

    let updated = try await useCases.updateNotes(characterID: created.id, notes: editedNotes)
    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(updated.notes.talents == ["Rapid Reload"])
    #expect(persisted?.notes.talents == ["Rapid Reload"])
}

@Test func editNotesListEntryPersistsCorrectly() async throws {
    let fileURL = uniqueTestFileURL("notes-edit")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Notes Edit"))
    _ = try await useCases.updateNotes(
        characterID: created.id,
        notes: NotesState(talents: ["Melee Weapon Training"])
    )

    let editedNotes = NotesState(talents: ["Melee Weapon Training (Chain)"])
    let updated = try await useCases.updateNotes(characterID: created.id, notes: editedNotes)
    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(updated.notes.talents == ["Melee Weapon Training (Chain)"])
    #expect(persisted?.notes.talents == ["Melee Weapon Training (Chain)"])
}

@Test func deleteNotesListEntryPersistsCorrectly() async throws {
    let fileURL = uniqueTestFileURL("notes-delete")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Notes Delete"))
    _ = try await useCases.updateNotes(
        characterID: created.id,
        notes: NotesState(traits: ["Dark Sight", "Unnatural Strength"])
    )

    let editedNotes = NotesState(traits: ["Unnatural Strength"])
    let updated = try await useCases.updateNotes(characterID: created.id, notes: editedNotes)
    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(updated.notes.traits == ["Unnatural Strength"])
    #expect(persisted?.notes.traits == ["Unnatural Strength"])
}

@Test func freeformNotesPersistCorrectly() async throws {
    let fileURL = uniqueTestFileURL("notes-freeform")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Notes Freeform"))
    let text = "Interrogation lead in lower habs. Verify contact at dusk."
    let editedNotes = NotesState(notes: text)

    let updated = try await useCases.updateNotes(characterID: created.id, notes: editedNotes)
    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(updated.notes.notes == text)
    #expect(persisted?.notes.notes == text)
}

@Test func notesEditsRemainScopedToSelectedCharacter() async throws {
    let fileURL = uniqueTestFileURL("notes-scoping")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let first = try await useCases.createCharacter(profile: Profile(name: "First Notes"))
    let second = try await useCases.createCharacter(profile: Profile(name: "Second Notes"))

    _ = try await useCases.updateNotes(
        characterID: first.id,
        notes: NotesState(psychicPowers: ["Precognition"], notes: "First character notes")
    )

    let firstPersisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: first.id)
    let secondPersisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: second.id)

    #expect(firstPersisted?.notes.psychicPowers == ["Precognition"])
    #expect(firstPersisted?.notes.notes == "First character notes")
    #expect(secondPersisted?.notes.psychicPowers.isEmpty == true)
    #expect(secondPersisted?.notes.notes.isEmpty == true)
}

@Test func addEditDeleteWeaponPersistsCorrectly() async throws {
    let fileURL = uniqueTestFileURL("equipment-weapons-crud")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Equipment Weapons"))
    let added = Weapon(
        name: "Laspistol",
        type: "Pistol",
        range: "30m",
        damage: "1d10+2 E",
        penetration: "0",
        clip: "30",
        reload: "Half",
        traits: "Reliable"
    )

    _ = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(weapons: [added])
    )

    var edited = added
    edited.name = "Accatran Laspistol"
    edited.penetration = "1"
    edited.traits = "Reliable, Accurate"

    let afterEdit = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(weapons: [edited])
    )

    let afterDelete = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(weapons: [])
    )

    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(afterEdit.equipment.weapons == [edited])
    #expect(afterDelete.equipment.weapons.isEmpty)
    #expect(persisted?.equipment.weapons.isEmpty == true)
}

@Test func addEditDeleteArmourPersistsCorrectly() async throws {
    let fileURL = uniqueTestFileURL("equipment-armour-crud")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Equipment Armour"))
    let added = Armour(location: "Body", armourPoints: 4)

    _ = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(armour: [added])
    )

    var edited = added
    edited.location = "Head"
    edited.armourPoints = 5

    let afterEdit = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(armour: [edited])
    )

    let afterDelete = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(armour: [])
    )

    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(afterEdit.equipment.armour == [edited])
    #expect(afterDelete.equipment.armour.isEmpty)
    #expect(persisted?.equipment.armour.isEmpty == true)
}

@Test func movementEditsPersistCorrectly() async throws {
    let fileURL = uniqueTestFileURL("equipment-movement")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Equipment Movement"))
    let movement = MovementProfile(halfMove: 4, fullMove: 8, charge: 12, run: 24)

    let updated = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(movement: movement)
    )

    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(updated.equipment.movement == movement)
    #expect(persisted?.equipment.movement == movement)
}

@Test func addEditDeleteInventoryItemPersistsCorrectly() async throws {
    let fileURL = uniqueTestFileURL("equipment-inventory-crud")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Equipment Inventory"))
    let added = InventoryItem(name: "Frag Grenade", quantity: 2, weight: 0.5)

    _ = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(inventory: [added])
    )

    var edited = added
    edited.name = "Krak Grenade"
    edited.quantity = 1
    edited.weight = 0.6

    let afterEdit = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(inventory: [edited])
    )

    let afterDelete = try await useCases.updateEquipment(
        characterID: created.id,
        equipment: EquipmentState(inventory: [])
    )

    let persisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: created.id)

    #expect(afterEdit.equipment.inventory == [edited])
    #expect(afterDelete.equipment.inventory.isEmpty)
    #expect(persisted?.equipment.inventory.isEmpty == true)
}

@Test func equipmentEditsRemainScopedToSelectedCharacter() async throws {
    let fileURL = uniqueTestFileURL("equipment-scoping")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let first = try await useCases.createCharacter(profile: Profile(name: "First Equipment"))
    let second = try await useCases.createCharacter(profile: Profile(name: "Second Equipment"))

    let firstEquipment = EquipmentState(
        weapons: [Weapon(name: "Autogun", type: "Basic", range: "100m", damage: "1d10+3 I", penetration: "0", clip: "30", reload: "Half", traits: "")],
        armour: [Armour(location: "Body", armourPoints: 5)],
        movement: MovementProfile(halfMove: 3, fullMove: 6, charge: 9, run: 18),
        inventory: [InventoryItem(name: "Lho-sticks", quantity: 1, weight: 0.1)]
    )

    _ = try await useCases.updateEquipment(characterID: first.id, equipment: firstEquipment)

    let firstPersisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: first.id)
    let secondPersisted = try await JSONFileCharacterRepository(fileURL: fileURL).fetch(id: second.id)

    #expect(firstPersisted?.equipment == firstEquipment)
    #expect(secondPersisted?.equipment == EquipmentState())
}

@Test func duplicateKeepsOriginalIntactAndCreatesDistinctID() async throws {
    let fileURL = uniqueTestFileURL("duplicate")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let originalProfile = Profile(name: "Original", homeWorld: "Void", background: "Outcast", role: "Assassin")
    let created = try await useCases.createCharacter(profile: originalProfile)
    let duplicated = try await useCases.duplicateCharacter(id: created.id)

    let all = try await repository.fetchAll()
    let originalStored = all.first(where: { $0.id == created.id })

    #expect(all.count == 2)
    #expect(duplicated.id != created.id)
    #expect(duplicated.profile.name == "Original Copy")
    #expect(originalStored?.profile == originalProfile)
}

@Test func deleteCharacterUseCaseRemovesRecord() async throws {
    let fileURL = uniqueTestFileURL("delete")
    let repository = JSONFileCharacterRepository(fileURL: fileURL)
    let useCases = CharacterUseCases(repository: repository)

    let created = try await useCases.createCharacter(profile: Profile(name: "Disposable"))
    try await useCases.deleteCharacter(id: created.id)

    let all = try await repository.fetchAll()
    #expect(all.isEmpty)
}

@Test func profileAutosaveCoordinatorCoalescesPendingEdits() async throws {
    let coordinator = ProfileAutosaveCoordinator(debounceNanoseconds: 50_000_000)
    let characterID = UUID()
    let recorder = SaveRecorder()

    await coordinator.scheduleSave(characterID: characterID, profile: Profile(name: "A")) { id, profile in
        await recorder.record(id: id, profile: profile)
    }
    try await Task.sleep(nanoseconds: 10_000_000)

    await coordinator.scheduleSave(characterID: characterID, profile: Profile(name: "B")) { id, profile in
        await recorder.record(id: id, profile: profile)
    }

    try await Task.sleep(nanoseconds: 120_000_000)

    let saves = await recorder.saves()
    #expect(saves.count == 1)
    #expect(saves.first?.1.name == "B")
}

@Test func profileAutosaveCoordinatorKeepsIndependentCharacters() async throws {
    let coordinator = ProfileAutosaveCoordinator(debounceNanoseconds: 30_000_000)
    let recorder = SaveRecorder()
    let firstID = UUID()
    let secondID = UUID()

    await coordinator.scheduleSave(characterID: firstID, profile: Profile(name: "First")) { id, profile in
        await recorder.record(id: id, profile: profile)
    }
    await coordinator.scheduleSave(characterID: secondID, profile: Profile(name: "Second")) { id, profile in
        await recorder.record(id: id, profile: profile)
    }

    try await Task.sleep(nanoseconds: 100_000_000)

    let saves = await recorder.saves()
    let ids = Set(saves.map { $0.0 })
    #expect(ids == Set([firstID, secondID]))
}

@Test func profileAutosaveCoordinatorDoesNotDropNewerTrackingAfterOlderCompletion() async throws {
    let coordinator = ProfileAutosaveCoordinator(debounceNanoseconds: 30_000_000)
    let recorder = SaveRecorder()
    let gate = SaveGate()
    let probe = CompletionProbe()
    let characterID = UUID()

    await coordinator.scheduleSave(characterID: characterID, profile: Profile(name: "First")) { id, profile in
        await gate.markStarted(profile.name)
        await gate.waitForPermit(profile.name)
        await recorder.record(id: id, profile: profile)
    }

    await gate.waitForStart("First")

    await coordinator.scheduleSave(characterID: characterID, profile: Profile(name: "Second")) { id, profile in
        await gate.markStarted(profile.name)
        await gate.waitForPermit(profile.name)
        await recorder.record(id: id, profile: profile)
    }

    await gate.waitForStart("Second")
    await gate.allow("First")

    let waitTask = Task {
        await coordinator.waitForPendingSaves()
        await probe.markComplete()
    }

    try await Task.sleep(nanoseconds: 10_000_000)
    #expect(await probe.isComplete() == false)

    await gate.allow("Second")
    await waitTask.value

    let names = Set(await recorder.saves().map { $0.1.name })
    #expect(names == Set(["First", "Second"]))
}

@Test func profileAutosaveCoordinatorCoalescesAfterPerformStarts() async throws {
    let coordinator = ProfileAutosaveCoordinator(debounceNanoseconds: 50_000_000)
    let recorder = SaveRecorder()
    let gate = SaveGate()
    let characterID = UUID()

    await coordinator.scheduleSave(characterID: characterID, profile: Profile(name: "First")) { id, profile in
        await gate.markStarted(profile.name)
        await gate.waitForPermit(profile.name)
        await recorder.record(id: id, profile: profile)
    }

    await gate.waitForStart("First")

    await coordinator.scheduleSave(characterID: characterID, profile: Profile(name: "Second")) { id, profile in
        await gate.markStarted(profile.name)
        await gate.waitForPermit(profile.name)
        await recorder.record(id: id, profile: profile)
    }

    try await Task.sleep(nanoseconds: 5_000_000)

    await coordinator.scheduleSave(characterID: characterID, profile: Profile(name: "Third")) { id, profile in
        await gate.markStarted(profile.name)
        await gate.waitForPermit(profile.name)
        await recorder.record(id: id, profile: profile)
    }

    await gate.waitForStart("Third")
    await gate.allow("First")
    await gate.allow("Third")

    await coordinator.waitForPendingSaves()

    let names = Set(await recorder.saves().map { $0.1.name })
    #expect(names == Set(["First", "Third"]))
}

@Test func profileAutosaveCoordinatorKeepsTrackingIsolatedAcrossCharacters() async throws {
    let coordinator = ProfileAutosaveCoordinator(debounceNanoseconds: 30_000_000)
    let recorder = SaveRecorder()
    let gate = SaveGate()
    let probe = CompletionProbe()
    let firstID = UUID()
    let secondID = UUID()

    await coordinator.scheduleSave(characterID: firstID, profile: Profile(name: "One")) { id, profile in
        await gate.markStarted(profile.name)
        await gate.waitForPermit(profile.name)
        await recorder.record(id: id, profile: profile)
    }

    await coordinator.scheduleSave(characterID: secondID, profile: Profile(name: "Two")) { id, profile in
        await gate.markStarted(profile.name)
        await gate.waitForPermit(profile.name)
        await recorder.record(id: id, profile: profile)
    }

    await gate.waitForStart("One")
    await gate.waitForStart("Two")
    await gate.allow("One")

    let waitTask = Task {
        await coordinator.waitForPendingSaves()
        await probe.markComplete()
    }

    try await Task.sleep(nanoseconds: 10_000_000)
    #expect(await probe.isComplete() == false)

    await gate.allow("Two")
    await waitTask.value

    let names = Set(await recorder.saves().map { $0.1.name })
    #expect(names == Set(["One", "Two"]))
}

private actor SaveRecorder {
    private var stored: [(UUID, Profile)] = []

    func record(id: UUID, profile: Profile) {
        stored.append((id, profile))
    }

    func saves() -> [(UUID, Profile)] {
        stored
    }
}

private actor SaveGate {
    private var started: Set<String> = []
    private var permitted: Set<String> = []
    private var startWaiters: [String: [CheckedContinuation<Void, Never>]] = [:]
    private var permitWaiters: [String: [CheckedContinuation<Void, Never>]] = [:]

    func markStarted(_ label: String) {
        started.insert(label)
        if let waiters = startWaiters.removeValue(forKey: label) {
            for waiter in waiters {
                waiter.resume()
            }
        }
    }

    func waitForStart(_ label: String) async {
        if started.contains(label) { return }
        await withCheckedContinuation { continuation in
            startWaiters[label, default: []].append(continuation)
        }
    }

    func allow(_ label: String) {
        permitted.insert(label)
        if let waiters = permitWaiters.removeValue(forKey: label) {
            for waiter in waiters {
                waiter.resume()
            }
        }
    }

    func waitForPermit(_ label: String) async {
        if permitted.contains(label) { return }
        await withCheckedContinuation { continuation in
            permitWaiters[label, default: []].append(continuation)
        }
    }
}

private actor CompletionProbe {
    private var completed = false

    func markComplete() {
        completed = true
    }

    func isComplete() -> Bool {
        completed
    }
}

private func uniqueTestFileURL(_ suffix: String) -> URL {
    URL(filePath: NSTemporaryDirectory())
        .appending(path: "dh_charlist_tests_\(suffix)_\(UUID().uuidString).json")
}
