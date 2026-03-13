import Foundation
import Testing
@testable import DHCharList

@Test func difficultyPresetRegistryProvidesStructuredStandardPresets() {
    let values = DifficultyPresetRegistry.standard.map(\.value)
    let preset = DifficultyPresetRegistry.preset(for: -20)

    #expect(values == [30, 20, 10, 0, -10, -20, -30])
    #expect(preset?.id == "minus20")
    #expect(preset?.label == "Standard Preset")
    #expect(preset?.source == "Difficulty Preset Registry")
    #expect(preset?.normalizedModifier().value == -20)
    #expect(preset?.normalizedModifier().source == "Difficulty Preset Registry")
}

@Test func skillMetadataRegistryResolvesCanonicalAndAdHocSkills() {
    let awareness = Skill(name: "  Awareness  ", characteristic: .perception, training: .trained)
    let customSkill = Skill(name: "Forbidden Litany", characteristic: .willpower, training: .known)

    let canonical = SkillMetadataRegistry.resolve(awareness)
    let adHoc = SkillMetadataRegistry.resolve(customSkill)

    #expect(canonical.id == "awareness")
    #expect(canonical.displayName == "Awareness")
    #expect(canonical.linkedCharacteristic == .perception)
    #expect(canonical.category == .fieldcraft)
    #expect(canonical.isCanonical)

    #expect(adHoc.displayName == "Forbidden Litany")
    #expect(adHoc.linkedCharacteristic == .willpower)
    #expect(adHoc.category == nil)
    #expect(adHoc.isCanonical == false)
}

@Test func blankAdHocSkillMetadataFallsBackToPlaceholderNameAndStableToken() {
    let blankSkill = Skill(name: "   ", characteristic: .willpower, training: .known)
    let metadata = SkillMetadataRegistry.resolve(blankSkill)

    #expect(metadata.displayName == "Unnamed Skill")
    #expect(metadata.id == "skill.unnamed-skill.willpower")
    #expect(metadata.isCanonical == false)
}

@Test func talentCatalogRegistryProvidesBoundedStructuredTalentMetadata() {
    let rapidReload = TalentCatalogRegistry.lookup(id: "rapid-reload")
    let deadeyeShot = TalentCatalogRegistry.lookup(name: "Deadeye Shot")

    #expect(rapidReload?.displayName == "Rapid Reload")
    #expect(rapidReload?.costModel.defaultCost == 100)
    #expect(rapidReload?.category == .combat)
    #expect(rapidReload?.source == "Bounded Talent Registry")
    #expect(rapidReload?.isCanonical == true)

    #expect(deadeyeShot?.id == "deadeye-shot")
    #expect(deadeyeShot?.aptitudeLinks == ["Ballistic Skill"])
    #expect(deadeyeShot?.prerequisites == [.minimumCharacteristic(.ballisticSkill, 35)])
    #expect(TalentCatalogRegistry.lookup(name: "Unknown Talent") == nil)
}

@Test func advanceCatalogRegistriesProvideStructuredCharacteristicAndSkillDefaults() {
    let characteristicEntry = CharacteristicAdvanceCatalogRegistry.entry(for: .weaponSkill)
    let awareness = Skill(name: "Awareness", characteristic: .perception, training: .trained)
    let skillEntry = SkillAdvanceCatalogRegistry.entry(for: awareness, targetTraining: .veteran)

    #expect(characteristicEntry.id == "characteristic.weaponSkill.tier1")
    #expect(characteristicEntry.delta == 5)
    #expect(characteristicEntry.costModel.defaultCost == 100)
    #expect(characteristicEntry.aptitudeLinks == ["Weapon Skill"])
    #expect(characteristicEntry.source == "Bounded Advance Registry")

    #expect(skillEntry.id == "skill.awareness.veteran")
    #expect(skillEntry.skillMetadata.id == "awareness")
    #expect(skillEntry.targetTraining == .veteran)
    #expect(skillEntry.costModel.defaultCost == 100)
    #expect(skillEntry.aptitudeLinks == ["Perception"])
    #expect(skillEntry.source == "Bounded Advance Registry")
}

