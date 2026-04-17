import Foundation
import Testing
@testable import DHCharList

@Test func characteristicQuickCheckAppliesModifierAndExposesBonus() {
    let characteristics = CharacteristicSet(
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

    let result = MechanicsCheckResolver.resolve(
        .characteristic(
            .agility,
            characteristics: characteristics,
            modifiers: [.manual(value: -10)]
        )
    )

    #expect(result.kind == .characteristic)
    #expect(result.definition == .characteristic(.agility))
    #expect(result.checkName == "Agility Check")
    #expect(result.sourceName == "Agility")
    #expect(result.breakdown.baseValue == 47)
    #expect(result.breakdown.derivedBonus == 4)
    #expect(result.breakdown.trainingContribution == nil)
    #expect(result.breakdown.appliedModifier == -10)
    #expect(result.breakdown.appliedModifiers.map(\.kind) == [.manual])
    #expect(result.breakdown.contributions.map(\.label) == ["Derived Bonus", "Custom Modifier"])
    #expect(result.finalTarget == 37)
    #expect(result.breakdown.contribution(of: .derivedBonus)?.appliesToFinalTarget == false)
    #expect(result.breakdown.contribution(of: .modifier)?.appliesToFinalTarget == true)
}

@Test func skillQuickCheckAppliesTrainingAndModifierWithTransparentBreakdown() {
    let characteristics = CharacteristicSet(
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
    let skill = Skill(name: "Awareness", characteristic: .perception, training: .trained)

    let result = MechanicsCheckResolver.resolve(
        .skill(
            skill,
            characteristics: characteristics,
            modifiers: [.preset(value: 20)]
        )
    )

    #expect(result.kind == .skill)
    #expect(result.definition == .skill(skill))
    #expect(result.checkName == "Awareness")
    #expect(result.sourceName == "Perception")
    #expect(result.breakdown.baseValue == 42)
    #expect(result.breakdown.derivedBonus == 4)
    #expect(result.breakdown.trainingContribution == 10)
    #expect(result.breakdown.appliedModifier == 20)
    #expect(result.breakdown.appliedModifiers.map(\.kind) == [.preset])
    #expect(
        result.breakdown.contributions.map(\.label) == [
            "Derived Bonus",
            "Training Contribution",
            "Standard Preset"
        ]
    )
    #expect(result.finalTarget == 72)
    #expect(result.breakdown.contribution(of: .training)?.appliesToFinalTarget == true)
}

@Test func skillTrainingRanksMatchDh2KnownTrainedExperiencedVeteranBonuses() {
    let characteristics = CharacteristicSet(
        weaponSkill: 30,
        ballisticSkill: 30,
        strength: 30,
        toughness: 30,
        agility: 30,
        intelligence: 30,
        perception: 40,
        willpower: 30,
        fellowship: 30
    )

    let known = Skill(name: "Awareness", characteristic: .perception, training: .known)
    let trained = Skill(name: "Awareness", characteristic: .perception, training: .trained)
    let experienced = Skill(name: "Awareness", characteristic: .perception, training: .experienced)
    let veteran = Skill(name: "Awareness", characteristic: .perception, training: .veteran)

    #expect(MechanicsCheckResolver.resolve(CheckRequest.skill(known, characteristics: characteristics, modifiers: [])).finalTarget == 40)
    #expect(MechanicsCheckResolver.resolve(CheckRequest.skill(trained, characteristics: characteristics, modifiers: [])).finalTarget == 50)
    #expect(MechanicsCheckResolver.resolve(CheckRequest.skill(experienced, characteristics: characteristics, modifiers: [])).finalTarget == 60)
    #expect(MechanicsCheckResolver.resolve(CheckRequest.skill(veteran, characteristics: characteristics, modifiers: [])).finalTarget == 70)
}

@Test func standardQuickMechanicsPresetsRemainExpected() {
    #expect(DifficultyPresetRegistry.standard.map(\.value) == [30, 20, 10, 0, -10, -20, -30])
    #expect(DifficultyPresetRegistry.preset(for: 20)?.source == "Difficulty Preset Registry")
}

@Test func structuredModifiersRespectScopeFilteringAndOrigin() {
    let characteristics = CharacteristicSet(
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
    let skill = Skill(name: "Awareness", characteristic: .perception, training: .known)

    let modifiers: [CheckModifier] = [
        .manual(value: 5, scope: .allChecks),
        .preset(value: 10, scope: .characteristicChecks),
        .sessionTemporary(label: "Smoke", value: -20),
        .conditionDerived(label: "Pinned Down", value: -30, scope: .combatSessionOnly),
        .equipmentDerived(label: "Red-Dot Sight", value: 10, scope: .specificSkill(skill.id))
    ]

    let standardCharacteristic = MechanicsCheckResolver.resolve(
        .characteristic(
            .agility,
            characteristics: characteristics,
            modifiers: modifiers
        )
    )
    let sessionSkill = MechanicsCheckResolver.resolve(
        .skill(
            skill,
            characteristics: characteristics,
            origin: .sessionCombat,
            modifiers: modifiers
        )
    )

    #expect(standardCharacteristic.finalTarget == 59)
    #expect(standardCharacteristic.breakdown.appliedModifier == 15)
    #expect(standardCharacteristic.breakdown.appliedModifiers.map(\.kind) == [.manual, .preset])

    #expect(sessionSkill.finalTarget == 8)
    #expect(sessionSkill.breakdown.appliedModifier == -35)
    #expect(sessionSkill.breakdown.appliedModifiers.map(\.kind) == [.manual, .sessionTemporary, .conditionDerived, .equipmentDerived])
}

@Test func multiModifierBreakdownRemainsExplainableAndKeepsConditionsVisible() {
    let characteristics = CharacteristicSet(
        weaponSkill: 46,
        ballisticSkill: 35,
        strength: 33,
        toughness: 31,
        agility: 38,
        intelligence: 40,
        perception: 42,
        willpower: 37,
        fellowship: 29
    )
    let skill = Skill(name: "Tech-Use", characteristic: .intelligence, training: .trained)
    let conditions = [
        RuleCondition.sessionCombatCondition(index: 0, text: "Partial Cover"),
        RuleCondition.sessionCombatCondition(index: 1, text: "Pinned Down")
    ]

    let result = MechanicsCheckResolver.resolve(
        .skill(
            skill,
            characteristics: characteristics,
            origin: .sessionCombat,
            modifiers: [
                .manual(value: 10),
                .sessionTemporary(label: "Smoke", value: -20)
            ],
            conditions: conditions
        )
    )

    #expect(result.breakdown.baseValue == 40)
    #expect(result.breakdown.trainingContribution == 10)
    #expect(result.breakdown.appliedModifier == -10)
    #expect(
        result.breakdown.contributions.map(\.label) == [
            "Derived Bonus",
            "Training Contribution",
            "Custom Modifier",
            "Smoke"
        ]
    )
    #expect(result.breakdown.appliedModifierContributions.map(\.label) == ["Custom Modifier", "Smoke"])
    #expect(result.breakdown.activeConditions.map(\.kind) == [.cover, .pinned])
    #expect(result.finalTarget == 40)
}

@Test func unifiedExplainableCheckEngineKeepsStableContributionOrdering() {
    let characteristics = CharacteristicSet(
        weaponSkill: 39,
        ballisticSkill: 34,
        strength: 35,
        toughness: 33,
        agility: 40,
        intelligence: 31,
        perception: 41,
        willpower: 38,
        fellowship: 30
    )
    let skill = Skill(name: "Awareness", characteristic: .perception, training: .trained)
    let condition = RuleCondition.sessionCombatCondition(index: 0, text: "Pinned Down")

    let result = MechanicsCheckResolver.resolve(
        .skill(
            skill,
            characteristics: characteristics,
            origin: .sessionCombat,
            modifiers: [
                .preset(value: 10),
                .sessionTemporary(label: "Aim", value: 20),
                .conditionDerived(label: "Pinned Down", value: -30)
            ],
            conditions: [condition]
        )
    )

    #expect(result.definition == .skill(skill))
    #expect(
        result.breakdown.contributions.map(\.label) == [
            "Derived Bonus",
            "Training Contribution",
            "Standard Preset",
            "Aim",
            "Pinned Down"
        ]
    )
    #expect(result.breakdown.appliedModifiers.map(\.kind) == [.preset, .sessionTemporary, .conditionDerived])
    #expect(result.breakdown.activeConditions == [condition])
    #expect(result.finalTarget == 51)
}

