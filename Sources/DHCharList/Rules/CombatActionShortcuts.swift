import Foundation

enum CombatReactionShortcutKind: String, CaseIterable, Identifiable, Equatable, Sendable {
    case dodge
    case parry

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dodge:
            "Dodge"
        case .parry:
            "Parry"
        }
    }

    var subtitle: String {
        switch self {
        case .dodge:
            "Agility reaction check"
        case .parry:
            "Weapon Skill reaction check"
        }
    }

    var canonicalSkillID: String {
        rawValue
    }
}

enum CombatAttackMode: String, Equatable, Sendable {
    case melee
    case ranged

    var title: String {
        switch self {
        case .melee:
            "Melee Attack"
        case .ranged:
            "Ranged Attack"
        }
    }

    var subtitle: String {
        switch self {
        case .melee:
            "Weapon Skill attack check"
        case .ranged:
            "Ballistic Skill attack check"
        }
    }

    var checkDefinition: CheckDefinition {
        switch self {
        case .melee:
            .characteristic(.weaponSkill)
        case .ranged:
            .characteristic(.ballisticSkill)
        }
    }

    static func from(activeWeapon: ActiveWeaponContext) -> CombatAttackMode {
        guard activeWeapon.typeMetadata?.classification == .melee else {
            return .ranged
        }
        return .melee
    }
}

struct CombatModifierShortcut: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let value: Int
    let note: String?

    func normalizedModifier() -> CheckModifier {
        CheckModifier.sessionTemporary(
            label: label,
            value: value,
            note: note
        )
    }
}

struct CombatConditionShortcut: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let note: String?
}

enum CombatShortcutRegistry {
    static let quickModifierShortcuts: [CombatModifierShortcut] = [
        CombatModifierShortcut(
            id: "aim",
            label: "Aim",
            value: 10,
            note: "Fast positive combat modifier"
        ),
        CombatModifierShortcut(
            id: "smoke",
            label: "Smoke",
            value: -20,
            note: "Fast visibility penalty"
        )
    ]

    static let quickConditionShortcuts: [CombatConditionShortcut] = [
        CombatConditionShortcut(
            id: "pinned-down",
            label: "Pinned Down",
            note: "Fast suppression condition toggle"
        ),
        CombatConditionShortcut(
            id: "partial-cover",
            label: "Partial Cover",
            note: "Fast cover reminder toggle"
        )
    ]

    static func reloadConditionLabel(for activeWeapon: ActiveWeaponContext?) -> String {
        guard let activeWeapon else {
            return "Reloading"
        }
        return "Reloading \(activeWeapon.displayName)"
    }
}

struct CombatEncounterCheckFlow: Equatable, Sendable {
    let title: String
    let subtitle: String
    let combatContext: CombatContext
    let activeWeapon: ActiveWeaponContext?
    let request: CheckRequest
    let result: CheckResult
    let autoAppliedModifiers: [CheckModifier]
    let visibleConditions: [RuleCondition]
    let pinnedChecks: [CombatPinnedCheck]
}

struct CombatCheckOutcome: Equatable, Sendable {
    let flow: CombatEncounterCheckFlow
    let roll: Int
    let isSuccess: Bool
    let margin: Int
}

enum CombatEncounterResolver {
    static func attackFlow(
        combatContext: CombatContext,
        characteristics: CharacteristicSet,
        additionalModifier: CheckModifier? = nil
    ) -> CombatEncounterCheckFlow? {
        guard let activeWeapon = combatContext.activeWeapon else {
            return nil
        }

        let attackMode = CombatAttackMode.from(activeWeapon: activeWeapon)
        let request = CheckRequest.combatPreparation(
            combatContext.preparation(
                for: attackMode.checkDefinition,
                appliedModifiers: resolvedModifiers(
                    combatContext: combatContext,
                    additionalModifier: additionalModifier
                )
            ),
            characteristics: characteristics
        )
        let result = MechanicsCheckResolver.resolve(request)

        return CombatEncounterCheckFlow(
            title: attackMode.title,
            subtitle: attackMode.subtitle,
            combatContext: combatContext,
            activeWeapon: activeWeapon,
            request: request,
            result: result,
            autoAppliedModifiers: resolvedModifiers(
                combatContext: combatContext,
                additionalModifier: additionalModifier
            ),
            visibleConditions: combatContext.combatConditions,
            pinnedChecks: combatContext.pinnedChecks
        )
    }

