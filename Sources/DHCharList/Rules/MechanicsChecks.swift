import Foundation

enum CheckOrigin: Equatable, Sendable {
    case standard
    case sessionCombat
}

enum CheckKind: Equatable, Sendable {
    case characteristic
    case skill
}

enum CheckDefinition: Equatable, Sendable {
    case characteristic(SkillCharacteristic)
    case skill(Skill)

    var kind: CheckKind {
        switch self {
        case .characteristic:
            .characteristic
        case .skill:
            .skill
        }
    }
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
        if let preset = DifficultyPresetRegistry.preset(for: value) {
            return preset.normalizedModifier(scope: scope)
        }

        return CheckModifier(
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
        request.definition.matches(modifierScope: scope, origin: request.origin)
    }
}

enum RuleConditionKind: String, Equatable, Sendable {
    case pinned
    case cover
    case suppression
    case injury
    case custom

    static func inferred(from label: String) -> RuleConditionKind {
        ConditionMetadataRegistry.resolve(label: label).kind
    }

    var label: String {
        ConditionMetadataRegistry.metadata(for: self)?.displayName ?? "Custom"
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
        let metadata = ConditionMetadataRegistry.resolve(label: cleanedText)
        return RuleCondition(
            id: "session-condition.\(index).\(cleanedText.stableToken)",
            kind: metadata.kind,
            label: cleanedText,
            source: "Session Combat Condition",
            note: note
        )
    }
}

struct CombatPinnedCheck: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let source: String

    static func sessionPinnedCheck(index: Int, text: String) -> CombatPinnedCheck {
        let cleanedText = text.trimmedOrPlaceholder("Unnamed Pinned Check")
        return CombatPinnedCheck(
            id: "pinned-check.\(index).\(cleanedText.stableToken)",
            label: cleanedText,
            source: "Session Pinned Check"
        )
    }
}

struct ActiveWeaponContext: Identifiable, Equatable, Sendable {
    let id: UUID
    let displayName: String
    let type: String?
    let typeMetadata: WeaponTypeMetadata?
    let range: String?
    let damage: String?
    let penetration: String?
    let clip: String?
    let reload: String?
    let traits: String?
    let traitMetadata: [WeaponTraitMetadata]

    var primarySummary: [String] {
        [
            typeMetadata?.displayName ?? type,
            range.map { "Range \($0)" },
            damage.map { "Damage \($0)" },
            penetration.map { "Pen \($0)" }
        ]
        .compactMap { $0 }
    }

    var secondarySummary: [String] {
        [
            clip.map { "Clip \($0)" },
            reload.map { "Reload \($0)" },
            traits
        ]
        .compactMap { $0 }
    }

    static func from(_ weapon: Weapon) -> ActiveWeaponContext {
        ActiveWeaponContext(
            id: weapon.id,
            displayName: weapon.name.trimmedOrPlaceholder("Unnamed Weapon"),
            type: weapon.type.trimmedOrNil,
            typeMetadata: WeaponTypeRegistry.resolve(weapon.type),
            range: weapon.range.trimmedOrNil,
            damage: weapon.damage.trimmedOrNil,
            penetration: weapon.penetration.trimmedOrNil,
            clip: weapon.clip.trimmedOrNil,
            reload: weapon.reload.trimmedOrNil,
            traits: weapon.traits.trimmedOrNil,
            traitMetadata: WeaponTraitRegistry.resolveAll(weapon.traits)
        )
    }
}

struct CombatContext: Equatable, Sendable {
    let modeEnabled: Bool
    let activeWeapon: ActiveWeaponContext?
    let combatConditions: [RuleCondition]
    let pinnedChecks: [CombatPinnedCheck]
    let temporaryModifiers: [CheckModifier]

    func preparation(
        for definition: CheckDefinition,
        appliedModifiers: [CheckModifier] = []
    ) -> CombatCheckPreparationContext {
        CombatCheckPreparationContext(
            definition: definition,
            origin: .sessionCombat,
            activeWeapon: activeWeapon,
            combatConditions: combatConditions,
            pinnedChecks: pinnedChecks,
            availableTemporaryModifiers: temporaryModifiers,
            appliedModifiers: appliedModifiers
        )
    }
}

struct CombatCheckPreparationContext: Equatable, Sendable {
    let definition: CheckDefinition
    let origin: CheckOrigin
    let activeWeapon: ActiveWeaponContext?
    let combatConditions: [RuleCondition]
    let pinnedChecks: [CombatPinnedCheck]
    let availableTemporaryModifiers: [CheckModifier]
    let appliedModifiers: [CheckModifier]