@Test func sessionStateNormalizesTemporaryModifiersAndCombatConditions() {
    let session = SessionState(
        modeEnabled: true,
        pinnedChecks: [],
        temporaryModifiers: [
            "Smoke": -20,
            "Aim": 10
        ],
        activeWeaponID: nil,
        combatConditions: [
            "Pinned Down",
            "Partial Cover",
            "Leg Injury",
            "Warp Echo"
        ]
    )

    #expect(session.normalizedTemporaryModifiers.map(\.label) == ["Aim", "Smoke"])
    #expect(session.normalizedTemporaryModifiers.map(\.kind) == [.sessionTemporary, .sessionTemporary])
    #expect(session.normalizedTemporaryModifiers.allSatisfy { $0.scope == .combatSessionOnly })
    #expect(session.normalizedCombatConditions.map(\.kind) == [.pinned, .cover, .injury, .custom])
    #expect(session.normalizedCombatConditions.allSatisfy { $0.source == "Session Combat Condition" })
}

@Test func combatContextFormalizesActiveWeaponPinnedChecksConditionsAndModifiers() {
    let weaponID = UUID()
    let session = SessionState(
        modeEnabled: true,
        pinnedChecks: ["Dodge +10", "Awareness"],
        temporaryModifiers: [
            "Smoke": -20,
            "Aim": 10
        ],
        activeWeaponID: weaponID,
        combatConditions: [
            "Pinned Down",
            "Partial Cover"
        ]
    )
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

    let context = session.combatContext(availableWeapons: [weapon])

    #expect(context.modeEnabled)
    #expect(context.activeWeapon?.id == weaponID)
    #expect(context.activeWeapon?.displayName == "Laspistol")
    #expect(
        context.activeWeapon?.primarySummary == [
            "Pistol",
            "Range 30m",
            "Damage 1d10+2",
            "Pen 0"
        ]
    )
    #expect(
        context.activeWeapon?.secondarySummary == [
            "Clip 30",
            "Reload Half",
            "Reliable"
        ]
    )
    #expect(context.activeWeapon?.typeMetadata?.classification == .pistol)
    #expect(context.activeWeapon?.traitMetadata.map(\.displayName) == ["Reliable"])
    #expect(context.pinnedChecks.map { $0.label } == ["Dodge +10", "Awareness"])
    #expect(context.temporaryModifiers.map { $0.label } == ["Aim", "Smoke"])
    #expect(context.combatConditions.map { $0.kind } == [RuleConditionKind.pinned, RuleConditionKind.cover])
}

