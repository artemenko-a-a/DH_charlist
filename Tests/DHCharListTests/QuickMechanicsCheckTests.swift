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

    let breakdown = QuickMechanicsCheckBuilder.characteristicCheck(
        for: .agility,
        characteristics: characteristics,
        modifier: -10
    )

    #expect(breakdown.kind == .characteristic)
    #expect(breakdown.checkName == "Agility Check")
    #expect(breakdown.sourceName == "Agility")
    #expect(breakdown.baseValue == 47)
    #expect(breakdown.derivedBonus == 4)
    #expect(breakdown.trainingModifier == nil)
    #expect(breakdown.appliedModifier == -10)
    #expect(breakdown.finalTarget == 37)
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

    let breakdown = QuickMechanicsCheckBuilder.skillCheck(
        for: skill,
        characteristics: characteristics,
        modifier: 20
    )

    #expect(breakdown.kind == .skill)
    #expect(breakdown.checkName == "Awareness")
    #expect(breakdown.sourceName == "Perception")
    #expect(breakdown.baseValue == 42)
    #expect(breakdown.derivedBonus == 4)
    #expect(breakdown.trainingModifier == 10)
    #expect(breakdown.appliedModifier == 20)
    #expect(breakdown.finalTarget == 72)
}

@Test func standardQuickMechanicsPresetsRemainExpected() {
    #expect(QuickMechanicsModifierPreset.standard.map(\.value) == [30, 20, 10, 0, -10, -20, -30])
}

@Test func derivedValueCalculatorRemainsConsistentWithQuickMechanicsBuilder() {
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
    #expect(QuickMechanicsCheckBuilder.skillCheck(for: skill, characteristics: characteristics, modifier: -10).checkName == "Unnamed Skill")
}
