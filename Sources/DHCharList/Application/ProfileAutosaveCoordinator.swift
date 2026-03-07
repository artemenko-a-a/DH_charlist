import Foundation

public actor ProfileAutosaveCoordinator {
    private struct PendingSave {
        let token: UUID
        let task: Task<Void, Never>
    }

    private var pendingTasks: [UUID: PendingSave] = [:]
    private let debounceNanoseconds: UInt64

    public init(debounceNanoseconds: UInt64 = 500_000_000) {
        self.debounceNanoseconds = debounceNanoseconds
    }

    public func scheduleSave(
        characterID: UUID,
        profile: Profile,
        perform: @escaping @Sendable (UUID, Profile) async -> Void
    ) {
        pendingTasks[characterID]?.task.cancel()

        let token = UUID()
        let task = Task {
            do {
                try await Task.sleep(nanoseconds: debounceNanoseconds)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            await perform(characterID, profile)
            await clearPendingTask(for: characterID, token: token)
        }

        pendingTasks[characterID] = PendingSave(token: token, task: task)
    }

    public func waitForPendingSaves() async {
        let tasks = pendingTasks.values.map { $0.task }
        for task in tasks {
            await task.value
        }
    }

    private func clearPendingTask(for characterID: UUID, token: UUID) async {
        guard pendingTasks[characterID]?.token == token else { return }
        pendingTasks[characterID] = nil
    }
}
