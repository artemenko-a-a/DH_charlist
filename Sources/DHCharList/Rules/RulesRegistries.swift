import Foundation

struct CheckModifierPreset: Identifiable, Equatable, Sendable {
    let id: String
    let value: Int
    let label: String
    let source: String
    let note: String?

    func normalizedModifier(scope: CheckModifierScope = .allChecks) -> CheckModifier {
        CheckModifier(
            id: "preset.\(scope.stableIdentifier).\(id)",
            kind: .preset,
            scope: scope,
            value: value,
            label: label,
            source: source,
            note: note
        )
    }
}

enum DifficultyPresetRegistry {
    static let standard: [CheckModifierPreset] = [
        CheckModifierPreset(id: "plus30", value: 30, label: "Standard Preset", source: "Difficulty Preset Registry", note: "Reusable preset modifier"),
        CheckModifierPreset(id: "plus20", value: 20, label: "Standard Preset", source: "Difficulty Preset Registry", note: "Reusable preset modifier"),
        CheckModifierPreset(id: "plus10", value: 10, label: "Standard Preset", source: "Difficulty Preset Registry", note: "Reusable preset modifier"),
        CheckModifierPreset(id: "plus0", value: 0, label: "Standard Preset", source: "Difficulty Preset Registry", note: "Reusable preset modifier"),
        CheckModifierPreset(id: "minus10", value: -10, label: "Standard Preset", source: "Difficulty Preset Registry", note: "Reusable preset modifier"),
        CheckModifierPreset(id: "minus20", value: -20, label: "Standard Preset", source: "Difficulty Preset Registry", note: "Reusable preset modifier"),
        CheckModifierPreset(id: "minus30", value: -30, label: "Standard Preset", source: "Difficulty Preset Registry", note: "Reusable preset modifier")
    ]

    static func preset(for value: Int) -> CheckModifierPreset? {
        standard.first(where: { $0.value == value })
    }
}

enum SkillCategory: String, Equatable, Sendable {
    case combat
    case fieldcraft
    case interaction
    case investigation
    case tech
    case knowledge
}

struct SkillMetadata: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let linkedCharacteristic: SkillCharacteristic
    let category: SkillCategory?
    let isCanonical: Bool

    static func adHoc(name: String, characteristic: SkillCharacteristic) -> SkillMetadata {
        SkillMetadata(
            id: "skill.\(normalizedRegistryToken(name)).\(characteristic.rawValue)",
            displayName: trimmedOrPlaceholder(name, placeholder: "Unnamed Skill"),
            linkedCharacteristic: characteristic,
            category: nil,
            isCanonical: false
        )
    }

    static func adHoc(for skill: Skill) -> SkillMetadata {
        adHoc(name: skill.displayName, characteristic: skill.characteristic)
    }
}

enum SkillMetadataRegistry {
    static let canonical: [SkillMetadata] = [
        SkillMetadata(id: "awareness", displayName: "Awareness", linkedCharacteristic: .perception, category: .fieldcraft, isCanonical: true),
        SkillMetadata(id: "tech-use", displayName: "Tech-Use", linkedCharacteristic: .intelligence, category: .tech, isCanonical: true),
        SkillMetadata(id: "dodge", displayName: "Dodge", linkedCharacteristic: .agility, category: .combat, isCanonical: true),
        SkillMetadata(id: "parry", displayName: "Parry", linkedCharacteristic: .weaponSkill, category: .combat, isCanonical: true),
        SkillMetadata(id: "scrutiny", displayName: "Scrutiny", linkedCharacteristic: .perception, category: .investigation, isCanonical: true),
        SkillMetadata(id: "inquiry", displayName: "Inquiry", linkedCharacteristic: .fellowship, category: .interaction, isCanonical: true),
        SkillMetadata(id: "stealth", displayName: "Stealth", linkedCharacteristic: .agility, category: .fieldcraft, isCanonical: true),
        SkillMetadata(id: "medicae", displayName: "Medicae", linkedCharacteristic: .intelligence, category: .tech, isCanonical: true),
        SkillMetadata(id: "athletics", displayName: "Athletics", linkedCharacteristic: .strength, category: .fieldcraft, isCanonical: true),
        SkillMetadata(id: "psyniscience", displayName: "Psyniscience", linkedCharacteristic: .perception, category: .knowledge, isCanonical: true)
    ]

