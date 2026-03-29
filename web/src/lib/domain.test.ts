import { describe, expect, it } from 'vitest'
import {
  addDetachedWeapon,
  composeDossier,
  createDefaultCharacter,
  parseArmourCompendiumImport,
  parseWeaponCompendiumImport,
  resolveAttackFlow,
  resolveDamage,
  resolveReactionFlow,
  resolveSkillCheck,
  validateOrApplyXPSpend
} from './domain'

describe('rules and safety helpers', () => {
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
    const skill = { ...character.skills[0]!, training: 'trained' as const }
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
