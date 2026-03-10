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
    #expect(result.checkName == "Agility Check")
    #expect(result.sourceName == "Agility")
    #expect(result.breakdown.baseValue == 47)
    #expect(result.breakdown.derivedBonus == 4)
    #expect(result.breakdown.trainingContribution == nil)
    #expect(result.breakdown.appliedModifier == -10)
    #expect(result.breakdown.appliedModifiers.map(\.kind) == [.manual])
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
    #expect(result.checkName == "Awareness")
    #expect(result.sourceName == "Perception")
    #expect(result.breakdown.baseValue == 42)
    #expect(result.breakdown.derivedBonus == 4)
    #expect(result.breakdown.trainingContribution == 10)
    #expect(result.breakdown.appliedModifier == 20)
    #expect(result.breakdown.appliedModifiers.map(\.kind) == [.preset])
    #expect(result.finalTarget == 72)
    #expect(result.breakdown.contribution(of: .training)?.appliesToFinalTarget == true)
}

@Test func standardQuickMechanicsPresetsRemainExpected() {
    #expect(CheckModifierPreset.standard.map(\.value) == [30, 20, 10, 0, -10, -20, -30])
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
    #expect(result.breakdown.appliedModifierContributions.map(\.label) == ["Custom Modifier", "Smoke"])
    #expect(result.breakdown.activeConditions.map(\.kind) == [.cover, .pinned])
    #expect(result.finalTarget == 40)
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
