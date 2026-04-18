import Foundation

enum DHIICreationEffectTarget: Equatable, Sendable {
    case characteristic(SkillCharacteristic)
    case influence

    var displayName: String {
        switch self {
        case .characteristic(let characteristic):
            characteristic.label
        case .influence:
            "Influence"
        }
    }
}

struct DHIICharacteristicModifierRule: Equatable, Sendable {
    let target: DHIICreationEffectTarget
    let delta: Int

    var summary: String {
        "\(delta >= 0 ? "+" : "-")\(target.displayName)"
    }
}

struct DHIIFateThresholdRule: Equatable, Sendable {
    let baseThreshold: Int
    let emperorsBlessingTarget: Int

    var summary: String {
        "\(baseThreshold) (Emperor's Blessing \(emperorsBlessingTarget)+)"
    }
}

struct DHIIWoundsRule: Equatable, Sendable {
    let base: Int
    let diceCount: Int
    let diceSides: Int

    var minimum: Int { base + diceCount }
    var maximum: Int { base + (diceCount * diceSides) }
    var summary: String { "\(base)+\(diceCount)d\(diceSides)" }
}

struct DHIIHomeWorldBonusRule: Equatable, Sendable {
    let name: String
    let summary: String
}

enum DHIIHomeWorldID: String, CaseIterable, Codable, Sendable {
    case feralWorld
    case forgeWorld
    case highborn
    case hiveWorld
    case shrineWorld
    case voidborn

    var displayName: String {
        switch self {
        case .feralWorld: "Feral World"
        case .forgeWorld: "Forge World"
        case .highborn: "Highborn"
        case .hiveWorld: "Hive World"
        case .shrineWorld: "Shrine World"
        case .voidborn: "Voidborn"
        }
    }
}

struct DHIIHomeWorldDefinition: Identifiable, Equatable, Sendable {
    let id: DHIIHomeWorldID
    let aliases: [String]
    let characteristicModifiers: [DHIICharacteristicModifierRule]
    let fateThreshold: DHIIFateThresholdRule
    let homeWorldBonus: DHIIHomeWorldBonusRule
    let aptitude: String
    let wounds: DHIIWoundsRule
    let recommendedBackgrounds: [String]
    let sourceCitation: String

    var displayName: String { id.displayName }

    var characteristicModifierSummary: String {
        characteristicModifiers.map(\.summary).joined(separator: ", ")
    }

    var recommendedBackgroundSummary: String {
        recommendedBackgrounds.joined(separator: ", ")
    }
}

struct DHIICharacterModelCompatibilityReport: Equatable, Sendable {
    let unsupportedTargets: [DHIICreationEffectTarget]
    let warningMessages: [String]

    var isFullySupported: Bool {
        unsupportedTargets.isEmpty
    }
}

struct DHIIHomeWorldPreview: Equatable, Sendable {
    let definition: DHIIHomeWorldDefinition
    let compatibility: DHIICharacterModelCompatibilityReport
}

