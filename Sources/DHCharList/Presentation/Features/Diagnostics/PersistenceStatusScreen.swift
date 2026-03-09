import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
struct PersistenceStatusScreen: View {
    @Environment(\.dismiss) private var dismiss

    let status: AppContainer.PersistenceBootstrapStatus

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statusRow(
                        "Requested Backend",
                        value: status.requestedBackend.displayName,
                        valueIdentifier: "persistence.status.requested.value"
                    )
                    statusRow(
                        "Active Backend",
                        value: status.activeBackend.displayName,
                        valueIdentifier: "persistence.status.active.value"
                    )
                    statusRow(
                        "Fallback Active",
                        value: status.didFallback ? "Yes" : "No",
                        valueIdentifier: "persistence.status.fallback.value"
                    )
                } header: {
                    CogitatorSectionHeader("Persistence", subtitle: "Bootstrap Status")
                } footer: {
                    Text(status.summaryLine)
                        .cogitatorSupportingText()
                }

                if let diagnosticNote = status.diagnosticNote {
                    Section {
                        Text(diagnosticNote)
                            .font(.body)
                            .foregroundStyle(CogitatorPalette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("persistence.status.diagnostic-note")
                            .cogitatorPanelRow()
                    } header: {
                        CogitatorSectionHeader("Diagnostics", subtitle: "Fallback Reason")
                    }
                }
            }
            .formContentWidth()
            .platformInsetGroupedListStyle()
            .cogitatorFormRhythm()
            .cogitatorScreenChrome()
            .navigationTitle("Persistence Status")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func statusRow(_ label: String, value: String, valueIdentifier: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .foregroundStyle(CogitatorPalette.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(CogitatorPalette.textPrimary)
                .multilineTextAlignment(.trailing)
                .accessibilityIdentifier(valueIdentifier)
        }
        .cogitatorPanelRow()
    }
}

@available(iOS 17, macOS 14, *)
struct PersistenceFallbackNoticeView: View {
    let status: AppContainer.PersistenceBootstrapStatus
    let openDetails: () -> Void

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label("Using JSON fallback instead of SwiftData", systemImage: "externaldrive.badge.exclamationmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(CogitatorPalette.warning)

                Text(status.diagnosticNote ?? "SwiftData did not become the active backend. JSON remains active so the app stays usable.")
                    .cogitatorSupportingText()
                    .fixedSize(horizontal: false, vertical: true)

                Button("View Persistence Status") {
                    openDetails()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("persistence.status.open")
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("persistence.fallback.notice")
            .cogitatorWarningSurface()
            .cogitatorPanelRow()
        } header: {
            CogitatorSectionHeader("Persistence Notice", subtitle: "Fallback Active")
        }
    }
}

private extension AppContainer.PersistenceBackend {
    var displayName: String {
        switch self {
        case .jsonFile:
            return "JSON File"
        case .swiftData:
            return "SwiftData"
        }
    }
}

private extension AppContainer.PersistenceBootstrapStatus {
    var summaryLine: String {
        if didFallback {
            return "Requested \(requestedBackend.displayName), but the app is currently using \(activeBackend.displayName)."
        }

        return "The app is currently using \(activeBackend.displayName) as requested."
    }
}
#endif
