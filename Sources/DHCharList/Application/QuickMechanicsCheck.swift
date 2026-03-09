import Foundation

struct QuickMechanicsModifierPreset: Identifiable, Equatable, Sendable {
    let value: Int

    var id: Int { value }

    static let standard: [QuickMechanicsModifierPreset] = [
        QuickMechanicsModifierPreset(value: 30),
        QuickMechanicsModifierPreset(value: 20),
        QuickMechanicsModifierPreset(value: 10),
        QuickMechanicsModifierPreset(value: 0),
        QuickMechanicsModifierPreset(value: -10),
        QuickMechanicsModifierPreset(value: -20),
        QuickMechanicsModifierPreset(value: -30)
    ]
}

struct QuickMechanicsCheckBreakdown: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case characteristic
        case skill
    }

    let kind: Kind
    let checkName: String
    let sourceName: String
    let baseValue: Int
    let derivedBonus: Int?
    let trainingModifier: Int?
    let appliedModifier: Int
    let finalTarget: Int
}

enum QuickMechanicsCheckBuilder {
    static func characteristicCheck(
        for characteristic: SkillCharacteristic,
        characteristics: CharacteristicSet,
        modifier: Int = 0
    ) -> QuickMechanicsCheckBreakdown {
        let baseValue = characteristics.value(for: characteristic)
        return QuickMechanicsCheckBreakdown(
            kind: .characteristic,
            checkName: "\(characteristic.label) Check",
            sourceName: characteristic.label,
            baseValue: baseValue,
            derivedBonus: characteristics.bonusValue(for: characteristic),
            trainingModifier: nil,
            appliedModifier: modifier,
            finalTarget: baseValue + modifier
        )
    }

    static func skillCheck(
        for skill: Skill,
        characteristics: CharacteristicSet,
        modifier: Int = 0
    ) -> QuickMechanicsCheckBreakdown {
        let baseValue = characteristics.value(for: skill.characteristic)
        let trainingModifier = skill.training.modifier
        return QuickMechanicsCheckBreakdown(
            kind: .skill,
            checkName: skill.displayName,
            sourceName: skill.characteristic.label,
            baseValue: baseValue,
            derivedBonus: characteristics.bonusValue(for: skill.characteristic),
            trainingModifier: trainingModifier,
            appliedModifier: modifier,
            finalTarget: baseValue + trainingModifier + modifier
        )
    }
}

extension CharacteristicSet {
    func value(for characteristic: SkillCharacteristic) -> Int {
        switch characteristic {
        case .weaponSkill: weaponSkill
        case .ballisticSkill: ballisticSkill
        case .strength: strength
        case .toughness: toughness
        case .agility: agility
        case .intelligence: intelligence
        case .perception: perception
        case .willpower: willpower
        case .fellowship: fellowship
        }
    }

    func bonusValue(for characteristic: SkillCharacteristic) -> Int {
        bonus.value(for: characteristic)
    }
}

private extension CharacteristicBonus {
    func value(for characteristic: SkillCharacteristic) -> Int {
        switch characteristic {
        case .weaponSkill: weaponSkill
        case .ballisticSkill: ballisticSkill
        case .strength: strength
        case .toughness: toughness
        case .agility: agility
        case .intelligence: intelligence
        case .perception: perception
        case .willpower: willpower
        case .fellowship: fellowship
        }
    }
}

extension SkillCharacteristic {
    var label: String {
        switch self {
        case .weaponSkill: "Weapon Skill"
        case .ballisticSkill: "Ballistic Skill"
        case .strength: "Strength"
        case .toughness: "Toughness"
        case .agility: "Agility"
        case .intelligence: "Intelligence"
        case .perception: "Perception"
        case .willpower: "Willpower"
        case .fellowship: "Fellowship"
        }
    }
}

extension SkillTrainingLevel {
    var label: String {
        switch self {
        case .untrained: "Untrained"
        case .known: "Known"
        case .trained: "Trained"
        case .veteran: "Veteran"
        }
    }
}

extension Skill {
    var displayName: String {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedName.isEmpty ? "Unnamed Skill" : cleanedName
    }
}

extension Int {
    var signedValueLabel: String {
        if self >= 0 {
            return "+\(self)"
        }
        return "\(self)"
    }

    var accessibilitySignedToken: String {
        if self >= 0 {
            return "plus\(self)"
        }
        return "minus\(abs(self))"
    }
}
