import Foundation
import Testing
@testable import DHCharList

private struct CheckGoldenSnapshot: Equatable, Sendable {
    let checkName: String
    let sourceName: String
    let baseValue: Int
    let finalTarget: Int
    let contributionLabels: [String]
    let contributionValues: [Int]
    let appliedModifierKinds: [CheckModifierKind]
    let activeConditionKinds: [RuleConditionKind]

    init(
        checkName: String,
        sourceName: String,
        baseValue: Int,
        finalTarget: Int,
        contributionLabels: [String],
        contributionValues: [Int],
        appliedModifierKinds: [CheckModifierKind],
        activeConditionKinds: [RuleConditionKind]
    ) {
        self.checkName = checkName
        self.sourceName = sourceName
        self.baseValue = baseValue
        self.finalTarget = finalTarget
        self.contributionLabels = contributionLabels
        self.contributionValues = contributionValues
        self.appliedModifierKinds = appliedModifierKinds
        self.activeConditionKinds = activeConditionKinds
    }

    init(_ result: CheckResult) {
        checkName = result.checkName
        sourceName = result.sourceName
        baseValue = result.breakdown.baseValue
        finalTarget = result.finalTarget
        contributionLabels = result.breakdown.contributions.map(\.label)
        contributionValues = result.breakdown.contributions.map(\.value)
        appliedModifierKinds = result.breakdown.appliedModifiers.map(\.kind)
        activeConditionKinds = result.breakdown.activeConditions.map(\.kind)
    }
}

private struct CheckGoldenScenario: Sendable, CustomStringConvertible {
    let name: String
    let request: CheckRequest
    let expected: CheckGoldenSnapshot

    var description: String { name }
}

private struct CombatContextGoldenSnapshot: Equatable, Sendable {
    let activeWeaponName: String?
    let activeWeaponPrimarySummary: [String]
    let pinnedChecks: [String]
    let temporaryModifierLabels: [String]
    let conditionKinds: [RuleConditionKind]

    init(
        activeWeaponName: String?,
        activeWeaponPrimarySummary: [String],
        pinnedChecks: [String],
        temporaryModifierLabels: [String],
        conditionKinds: [RuleConditionKind]
    ) {
        self.activeWeaponName = activeWeaponName
        self.activeWeaponPrimarySummary = activeWeaponPrimarySummary
        self.pinnedChecks = pinnedChecks
        self.temporaryModifierLabels = temporaryModifierLabels
        self.conditionKinds = conditionKinds
    }

    init(_ context: CombatContext) {
        activeWeaponName = context.activeWeapon?.displayName
        activeWeaponPrimarySummary = context.activeWeapon?.primarySummary ?? []
        pinnedChecks = context.pinnedChecks.map(\.label)
        temporaryModifierLabels = context.temporaryModifiers.map(\.label)
        conditionKinds = context.combatConditions.map(\.kind)
    }
}

private struct CombatPreparationGoldenSnapshot: Equatable, Sendable {
    let activeWeaponName: String?
    let availableTemporaryModifierLabels: [String]
    let requestModifierLabels: [String]
    let requestConditionKinds: [RuleConditionKind]
    let finalTarget: Int
    let contributionLabels: [String]
    let contributionValues: [Int]

    init(
        activeWeaponName: String?,
        availableTemporaryModifierLabels: [String],
        requestModifierLabels: [String],
        requestConditionKinds: [RuleConditionKind],
        finalTarget: Int,
        contributionLabels: [String],
        contributionValues: [Int]
    ) {
        self.activeWeaponName = activeWeaponName
        self.availableTemporaryModifierLabels = availableTemporaryModifierLabels
        self.requestModifierLabels = requestModifierLabels
        self.requestConditionKinds = requestConditionKinds
        self.finalTarget = finalTarget
        self.contributionLabels = contributionLabels
        self.contributionValues = contributionValues
    }

    init(preparation: CombatCheckPreparationContext, result: CheckResult) {
        activeWeaponName = preparation.activeWeapon?.displayName
        availableTemporaryModifierLabels = preparation.availableTemporaryModifiers.map(\.label)
        requestModifierLabels = preparation.appliedModifiers.map(\.label)
        requestConditionKinds = result.breakdown.activeConditions.map(\.kind)
        finalTarget = result.finalTarget
        contributionLabels = result.breakdown.contributions.map(\.label)
        contributionValues = result.breakdown.contributions.map(\.value)
    }
}

private struct CombatGoldenScenario: Sendable, CustomStringConvertible {
    let name: String
    let context: CombatContext
    let expectedContext: CombatContextGoldenSnapshot
    let preparation: CombatCheckPreparationContext
    let requestCharacteristics: CharacteristicSet
    let expectedPreparation: CombatPreparationGoldenSnapshot

