import { describe, expect, it } from 'vitest'
import {
  addDetachedWeapon,
  coerceCharacter,
  composeDossier,
  createDefaultCharacter,
  parseArmourCompendiumImport,
  parseWeaponCompendiumImport,
  resolveAttackFlow,
  resolveDamage,
  resolveReactionFlow,
  resolveSkillCheck,
  trainingModifiers,
  validateOrApplyXPSpend
} from './domain'

describe('rules and safety helpers', () => {
  it('starts new web characters as blank manual records instead of invented DH2 defaults', () => {
    const character = createDefaultCharacter('Blank Start')

    expect(character.profile.aptitudes).toEqual([])
    expect(character.characteristics).toEqual({
      weaponSkill: 0,
      ballisticSkill: 0,
      strength: 0,
      toughness: 0,
      agility: 0,
      intelligence: 0,
      perception: 0,
      willpower: 0,
      fellowship: 0
    })
    expect(character.resources).toMatchObject({
      currentWounds: 0,
      maxWounds: 0,
      currentFate: 0,
      maxFate: 0,
      experienceSpent: 0,
      experienceTotal: 0
    })
    expect(character.skills).toEqual([])
    expect(character.equipment.movement).toEqual({
      halfMove: 0,
      fullMove: 0,
      charge: 0,
      run: 0
    })
  })

  it('keeps detached weapon instances separate from compendium definitions', () => {
    const character = createDefaultCharacter('Detach Test')
    const originalName = 'Lasgun'
    const definition = {
      id: 'catalog.lasgun',
      catalogID: 'catalog',
      name: originalName,
      type: 'Basic',
      range: '100m',
      damage: '1d10+3 E',
      penetration: '0',
      clip: '60',
      reload: 'Full',
      traits: ['Reliable'],
      notes: ''
    }

    const updated = addDetachedWeapon(character, definition)
    updated.equipment.weapons[0]!.name = 'Customized Lasgun'

    expect(definition.name).toBe(originalName)
    expect(updated.equipment.weapons[0]!.name).toBe('Customized Lasgun')
  })

  it('preserves persisted history entry types during coercion', () => {
    const source = createDefaultCharacter('History Type Test')
    source.history = [
      {
        id: 'history-1',
        characterID: source.id,
        createdAt: '2026-03-29T00:00:00.000Z',
        title: 'Recovered Advancement',
        type: 'advancement',
        body: 'Bought a rank.',
        tags: ['xp']
      }
    ]

    const coerced = coerceCharacter(source)

    expect(coerced?.history[0]?.type).toBe('advancement')
  })

  it('does not invent canonical stats or resources when recovering sparse records', () => {
    const coerced = coerceCharacter({
      id: 'sparse',
      profile: {
        name: 'Sparse'
      }
    })

    expect(coerced?.characteristics).toEqual({
      weaponSkill: 0,
      ballisticSkill: 0,
      strength: 0,
      toughness: 0,
      agility: 0,
      intelligence: 0,
      perception: 0,
      willpower: 0,
      fellowship: 0
    })
    expect(coerced?.resources).toMatchObject({
      currentWounds: 0,
      maxWounds: 0,
      currentFate: 0,
      maxFate: 0,
      experienceSpent: 0,
      experienceTotal: 0
    })
  })

  it('matches DH2 skill progression bonuses through veteran rank', () => {
    expect(trainingModifiers.known).toBe(0)
    expect(trainingModifiers.trained).toBe(10)
    expect(trainingModifiers.experienced).toBe(20)
    expect(trainingModifiers.veteran).toBe(30)

    const characteristics = {
      weaponSkill: 0,
      ballisticSkill: 0,
      strength: 0,
      toughness: 0,
      agility: 0,
      intelligence: 0,
      perception: 40,
      willpower: 0,
      fellowship: 0
    }

    const experiencedSkill = {
      id: 'skill-experienced',
      name: 'Awareness',
      characteristic: 'perception' as const,
      training: 'experienced' as const,
      specialisations: []
    }
    const veteranSkill = {
      ...experiencedSkill,
      id: 'skill-veteran',
      training: 'veteran' as const
    }

    expect(resolveSkillCheck(experiencedSkill, characteristics).finalTarget).toBe(60)
    expect(resolveSkillCheck(veteranSkill, characteristics).finalTarget).toBe(70)
  })

  it('rejects malformed compendium imports and accepts valid replace-all payloads', () => {
    expect(parseWeaponCompendiumImport('{').ok).toBe(false)
    expect(parseArmourCompendiumImport('{"schemaVersion":2}').ok).toBe(false)
    expect(parseWeaponCompendiumImport(JSON.stringify({
      schemaVersion: 1,
      catalog: {
        id: 'valid',
        displayName: 'Valid',
        definitions: [{ id: 'valid.one', name: 'One' }]
      }
    })).ok).toBe(true)
  })

  it('resolves skill and combat helpers with explainable targets', () => {
    const character = createDefaultCharacter('Mechanics')
    character.characteristics = {
      weaponSkill: 30,
      ballisticSkill: 30,
      strength: 30,
      toughness: 30,
      agility: 30,
      intelligence: 30,
      perception: 30,
      willpower: 30,
      fellowship: 30
    }
    const skill = {
      id: 'mechanics-awareness',
      name: 'Awareness',
      characteristic: 'perception' as const,
      training: 'trained' as const,
      specialisations: []
    }
    character.skills = [skill]
    const skillResult = resolveSkillCheck(skill, character.characteristics, 10)

    expect(skillResult.finalTarget).toBe(50)
    expect(skillResult.contributions.map((entry) => entry.label)).toEqual([
      'Derived Bonus',
      'Training Contribution',
      'Standard Preset'
    ])

    const armed = {
      ...character,
      equipment: {
        ...character.equipment,
        weapons: [{ id: 'w1', name: 'Laspistol', type: 'Pistol', range: '30m', damage: '1d10+2 E', penetration: '2', clip: '30', reload: 'Half', traits: 'Reliable' }]
      },
      session: {
        ...character.session,
        activeWeaponID: 'w1',
        temporaryModifiers: { Aim: 10, Smoke: -20 },
        combatConditions: ['Partial Cover']
      }
    }

    expect(resolveAttackFlow(armed, 10)?.result.finalTarget).toBe(30)
    expect(resolveReactionFlow(armed, 'dodge', 10).result.finalTarget).toBe(10)
  })

  it('validates and applies XP spending with history updates', () => {
    const character = createDefaultCharacter('XP Test')
    character.profile.aptitudes = ['Knowledge']
    character.characteristics.strength = 30
    character.resources.experienceTotal = 400
    character.resources.experienceSpent = 0

    const blocked = validateOrApplyXPSpend(character, {
      kind: 'characteristicAdvance',
      characteristic: 'strength',
      delta: 5,
      cost: 450,
      prerequisites: []
    }, false)
    expect(blocked.isValid).toBe(false)

    const applied = validateOrApplyXPSpend(character, {
      kind: 'characteristicAdvance',
      characteristic: 'strength',
      delta: 5,
      cost: 150,
      prerequisites: [{ kind: 'requiredAptitude', value: 'Knowledge' }]
    }, true)

    expect(applied.isValid).toBe(true)
    expect(applied.appliedCharacter?.characteristics.strength).toBe(35)
    expect(applied.appliedCharacter?.resources.experienceSpent).toBe(150)
    expect(applied.appliedCharacter?.history[0]?.title).toContain('Advancement')
  })

  it('composes dossier output and bounded damage breakdowns', () => {
    const character = createDefaultCharacter('Dossier Test')
    const dossier = composeDossier(character)
    const damage = resolveDamage('Manual Damage', 12, 10, 4, 3, 2)

    expect(dossier.sections.some((section) => section.title === 'Session Snapshot')).toBe(true)
    expect(damage.breakdown.effectiveArmour).toBe(2)
    expect(damage.breakdown.appliedDamage).toBe(7)
  })
})
