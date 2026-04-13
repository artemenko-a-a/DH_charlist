import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
enum CogitatorPalette {
    static let canvas = Color(red: 0.10, green: 0.11, blue: 0.13)
    static let canvasSecondary = Color(red: 0.16, green: 0.17, blue: 0.20)
    static let modalSurface = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let panel = Color(red: 0.20, green: 0.22, blue: 0.26)
    static let panelRaised = Color(red: 0.24, green: 0.26, blue: 0.30)
    static let editorField = Color(red: 0.17, green: 0.18, blue: 0.22)
    static let panelEdge = Color(red: 0.57, green: 0.48, blue: 0.34)
    static let marsRed = Color(red: 0.58, green: 0.17, blue: 0.14)
    static let brass = Color(red: 0.82, green: 0.70, blue: 0.48)
    static let amber = Color(red: 0.92, green: 0.72, blue: 0.33)
    static let warning = Color(red: 0.80, green: 0.42, blue: 0.16)
    static let critical = Color(red: 0.74, green: 0.18, blue: 0.16)
    static let textPrimary = Color(red: 0.95, green: 0.95, blue: 0.93)
    static let textSecondary = Color(red: 0.81, green: 0.82, blue: 0.80)
    static let textTertiary = Color(red: 0.69, green: 0.70, blue: 0.69)

    static var screenGradient: some ShapeStyle {
        LinearGradient(
            colors: [canvas, canvasSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

@available(iOS 17, macOS 14, *)
enum CogitatorRhythm {
    static let rowMinHeight: CGFloat = 52
    static let sectionSpacing: CGFloat = 14
    static let rowVerticalInset: CGFloat = 8
    static let rowHorizontalInset: CGFloat = 14
}

@available(iOS 17, macOS 14, *)
enum CogitatorStatusLevel {
    case nominal
    case caution
    case warning
    case critical

    var foreground: Color {
        switch self {
        case .nominal:
            return CogitatorPalette.brass
        case .caution:
            return CogitatorPalette.amber
        case .warning:
            return CogitatorPalette.warning
        case .critical:
            return CogitatorPalette.critical
        }
    }
}

@available(iOS 17, macOS 14, *)
struct CogitatorSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .tracking(0.9)
                .foregroundStyle(CogitatorPalette.brass)
                .textCase(.uppercase)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CogitatorPalette.textSecondary)
            }
        }
    }
}

@available(iOS 17, macOS 14, *)
struct CogitatorStatusChip: View {
    let text: String
    let level: CogitatorStatusLevel

    init(_ text: String, level: CogitatorStatusLevel = .nominal) {
        self.text = text
        self.level = level
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(level.foreground)
            .background {
                Capsule(style: .continuous)
                    .fill(CogitatorPalette.panelRaised)
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(level.foreground.opacity(0.45), lineWidth: 1)
                    }
            }
    }
}

@available(iOS 17, macOS 14, *)
private struct CogitatorScreenChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background {
                Rectangle()
                    .fill(CogitatorPalette.screenGradient)
                    .ignoresSafeArea()
            }
            .foregroundStyle(CogitatorPalette.textPrimary)
            .tint(CogitatorPalette.marsRed)
#if os(iOS)
            .toolbarBackground(CogitatorPalette.canvasSecondary.opacity(0.98), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .presentationBackground(CogitatorPalette.modalSurface)
#endif
    }
}

@available(iOS 17, macOS 14, *)
private struct CogitatorPanelRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowInsets(
                EdgeInsets(
                    top: CogitatorRhythm.rowVerticalInset,
                    leading: CogitatorRhythm.rowHorizontalInset,
                    bottom: CogitatorRhythm.rowVerticalInset,
                    trailing: CogitatorRhythm.rowHorizontalInset
                )
            )
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(CogitatorPalette.panel.opacity(0.96))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(CogitatorPalette.panelEdge.opacity(0.55), lineWidth: 1)
                    }
            )
            .listRowSeparator(.hidden)
            .listRowSeparatorTint(CogitatorPalette.panelEdge.opacity(0.45))
    }
}

@available(iOS 17, macOS 14, *)
private struct CogitatorEmptyStateModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(CogitatorPalette.textPrimary, CogitatorPalette.textSecondary)
    }
}

@available(iOS 17, macOS 14, *)
private struct CogitatorFormRhythmModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.defaultMinListRowHeight, CogitatorRhythm.rowMinHeight)
#if os(iOS)
            .listSectionSpacing(CogitatorRhythm.sectionSpacing)
            .scrollDismissesKeyboard(.interactively)
#endif
    }
}

@available(iOS 17, macOS 14, *)
private struct CogitatorSupportingTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.medium))
            .foregroundStyle(CogitatorPalette.textSecondary)
    }
}

@available(iOS 17, macOS 14, *)
private struct CogitatorAppChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .fill(CogitatorPalette.screenGradient)
                    .ignoresSafeArea()
            }
#if os(iOS)
            .toolbarBackground(CogitatorPalette.canvasSecondary.opacity(0.98), for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
#endif
    }
}

@available(iOS 17, macOS 14, *)
private struct CogitatorInputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
#if os(iOS)
            .scrollContentBackground(.hidden)
#endif
            .foregroundStyle(CogitatorPalette.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(CogitatorPalette.editorField)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(CogitatorPalette.panelEdge.opacity(0.4), lineWidth: 1)
                    }
            }
    }
}

@available(iOS 17, macOS 14, *)
private struct CogitatorStatusSurfaceModifier: ViewModifier {
    let accent: Color

    func body(content: Content) -> some View {
        content
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(CogitatorPalette.panelRaised.opacity(0.92))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(accent.opacity(0.55), lineWidth: 1)
                    }
            }
    }
}

@available(iOS 17, macOS 14, *)
private struct CogitatorReadoutLabelStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            configuration.label
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CogitatorPalette.textSecondary)
            Spacer(minLength: 12)
            configuration.content
                .font(.body.weight(.semibold))
                .foregroundStyle(CogitatorPalette.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

@available(iOS 17, macOS 14, *)
extension View {
    func cogitatorAppChrome() -> some View {
        modifier(CogitatorAppChromeModifier())
    }

    func cogitatorScreenChrome() -> some View {
        modifier(CogitatorScreenChromeModifier())
    }

    func cogitatorPanelRow() -> some View {
        modifier(CogitatorPanelRowModifier())
    }

    func cogitatorEmptyStateStyle() -> some View {
        modifier(CogitatorEmptyStateModifier())
    }

    func cogitatorFormRhythm() -> some View {
        modifier(CogitatorFormRhythmModifier())
    }

    func cogitatorSupportingText() -> some View {
        modifier(CogitatorSupportingTextModifier())
    }

    func cogitatorInputField() -> some View {
        modifier(CogitatorInputFieldModifier())
    }

    func cogitatorWarningSurface() -> some View {
        modifier(CogitatorStatusSurfaceModifier(accent: CogitatorPalette.warning))
    }

    func cogitatorReadoutStyle() -> some View {
        labeledContentStyle(CogitatorReadoutLabelStyle())
    }

    func cogitatorEmphasisText() -> some View {
        foregroundStyle(CogitatorPalette.amber)
    }
}
#endif
