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
        .characteristic(.agility, characteristics: characteristics, modifier: -10)
    )

    #expect(result.kind == .characteristic)
    #expect(result.checkName == "Agility Check")
    #expect(result.sourceName == "Agility")
    #expect(result.breakdown.baseValue == 47)
    #expect(result.breakdown.derivedBonus == 4)
    #expect(result.breakdown.trainingContribution == nil)
    #expect(result.breakdown.appliedModifier == -10)
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
        .skill(skill, characteristics: characteristics, modifier: 20)
    )

    #expect(result.kind == .skill)
    #expect(result.checkName == "Awareness")
    #expect(result.sourceName == "Perception")
    #expect(result.breakdown.baseValue == 42)
    #expect(result.breakdown.derivedBonus == 4)
    #expect(result.breakdown.trainingContribution == 10)
    #expect(result.breakdown.appliedModifier == 20)
    #expect(result.finalTarget == 72)
    #expect(result.breakdown.contribution(of: .training)?.appliesToFinalTarget == true)
}

@Test func standardQuickMechanicsPresetsRemainExpected() {
    #expect(CheckModifierPreset.standard.map(\.value) == [30, 20, 10, 0, -10, -20, -30])
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
