import Foundation

public struct CharacterImportPreviewSummary: Equatable, Sendable {
    public let detectedCharacterCount: Int
    public let existingCharacterCount: Int

    public init(detectedCharacterCount: Int, existingCharacterCount: Int) {
        self.detectedCharacterCount = detectedCharacterCount
        self.existingCharacterCount = existingCharacterCount
    }

    public var isReplaceAll: Bool { true }
    public var removesCharactersMissingFromImport: Bool { true }
    public var isDestructive: Bool { true }

    public var confirmationMessage: String {
        """
        Imported file contains \(detectedCharacterCount) \(Self.characterLabel(count: detectedCharacterCount)).
        This import replaces your current local roster (\(existingCharacterCount) \(Self.localCharacterLabel(count: existingCharacterCount))); it does not merge.
        Characters not present in the imported file will be removed.
        This action is destructive and cannot be undone here.
        """
    }

    private static func characterLabel(count: Int) -> String {
        count == 1 ? "character" : "characters"
    }

    private static func localCharacterLabel(count: Int) -> String {
        count == 1 ? "local character" : "local characters"
    }
}
