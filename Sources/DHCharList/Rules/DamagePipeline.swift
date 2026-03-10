import Foundation

enum DamageSource: Equatable, Sendable {
    case manual(label: String)
    case activeWeapon(ActiveWeaponContext)

    var label: String {
        switch self {
        case .manual(let label):
            return label.trimmedOrPlaceholder("Manual Damage")
        case .activeWeapon(let weapon):
            return weapon.displayName
        }
    }

    var activeWeapon: ActiveWeaponContext? {
        if case .activeWeapon(let weapon) = self {
            return weapon
        }
        return nil
    }
}

struct DamageMitigation: Equatable, Sendable {
    let armour: Int
    let penetration: Int
    let toughnessBonus: Int

    init(armour: Int = 0, penetration: Int = 0, toughnessBonus: Int = 0) {
        self.armour = max(0, armour)
        self.penetration = max(0, penetration)
        self.toughnessBonus = max(0, toughnessBonus)
    }

    var effectiveArmour: Int {
        max(0, armour - penetration)
    }

    var totalMitigation: Int {
        effectiveArmour + toughnessBonus
    }
}

struct DamageRequest: Equatable, Sendable {
    let source: DamageSource
    let rawDamage: Int
    let woundsBefore: Int
    let mitigation: DamageMitigation
    let combatContext: CombatContext?

    init(
        source: DamageSource,
        rawDamage: Int,
        woundsBefore: Int,
        mitigation: DamageMitigation,
        combatContext: CombatContext? = nil
    ) {
        self.source = source
        self.rawDamage = max(0, rawDamage)
        self.woundsBefore = max(0, woundsBefore)
        self.mitigation = mitigation
        self.combatContext = combatContext
    }

    static func manual(
        rawDamage: Int,
        woundsBefore: Int,
        armour: Int = 0,
        penetration: Int = 0,
        toughnessBonus: Int = 0,
        label: String = "Manual Damage"
    ) -> DamageRequest {
        DamageRequest(
            source: .manual(label: label),
            rawDamage: rawDamage,
            woundsBefore: woundsBefore,
            mitigation: DamageMitigation(
                armour: armour,
                penetration: penetration,
                toughnessBonus: toughnessBonus
            )
        )
    }

    static func combat(
        rawDamage: Int,
        resources: ResourceState,
        characteristics: CharacteristicSet,
        armourPoints: Int,
        combatContext: CombatContext,
        penetrationOverride: Int? = nil
    ) -> DamageRequest {
        let source: DamageSource
        if let activeWeapon = combatContext.activeWeapon {
            source = .activeWeapon(activeWeapon)
        } else {
            source = .manual(label: "Combat Damage")
        }

        return DamageRequest(
            source: source,
            rawDamage: rawDamage,
            woundsBefore: resources.currentWounds,
            mitigation: DamageMitigation(
                armour: armourPoints,
                penetration: penetrationOverride ?? parsedLeadingInteger(from: combatContext.activeWeapon?.penetration) ?? 0,
                toughnessBonus: characteristics.bonus.toughness
            ),
            combatContext: combatContext
        )
    }
}

enum DamageContributionKind: Equatable, Sendable {
    case rawDamage
    case penetration
    case armourMitigation
    case toughnessMitigation
    case appliedDamage
    case woundDelta
    case overflow
}

struct DamageContribution: Equatable, Sendable {
    let kind: DamageContributionKind
    let label: String
    let value: Int
}

struct DamageBreakdown: Equatable, Sendable {
    let rawDamage: Int
    let mitigation: DamageMitigation
    let contributions: [DamageContribution]
    let appliedDamage: Int
    let woundsBefore: Int
    let woundDelta: Int
    let woundsAfter: Int
    let overflowDamage: Int

    var effectiveArmour: Int {
        mitigation.effectiveArmour
    }

    var totalMitigation: Int {
        mitigation.totalMitigation
    }

    func contribution(of kind: DamageContributionKind) -> DamageContribution? {
        contributions.first(where: { $0.kind == kind })
    }
}

struct DamageResult: Equatable, Sendable {
    let source: DamageSource
    let combatContext: CombatContext?
    let breakdown: DamageBreakdown

    var sourceLabel: String {
        source.label
    }

    var sourceWeapon: ActiveWeaponContext? {
        source.activeWeapon
    }

    var appliedDamage: Int {
        breakdown.appliedDamage
    }

    var woundsAfter: Int {
        breakdown.woundsAfter
    }
}

enum DamageResolver {
    static func resolve(_ request: DamageRequest) -> DamageResult {
        let effectiveArmour = request.mitigation.effectiveArmour
        let totalMitigation = request.mitigation.totalMitigation
        let appliedDamage = max(0, request.rawDamage - totalMitigation)
        let woundsAfter = max(0, request.woundsBefore - appliedDamage)
        let woundDelta = woundsAfter - request.woundsBefore
        let overflowDamage = max(0, appliedDamage - request.woundsBefore)

        let contributions = [
            DamageContribution(kind: .rawDamage, label: "Raw Damage", value: request.rawDamage),
            DamageContribution(kind: .penetration, label: "Penetration", value: request.mitigation.penetration),
            DamageContribution(kind: .armourMitigation, label: "Armour Mitigation", value: -effectiveArmour),
            DamageContribution(kind: .toughnessMitigation, label: "Toughness Mitigation", value: -request.mitigation.toughnessBonus),
            DamageContribution(kind: .appliedDamage, label: "Applied Damage", value: appliedDamage),
            DamageContribution(kind: .woundDelta, label: "Wound Delta", value: woundDelta),
            DamageContribution(kind: .overflow, label: "Overflow", value: overflowDamage)
        ]

        return DamageResult(
            source: request.source,
            combatContext: request.combatContext,
            breakdown: DamageBreakdown(
                rawDamage: request.rawDamage,
                mitigation: request.mitigation,
                contributions: contributions,
                appliedDamage: appliedDamage,
                woundsBefore: request.woundsBefore,
                woundDelta: woundDelta,
                woundsAfter: woundsAfter,
                overflowDamage: overflowDamage
            )
        )
    }
}

extension CombatContext {
    func damageRequest(
        rawDamage: Int,
        resources: ResourceState,
        characteristics: CharacteristicSet,
        armourPoints: Int,
        penetrationOverride: Int? = nil
    ) -> DamageRequest {
        DamageRequest.combat(
            rawDamage: rawDamage,
            resources: resources,
            characteristics: characteristics,
            armourPoints: armourPoints,
            combatContext: self,
            penetrationOverride: penetrationOverride
        )
    }
}

private func parsedLeadingInteger(from text: String?) -> Int? {
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

private extension String {
    func trimmedOrPlaceholder(_ placeholder: String) -> String {
        let cleaned = trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? placeholder : cleaned
    }
}