    func makeRequest(characteristics: CharacteristicSet) -> CheckRequest {
        CheckRequest(
            definition: definition,
            characteristics: characteristics,
            origin: origin,
            modifiers: appliedModifiers,
            conditions: combatConditions
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
    let definition: CheckDefinition
    let characteristics: CharacteristicSet
    let origin: CheckOrigin
    let modifiers: [CheckModifier]
    let conditions: [RuleCondition]

    var kind: CheckKind {
        definition.kind
    }

    static func characteristic(
        _ characteristic: SkillCharacteristic,
        characteristics: CharacteristicSet,
        origin: CheckOrigin = .standard,
        modifiers: [CheckModifier] = [],
        conditions: [RuleCondition] = []
    ) -> CheckRequest {
        CheckRequest(
            definition: .characteristic(characteristic),
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
            definition: .skill(skill),
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

    static func combatPreparation(
        _ preparation: CombatCheckPreparationContext,
        characteristics: CharacteristicSet
    ) -> CheckRequest {
        preparation.makeRequest(characteristics: characteristics)
    }
}

struct CheckResult: Equatable, Sendable {
    let definition: CheckDefinition
    let kind: CheckKind
    let checkName: String
    let sourceName: String
    let breakdown: RuleBreakdown

    var finalTarget: Int { breakdown.finalTarget }
}

enum MechanicsCheckResolver {
    static func resolve(_ request: CheckRequest) -> CheckResult {
        let resolvedDefinition = request.definition.resolve(using: request.characteristics)
        let modifierContributions = orderedModifierContributions(for: request)
        let contributions = resolvedDefinition.defaultContributions + modifierContributions
        let finalTarget = resolvedDefinition.baseValue
            + contributions
            .filter(\.appliesToFinalTarget)
            .reduce(0) { $0 + $1.value }

        return CheckResult(
            definition: request.definition,
            kind: resolvedDefinition.kind,
            checkName: resolvedDefinition.checkName,
            sourceName: resolvedDefinition.sourceName,
            breakdown: RuleBreakdown(
                baseValue: resolvedDefinition.baseValue,
                contributions: contributions,
                activeConditions: request.conditions,
                finalTarget: finalTarget
            )
        )
    }

    private static func orderedModifierContributions(for request: CheckRequest) -> [RuleContribution] {
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

private struct ResolvedCheckDefinition: Equatable, Sendable {
    let kind: CheckKind
    let checkName: String
    let sourceName: String
    let baseValue: Int
    let defaultContributions: [RuleContribution]
}

private extension CheckDefinition {
    func matches(modifierScope: CheckModifierScope, origin: CheckOrigin) -> Bool {
        switch modifierScope {
        case .allChecks:
            return true
        case .characteristicChecks:
            return kind == .characteristic
        case .skillChecks:
            return kind == .skill
        case .specificCharacteristic(let characteristic):
            if case .characteristic(let requestCharacteristic) = self {
                return requestCharacteristic == characteristic
            }
            return false
        case .specificSkill(let skillID):
            if case .skill(let skill) = self {
                return skill.id == skillID
            }
            return false
        case .combatSessionOnly:
            return origin == .sessionCombat
        }
    }

    func resolve(using characteristics: CharacteristicSet) -> ResolvedCheckDefinition {
        switch self {
        case .characteristic(let characteristic):
            let baseValue = characteristics.value(for: characteristic)
            let derivedBonus = characteristics.bonusValue(for: characteristic)
            return ResolvedCheckDefinition(
                kind: .characteristic,
                checkName: "\(characteristic.label) Check",
                sourceName: characteristic.label,
                baseValue: baseValue,
                defaultContributions: [
                    RuleContribution(
                        kind: .derivedBonus,
                        label: "Derived Bonus",
                        value: derivedBonus,
                        appliesToFinalTarget: false,
                        modifier: nil
                    )
                ]
            )
        case .skill(let skill):
            let metadata = SkillMetadataRegistry.resolve(skill)
            let baseValue = characteristics.value(for: metadata.linkedCharacteristic)
            let derivedBonus = characteristics.bonusValue(for: metadata.linkedCharacteristic)
            return ResolvedCheckDefinition(
                kind: .skill,
                checkName: metadata.displayName,
                sourceName: metadata.linkedCharacteristic.label,
                baseValue: baseValue,
                defaultContributions: [
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
                        value: skill.training.modifier,
                        appliesToFinalTarget: true,
                        modifier: nil
                    )
                ]
            )
        }
    }
}

extension SessionState {
    func combatContext(availableWeapons: [Weapon]) -> CombatContext {
        let activeWeapon = activeWeaponID
            .flatMap { activeWeaponID in
                availableWeapons.first(where: { $0.id == activeWeaponID })
            }
            .map(ActiveWeaponContext.from)

        return CombatContext(
            modeEnabled: modeEnabled,
            activeWeapon: activeWeapon,
            combatConditions: normalizedCombatConditions,
            pinnedChecks: normalizedPinnedChecks,
            temporaryModifiers: normalizedTemporaryModifiers
        )
    }

    var normalizedPinnedChecks: [CombatPinnedCheck] {
        pinnedChecks.enumerated().map { index, value in
            CombatPinnedCheck.sessionPinnedCheck(index: index, text: value)
        }
    }

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

extension CheckModifierScope {
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

    var trimmedOrNil: String? {
        let cleaned = trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
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
