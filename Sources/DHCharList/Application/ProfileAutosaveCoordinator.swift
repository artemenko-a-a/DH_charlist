import Foundation

public actor ProfileAutosaveCoordinator {
    private var pendingTasks: [UUID: Task<Void, Never>] = [:]
    private let debounceNanoseconds: UInt64

    public init(debounceNanoseconds: UInt64 = 500_000_000) {
        self.debounceNanoseconds = debounceNanoseconds
    }

    public func scheduleSave(
        characterID: UUID,
        profile: Profile,
        perform: @escaping @Sendable (UUID, Profile) async -> Void
    ) {
        pendingTasks[characterID]?.cancel()

        pendingTasks[characterID] = Task {
            do {
                try await Task.sleep(nanoseconds: debounceNanoseconds)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            await perform(characterID, profile)
            await clearPendingTask(for: characterID)
        }
    }

    public func waitForPendingSaves() async {
        let tasks = pendingTasks.values
        for task in tasks {
            await task.value
        }
    }

    private func clearPendingTask(for characterID: UUID) async {
        pendingTasks[characterID] = nil
    }
}