    static func lookup(name: String, characteristic: SkillCharacteristic) -> SkillMetadata? {
        let normalizedName = normalizedRegistryToken(name)
        return canonical.first { metadata in
            metadata.linkedCharacteristic == characteristic
                && normalizedRegistryToken(metadata.displayName) == normalizedName
        }
    }

    static func resolve(_ skill: Skill) -> SkillMetadata {
        lookup(name: skill.displayName, characteristic: skill.characteristic) ?? .adHoc(for: skill)
    }
}

enum WeaponClassification: String, Equatable, Sendable {
    case melee
    case pistol
    case basic
    case heavy
    case launcher
    case grenade
    case thrown
    case other
}

struct WeaponTypeMetadata: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let classification: WeaponClassification
    let aliases: [String]
    let isCanonical: Bool

    static func adHoc(_ rawValue: String) -> WeaponTypeMetadata {
        let cleaned = trimmedOrPlaceholder(rawValue, placeholder: "Unknown")
        return WeaponTypeMetadata(
            id: "weapon-type.\(normalizedRegistryToken(cleaned))",
            displayName: cleaned,
            classification: .other,
            aliases: [cleaned],
            isCanonical: false
        )
    }
}

enum WeaponTypeRegistry {
    static let canonical: [WeaponTypeMetadata] = [
        WeaponTypeMetadata(id: "melee", displayName: "Melee", classification: .melee, aliases: ["melee"], isCanonical: true),
        WeaponTypeMetadata(id: "pistol", displayName: "Pistol", classification: .pistol, aliases: ["pistol"], isCanonical: true),
        WeaponTypeMetadata(id: "basic", displayName: "Basic", classification: .basic, aliases: ["basic"], isCanonical: true),
        WeaponTypeMetadata(id: "heavy", displayName: "Heavy", classification: .heavy, aliases: ["heavy"], isCanonical: true),
        WeaponTypeMetadata(id: "launcher", displayName: "Launcher", classification: .launcher, aliases: ["launcher"], isCanonical: true),
        WeaponTypeMetadata(id: "grenade", displayName: "Grenade", classification: .grenade, aliases: ["grenade"], isCanonical: true),
        WeaponTypeMetadata(id: "thrown", displayName: "Thrown", classification: .thrown, aliases: ["thrown"], isCanonical: true)
    ]

    static func resolve(_ rawValue: String?) -> WeaponTypeMetadata? {
        guard let cleaned = trimmedOrNil(rawValue) else {
            return nil
        }

        let normalized = normalizedRegistryToken(cleaned)
        if let metadata = canonical.first(where: { metadata in
            metadata.aliases.contains(where: { normalizedRegistryToken($0) == normalized })
        }) {
            return metadata
        }

        return .adHoc(cleaned)
    }
}

enum WeaponTraitCategory: String, Equatable, Sendable {
    case reliability
    case accuracy
    case damage
    case defensive
    case special
}

struct WeaponTraitMetadata: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let category: WeaponTraitCategory?
    let note: String?
    let aliases: [String]
    let isCanonical: Bool

    static func adHoc(_ rawValue: String) -> WeaponTraitMetadata {
        let cleaned = trimmedOrPlaceholder(rawValue, placeholder: "Unknown Trait")
        return WeaponTraitMetadata(
            id: "weapon-trait.\(normalizedRegistryToken(cleaned))",
            displayName: cleaned,
            category: .special,
            note: nil,
            aliases: [cleaned],
            isCanonical: false
        )
    }
}

enum WeaponTraitRegistry {
    static let canonical: [WeaponTraitMetadata] = [
        WeaponTraitMetadata(id: "reliable", displayName: "Reliable", category: .reliability, note: "Improves operational dependability.", aliases: ["reliable"], isCanonical: true),
        WeaponTraitMetadata(id: "tearing", displayName: "Tearing", category: .damage, note: "Relevant to future damage resolution.", aliases: ["tearing"], isCanonical: true),
        WeaponTraitMetadata(id: "accurate", displayName: "Accurate", category: .accuracy, note: "Relevant to future aim/accuracy resolution.", aliases: ["accurate"], isCanonical: true),
        WeaponTraitMetadata(id: "balanced", displayName: "Balanced", category: .defensive, note: "Relevant to future combat-action rules.", aliases: ["balanced"], isCanonical: true),
        WeaponTraitMetadata(id: "primitive", displayName: "Primitive", category: .damage, note: "Relevant to future armour interaction rules.", aliases: ["primitive"], isCanonical: true),
        WeaponTraitMetadata(id: "razor-sharp", displayName: "Razor Sharp", category: .damage, note: "Relevant to future penetration rules.", aliases: ["razor sharp", "razor-sharp"], isCanonical: true),
        WeaponTraitMetadata(id: "scatter", displayName: "Scatter", category: .special, note: "Relevant to future range/context rules.", aliases: ["scatter"], isCanonical: true),
        WeaponTraitMetadata(id: "blast", displayName: "Blast", category: .special, note: "Relevant to future area-effect rules.", aliases: ["blast"], isCanonical: true),
        WeaponTraitMetadata(id: "overheats", displayName: "Overheats", category: .reliability, note: "Relevant to future overheating rules.", aliases: ["overheats"], isCanonical: true)
    ]