    var description: String { name }
}

private struct DamageGoldenSnapshot: Equatable, Sendable {
    let sourceLabel: String
    let effectiveArmour: Int
    let totalMitigation: Int
    let appliedDamage: Int
    let woundsBefore: Int
    let woundDelta: Int
    let woundsAfter: Int
    let overflowDamage: Int
    let contributionLabels: [String]
    let contributionValues: [Int]

    init(
        sourceLabel: String,
        effectiveArmour: Int,
        totalMitigation: Int,
        appliedDamage: Int,
        woundsBefore: Int,
        woundDelta: Int,
        woundsAfter: Int,
        overflowDamage: Int,
        contributionLabels: [String],
        contributionValues: [Int]
    ) {
        self.sourceLabel = sourceLabel
        self.effectiveArmour = effectiveArmour
        self.totalMitigation = totalMitigation
        self.appliedDamage = appliedDamage
        self.woundsBefore = woundsBefore
        self.woundDelta = woundDelta
        self.woundsAfter = woundsAfter
        self.overflowDamage = overflowDamage
        self.contributionLabels = contributionLabels
        self.contributionValues = contributionValues
    }

    init(_ result: DamageResult) {
        sourceLabel = result.sourceLabel
        effectiveArmour = result.breakdown.effectiveArmour
        totalMitigation = result.breakdown.totalMitigation
        appliedDamage = result.appliedDamage
        woundsBefore = result.breakdown.woundsBefore
        woundDelta = result.breakdown.woundDelta
        woundsAfter = result.woundsAfter
        overflowDamage = result.breakdown.overflowDamage
        contributionLabels = result.breakdown.contributions.map(\.label)
        contributionValues = result.breakdown.contributions.map(\.value)
    }
}

private struct DamageGoldenScenario: Sendable, CustomStringConvertible {
    let name: String
    let request: DamageRequest
    let expected: DamageGoldenSnapshot

    var description: String { name }
}

private let goldenCheckScenarios: [CheckGoldenScenario] = {
    let agilityCharacteristics = CharacteristicSet(
        weaponSkill: 43,
        ballisticSkill: 38,
        strength: 32,
        toughness: 36,
        agility: 47,
        intelligence: 29,
        perception: 41,
        willpower: 34,
        fellowship: 27
    )
    let awarenessCharacteristics = CharacteristicSet(
        weaponSkill: 31,
        ballisticSkill: 36,
        strength: 33,
        toughness: 39,
        agility: 40,
        intelligence: 35,
        perception: 42,
        willpower: 44,
        fellowship: 28
    )
    let combatCharacteristics = CharacteristicSet(
        weaponSkill: 41,
        ballisticSkill: 32,
        strength: 37,
        toughness: 36,
        agility: 44,
        intelligence: 35,
        perception: 43,
        willpower: 39,
        fellowship: 28
    )
    let trainedAwareness = Skill(name: "Awareness", characteristic: .perception, training: .trained)
    let knownAwareness = Skill(name: "Awareness", characteristic: .perception, training: .known)

    return [
        CheckGoldenScenario(
            name: "characteristic-custom-modifier",
            request: .characteristic(
                .agility,
                characteristics: agilityCharacteristics,
                modifiers: [.manual(value: -10)]
            ),
            expected: CheckGoldenSnapshot(
                checkName: "Agility Check",
                sourceName: "Agility",
                baseValue: 47,
                finalTarget: 37,
                contributionLabels: ["Derived Bonus", "Custom Modifier"],
                contributionValues: [4, -10],
                appliedModifierKinds: [.manual],
                activeConditionKinds: []
            )
        ),
        CheckGoldenScenario(
            name: "skill-preset-modifier",
            request: .skill(
                trainedAwareness,
                characteristics: awarenessCharacteristics,
                modifiers: [.preset(value: 20)]
            ),
            expected: CheckGoldenSnapshot(
                checkName: "Awareness",
                sourceName: "Perception",
                baseValue: 42,
                finalTarget: 72,
                contributionLabels: ["Derived Bonus", "Training Contribution", "Standard Preset"],
                contributionValues: [4, 10, 20],
                appliedModifierKinds: [.preset],
                activeConditionKinds: []
            )
        ),
        CheckGoldenScenario(
            name: "session-skill-with-structured-modifiers-and-condition",
            request: .skill(
                knownAwareness,
                characteristics: combatCharacteristics,
                origin: .sessionCombat,
                modifiers: [
                    .manual(value: 5),
                    .sessionTemporary(label: "Smoke", value: -20),
                    .conditionDerived(label: "Pinned Down", value: -30),
                    .equipmentDerived(label: "Red-Dot Sight", value: 10, scope: .specificSkill(knownAwareness.id))
                ],
                conditions: [RuleCondition.sessionCombatCondition(index: 0, text: "Pinned Down")]
            ),
            expected: CheckGoldenSnapshot(
                checkName: "Awareness",
                sourceName: "Perception",
                baseValue: 43,
                finalTarget: 8,
                contributionLabels: [
                    "Derived Bonus",
                    "Training Contribution",
                    "Custom Modifier",
                    "Smoke",
                    "Pinned Down",
                    "Red-Dot Sight"
                ],
                contributionValues: [4, 0, 5, -20, -30, 10],
                appliedModifierKinds: [.manual, .sessionTemporary, .conditionDerived, .equipmentDerived],
                activeConditionKinds: [.pinned]
            )
        )
    ]
}()