@Test func weaponMetadataRegistriesResolveTypesAndTraitsForCombatContext() {
    let weapon = Weapon(
        name: "Chainsword",
        type: "Melee",
        range: "—",
        damage: "1d10+2 R",
        penetration: "2",
        traits: "Tearing, Custom Edge"
    )

    let context = ActiveWeaponContext.from(weapon)

    #expect(context.typeMetadata?.classification == .melee)
    #expect(context.typeMetadata?.displayName == "Melee")
    #expect(context.traitMetadata.map(\.displayName) == ["Tearing", "Custom Edge"])
    #expect(context.traitMetadata.map(\.isCanonical) == [true, false])
}

@Test func weaponRegistriesHandleNilAliasAndAdHocFallbackCases() {
    let missingType = WeaponTypeRegistry.resolve(nil)
    let adHocType = WeaponTypeRegistry.resolve("Archeotech Carbine")
    let traits = WeaponTraitRegistry.resolveAll("Razor Sharp; Custom Edge")
    let blankTrait = WeaponTraitRegistry.resolve("   ")

    #expect(missingType == nil)
    #expect(adHocType?.classification == .other)
    #expect(adHocType?.displayName == "Archeotech Carbine")
    #expect(adHocType?.isCanonical == false)
    #expect(traits.map(\.displayName) == ["Razor Sharp", "Custom Edge"])
    #expect(traits.map(\.isCanonical) == [true, false])
    #expect(blankTrait.displayName == "Unknown Trait")
}

@Test func conditionMetadataRegistryResolvesCanonicalAndCustomLabels() {
    let pinned = ConditionMetadataRegistry.resolve(label: "Pinned Down")
    let cover = ConditionMetadataRegistry.resolve(label: "Partial Cover")
    let injury = ConditionMetadataRegistry.resolve(label: "Leg Injury")
    let custom = ConditionMetadataRegistry.resolve(label: "Warp Echo")

    #expect(pinned.kind == .pinned)
    #expect(pinned.displayName == "Pinned")
    #expect(cover.kind == .cover)
    #expect(injury.kind == .injury)
    #expect(custom.kind == .custom)
    #expect(custom.displayName == "Warp Echo")
}

@Test func conditionMetadataRegistryHandlesSuppressionMetadataAndBlankFallback() {
    let suppression = ConditionMetadataRegistry.resolve(label: "Suppressing Fire")
    let metadata = ConditionMetadataRegistry.metadata(for: .suppression)
    let blank = ConditionMetadataRegistry.resolve(label: "   ")

    #expect(suppression.kind == .suppression)
    #expect(metadata?.displayName == "Suppression")
    #expect(blank.kind == .custom)
    #expect(blank.displayName == "Custom")
}

@Test func mechanicsResolverConsumesRegistryBackedSkillAndPresetMetadata() {
    let characteristics = CharacteristicSet(
        weaponSkill: 40,
        ballisticSkill: 35,
        strength: 32,
        toughness: 33,
        agility: 39,
        intelligence: 36,
        perception: 44,
        willpower: 31,
        fellowship: 28
    )
    let awareness = Skill(name: "Awareness", characteristic: .perception, training: .trained)

    let result = MechanicsCheckResolver.resolve(
        .skill(
            awareness,
            characteristics: characteristics,
            modifiers: [CheckModifier.preset(value: 20)]
        )
    )

    #expect(result.checkName == "Awareness")
    #expect(result.sourceName == "Perception")
    #expect(result.breakdown.appliedModifiers.map(\.source) == ["Difficulty Preset Registry"])
    #expect(result.breakdown.appliedModifiers.map(\.label) == ["Standard Preset"])
    #expect(result.finalTarget == 74)
}

@Test func difficultyPresetRegistryReturnsNilForUnsupportedValue() {
    #expect(DifficultyPresetRegistry.preset(for: 99) == nil)
}
