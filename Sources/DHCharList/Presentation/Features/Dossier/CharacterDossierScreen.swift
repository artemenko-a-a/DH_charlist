import Foundation

#if canImport(SwiftUI)
import SwiftUI

#if os(iOS)
import UIKit
#endif

@available(iOS 17, macOS 14, *)
struct CharacterDossierScreen: View {
    @Environment(\.dismiss) private var dismiss

    let character: Character

    @State private var shareURL: URL?
    @State private var isPreparingPDF = false
    @State private var isShowingShareSheet = false
    @State private var errorMessage: String?

    private var dossier: CharacterDossier {
        CharacterDossierComposer.compose(for: character)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    exportStatusView
                    CharacterDossierDocumentView(dossier: dossier)
                        .accessibilityIdentifier("dossier.preview")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .frame(maxWidth: 860)
            }
            .background {
                Rectangle()
                    .fill(CogitatorPalette.screenGradient)
                    .ignoresSafeArea()
            }
            .navigationTitle("Character Dossier")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }

#if os(iOS)
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await sharePDF() }
                    } label: {
                        if isPreparingPDF {
                            ProgressView()
                        } else {
                            Label("Share PDF", systemImage: "square.and.arrow.up")
                        }
                    }
                    .accessibilityIdentifier("dossier.share.pdf")
                    .disabled(isPreparingPDF)
                }
#endif
            }
#if os(iOS)
            .task {
                await preparePDFIfNeeded()
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let shareURL {
                    DossierShareSheet(activityItems: [shareURL])
                }
            }
#endif
            .alert(
                "Dossier Export Error",
                isPresented: isShowingErrorAlert,
                actions: {
                    Button("OK") { errorMessage = nil }
                },
                message: {
                    Text(errorMessage ?? "")
                }
            )
        }
    }

    @ViewBuilder
    private var exportStatusView: some View {
#if os(iOS)
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: shareStatusIconName)
                .foregroundStyle(shareStatusColor)
                .font(.headline)

            VStack(alignment: .leading, spacing: 3) {
                Text("Printable PDF")
                    .font(.headline)
                    .foregroundStyle(CogitatorPalette.textPrimary)

                Text(shareStatusText)
                    .font(.caption)
                    .foregroundStyle(CogitatorPalette.textSecondary)
                    .accessibilityIdentifier("dossier.pdf.status")
            }

            Spacer()
        }
        .cogitatorWarningSurface()
#else
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "doc.text")
                .foregroundStyle(CogitatorPalette.brass)
                .font(.headline)

            VStack(alignment: .leading, spacing: 3) {
                Text("Printable PDF")
                    .font(.headline)
                    .foregroundStyle(CogitatorPalette.textPrimary)

                Text("Preview is available here. PDF sharing/export remains enabled in the iOS host runtime.")
                    .font(.caption)
                    .foregroundStyle(CogitatorPalette.textSecondary)
                    .accessibilityIdentifier("dossier.pdf.status")
            }

            Spacer()
        }
        .cogitatorWarningSurface()
#endif
    }

#if os(iOS)
    private var shareStatusText: String {
        if isPreparingPDF {
            return "Preparing a printable dossier PDF from the current character data."
        }

        if shareURL != nil {
            return "PDF ready to share, save to Files, or print."
        }

        return "PDF export is available from this preview."
    }

    private var shareStatusIconName: String {
        if isPreparingPDF {
            return "clock.arrow.circlepath"
        }

        if shareURL != nil {
            return "checkmark.circle.fill"
        }

        return "doc.richtext"
    }

    private var shareStatusColor: Color {
        if isPreparingPDF {
            return CogitatorPalette.amber
        }

        if shareURL != nil {
            return CogitatorPalette.brass
        }

        return CogitatorPalette.warning
    }

    @MainActor
    private func preparePDFIfNeeded() async {
        guard shareURL == nil, !isPreparingPDF else { return }
        isPreparingPDF = true
        defer { isPreparingPDF = false }

        do {
            shareURL = try CharacterDossierPDFRenderer.export(dossier: dossier)
            errorMessage = nil
        } catch {
            shareURL = nil
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func sharePDF() async {
        if shareURL == nil {
            await preparePDFIfNeeded()
        }

        guard shareURL != nil else { return }
        isShowingShareSheet = true
    }
#endif

    private var isShowingErrorAlert: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }
}

@available(iOS 17, macOS 14, *)
private struct CharacterDossierDocumentView: View {
    let dossier: CharacterDossier

    private let paperBackground = Color(red: 0.96, green: 0.95, blue: 0.92)
    private let paperEdge = Color(red: 0.80, green: 0.77, blue: 0.70)
    private let inkPrimary = Color(red: 0.14, green: 0.14, blue: 0.16)
    private let inkSecondary = Color(red: 0.32, green: 0.31, blue: 0.29)
    private let accent = Color(red: 0.44, green: 0.16, blue: 0.12)

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text(dossier.title)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(dossier.subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(dossier.metadataLine)
                    .font(.caption)
                    .foregroundStyle(inkSecondary)
            }

