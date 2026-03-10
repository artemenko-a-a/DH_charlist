import Foundation

struct CheckModifierPreset: Identifiable, Equatable, Sendable {
    let value: Int

    var id: Int { value }

    var normalizedModifier: CheckModifier {
        .preset(value: value)
    }

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

enum CheckOrigin: Equatable, Sendable {
    case standard
    case sessionCombat
}

enum CheckKind: Equatable, Sendable {
    case characteristic
    case skill
}

enum CheckModifierKind: String, Equatable, Sendable {
    case preset
    case manual
    case sessionTemporary
    case conditionDerived
    case equipmentDerived
}

enum CheckModifierScope: Equatable, Sendable {
    case allChecks
    case characteristicChecks
    case skillChecks
    case specificCharacteristic(SkillCharacteristic)
    case specificSkill(UUID)
    case combatSessionOnly
}

struct CheckModifier: Identifiable, Equatable, Sendable {
    let id: String
    let kind: CheckModifierKind
    let scope: CheckModifierScope
    let value: Int
    let label: String
    let source: String
    let note: String?

    static func preset(
        value: Int,
        scope: CheckModifierScope = .allChecks
    ) -> CheckModifier {
        CheckModifier(
            id: "preset.\(scope.stableIdentifier).\(value.accessibilitySignedToken)",
            kind: .preset,
            scope: scope,
            value: value,
            label: "Standard Preset",
            source: "Quick Mechanics Preset",
            note: nil
        )
    }

    static func manual(
        value: Int,
        scope: CheckModifierScope = .allChecks,
        note: String? = nil
    ) -> CheckModifier {
        CheckModifier(
            id: "manual.\(scope.stableIdentifier).\(value.accessibilitySignedToken)",
            kind: .manual,
            scope: scope,
            value: value,
            label: "Custom Modifier",
            source: "Manual Entry",
            note: note
        )
    }

    static func sessionTemporary(
        label: String,
        value: Int,
        scope: CheckModifierScope = .combatSessionOnly,
        note: String? = nil
    ) -> CheckModifier {
        let cleanedLabel = label.trimmedOrPlaceholder("Unnamed Session Modifier")
        return CheckModifier(
            id: "session.\(cleanedLabel.stableToken)",
            kind: .sessionTemporary,
            scope: scope,
            value: value,
            label: cleanedLabel,
            source: "Session Temporary Modifier",
            note: note
        )
    }

    static func conditionDerived(
        label: String,
        value: Int,
        scope: CheckModifierScope = .combatSessionOnly,
        note: String? = nil
    ) -> CheckModifier {
        let cleanedLabel = label.trimmedOrPlaceholder("Condition Modifier")
        return CheckModifier(
            id: "condition-derived.\(scope.stableIdentifier).\(cleanedLabel.stableToken).\(value.accessibilitySignedToken)",
            kind: .conditionDerived,
            scope: scope,
            value: value,
            label: cleanedLabel,
            source: "Condition Derived Modifier",
            note: note
        )
    }

    static func equipmentDerived(
        label: String,
        value: Int,
        scope: CheckModifierScope = .allChecks,
        note: String? = nil
    ) -> CheckModifier {
        let cleanedLabel = label.trimmedOrPlaceholder("Equipment Modifier")
        return CheckModifier(
            id: "equipment-derived.\(scope.stableIdentifier).\(cleanedLabel.stableToken).\(value.accessibilitySignedToken)",
            kind: .equipmentDerived,
            scope: scope,
            value: value,
            label: cleanedLabel,
            source: "Equipment Derived Modifier",
            note: note
        )
    }

    func applies(to request: CheckRequest) -> Bool {
        switch scope {
        case .allChecks:
            return true
        case .characteristicChecks:
            return request.kind == .characteristic
        case .skillChecks:
            return request.kind == .skill
        case .specificCharacteristic(let characteristic):
            if case .characteristic(let requestCharacteristic) = request.scope {
                return requestCharacteristic == characteristic
            }
            return false
        case .specificSkill(let skillID):
            if case .skill(let skill) = request.scope {
                return skill.id == skillID
            }
            return false
        case .combatSessionOnly:
            return request.origin == .sessionCombat
        }
    }
}

enum RuleConditionKind: String, Equatable, Sendable {
    case pinned
    case cover
    case suppression
    case injury
    case custom

