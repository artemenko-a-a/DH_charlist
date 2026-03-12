import Foundation
import Testing
@testable import DHCharList

@Test func rangedAttackShortcutUsesBallisticSkillAndActiveSessionModifiers() {
    let weaponID = UUID()
    let characteristics = CharacteristicSet(
        weaponSkill: 38,
        ballisticSkill: 44,
        strength: 32,
        toughness: 35,
        agility: 41,
        intelligence: 30,
        perception: 37,
        willpower: 33,
        fellowship: 29
    )
    let session = SessionState(
        modeEnabled: true,
        pinnedChecks: ["Dodge +10"],
        temporaryModifiers: [
            "Aim": 10,
            "Smoke": -20
        ],
        activeWeaponID: weaponID,
        combatConditions: ["Partial Cover"]
    )
    let weapon = Weapon(
        id: weaponID,
        name: "Laspistol",
        type: "Pistol",
        range: "30m",
        damage: "1d10+2 E",
        penetration: "2",
        clip: "30",
        reload: "Half",
        traits: "Reliable"
    )

    let flow = CombatEncounterResolver.attackFlow(
        combatContext: session.combatContext(availableWeapons: [weapon]),
        characteristics: characteristics,
        additionalModifier: .preset(value: 10)
    )

    #expect(flow != nil)
    #expect(flow?.title == "Ranged Attack")
    #expect(flow?.activeWeapon?.displayName == "Laspistol")
    #expect(flow?.request.definition == .characteristic(.ballisticSkill))
    #expect(flow?.autoAppliedModifiers.map(\.label) == ["Aim", "Smoke", "Standard Preset"])
    #expect(flow?.autoAppliedModifiers.map(\.kind) == [.sessionTemporary, .sessionTemporary, .preset])
    #expect(flow?.visibleConditions.map(\.label) == ["Partial Cover"])
    #expect(flow?.pinnedChecks.map(\.label) == ["Dodge +10"])
    #expect(flow?.result.finalTarget == 44)
}

@Test func meleeAttackShortcutUsesWeaponSkill() {
    let weaponID = UUID()
    let characteristics = CharacteristicSet(
        weaponSkill: 51,
        ballisticSkill: 34,
        strength: 39,
        toughness: 41,
        agility: 35,
        intelligence: 28,
        perception: 33,
        willpower: 31,
        fellowship: 26
    )
    let session = SessionState(
        modeEnabled: true,
        pinnedChecks: [],
        temporaryModifiers: [:],
        activeWeaponID: weaponID,
        combatConditions: []
    )
    let weapon = Weapon(
        id: weaponID,
        name: "Chainsword",
        type: "Melee",
        range: "—",
        damage: "1d10+2 R",
        penetration: "2",
        clip: "",
        reload: "",
        traits: "Tearing"
    )

    let flow = CombatEncounterResolver.attackFlow(
        combatContext: session.combatContext(availableWeapons: [weapon]),
        characteristics: characteristics
    )

    #expect(flow?.title == "Melee Attack")
    #expect(flow?.request.definition == .characteristic(.weaponSkill))
    #expect(flow?.result.finalTarget == 51)
}

@Test func dodgeReactionShortcutFallsBackToCanonicalUntrainedSkillWhenCharacterLacksIt() {
    let characteristics = CharacteristicSet(
        weaponSkill: 36,
        ballisticSkill: 32,
        strength: 31,
        toughness: 34,
        agility: 45,
        intelligence: 29,
        perception: 38,
        willpower: 30,
        fellowship: 27
    )
    let session = SessionState(
        modeEnabled: true,
        pinnedChecks: ["Dodge +10"],
        temporaryModifiers: ["Smoke": -20],
        activeWeaponID: nil,
        combatConditions: ["Pinned Down"]
    )

    let flow = CombatEncounterResolver.reactionFlow(
        .dodge,
        combatContext: session.combatContext(availableWeapons: []),
        characteristics: characteristics,
        skills: [],
        additionalModifier: .manual(value: 10)
    )

    #expect(flow.title == "Dodge")
    #expect(flow.request.definition.kind == .skill)
    #expect(flow.result.checkName == "Dodge")
    #expect(flow.result.sourceName == "Agility")
    #expect(flow.autoAppliedModifiers.map(\.label) == ["Smoke", "Custom Modifier"])
    #expect(flow.visibleConditions.map(\.kind) == [.pinned])
    #expect(flow.result.finalTarget == 15)
}