private let combatGoldenScenarios: [CombatGoldenScenario] = {
    let weaponID = UUID(uuidString: "00000000-0000-0000-0000-00000000C041")!
    let weapon = Weapon(
        id: weaponID,
        name: "Laspistol",
        type: "Pistol",
        range: "30m",
        damage: "1d10+2",
        penetration: "0",
        clip: "30",
        reload: "Half",
        traits: "Reliable"
    )
    let session = SessionState(
        modeEnabled: true,
        pinnedChecks: ["Dodge +10", "Awareness"],
        temporaryModifiers: ["Smoke": -20, "Aim": 10],
        activeWeaponID: weaponID,
        combatConditions: ["Pinned Down", "Partial Cover"]
    )
    let context = session.combatContext(availableWeapons: [weapon])
    let awareness = Skill(id: UUID(uuidString: "00000000-0000-0000-0000-00000000A111")!, name: "Awareness", characteristic: .perception, training: .trained)
    let preparation = context.preparation(
        for: .skill(awareness),
        appliedModifiers: [
            CheckModifier.sessionTemporary(label: "Aim", value: 10),
            CheckModifier.conditionDerived(label: "Pinned Down", value: -30)
        ]
    )
    let characteristics = CharacteristicSet(
        weaponSkill: 39,
        ballisticSkill: 37,
        strength: 34,
        toughness: 35,
        agility: 40,
        intelligence: 31,
        perception: 41,
        willpower: 38,
        fellowship: 30
    )
    let request = CheckRequest.combatPreparation(preparation, characteristics: characteristics)
    let result = MechanicsCheckResolver.resolve(request)

    return [
        CombatGoldenScenario(
            name: "combat-context-and-preparation-lock-accepted-session-flow",
            context: context,
            expectedContext: CombatContextGoldenSnapshot(
                activeWeaponName: "Laspistol",
                activeWeaponPrimarySummary: ["Pistol", "Range 30m", "Damage 1d10+2", "Pen 0"],
                pinnedChecks: ["Dodge +10", "Awareness"],
                temporaryModifierLabels: ["Aim", "Smoke"],
                conditionKinds: [.pinned, .cover]
            ),
            preparation: preparation,
            requestCharacteristics: characteristics,
            expectedPreparation: CombatPreparationGoldenSnapshot(
                activeWeaponName: "Laspistol",
                availableTemporaryModifierLabels: ["Aim", "Smoke"],
                requestModifierLabels: ["Aim", "Pinned Down"],
                requestConditionKinds: [.pinned, .cover],
                finalTarget: 31,
                contributionLabels: ["Derived Bonus", "Training Contribution", "Aim", "Pinned Down"],
                contributionValues: [4, 10, 10, -30]
            )
        )
    ]
}()

