import Foundation

struct CheckModifierPreset: Identifiable, Equatable, Sendable {
    let value: Int

    var id: Int { value }

    static let standard: [CheckModifierPreset] = [
        CheckModifierPreset(value: 30),
        CheckModifierPreset(value: 20),
        CheckModifierPreset(value: 10),
        CheckModifierPreset(value: 0),
        CheckModifierPreset(value: -10),
        CheckModifierPreset(value: -20),
        CheckModifierPreset(value: -30)
    ]
}

enum CheckKind: Equatable, Sendable {
    case characteristic
    case skill
}

enum RuleContributionKind: Equatable, Sendable {
    case derivedBonus
    case training
    case modifier
}

struct RuleContribution: Equatable, Sendable {
    let kind: RuleContributionKind
    let label: String
    let value: Int
    let appliesToFinalTarget: Bool
}

struct RuleBreakdown: Equatable, Sendable {
    let baseValue: Int
    let contributions: [RuleContribution]
    let finalTarget: Int

    func contribution(of kind: RuleContributionKind) -> RuleContribution? {
        contributions.first(where: { $0.kind == kind })
    }

    var derivedBonus: Int? {
        contribution(of: .derivedBonus)?.value
    }

    var trainingContribution: Int? {
        contribution(of: .training)?.value
    }

    var appliedModifier: Int {
        contribution(of: .modifier)?.value ?? 0
    }
}

struct CheckRequest: Equatable, Sendable {
    enum Scope: Equatable, Sendable {
        case characteristic(SkillCharacteristic)
        case skill(Skill)
    }

    let scope: Scope
    let characteristics: CharacteristicSet
    let modifier: Int

    static func characteristic(
        _ characteristic: SkillCharacteristic,
        characteristics: CharacteristicSet,
        modifier: Int = 0
    ) -> CheckRequest {
        CheckRequest(scope: .characteristic(characteristic), characteristics: characteristics, modifier: modifier)
    }

    static func skill(
        _ skill: Skill,
        characteristics: CharacteristicSet,
        modifier: Int = 0
    ) -> CheckRequest {
        CheckRequest(scope: .skill(skill), characteristics: characteristics, modifier: modifier)
    }
}

struct CheckResult: Equatable, Sendable {
    let kind: CheckKind
    let checkName: String
    let sourceName: String
    let breakdown: RuleBreakdown

    var finalTarget: Int { breakdown.finalTarget }
}

enum MechanicsCheckResolver {
    static func resolve(_ request: CheckRequest) -> CheckResult {
        switch request.scope {
        case .characteristic(let characteristic):
            resolveCharacteristicCheck(
                characteristic,
                characteristics: request.characteristics,
                modifier: request.modifier
            )
        case .skill(let skill):
            resolveSkillCheck(
                skill,
                characteristics: request.characteristics,
                modifier: request.modifier
            )
        }
    }

    private static func resolveCharacteristicCheck(
        _ characteristic: SkillCharacteristic,
        characteristics: CharacteristicSet,
        modifier: Int
    ) -> CheckResult {
        let baseValue = characteristics.value(for: characteristic)
        let derivedBonus = characteristics.bonusValue(for: characteristic)
        let contributions = [
            RuleContribution(
                kind: .derivedBonus,
                label: "Derived Bonus",
                value: derivedBonus,
                appliesToFinalTarget: false
            ),
            RuleContribution(
                kind: .modifier,
                label: "Applied Modifier",
                value: modifier,
                appliesToFinalTarget: true
            )
        ]

        return CheckResult(
            kind: .characteristic,
            checkName: "\(characteristic.label) Check",
            sourceName: characteristic.label,
            breakdown: RuleBreakdown(
                baseValue: baseValue,
                contributions: contributions,
                finalTarget: baseValue + modifier
            )
        )
    }

    private static func resolveSkillCheck(
        _ skill: Skill,
        characteristics: CharacteristicSet,
        modifier: Int
    ) -> CheckResult {
        let baseValue = characteristics.value(for: skill.characteristic)
        let derivedBonus = characteristics.bonusValue(for: skill.characteristic)
        let trainingModifier = skill.training.modifier
        let contributions = [
            RuleContribution(
                kind: .derivedBonus,
                label: "Derived Bonus",
                value: derivedBonus,
                appliesToFinalTarget: false
            ),
            RuleContribution(
                kind: .training,
                label: "Training Contribution",
                value: trainingModifier,
                appliesToFinalTarget: true
            ),
            RuleContribution(
                kind: .modifier,
                label: "Applied Modifier",
                value: modifier,
                appliesToFinalTarget: true
            )
        ]

        return CheckResult(
            kind: .skill,
            checkName: skill.displayName,
            sourceName: skill.characteristic.label,
            breakdown: RuleBreakdown(
                baseValue: baseValue,
                contributions: contributions,
                finalTarget: baseValue + trainingModifier + modifier
            )
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
