import Foundation
import Testing
@testable import DHCharList

@Test func damageResolverAppliesPenetrationArmourAndToughnessWithExplainableBreakdown() {
    let request = DamageRequest.manual(
        rawDamage: 12,
        woundsBefore: 14,
        armour: 5,
        penetration: 2,
        toughnessBonus: 4
    )

    let result = DamageResolver.resolve(request)

    #expect(result.sourceLabel == "Manual Damage")
    #expect(result.sourceWeapon == nil)
    #expect(result.breakdown.rawDamage == 12)
    #expect(result.breakdown.effectiveArmour == 3)
    #expect(result.breakdown.totalMitigation == 7)
    #expect(result.appliedDamage == 5)
    #expect(result.breakdown.woundsBefore == 14)
    #expect(result.breakdown.woundDelta == -5)
    #expect(result.woundsAfter == 9)
    #expect(result.breakdown.overflowDamage == 0)
    #expect(
        result.breakdown.contributions.map(\.label) == [
            "Raw Damage",
            "Penetration",
            "Armour Mitigation",
            "Toughness Mitigation",
            "Applied Damage",
            "Wound Delta",
            "Overflow"
        ]
    )
    #expect(result.breakdown.contributions.map(\.value) == [12, 2, -3, -4, 5, -5, 0])
}

@Test func damageResolverClampsAppliedDamageAtZeroWhenMitigationExceedsRawDamage() {
    let request = DamageRequest.manual(
        rawDamage: 6,
        woundsBefore: 11,
        armour: 4,
        penetration: 0,
        toughnessBonus: 3
    )

    let result = DamageResolver.resolve(request)

    #expect(result.breakdown.totalMitigation == 7)
    #expect(result.appliedDamage == 0)
    #expect(result.woundsAfter == 11)
    #expect(result.breakdown.woundDelta == 0)
    #expect(result.breakdown.overflowDamage == 0)
}

@Test func damageResolverTracksOverflowWhenAppliedDamageExceedsRemainingWounds() {
    let request = DamageRequest.manual(
        rawDamage: 18,
        woundsBefore: 7,
        armour: 2,
        penetration: 0,
        toughnessBonus: 3
    )

    let result = DamageResolver.resolve(request)

    #expect(result.appliedDamage == 13)
    #expect(result.woundsAfter == 0)
    #expect(result.breakdown.woundDelta == -7)
    #expect(result.breakdown.overflowDamage == 6)
    #expect(result.breakdown.contribution(of: .overflow)?.value == 6)
}

@Test func combatDamageRequestUsesCombatContextWeaponPenetrationAndToughnessBonus() {
    let weaponID = UUID()
    let session = SessionState(
        modeEnabled: true,
        pinnedChecks: ["Dodge +10"],
        temporaryModifiers: ["Aim": 10],
        activeWeaponID: weaponID,
        combatConditions: ["Pinned Down"]
    )
    let weapon = Weapon(
        id: weaponID,
        name: "Laspistol",
        type: "Pistol",
        range: "30m",
        damage: "1d10+3",
        penetration: "4",
        clip: "30",
        reload: "Half",
        traits: "Reliable"
    )
    let combatContext = session.combatContext(availableWeapons: [weapon])
    let characteristics = CharacteristicSet(
        weaponSkill: 39,
        ballisticSkill: 37,
        strength: 34,
        toughness: 36,
        agility: 40,
        intelligence: 31,
        perception: 41,
        willpower: 38,
        fellowship: 30
    )
    let resources = ResourceState(currentWounds: 12, maxWounds: 12)

    let request = combatContext.damageRequest(
        rawDamage: 14,
        resources: resources,
        characteristics: characteristics,
        armourPoints: 5
    )
    let result = DamageResolver.resolve(request)

    #expect(request.combatContext == combatContext)
    #expect(request.mitigation.penetration == 4)
    #expect(request.mitigation.toughnessBonus == 3)
    #expect(result.sourceLabel == "Laspistol")
    #expect(result.sourceWeapon?.id == weaponID)
    #expect(result.appliedDamage == 10)
    #expect(result.woundsAfter == 2)
    #expect(result.breakdown.effectiveArmour == 1)
    #expect(result.combatContext?.combatConditions.map(\.kind) == [.pinned])
}

@Test func damageRequestNormalizesNegativeInputsToSafeValues() {
    let request = DamageRequest.manual(
        rawDamage: -5,
        woundsBefore: -2,
        armour: -1,
        penetration: -3,
        toughnessBonus: -4,
        label: "   "
    )

    let result = DamageResolver.resolve(request)

    #expect(request.rawDamage == 0)
    #expect(request.woundsBefore == 0)
    #expect(request.mitigation.armour == 0)
    #expect(request.mitigation.penetration == 0)
    #expect(request.mitigation.toughnessBonus == 0)
    #expect(result.sourceLabel == "Manual Damage")
    #expect(result.appliedDamage == 0)
    #expect(result.woundsAfter == 0)
    #expect(result.breakdown.contributions.map(\.value) == [0, 0, 0, 0, 0, 0, 0])
}