private let damageGoldenScenarios: [DamageGoldenScenario] = {
    let combatWeaponID = UUID(uuidString: "00000000-0000-0000-0000-00000000D411")!
    let combatWeapon = Weapon(
        id: combatWeaponID,
        name: "Laspistol",
        type: "Pistol",
        range: "30m",
        damage: "1d10+3",
        penetration: "4",
        clip: "30",
        reload: "Half",
        traits: "Reliable"
    )
    let combatSession = SessionState(
        modeEnabled: true,
        pinnedChecks: ["Dodge +10"],
        temporaryModifiers: ["Aim": 10],
        activeWeaponID: combatWeaponID,
        combatConditions: ["Pinned Down"]
    )
    let combatContext = combatSession.combatContext(availableWeapons: [combatWeapon])
    let combatCharacteristics = CharacteristicSet(
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
    let combatResources = ResourceState(currentWounds: 12, maxWounds: 12)

    return [
        DamageGoldenScenario(
            name: "manual-damage-with-armour-and-toughness",
            request: .manual(rawDamage: 12, woundsBefore: 14, armour: 5, penetration: 2, toughnessBonus: 4),
            expected: DamageGoldenSnapshot(
                sourceLabel: "Manual Damage",
                effectiveArmour: 3,
                totalMitigation: 7,
                appliedDamage: 5,
                woundsBefore: 14,
                woundDelta: -5,
                woundsAfter: 9,
                overflowDamage: 0,
                contributionLabels: [
                    "Raw Damage",
                    "Penetration",
                    "Armour Mitigation",
                    "Toughness Mitigation",
                    "Applied Damage",
                    "Wound Delta",
                    "Overflow"
                ],
                contributionValues: [12, 2, -3, -4, 5, -5, 0]
            )
        ),
        DamageGoldenScenario(
            name: "combat-damage-uses-active-weapon-penetration",
            request: combatContext.damageRequest(
                rawDamage: 14,
                resources: combatResources,
                characteristics: combatCharacteristics,
                armourPoints: 5
            ),
            expected: DamageGoldenSnapshot(
                sourceLabel: "Laspistol",
                effectiveArmour: 1,
                totalMitigation: 4,
                appliedDamage: 10,
                woundsBefore: 12,
                woundDelta: -10,
                woundsAfter: 2,
                overflowDamage: 0,
                contributionLabels: [
                    "Raw Damage",
                    "Penetration",
                    "Armour Mitigation",
                    "Toughness Mitigation",
                    "Applied Damage",
                    "Wound Delta",
                    "Overflow"
                ],
                contributionValues: [14, 4, -1, -3, 10, -10, 0]
            )
        ),
        DamageGoldenScenario(
            name: "mitigation-zero-floor",
            request: .manual(rawDamage: 6, woundsBefore: 11, armour: 4, penetration: 0, toughnessBonus: 3),
            expected: DamageGoldenSnapshot(
                sourceLabel: "Manual Damage",
                effectiveArmour: 4,
                totalMitigation: 7,
                appliedDamage: 0,
                woundsBefore: 11,
                woundDelta: 0,
                woundsAfter: 11,
                overflowDamage: 0,
                contributionLabels: [
                    "Raw Damage",
                    "Penetration",
                    "Armour Mitigation",
                    "Toughness Mitigation",
                    "Applied Damage",
                    "Wound Delta",
                    "Overflow"
                ],
                contributionValues: [6, 0, -4, -3, 0, 0, 0]
            )
        ),
        DamageGoldenScenario(
            name: "overflow-tracking",
            request: .manual(rawDamage: 18, woundsBefore: 7, armour: 2, penetration: 0, toughnessBonus: 3),
            expected: DamageGoldenSnapshot(
                sourceLabel: "Manual Damage",
                effectiveArmour: 2,
                totalMitigation: 5,
                appliedDamage: 13,
                woundsBefore: 7,
                woundDelta: -7,
                woundsAfter: 0,
                overflowDamage: 6,
                contributionLabels: [
                    "Raw Damage",
                    "Penetration",
                    "Armour Mitigation",
                    "Toughness Mitigation",
                    "Applied Damage",
                    "Wound Delta",
                    "Overflow"
                ],
                contributionValues: [18, 0, -2, -3, 13, -7, 6]
            )
        )
    ]
}()

@Test("golden explainable check scenario", arguments: goldenCheckScenarios)
private func goldenExplainableCheckScenarioRemainsStable(_ scenario: CheckGoldenScenario) {
    let result = MechanicsCheckResolver.resolve(scenario.request)
    #expect(CheckGoldenSnapshot(result) == scenario.expected)
}

@Test("golden combat scenario", arguments: combatGoldenScenarios)
private func goldenCombatScenarioRemainsStable(_ scenario: CombatGoldenScenario) {
    let request = CheckRequest.combatPreparation(scenario.preparation, characteristics: scenario.requestCharacteristics)
    let result = MechanicsCheckResolver.resolve(request)

    #expect(CombatContextGoldenSnapshot(scenario.context) == scenario.expectedContext)
    #expect(CombatPreparationGoldenSnapshot(preparation: scenario.preparation, result: result) == scenario.expectedPreparation)
}

@Test("golden damage scenario", arguments: damageGoldenScenarios)
private func goldenDamageScenarioRemainsStable(_ scenario: DamageGoldenScenario) {
    let result = DamageResolver.resolve(scenario.request)
    #expect(DamageGoldenSnapshot(result) == scenario.expected)
}