            ForEach(dossier.sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.title)
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundStyle(accent)
                        if let subtitle = section.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(inkSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                            dossierItemView(item)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(paperBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(paperEdge, lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
        }
    }

    @ViewBuilder
    private func dossierItemView(_ item: CharacterDossier.Item) -> some View {
        switch item {
        case let .field(label, value):
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(inkSecondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.body)
                    .foregroundStyle(inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case let .paragraph(text):
            Text(text)
                .font(.body)
                .foregroundStyle(inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
        case let .bullet(text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.body.weight(.bold))
                    .foregroundStyle(inkPrimary)
                Text(text)
                    .font(.body)
                    .foregroundStyle(inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#if os(iOS)
@available(iOS 17, *)
private struct DossierShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

@available(iOS 17, *)
private enum CharacterDossierPDFRenderer {
    private static let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)
    private static let pageInsets = UIEdgeInsets(top: 54, left: 54, bottom: 54, right: 54)
    private static let titleColor = UIColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1)
    private static let textColor = UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1)
    private static let accentColor = UIColor(red: 0.44, green: 0.16, blue: 0.12, alpha: 1)
    private static let subtleColor = UIColor(red: 0.38, green: 0.36, blue: 0.33, alpha: 1)

    static func export(dossier: CharacterDossier) throws -> URL {
        let directory = try makeOutputDirectory()
        let suffix = String(UUID().uuidString.prefix(8)).lowercased()
        let url = directory.appendingPathComponent("\(dossier.filenameStem)-\(suffix).pdf")
        try render(dossier: dossier).write(to: url, options: .atomic)
        return url
    }

    private static func makeOutputDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "dh_charlist_dossiers", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func render(dossier: CharacterDossier) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        let contentWidth = pageBounds.width - pageInsets.left - pageInsets.right

        return renderer.pdfData { context in
            var pageNumber = 0
            var yPosition: CGFloat = 0

            func beginPage() {
                context.beginPage()
                pageNumber += 1
                yPosition = pageInsets.top

                if pageNumber == 1 {
                    yPosition += draw(
                        attributedHeaderTitle(dossier.title),
                        at: CGPoint(x: pageInsets.left, y: yPosition),
                        width: contentWidth
                    )
                    yPosition += 8
                    yPosition += draw(
                        attributedHeaderSubtitle(dossier.subtitle),
                        at: CGPoint(x: pageInsets.left, y: yPosition),
                        width: contentWidth
                    )
                    yPosition += 6
                    yPosition += draw(
                        attributedMetadata(dossier.metadataLine),
                        at: CGPoint(x: pageInsets.left, y: yPosition),
                        width: contentWidth
                    )
                    yPosition += 18
                } else {
                    yPosition += draw(
                        attributedContinuationTitle("Character Dossier — \(dossier.title)"),
                        at: CGPoint(x: pageInsets.left, y: yPosition),
                        width: contentWidth
                    )
                    yPosition += 16
                }
            }

            func ensureSpace(for height: CGFloat) {
                if yPosition + height > pageBounds.height - pageInsets.bottom {
                    beginPage()
                }
            }

            beginPage()

            for section in dossier.sections {
                let sectionHeadingHeight = attributedHeight(attributedSectionTitle(section.title), width: contentWidth)
                    + (section.subtitle == nil ? 0 : attributedHeight(attributedSectionSubtitle(section.subtitle ?? ""), width: contentWidth) + 4)
                    + 12
                ensureSpace(for: sectionHeadingHeight)

                yPosition += draw(
                    attributedSectionTitle(section.title),
                    at: CGPoint(x: pageInsets.left, y: yPosition),
                    width: contentWidth
                )

                if let subtitle = section.subtitle, !subtitle.isEmpty {
                    yPosition += 4
                    yPosition += draw(
                        attributedSectionSubtitle(subtitle),
                        at: CGPoint(x: pageInsets.left, y: yPosition),
                        width: contentWidth
                    )
                }
                yPosition += 10

                for item in section.items {
                    let attributedItem = attributedItemText(item)
                    let itemHeight = attributedHeight(attributedItem, width: contentWidth)
                    ensureSpace(for: itemHeight + 8)
                    yPosition += draw(attributedItem, at: CGPoint(x: pageInsets.left, y: yPosition), width: contentWidth)
                    yPosition += 8
                }

                yPosition += 10
            }
        }
    }

    private static func draw(_ text: NSAttributedString, at point: CGPoint, width: CGFloat) -> CGFloat {
        let height = attributedHeight(text, width: width)
        let rect = CGRect(x: point.x, y: point.y, width: width, height: height)
        text.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return height
    }

    private static func attributedHeight(_ text: NSAttributedString, width: CGFloat) -> CGFloat {
        let size = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).integral.size
        return size.height
    }

    private static func attributedHeaderTitle(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: titleColor
            ]
        )
    }

    private static func attributedHeaderSubtitle(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: subtleColor
            ]
        )
    }

    private static func attributedMetadata(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: subtleColor
            ]
        )
    }

    private static func attributedContinuationTitle(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: subtleColor
            ]
        )
    }

    private static func attributedSectionTitle(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                .foregroundColor: accentColor
            ]
        )
    }

    private static func attributedSectionSubtitle(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: subtleColor
            ]
        )
    }

    private static func attributedItemText(_ item: CharacterDossier.Item) -> NSAttributedString {
        switch item {
        case let .field(label, value):
            let result = NSMutableAttributedString(
                string: "\(label): ",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                    .foregroundColor: textColor
                ]
            )
            result.append(
                NSAttributedString(
                    string: value,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                        .foregroundColor: textColor
                    ]
                )
            )
            return result
        case let .paragraph(text):
            return NSAttributedString(
                string: text,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: textColor
                ]
            )
        case let .bullet(text):
            return NSAttributedString(
                string: "• \(text)",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: textColor
                ]
            )
        }
    }
}
#endif
#endif