    static func inferred(from label: String) -> RuleConditionKind {
        let normalized = label.lowercased()
        if normalized.contains("pinned") {
            return .pinned
        }
        if normalized.contains("cover") {
            return .cover
        }
        if normalized.contains("suppress") {
            return .suppression
        }
        if normalized.contains("injur") || normalized.contains("wound") || normalized.contains("bleed") {
            return .injury
        }
        return .custom
    }

    var label: String {
        switch self {
        case .pinned: "Pinned"
        case .cover: "Cover"
        case .suppression: "Suppression"
        case .injury: "Injury"
        case .custom: "Custom"
        }
    }
}

struct RuleCondition: Identifiable, Equatable, Sendable {
    let id: String
    let kind: RuleConditionKind
    let label: String
    let source: String
    let note: String?

    static func sessionCombatCondition(
        index: Int,
        text: String,
        note: String? = nil
    ) -> RuleCondition {
        let cleanedText = text.trimmedOrPlaceholder("Unnamed Condition")
        return RuleCondition(
            id: "session-condition.\(index).\(cleanedText.stableToken)",
            kind: .inferred(from: cleanedText),
            label: cleanedText,
            source: "Session Combat Condition",
            note: note
        )
    }
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
    let modifier: CheckModifier?
}

struct RuleBreakdown: Equatable, Sendable {
    let baseValue: Int
    let contributions: [RuleContribution]
    let activeConditions: [RuleCondition]
    let finalTarget: Int

    func contribution(of kind: RuleContributionKind) -> RuleContribution? {
        contributions.first(where: { $0.kind == kind })
    }

    func contributions(of kind: RuleContributionKind) -> [RuleContribution] {
        contributions.filter { $0.kind == kind }
    }

    var derivedBonus: Int? {
        contribution(of: .derivedBonus)?.value
    }

    var trainingContribution: Int? {
        contribution(of: .training)?.value
    }

    var appliedModifier: Int {
        contributions(of: .modifier)
            .reduce(0) { $0 + $1.value }
    }

    var appliedModifierContributions: [RuleContribution] {
        contributions(of: .modifier)
    }

    var appliedModifiers: [CheckModifier] {
        appliedModifierContributions.compactMap(\.modifier)
    }
}

struct CheckRequest: Equatable, Sendable {
    enum Scope: Equatable, Sendable {
        case characteristic(SkillCharacteristic)
        case skill(Skill)
    }

    let scope: Scope
    let characteristics: CharacteristicSet
    let origin: CheckOrigin
    let modifiers: [CheckModifier]
    let conditions: [RuleCondition]

    var kind: CheckKind {
        switch scope {
        case .characteristic:
            .characteristic
        case .skill:
            .skill
        }
    }

    static func characteristic(
        _ characteristic: SkillCharacteristic,
        characteristics: CharacteristicSet,
        origin: CheckOrigin = .standard,
        modifiers: [CheckModifier] = [],
        conditions: [RuleCondition] = []
    ) -> CheckRequest {
        CheckRequest(
            scope: .characteristic(characteristic),
            characteristics: characteristics,
            origin: origin,
            modifiers: modifiers,
            conditions: conditions
        )
    }

    static func characteristic(
        _ characteristic: SkillCharacteristic,
        characteristics: CharacteristicSet,
        origin: CheckOrigin = .standard,
        modifier: Int = 0,
        conditions: [RuleCondition] = []
    ) -> CheckRequest {
        CheckRequest.characteristic(
            characteristic,
            characteristics: characteristics,
            origin: origin,
            modifiers: modifier == 0 ? [] : [CheckModifier.manual(value: modifier)],
            conditions: conditions
        )
    }

    static func skill(
        _ skill: Skill,
        characteristics: CharacteristicSet,
        origin: CheckOrigin = .standard,
        modifiers: [CheckModifier] = [],
        conditions: [RuleCondition] = []
    ) -> CheckRequest {
        CheckRequest(
            scope: .skill(skill),
            characteristics: characteristics,
            origin: origin,
            modifiers: modifiers,
            conditions: conditions
        )
    }

