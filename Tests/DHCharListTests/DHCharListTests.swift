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