@Test func parryReactionShortcutPrefersExistingCharacterSkill() {
    let characteristics = CharacteristicSet(
        weaponSkill: 48,
        ballisticSkill: 31,
        strength: 38,
        toughness: 36,
        agility: 34,
        intelligence: 28,
        perception: 30,
        willpower: 33,
        fellowship: 25
    )
    let parry = Skill(name: "Parry", characteristic: .weaponSkill, training: .trained)

    let flow = CombatEncounterResolver.reactionFlow(
        .parry,
        combatContext: CombatContext(
            modeEnabled: true,
            activeWeapon: nil,
            combatConditions: [],
            pinnedChecks: [],
            temporaryModifiers: [CheckModifier.sessionTemporary(label: "Aim", value: 10)]
        ),
        characteristics: characteristics,
        skills: [parry]
    )

    #expect(flow.request.definition == .skill(parry))
    #expect(flow.result.checkName == "Parry")
    #expect(flow.result.finalTarget == 68)
}

@Test func attackShortcutRollAndDamageHandoffStayExplainable() {
    let weaponID = UUID()
    let characteristics = CharacteristicSet(
        weaponSkill: 41,
        ballisticSkill: 47,
        strength: 34,
        toughness: 36,
        agility: 42,
        intelligence: 30,
        perception: 38,
        willpower: 31,
        fellowship: 29
    )
    let session = SessionState(
        modeEnabled: true,
        pinnedChecks: [],
        temporaryModifiers: ["Aim": 10],
        activeWeaponID: weaponID,
        combatConditions: ["Partial Cover"]
    )
    let weapon = Weapon(
        id: weaponID,
        name: "Boltgun",
        type: "Basic",
        range: "100m",
        damage: "1d10+5 X",
        penetration: "4",
        clip: "24",
        reload: "Full",
        traits: "Tearing"
    )

    let flow = CombatEncounterResolver.attackFlow(
        combatContext: session.combatContext(availableWeapons: [weapon]),
        characteristics: characteristics
    )!
    let outcome = CombatEncounterResolver.resolveRoll(for: flow, roll: 38)
    let damage = CombatEncounterResolver.resolveTargetDamage(
        for: flow,
        rawDamage: 13,
        targetWounds: 9,
        targetArmour: 6,
        targetToughnessBonus: 3
    )

    #expect(outcome.isSuccess)
    #expect(outcome.margin == 19)
    #expect(damage.sourceWeapon?.displayName == "Boltgun")
    #expect(damage.breakdown.effectiveArmour == 2)
    #expect(damage.appliedDamage == 8)
    #expect(damage.woundsAfter == 1)
    #expect(damage.breakdown.overflowDamage == 0)
}

@Test func attackShortcutRequiresActiveWeaponAndIgnoresZeroAdditionalModifier() {
    let characteristics = CharacteristicSet(
        weaponSkill: 40,
        ballisticSkill: 39,
        strength: 33,
        toughness: 34,
        agility: 37,
        intelligence: 31,
        perception: 35,
        willpower: 32,
        fellowship: 28
    )
    let noWeaponContext = CombatContext(
        modeEnabled: true,
        activeWeapon: nil,
        combatConditions: [],
        pinnedChecks: [],
        temporaryModifiers: [CheckModifier.sessionTemporary(label: "Aim", value: 10)]
    )

    #expect(
        CombatEncounterResolver.attackFlow(
            combatContext: noWeaponContext,
            characteristics: characteristics
        ) == nil
    )

    let reactionFlow = CombatEncounterResolver.reactionFlow(
        .dodge,
        combatContext: noWeaponContext,
        characteristics: characteristics,
        skills: [],
        additionalModifier: .manual(value: 0)
    )

    #expect(reactionFlow.autoAppliedModifiers.map(\.label) == ["Aim"])
}

@Test func combatShortcutRollClampsMinimumRollAndSupportsFailureMargins() {
    let flow = CombatEncounterResolver.reactionFlow(
        .parry,
        combatContext: CombatContext(
            modeEnabled: true,
            activeWeapon: nil,
            combatConditions: [],
            pinnedChecks: [],
            temporaryModifiers: []
        ),
        characteristics: CharacteristicSet(
            weaponSkill: 30,
            ballisticSkill: 28,
            strength: 32,
            toughness: 33,
            agility: 29,
            intelligence: 27,
            perception: 26,
            willpower: 31,
            fellowship: 24
        ),
        skills: []
    )

    let lowRollOutcome = CombatEncounterResolver.resolveRoll(for: flow, roll: 0)
    #expect(lowRollOutcome.roll == 1)
    #expect(lowRollOutcome.isSuccess)

    let failedOutcome = CombatEncounterResolver.resolveRoll(for: flow, roll: 50)
    #expect(failedOutcome.isSuccess == false)
    #expect(failedOutcome.margin < 0)
}