@Test func combatContextDropsMissingActiveWeaponWithoutDiscardingOtherCombatState() {
    let session = SessionState(
        modeEnabled: true,
        pinnedChecks: ["Dodge +10"],
        temporaryModifiers: ["Smoke": -20],
        activeWeaponID: UUID(),
        combatConditions: ["Pinned Down"]
    )

    let context = session.combatContext(availableWeapons: [])

    #expect(context.activeWeapon == nil)
    #expect(context.pinnedChecks.map { $0.label } == ["Dodge +10"])
    #expect(context.temporaryModifiers.map { $0.label } == ["Smoke"])
    #expect(context.combatConditions.map { $0.label } == ["Pinned Down"])
}

@Test func combatCheckPreparationContextBuildsStructuredSessionCombatRequest() {
    let weaponID = UUID()
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
    let skill = Skill(name: "Awareness", characteristic: .perception, training: .trained)
    let session = SessionState(
        modeEnabled: true,
        pinnedChecks: ["Dodge +10"],
        temporaryModifiers: ["Aim": 10],
        activeWeaponID: weaponID,
        combatConditions: ["Pinned Down"]
    )
    let weapon = Weapon(id: weaponID, name: "Laspistol", type: "Pistol", range: "30m")

    let context = session.combatContext(availableWeapons: [weapon])
    let preparation = context.preparation(
        for: CheckDefinition.skill(skill),
        appliedModifiers: [
            CheckModifier.sessionTemporary(label: "Aim", value: 10),
            CheckModifier.conditionDerived(label: "Pinned Down", value: -30)
        ]
    )
    let request = CheckRequest.combatPreparation(preparation, characteristics: characteristics)
    let result = MechanicsCheckResolver.resolve(request)

    #expect(preparation.origin == CheckOrigin.sessionCombat)
    #expect(preparation.activeWeapon?.displayName == "Laspistol")
    #expect(preparation.pinnedChecks.map { $0.label } == ["Dodge +10"])
    #expect(preparation.availableTemporaryModifiers.map { $0.label } == ["Aim"])
    #expect(request.definition == CheckDefinition.skill(skill))
    #expect(request.origin == CheckOrigin.sessionCombat)
    #expect(request.conditions == context.combatConditions)
    #expect(request.modifiers.map { $0.label } == ["Aim", "Pinned Down"])
    #expect(result.finalTarget == 31)
    #expect(
        result.breakdown.contributions.map { $0.label } == [
            "Derived Bonus",
            "Training Contribution",
            "Aim",
            "Pinned Down"
        ]
    )
}

@Test func derivedValueCalculatorRemainsConsistentWithMechanicsCheckResolver() {
    let characteristics = CharacteristicSet(
        weaponSkill: 48,
        ballisticSkill: 37,
        strength: 34,
        toughness: 33,
        agility: 41,
        intelligence: 39,
        perception: 44,
        willpower: 30,
        fellowship: 26
    )
    let skill = Skill(name: "", characteristic: .intelligence, training: .known)

    let characteristicTarget = DerivedValueCalculator.characteristicTarget(
        for: .weaponSkill,
        characteristics: characteristics,
        modifiers: -20
    )
    let skillTarget = DerivedValueCalculator.skillTarget(
        for: skill,
        characteristics: characteristics,
        modifiers: -10
    )

    #expect(characteristicTarget == 28)
    #expect(skillTarget == 29)
    #expect(
        MechanicsCheckResolver
            .resolve(.skill(skill, characteristics: characteristics, modifier: -10))
            .checkName == "Unnamed Skill"
    )
}