enum DHIICharacterCreationEngine {
    static let canonicalHomeWorlds: [DHIIHomeWorldDefinition] = [
        DHIIHomeWorldDefinition(
            id: .feralWorld,
            aliases: ["Feral", "Feral World"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.strength), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.toughness), delta: 1),
                DHIICharacteristicModifierRule(target: .influence, delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 2, emperorsBlessingTarget: 3),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "The Old Ways",
                summary: "Any Low-Tech weapon the character uses loses Primitive and gains Proven (3)."
            ),
            aptitude: "Toughness",
            wounds: DHIIWoundsRule(base: 9, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Arbites", "Adeptus Astra Telepathica", "Imperial Guard", "Outcast"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 32"
        ),
        DHIIHomeWorldDefinition(
            id: .forgeWorld,
            aliases: ["Forge", "Forge World"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.intelligence), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.toughness), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.fellowship), delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 3, emperorsBlessingTarget: 8),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "Omnissiah's Chosen",
                summary: "The character starts with either the Technical Knock or Weapon-Tech talent."
            ),
            aptitude: "Intelligence",
            wounds: DHIIWoundsRule(base: 8, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Administratum", "Adeptus Arbites", "Adeptus Mechanicus", "Imperial Guard"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 34"
        ),
        DHIIHomeWorldDefinition(
            id: .highborn,
            aliases: ["Highborn"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.fellowship), delta: 1),
                DHIICharacteristicModifierRule(target: .influence, delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.toughness), delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 4, emperorsBlessingTarget: 10),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "Breeding Counts",
                summary: "Whenever the character would reduce Influence, reduce it by 1 less to a minimum reduction of 1."
            ),
            aptitude: "Fellowship",
            wounds: DHIIWoundsRule(base: 9, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Administratum", "Adeptus Arbites", "Adeptus Astra Telepathica", "Adeptus Ministorum"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 36"
        ),
        DHIIHomeWorldDefinition(
            id: .hiveWorld,
            aliases: ["Hive", "Hive World"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.agility), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.perception), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.willpower), delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 2, emperorsBlessingTarget: 6),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "Teeming Masses in Metal Mountains",
                summary: "Crowds count as open terrain for movement, and enclosed spaces grant +20 to Navigate (Surface)."
            ),
            aptitude: "Perception",
            wounds: DHIIWoundsRule(base: 8, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Arbites", "Adeptus Mechanicus", "Imperial Guard", "Outcast"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 38"
        ),
        DHIIHomeWorldDefinition(
            id: .shrineWorld,
            aliases: ["Shrine", "Shrine World"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.fellowship), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.willpower), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.perception), delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 3, emperorsBlessingTarget: 6),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "Faith in the Creed",
                summary: "When the character spends a Fate point, roll 1d10; on 1 the total Fate pool is not reduced."
            ),
            aptitude: "Willpower",
            wounds: DHIIWoundsRule(base: 7, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Administratum", "Adeptus Arbites", "Adeptus Ministorum", "Imperial Guard"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 40"
        ),
        DHIIHomeWorldDefinition(
            id: .voidborn,
            aliases: ["Voidborn", "Void Born"],
            characteristicModifiers: [
                DHIICharacteristicModifierRule(target: .characteristic(.intelligence), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.willpower), delta: 1),
                DHIICharacteristicModifierRule(target: .characteristic(.strength), delta: -1)
            ],
            fateThreshold: DHIIFateThresholdRule(baseThreshold: 3, emperorsBlessingTarget: 5),
            homeWorldBonus: DHIIHomeWorldBonusRule(
                name: "Child of the Dark",
                summary: "The character starts with Strong Minded and gains +30 to move in zero gravity."
            ),
            aptitude: "Intelligence",
            wounds: DHIIWoundsRule(base: 7, diceCount: 1, diceSides: 5),
            recommendedBackgrounds: ["Adeptus Astra Telepathica", "Adeptus Mechanicus", "Adeptus Ministorum", "Outcast"],
            sourceCitation: "Dark Heresy Second Edition Core Rulebook p. 42"
        )
    ]

    static func canonicalHomeWorld(for rawValue: String) -> DHIIHomeWorldDefinition? {
        let normalized = normalizedHomeWorldToken(rawValue)
        guard normalized != nil else {
            return nil
        }

        return canonicalHomeWorlds.first { definition in
            definition.aliases.contains { alias in
                normalizedHomeWorldToken(alias) == normalized
            } || normalizedHomeWorldToken(definition.displayName) == normalized
        }
    }

    static func previewHomeWorldSelection(rawValue: String) -> DHIIHomeWorldPreview? {
        guard let definition = canonicalHomeWorld(for: rawValue) else {
            return nil
        }

        return DHIIHomeWorldPreview(
            definition: definition,
            compatibility: compatibilityReport(for: definition)
        )
    }

    static func compatibilityReport(for definition: DHIIHomeWorldDefinition) -> DHIICharacterModelCompatibilityReport {
        let unsupportedTargets = definition.characteristicModifiers.compactMap { modifier -> DHIICreationEffectTarget? in
            switch modifier.target {
            case .influence:
                return .influence
            case .characteristic:
                return nil
            }
        }

        let warningMessages = unsupportedTargets.map { target in
            "\(target.displayName) is part of \(definition.displayName) creation rules, but the current saved character snapshot does not yet store it as a first-class DHII engine field."
        }

        return DHIICharacterModelCompatibilityReport(
            unsupportedTargets: unsupportedTargets,
            warningMessages: warningMessages
        )
    }
}

private func normalizedHomeWorldToken(_ value: String) -> String? {
    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else {
        return nil
    }

    let pieces = cleaned.lowercased().map { character -> String in
        if character.isLetter || character.isNumber {
            return String(character)
        }
        return "-"
    }

    let normalized = pieces.joined()
        .split(separator: "-", omittingEmptySubsequences: true)
        .joined(separator: "-")
    return normalized.isEmpty ? nil : normalized
}