@Test func manualDamageShortcutUsesOverridePenetrationAndManualSource() {
    let request = CheckRequest.characteristic(
        .weaponSkill,
        characteristics: .empty,
        modifiers: []
    )

    let result = CombatEncounterResolver.resolveTargetDamage(
        for: CombatEncounterCheckFlow(
            title: "Manual Damage",
            subtitle: "Shortcut",
            combatContext: CombatContext(
                modeEnabled: true,
                activeWeapon: nil,
                combatConditions: [],
                pinnedChecks: [],
                temporaryModifiers: []
            ),
            activeWeapon: nil,
            request: request,
            result: MechanicsCheckResolver.resolve(request),
            autoAppliedModifiers: [],
            visibleConditions: [],
            pinnedChecks: []
        ),
        rawDamage: 11,
        targetWounds: 7,
        targetArmour: 6,
        targetToughnessBonus: 2,
        penetrationOverride: 4
    )

    #expect(result.sourceWeapon == nil)
    #expect(result.breakdown.effectiveArmour == 2)
    #expect(result.appliedDamage == 7)
    #expect(result.woundsAfter == 0)
}

@Test func attackShortcutParsesPenetrationFromWeaponSummaryAndCombatContextCanReplaceWeapon() {
    let initialWeapon = Weapon(
        id: UUID(),
        name: "Stub Revolver",
        type: "Pistol",
        range: "30m",
        damage: "1d10+2 I",
        penetration: "",
        clip: "6",
        reload: "Half",
        traits: ""
    )
    let replacementWeapon = Weapon(
        id: UUID(),
        name: "Power Sword",
        type: "Melee",
        range: "—",
        damage: "1d10+5 E",
        penetration: "Pen 6 (Power Field)",
        clip: "",
        reload: "",
        traits: "Power Field"
    )
    let combatContext = CombatContext(
        modeEnabled: true,
        activeWeapon: ActiveWeaponContext.from(initialWeapon),
        combatConditions: [],
        pinnedChecks: [],
        temporaryModifiers: []
    ).replacingActiveWeapon(replacementWeapon)
    let characteristics = CharacteristicSet(
        weaponSkill: 48,
        ballisticSkill: 33,
        strength: 40,
        toughness: 38,
        agility: 35,
        intelligence: 30,
        perception: 32,
        willpower: 31,
        fellowship: 27
    )

    #expect(combatContext.activeWeapon?.displayName == "Power Sword")

    let flow = CombatEncounterResolver.attackFlow(
        combatContext: combatContext,
        characteristics: characteristics
    )!
    let damage = CombatEncounterResolver.resolveTargetDamage(
        for: flow,
        rawDamage: 12,
        targetWounds: 10,
        targetArmour: 8,
        targetToughnessBonus: 3
    )

    #expect(flow.title == "Melee Attack")
    #expect(damage.breakdown.effectiveArmour == 2)
    #expect(damage.appliedDamage == 7)
}

@Test func combatShortcutRegistryProvidesBoundedQuickTogglesAndReloadLabel() {
    let activeWeapon = ActiveWeaponContext(
        id: UUID(),
        displayName: "Laspistol",
        type: "Pistol",
        typeMetadata: WeaponTypeRegistry.resolve("Pistol"),
        range: "30m",
        damage: "1d10+2 E",
        penetration: "0",
        clip: "30",
        reload: "Half",
        traits: "Reliable",
        traitMetadata: WeaponTraitRegistry.resolveAll("Reliable")
    )

    #expect(CombatShortcutRegistry.quickModifierShortcuts.map(\.label) == ["Aim", "Smoke"])
    #expect(CombatShortcutRegistry.quickModifierShortcuts.map(\.value) == [10, -20])
    #expect(CombatShortcutRegistry.quickConditionShortcuts.map(\.label) == ["Pinned Down", "Partial Cover"])
    #expect(CombatShortcutRegistry.reloadConditionLabel(for: activeWeapon) == "Reloading Laspistol")
    #expect(CombatShortcutRegistry.reloadConditionLabel(for: nil) == "Reloading")
}