    static func resolveAll(_ rawValue: String?) -> [WeaponTraitMetadata] {
        guard let cleaned = trimmedOrNil(rawValue) else {
            return []
        }

        return cleaned
            .split(whereSeparator: { $0 == "," || $0 == ";" })
            .map { component in
                let value = String(component)
                return resolve(value)
            }
    }

    static func resolve(_ rawValue: String) -> WeaponTraitMetadata {
        let cleaned = trimmedOrPlaceholder(rawValue, placeholder: "Unknown Trait")
        let normalized = normalizedRegistryToken(cleaned)
        if let metadata = canonical.first(where: { metadata in
            metadata.aliases.contains(where: { normalizedRegistryToken($0) == normalized })
        }) {
            return metadata
        }
        return .adHoc(cleaned)
    }
}

struct ConditionMetadata: Identifiable, Equatable, Sendable {
    let id: String
    let kind: RuleConditionKind
    let displayName: String
    let aliases: [String]
    let note: String?
    let isCanonical: Bool

    static func adHoc(_ rawValue: String) -> ConditionMetadata {
        let cleaned = trimmedOrPlaceholder(rawValue, placeholder: "Custom")
        return ConditionMetadata(
            id: "condition.\(normalizedRegistryToken(cleaned))",
            kind: .custom,
            displayName: cleaned,
            aliases: [cleaned],
            note: nil,
            isCanonical: false
        )
    }
}

enum ConditionMetadataRegistry {
    static let canonical: [ConditionMetadata] = [
        ConditionMetadata(id: "pinned", kind: .pinned, displayName: "Pinned", aliases: ["pinned", "pinned down"], note: "Relevant to future combat restrictions.", isCanonical: true),
        ConditionMetadata(id: "cover", kind: .cover, displayName: "Cover", aliases: ["cover", "in cover", "partial cover", "full cover"], note: "Relevant to future defensive calculations.", isCanonical: true),
        ConditionMetadata(id: "suppression", kind: .suppression, displayName: "Suppression", aliases: ["suppression", "suppressed", "suppressing fire"], note: "Relevant to future morale/fire-effect rules.", isCanonical: true),
        ConditionMetadata(id: "injury", kind: .injury, displayName: "Injury", aliases: ["injury", "injured", "wound", "wounded", "bleed", "bleeding"], note: "Relevant to future wound/critical rules.", isCanonical: true)
    ]

    static func metadata(for kind: RuleConditionKind) -> ConditionMetadata? {
        canonical.first(where: { $0.kind == kind })
    }

    static func lookup(label: String) -> ConditionMetadata? {
        let cleaned = trimmedOrPlaceholder(label, placeholder: "Custom")
        let normalized = cleaned.lowercased()
        return canonical.first { metadata in
            metadata.aliases.contains(where: normalized.contains)
        }
    }

    static func resolve(label: String) -> ConditionMetadata {
        lookup(label: label) ?? .adHoc(label)
    }
}

private func trimmedOrNil(_ value: String?) -> String? {
    guard let value else {
        return nil
    }

    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return cleaned.isEmpty ? nil : cleaned
}

private func trimmedOrPlaceholder(_ value: String, placeholder: String) -> String {
    let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return cleaned.isEmpty ? placeholder : cleaned
}

private func normalizedRegistryToken(_ value: String) -> String {
    let lowercased = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let normalized = lowercased.map { character -> String in
        if character.isLetter || character.isNumber {
            return String(character)
        }
        return "-"
    }

    let collapsed = normalized.joined()
        .split(separator: "-", omittingEmptySubsequences: true)
        .joined(separator: "-")
    return collapsed.isEmpty ? "value" : collapsed
}