    static func reactionFlow(
        _ reaction: CombatReactionShortcutKind,
        combatContext: CombatContext,
        characteristics: CharacteristicSet,
        skills: [Skill],
        additionalModifier: CheckModifier? = nil
    ) -> CombatEncounterCheckFlow {
        let skill = resolvedReactionSkill(reaction, skills: skills)
        let request = CheckRequest.combatPreparation(
            combatContext.preparation(
                for: .skill(skill),
                appliedModifiers: resolvedModifiers(
                    combatContext: combatContext,
                    additionalModifier: additionalModifier
                )
            ),
            characteristics: characteristics
        )
        let result = MechanicsCheckResolver.resolve(request)

        return CombatEncounterCheckFlow(
            title: reaction.title,
            subtitle: reaction.subtitle,
            combatContext: combatContext,
            activeWeapon: combatContext.activeWeapon,
            request: request,
            result: result,
            autoAppliedModifiers: resolvedModifiers(
                combatContext: combatContext,
                additionalModifier: additionalModifier
            ),
            visibleConditions: combatContext.combatConditions,
            pinnedChecks: combatContext.pinnedChecks
        )
    }

    static func resolveRoll(
        for flow: CombatEncounterCheckFlow,
        roll: Int
    ) -> CombatCheckOutcome {
        let normalizedRoll = max(1, roll)
        let margin = flow.result.finalTarget - normalizedRoll
        return CombatCheckOutcome(
            flow: flow,
            roll: normalizedRoll,
            isSuccess: normalizedRoll <= flow.result.finalTarget,
            margin: margin
        )
    }

    static func resolveTargetDamage(
        for flow: CombatEncounterCheckFlow,
        rawDamage: Int,
        targetWounds: Int,
        targetArmour: Int,
        targetToughnessBonus: Int,
        penetrationOverride: Int? = nil
    ) -> DamageResult {
        let penetration = penetrationOverride ?? parsedShortcutInteger(from: flow.activeWeapon?.penetration) ?? 0
        let request = DamageRequest(
            source: flow.activeWeapon.map(DamageSource.activeWeapon) ?? .manual(label: flow.title),
            rawDamage: rawDamage,
            woundsBefore: targetWounds,
            mitigation: DamageMitigation(
                armour: targetArmour,
                penetration: penetration,
                toughnessBonus: targetToughnessBonus
            ),
            combatContext: flow.combatContext
        )
        return DamageResolver.resolve(request)
    }

    private static func resolvedModifiers(
        combatContext: CombatContext,
        additionalModifier: CheckModifier?
    ) -> [CheckModifier] {
        var modifiers = combatContext.temporaryModifiers
        if let additionalModifier, additionalModifier.value != 0 {
            modifiers.append(additionalModifier)
        }
        return modifiers
    }

    private static func resolvedReactionSkill(
        _ reaction: CombatReactionShortcutKind,
        skills: [Skill]
    ) -> Skill {
        if let existing = skills.first(where: { skill in
            SkillMetadataRegistry.resolve(skill).id == reaction.canonicalSkillID
        }) {
            return existing
        }

        guard let metadata = SkillMetadataRegistry.canonical.first(where: { $0.id == reaction.canonicalSkillID }) else {
            return Skill(
                name: reaction.title,
                characteristic: reaction == .dodge ? .agility : .weaponSkill,
                training: .untrained
            )
        }

        return Skill(
            name: metadata.displayName,
            characteristic: metadata.linkedCharacteristic,
            training: .untrained
        )
    }
}

extension CombatContext {
    func replacingActiveWeapon(_ weapon: Weapon?) -> CombatContext {
        CombatContext(
            modeEnabled: modeEnabled,
            activeWeapon: weapon.map(ActiveWeaponContext.from),
            combatConditions: combatConditions,
            pinnedChecks: pinnedChecks,
            temporaryModifiers: temporaryModifiers
        )
    }
}

private func parsedShortcutInteger(from text: String?) -> Int? {
    guard let cleaned = text?.trimmingCharacters(in: .whitespacesAndNewlines), !cleaned.isEmpty else {
        return nil
    }

    let tokens = cleaned.split(whereSeparator: { character in
        !character.isNumber && character != "-" && character != "+"
    })

    for token in tokens {
        if let value = Int(token) {
            return value
        }
    }

    return nil
}