    static func skill(
        _ skill: Skill,
        characteristics: CharacteristicSet,
        origin: CheckOrigin = .standard,
        modifier: Int = 0,
        conditions: [RuleCondition] = []
    ) -> CheckRequest {
        CheckRequest.skill(
            skill,
            characteristics: characteristics,
            origin: origin,
            modifiers: modifier == 0 ? [] : [CheckModifier.manual(value: modifier)],
            conditions: conditions
        )
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
                request: request
            )
        case .skill(let skill):
            resolveSkillCheck(
                skill,
                request: request
            )
        }
    }

    private static func resolveCharacteristicCheck(
        _ characteristic: SkillCharacteristic,
        request: CheckRequest
    ) -> CheckResult {
        let baseValue = request.characteristics.value(for: characteristic)
        let derivedBonus = request.characteristics.bonusValue(for: characteristic)
        let modifierContributions = modifierContributions(for: request)
        let totalModifier = modifierContributions.reduce(0) { $0 + $1.value }
        let contributions = [
            RuleContribution(
                kind: .derivedBonus,
                label: "Derived Bonus",
                value: derivedBonus,
                appliesToFinalTarget: false,
                modifier: nil
            )
        ] + modifierContributions

        return CheckResult(
            kind: .characteristic,
            checkName: "\(characteristic.label) Check",
            sourceName: characteristic.label,
            breakdown: RuleBreakdown(
                baseValue: baseValue,
                contributions: contributions,
                activeConditions: request.conditions,
                finalTarget: baseValue + totalModifier
            )
        )
    }

    private static func resolveSkillCheck(
        _ skill: Skill,
        request: CheckRequest
    ) -> CheckResult {
        let baseValue = request.characteristics.value(for: skill.characteristic)
        let derivedBonus = request.characteristics.bonusValue(for: skill.characteristic)
        let trainingModifier = skill.training.modifier
        let modifierContributions = modifierContributions(for: request)
        let totalModifier = modifierContributions.reduce(0) { $0 + $1.value }
        let contributions = [
            RuleContribution(
                kind: .derivedBonus,
                label: "Derived Bonus",
                value: derivedBonus,
                appliesToFinalTarget: false,
                modifier: nil
            ),
            RuleContribution(
                kind: .training,
                label: "Training Contribution",
                value: trainingModifier,
                appliesToFinalTarget: true,
                modifier: nil
            )
        ] + modifierContributions

        return CheckResult(
            kind: .skill,
            checkName: skill.displayName,
            sourceName: skill.characteristic.label,
            breakdown: RuleBreakdown(
                baseValue: baseValue,
                contributions: contributions,
                activeConditions: request.conditions,
                finalTarget: baseValue + trainingModifier + totalModifier
            )
        )
    }

    private static func modifierContributions(for request: CheckRequest) -> [RuleContribution] {
        request.modifiers
            .filter { $0.applies(to: request) }
            .map { modifier in
                RuleContribution(
                    kind: .modifier,
                    label: modifier.label,
                    value: modifier.value,
                    appliesToFinalTarget: true,
                    modifier: modifier
                )
            }
    }
}

extension SessionState {
    var normalizedTemporaryModifiers: [CheckModifier] {
        temporaryModifiers
            .map { key, value in
                CheckModifier.sessionTemporary(label: key, value: value)
            }
            .sorted { lhs, rhs in
                lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
    }

    var normalizedCombatConditions: [RuleCondition] {
        combatConditions.enumerated().map { index, value in
            RuleCondition.sessionCombatCondition(index: index, text: value)
        }
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

private extension CheckModifierScope {
    var stableIdentifier: String {
        switch self {
        case .allChecks:
            "all-checks"
        case .characteristicChecks:
            "characteristic-checks"
        case .skillChecks:
            "skill-checks"
        case .specificCharacteristic(let characteristic):
            "characteristic-\(characteristic.rawValue)"
        case .specificSkill(let skillID):
            "skill-\(skillID.uuidString.lowercased())"
        case .combatSessionOnly:
            "combat-session-only"
        }
    }
}

private extension String {
    func trimmedOrPlaceholder(_ placeholder: String) -> String {
        let cleaned = trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? placeholder : cleaned
    }

    var stableToken: String {
        let lowercased = trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = lowercased.map { character -> String in
            if character.isLetter || character.isNumber {
                return String(character)
            }
            return "-"
        }
        let collapsed = allowed.joined()
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return collapsed.isEmpty ? "value" : collapsed
    }
}
