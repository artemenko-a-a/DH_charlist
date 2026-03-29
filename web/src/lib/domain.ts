import {
  Armour,
  ArmourCompendiumCatalog,
  ArmourCompendiumDefinition,
  Character,
  CharacterDossier,
  CharacterHistoryEntry,
  CharacteristicKey,
  CharacteristicSet,
  CombatFlow,
  DamageResult,
  DossierSection,
  EquipmentState,
  MechanicsContribution,
  MechanicsResult,
  Skill,
  SkillTrainingLevel,
  StorageLoadReport,
  TalentUnlock,
  Weapon,
  WeaponCompendiumCatalog,
  WeaponCompendiumDefinition,
  XPPrerequisite,
  XPSpendResult,
  XPUpgrade,
  characteristicOrder,
  trainingOrder
} from './types'

export const characteristicLabels: Record<CharacteristicKey, string> = {
  weaponSkill: 'Weapon Skill',
  ballisticSkill: 'Ballistic Skill',
  strength: 'Strength',
  toughness: 'Toughness',
  agility: 'Agility',
  intelligence: 'Intelligence',
  perception: 'Perception',
  willpower: 'Willpower',
  fellowship: 'Fellowship'
}

export const trainingLabels: Record<SkillTrainingLevel, string> = {
  untrained: 'Untrained',
  known: 'Known',
  trained: 'Trained',
  veteran: 'Veteran'
}

export const trainingModifiers: Record<SkillTrainingLevel, number> = {
  untrained: -20,
  known: 0,
  trained: 10,
  veteran: 20
}

export const demoWeaponCatalog: WeaponCompendiumCatalog = {
  id: 'local-demo',
  displayName: 'Local Demo Catalog',
  definitions: [
    { id: 'local-demo.autogun', catalogID: 'local-demo', name: 'Autogun', type: 'Basic', range: '100m', damage: '1d10+3 I', penetration: '0', clip: '30', reload: 'Half', traits: ['Reliable'], notes: '' },
    { id: 'local-demo.autopistol', catalogID: 'local-demo', name: 'Autopistol', type: 'Pistol', range: '30m', damage: '1d10+2 I', penetration: '0', clip: '18', reload: 'Half', traits: ['Reliable'], notes: '' },
    { id: 'local-demo.chainsword', catalogID: 'local-demo', name: 'Chainsword', type: 'Melee', range: 'Melee', damage: '1d10+2 R', penetration: '2', clip: '-', reload: '-', traits: ['Balanced', 'Tearing'], notes: '' },
    { id: 'local-demo.lasgun', catalogID: 'local-demo', name: 'Lasgun', type: 'Basic', range: '100m', damage: '1d10+3 E', penetration: '0', clip: '60', reload: 'Full', traits: ['Reliable'], notes: '' },
    { id: 'local-demo.laspistol', catalogID: 'local-demo', name: 'Laspistol', type: 'Pistol', range: '30m', damage: '1d10+2 E', penetration: '0', clip: '30', reload: 'Half', traits: ['Reliable'], notes: '' }
  ]
}

export const demoArmourCatalog: ArmourCompendiumCatalog = {
  id: 'local-demo',
  displayName: 'Local Demo Armour Catalog',
  definitions: [
    { id: 'local-demo.carapace-breastplate', catalogID: 'local-demo', name: 'Carapace Breastplate', category: 'Body Armour', coverage: ['Body'], armourPoints: 6, weight: '15kg', availability: 'Very Rare', traits: ['Rigid'], notes: '' },
    { id: 'local-demo.flak-coat', catalogID: 'local-demo', name: 'Flak Coat', category: 'Body Armour', coverage: ['Body', 'Arms'], armourPoints: 4, weight: '8kg', availability: 'Scarce', traits: ['Flak'], notes: '' },
    { id: 'local-demo.guard-helm', catalogID: 'local-demo', name: 'Guard Helm', category: 'Head Armour', coverage: ['Head'], armourPoints: 3, weight: '2kg', availability: 'Common', traits: ['Enclosed'], notes: '' },
    { id: 'local-demo.mesh-vest', catalogID: 'local-demo', name: 'Mesh Vest', category: 'Body Armour', coverage: ['Body'], armourPoints: 5, weight: '5kg', availability: 'Rare', traits: ['Flexible'], notes: '' }
  ]
}

export function createDefaultCharacter(name = 'New Acolyte'): Character {
  const id = crypto.randomUUID()
  return {
    id,
    profile: {
      name,
      homeWorld: '',
      background: '',
      role: '',
      aptitudes: ['Perception'],
      description: ''
    },
    characteristics: {
      weaponSkill: 30,
      ballisticSkill: 30,
      strength: 30,
      toughness: 30,
      agility: 30,
      intelligence: 30,
      perception: 30,
      willpower: 30,
      fellowship: 30
    },
    resources: {
      currentWounds: 10,
      maxWounds: 10,
      fatigue: 0,
      corruption: 0,
      insanity: 0,
      currentFate: 1,
      maxFate: 1,
      experienceSpent: 0,
      experienceTotal: 400
    },
    skills: [
      {
        id: crypto.randomUUID(),
        name: 'Awareness',
        characteristic: 'perception',
        training: 'known',
        specialisations: []
      }
    ],
    notes: {
      talents: [],
      traits: [],
      mutations: [],
      disorders: [],
      psychicPowers: [],
      specialAbilities: [],
      notes: ''
    },
    equipment: {
      weapons: [],
      armour: [],
      movement: { halfMove: 3, fullMove: 6, charge: 9, run: 18 },
      inventory: []
    },
    session: {
      modeEnabled: false,
      pinnedChecks: [],
      temporaryModifiers: {},
      activeWeaponID: null,
      combatConditions: []
    },
    history: [],
    updatedAt: new Date().toISOString()
  }
}

export function normalizeText(value: string, fallback = ''): string {
  const cleaned = value.trim()
  return cleaned.length > 0 ? cleaned : fallback
}

export function normalizedToken(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/-/g, ' ')
    .split(/\s+/)
    .filter(Boolean)
    .join(' ')
}

export function signedValue(value: number): string {
  return value >= 0 ? `+${value}` : `${value}`
}

export function experienceAvailable(character: Character): number {
  return Math.max(0, character.resources.experienceTotal - character.resources.experienceSpent)
}

export function characteristicBonus(value: number): number {
  return Math.floor(value / 10)
}

export function characteristicValue(characteristics: CharacteristicSet, key: CharacteristicKey): number {
  return characteristics[key]
}

export function skillTarget(skill: Skill, characteristics: CharacteristicSet): number {
  return characteristicValue(characteristics, skill.characteristic) + trainingModifiers[skill.training]
}

export function addDetachedWeapon(character: Character, definition: WeaponCompendiumDefinition): Character {
  const detached: Weapon = {
    id: crypto.randomUUID(),
    name: normalizeText(definition.name, 'Unnamed Weapon'),
    type: normalizeText(definition.type),
    range: normalizeText(definition.range),
    damage: normalizeText(definition.damage),
    penetration: normalizeText(definition.penetration),
    clip: normalizeText(definition.clip),
    reload: normalizeText(definition.reload),
    traits: definition.traits.map((item) => item.trim()).filter(Boolean).join(', ')
  }
  return withUpdatedCharacter(character, {
    equipment: {
      ...character.equipment,
      weapons: [...character.equipment.weapons, detached]
    }
  })
}

export function addDetachedArmour(character: Character, definition: ArmourCompendiumDefinition): Character {
  const coverage = definition.coverage.map((item) => item.trim()).filter(Boolean).join(', ')
  const detached: Armour = {
    id: crypto.randomUUID(),
    location: coverage ? `${normalizeText(definition.name, 'Unnamed Armour')} (${coverage})` : normalizeText(definition.name, 'Unnamed Armour'),
    armourPoints: definition.armourPoints
  }
  return withUpdatedCharacter(character, {
    equipment: {
      ...character.equipment,
      armour: [...character.equipment.armour, detached]
    }
  })
}

export function withUpdatedCharacter(character: Character, patch: Partial<Character>): Character {
  return {
    ...character,
    ...patch,
    updatedAt: new Date().toISOString()
  }
}

export function duplicateCharacter(character: Character): Character {
  return {
    ...structuredClone(character),
    id: crypto.randomUUID(),
    profile: {
      ...character.profile,
      name: `${normalizeText(character.profile.name, 'Unnamed Character')} Copy`
    },
    history: [],
    updatedAt: new Date().toISOString()
  }
}

function modifierLabel(value: number): string {
  const standard = [30, 20, 10, 0, -10, -20, -30]
  return standard.includes(value) ? 'Standard Preset' : 'Custom Modifier'
}

function modifierContributions(
  baseModifiers: number[],
  temporaryModifiers: Array<{ label: string; value: number }>
): MechanicsContribution[] {
  const manual = baseModifiers
    .filter((value) => value !== 0)
    .map((value) => ({
      kind: 'modifier' as const,
      label: modifierLabel(value),
      value,
      appliesToFinalTarget: true
    }))

  const temporary = temporaryModifiers
    .filter((item) => item.value !== 0)
    .map((item) => ({
      kind: 'modifier' as const,
      label: item.label,
      value: item.value,
      appliesToFinalTarget: true
    }))

  return [...manual, ...temporary]
}

export function resolveCharacteristicCheck(
  characteristics: CharacteristicSet,
  characteristic: CharacteristicKey,
  modifier = 0,
  temporaryModifiers: Array<{ label: string; value: number }> = [],
  conditions: string[] = []
): MechanicsResult {
  const baseValue = characteristicValue(characteristics, characteristic)
  const derivedBonus = characteristicBonus(baseValue)
  const contributions: MechanicsContribution[] = [
    {
      kind: 'derivedBonus',
      label: 'Derived Bonus',
      value: derivedBonus,
      appliesToFinalTarget: false
    },
    ...modifierContributions([modifier], temporaryModifiers)
  ]
  const appliedModifier = contributions
    .filter((entry) => entry.kind === 'modifier')
    .reduce((sum, entry) => sum + entry.value, 0)
  return {
    checkName: `${characteristicLabels[characteristic]} Check`,
    sourceName: characteristicLabels[characteristic],
    baseValue,
    derivedBonus,
    trainingContribution: null,
    appliedModifier,
    contributions,
    finalTarget: baseValue + appliedModifier,
    conditions
  }
}

export function resolveSkillCheck(
  skill: Skill,
  characteristics: CharacteristicSet,
  modifier = 0,
  temporaryModifiers: Array<{ label: string; value: number }> = [],
  conditions: string[] = []
): MechanicsResult {
  const baseValue = characteristicValue(characteristics, skill.characteristic)
  const derivedBonus = characteristicBonus(baseValue)
  const trainingContribution = trainingModifiers[skill.training]
  const contributions: MechanicsContribution[] = [
    {
      kind: 'derivedBonus',
      label: 'Derived Bonus',
      value: derivedBonus,
      appliesToFinalTarget: false
    },
    {
      kind: 'training',
      label: 'Training Contribution',
      value: trainingContribution,
      appliesToFinalTarget: true
    },
    ...modifierContributions([modifier], temporaryModifiers)
  ]
  const appliedModifier = contributions
    .filter((entry) => entry.kind === 'modifier')
    .reduce((sum, entry) => sum + entry.value, 0)
  return {
    checkName: normalizeText(skill.name, 'Unnamed Skill'),
    sourceName: characteristicLabels[skill.characteristic],
    baseValue,
    derivedBonus,
    trainingContribution,
    appliedModifier,
    contributions,
    finalTarget: baseValue + trainingContribution + appliedModifier,
    conditions
  }
}

function activeWeapon(character: Character): Weapon | null {
  const activeWeaponID = character.session.activeWeaponID
  if (!activeWeaponID) return null
  return character.equipment.weapons.find((weapon) => weapon.id === activeWeaponID) ?? null
}

function normalizedTemporaryModifiers(character: Character): Array<{ label: string; value: number }> {
  return Object.entries(character.session.temporaryModifiers)
    .map(([label, value]) => ({ label: normalizeText(label, 'Unnamed Session Modifier'), value }))
    .sort((left, right) => left.label.localeCompare(right.label))
}

export function resolveAttackFlow(character: Character, additionalModifier = 0): CombatFlow | null {
  const weapon = activeWeapon(character)
  if (!weapon) return null

  const isMelee = normalizedToken(weapon.type) === 'melee'
  const result = resolveCharacteristicCheck(
    character.characteristics,
    isMelee ? 'weaponSkill' : 'ballisticSkill',
    additionalModifier,
    normalizedTemporaryModifiers(character),
    character.session.combatConditions
  )

  return {
    title: isMelee ? 'Melee Attack' : 'Ranged Attack',
    subtitle: isMelee ? 'Weapon Skill attack check' : 'Ballistic Skill attack check',
    weaponName: weapon.name,
    result,
    visibleConditions: character.session.combatConditions,
    pinnedChecks: character.session.pinnedChecks,
    autoAppliedModifiers: [
      ...normalizedTemporaryModifiers(character),
      ...(additionalModifier !== 0 ? [{ label: modifierLabel(additionalModifier), value: additionalModifier }] : [])
    ]
  }
}

export function resolveReactionFlow(
  character: Character,
  reaction: 'dodge' | 'parry',
  additionalModifier = 0
): CombatFlow {
  const matchedSkill = character.skills.find((skill) => normalizedToken(skill.name) === reaction)
  const fallback: Skill =
    matchedSkill ??
    {
      id: `canonical-${reaction}`,
      name: reaction === 'dodge' ? 'Dodge' : 'Parry',
      characteristic: reaction === 'dodge' ? 'agility' : 'weaponSkill',
      training: 'untrained',
      specialisations: []
    }
  const result = resolveSkillCheck(
    fallback,
    character.characteristics,
    additionalModifier,
    normalizedTemporaryModifiers(character),
    character.session.combatConditions
  )
  return {
    title: reaction === 'dodge' ? 'Dodge' : 'Parry',
    subtitle: reaction === 'dodge' ? 'Agility reaction check' : 'Weapon Skill reaction check',
    weaponName: activeWeapon(character)?.name ?? null,
    result,
    visibleConditions: character.session.combatConditions,
    pinnedChecks: character.session.pinnedChecks,
    autoAppliedModifiers: [
      ...normalizedTemporaryModifiers(character),
      ...(additionalModifier !== 0 ? [{ label: modifierLabel(additionalModifier), value: additionalModifier }] : [])
    ]
  }
}

export function resolveDamage(
  sourceLabel: string,
  rawDamage: number,
  targetWounds: number,
  targetArmour: number,
  targetToughnessBonus: number,
  penetration = 0
): DamageResult {
  const safeRaw = Math.max(0, rawDamage)
  const safeWounds = Math.max(0, targetWounds)
  const safeArmour = Math.max(0, targetArmour)
  const safePenetration = Math.max(0, penetration)
  const safeToughness = Math.max(0, targetToughnessBonus)
  const effectiveArmour = Math.max(0, safeArmour - safePenetration)
  const totalMitigation = effectiveArmour + safeToughness
  const appliedDamage = Math.max(0, safeRaw - totalMitigation)
  const woundsAfter = Math.max(0, safeWounds - appliedDamage)
  const overflowDamage = Math.max(0, appliedDamage - safeWounds)

  return {
    sourceLabel: normalizeText(sourceLabel, 'Manual Damage'),
    breakdown: {
      rawDamage: safeRaw,
      penetration: safePenetration,
      effectiveArmour,
      toughnessBonus: safeToughness,
      totalMitigation,
      appliedDamage,
      woundsBefore: safeWounds,
      woundsAfter,
      overflowDamage
    }
  }
}

function prerequisiteLabel(prerequisite: XPPrerequisite): string {
  switch (prerequisite.kind) {
    case 'availableExperience':
      return `Available XP ${prerequisite.required}+`
    case 'minimumCharacteristic':
      return `${characteristicLabels[prerequisite.characteristic]} ${prerequisite.value}+`
    case 'requiredSkill':
      return `${normalizeText(prerequisite.name, 'Unnamed Skill')} ${trainingLabels[prerequisite.minimumTraining]}+`
    case 'requiredAptitude':
      return `Aptitude: ${normalizeText(prerequisite.value, 'Unnamed Aptitude')}`
    case 'requiredTalent':
      return `Talent: ${normalizeText(prerequisite.value, 'Unnamed Talent')}`
    case 'requiredTrait':
      return `Trait: ${normalizeText(prerequisite.value, 'Unnamed Trait')}`
  }
}

function evaluatePrerequisite(character: Character, prerequisite: XPPrerequisite) {
  switch (prerequisite.kind) {
    case 'availableExperience': {
      const available = experienceAvailable(character)
      return {
        label: prerequisiteLabel(prerequisite),
        isSatisfied: available >= prerequisite.required,
        detail: `${available} XP currently available.`
      }
    }
    case 'minimumCharacteristic': {
      const currentValue = character.characteristics[prerequisite.characteristic]
      return {
        label: prerequisiteLabel(prerequisite),
        isSatisfied: currentValue >= prerequisite.value,
        detail: `${characteristicLabels[prerequisite.characteristic]} is currently ${currentValue}.`
      }
    }
    case 'requiredSkill': {
      const matched = character.skills.find((skill) => normalizedToken(skill.name) === normalizedToken(prerequisite.name))
      const currentTraining = matched?.training ?? 'untrained'
      return {
        label: prerequisiteLabel(prerequisite),
        isSatisfied: trainingOrder.indexOf(currentTraining) >= trainingOrder.indexOf(prerequisite.minimumTraining),
        detail: `${normalizeText(prerequisite.name, 'Unnamed Skill')} is currently ${trainingLabels[currentTraining]}.`
      }
    }
    case 'requiredAptitude': {
      const required = normalizeText(prerequisite.value, 'Unnamed Aptitude')
      const hasIt = character.profile.aptitudes.some((item) => normalizedToken(item) === normalizedToken(required))
      return {
        label: prerequisiteLabel(prerequisite),
        isSatisfied: hasIt,
        detail: hasIt ? `Character already has ${required}.` : `${required} is not listed on the profile.`
      }
    }
    case 'requiredTalent': {
      const required = normalizeText(prerequisite.value, 'Unnamed Talent')
      const hasIt = character.notes.talents.some((item) => normalizedToken(item) === normalizedToken(required))
      return {
        label: prerequisiteLabel(prerequisite),
        isSatisfied: hasIt,
        detail: hasIt ? `Character already knows ${required}.` : `${required} is not present in talents.`
      }
    }
    case 'requiredTrait': {
      const required = normalizeText(prerequisite.value, 'Unnamed Trait')
      const hasIt = character.notes.traits.some((item) => normalizedToken(item) === normalizedToken(required))
      return {
        label: prerequisiteLabel(prerequisite),
        isSatisfied: hasIt,
        detail: hasIt ? `Character already has ${required}.` : `${required} is not present in traits.`
      }
    }
  }
}

export function validateOrApplyXPSpend(character: Character, upgrade: XPUpgrade, apply: boolean): XPSpendResult {
  const cost = Math.max(0, upgrade.cost)
  const available = experienceAvailable(character)
  const prerequisites: XPPrerequisite[] = [{ kind: 'availableExperience', required: cost }, ...upgrade.prerequisites]
  const prerequisiteEvaluations = prerequisites.map((item) => evaluatePrerequisite(character, item))
  const validationErrors: string[] = []

  if (upgrade.kind === 'characteristicAdvance') {
    if (upgrade.delta <= 0) validationErrors.push('Characteristic advances must increase the selected characteristic.')
    if (upgrade.cost < 0) validationErrors.push('XP cost cannot be negative.')
  }

  if (upgrade.kind === 'skillAdvance') {
    const currentSkill = character.skills.find((skill) => skill.id === upgrade.skillID)
    if (upgrade.cost < 0) validationErrors.push('XP cost cannot be negative.')
    if (!currentSkill) {
      validationErrors.push('The selected skill no longer exists on this character.')
    } else if (trainingOrder.indexOf(currentSkill.training) >= trainingOrder.indexOf(upgrade.targetTraining)) {
      validationErrors.push('Skill advances must move to a higher training level than the character already has.')
    }
  }

  if (upgrade.kind === 'talentUnlock') {
    if (upgrade.cost < 0) validationErrors.push('XP cost cannot be negative.')
    const talentName = normalizeText(upgrade.talentName, 'Unnamed Talent')
    if (talentName === 'Unnamed Talent') {
      validationErrors.push('Talent unlocks require a talent name.')
    } else if (character.notes.talents.some((item) => normalizedToken(item) === normalizedToken(talentName))) {
      validationErrors.push('Talent unlocks must add a talent the character does not already know.')
    }
  }

  for (const evaluation of prerequisiteEvaluations) {
    if (!evaluation.isSatisfied) {
      validationErrors.push(evaluation.label.startsWith('Available XP')
        ? `Requires ${cost} XP but only ${available} XP is currently available.`
        : `Requirement not met: ${evaluation.label}.`)
    }
  }

  if (!apply || validationErrors.length > 0) {
    return {
      isValid: validationErrors.length === 0,
      cost,
      availableExperience: available,
      projectedRemainingExperience: available - cost,
      validationErrors,
      prerequisiteEvaluations,
      appliedCharacter: null,
      historyTitle: null,
      historyBody: null
    }
  }

  const updated = structuredClone(character)
  if (upgrade.kind === 'characteristicAdvance') {
    updated.characteristics[upgrade.characteristic] += upgrade.delta
  } else if (upgrade.kind === 'skillAdvance') {
    const index = updated.skills.findIndex((skill) => skill.id === upgrade.skillID)
    if (index >= 0) updated.skills[index] = { ...updated.skills[index], training: upgrade.targetTraining }
  } else if (upgrade.kind === 'talentUnlock') {
    updated.notes.talents = [...updated.notes.talents, normalizeText(upgrade.talentName, 'Unnamed Talent')]
  }

  updated.resources.experienceSpent += cost
  const historyTitle = `Advancement: ${xpUpgradeSummary(upgrade)}`
  const historyBody = [
    `Spent ${cost} XP on ${xpUpgradeSummary(upgrade)}.`,
    `Available before: ${available} XP.`,
    `Available after: ${available - cost} XP.`
  ].join('\n')
  const entry: CharacterHistoryEntry = {
    id: crypto.randomUUID(),
    characterID: updated.id,
    createdAt: new Date().toISOString(),
    title: historyTitle,
    type: 'advancement',
    body: historyBody,
    tags: ['xp']
  }
  updated.history = [entry, ...updated.history]
  updated.updatedAt = new Date().toISOString()

  return {
    isValid: true,
    cost,
    availableExperience: available,
    projectedRemainingExperience: available - cost,
    validationErrors: [],
    prerequisiteEvaluations,
    appliedCharacter: updated,
    historyTitle,
    historyBody
  }
}

export function xpUpgradeSummary(upgrade: XPUpgrade): string {
  if (upgrade.kind === 'characteristicAdvance') {
    return `${characteristicLabels[upgrade.characteristic]} ${signedValue(upgrade.delta)}`
  }
  if (upgrade.kind === 'skillAdvance') {
    return `${normalizeText(upgrade.skillName, 'Unnamed Skill')} to ${trainingLabels[upgrade.targetTraining]}`
  }
  return `Talent: ${normalizeText((upgrade as TalentUnlock).talentName, 'Unnamed Talent')}`
}

export function weaponAutocomplete(definitions: WeaponCompendiumDefinition[], query: string, limit = 8): WeaponCompendiumDefinition[] {
  const normalizedQuery = normalizedToken(query)
  if (!normalizedQuery) return []
  return definitions
    .map((definition) => ({
      definition,
      normalizedName: normalizedToken(definition.name)
    }))
    .filter(({ normalizedName }) => normalizedName.includes(normalizedQuery))
    .sort((left, right) => {
      const leftRank = left.normalizedName === normalizedQuery ? 0 : left.normalizedName.startsWith(normalizedQuery) ? 1 : 2
      const rightRank = right.normalizedName === normalizedQuery ? 0 : right.normalizedName.startsWith(normalizedQuery) ? 1 : 2
      if (leftRank !== rightRank) return leftRank - rightRank
      if (left.definition.name.length !== right.definition.name.length) {
        return left.definition.name.length - right.definition.name.length
      }
      return left.definition.name.localeCompare(right.definition.name)
    })
    .slice(0, limit)
    .map(({ definition }) => definition)
}

export const armourAutocomplete = (definitions: ArmourCompendiumDefinition[], query: string, limit = 8) =>
  weaponAutocomplete(definitions as never, query, limit) as unknown as ArmourCompendiumDefinition[]

export function parseWeaponCompendiumImport(payload: string):
  | { ok: true; catalog: WeaponCompendiumCatalog; summary: string }
  | { ok: false; error: string } {
  let parsed: unknown
  try {
    parsed = JSON.parse(payload)
  } catch {
    return { ok: false, error: 'Weapon compendium import failed: malformed JSON or unsupported file structure.' }
  }

  if (!isRecord(parsed) || parsed.schemaVersion !== 1 || !isRecord(parsed.catalog)) {
    if (isRecord(parsed) && typeof parsed.schemaVersion === 'number' && parsed.schemaVersion !== 1) {
      return { ok: false, error: `Weapon compendium import failed: unsupported schema version ${parsed.schemaVersion}.` }
    }
    return { ok: false, error: 'Weapon compendium import failed: malformed JSON or unsupported file structure.' }
  }

  const catalogID = normalizeText(asString(parsed.catalog.id))
  const displayName = normalizeText(asString(parsed.catalog.displayName))
  const definitions = Array.isArray(parsed.catalog.definitions) ? parsed.catalog.definitions : null
  if (!catalogID) return { ok: false, error: 'Weapon compendium import failed: catalog id is required.' }
  if (!displayName) return { ok: false, error: 'Weapon compendium import failed: catalog display name is required.' }
  if (!definitions) return { ok: false, error: 'Weapon compendium import failed: malformed JSON or unsupported file structure.' }

  const seen = new Set<string>()
  const duplicates = new Set<string>()
  const mapped: WeaponCompendiumDefinition[] = []
  for (const [index, item] of definitions.entries()) {
    if (!isRecord(item)) return { ok: false, error: 'Weapon compendium import failed: malformed JSON or unsupported file structure.' }
    const id = normalizeText(asString(item.id))
    const name = normalizeText(asString(item.name))
    if (!id) return { ok: false, error: `Weapon compendium import failed: definition #${index + 1} is missing an id.` }
    if (!name) return { ok: false, error: `Weapon compendium import failed: definition #${index + 1} is missing a name.` }
    const lower = id.toLowerCase()
    if (seen.has(lower)) duplicates.add(id)
    seen.add(lower)
    mapped.push({
      id,
      catalogID,
      name,
      type: normalizeText(asString(item.type)),
      range: normalizeText(asString(item.range)),
      damage: normalizeText(asString(item.damage)),
      penetration: normalizeText(asString(item.penetration)),
      clip: normalizeText(asString(item.clip)),
      reload: normalizeText(asString(item.reload)),
      traits: asStringArray(item.traits),
      notes: normalizeText(asString(item.notes))
    })
  }
  if (duplicates.size > 0) {
    return { ok: false, error: `Weapon compendium import failed: duplicate definition ids found (${[...duplicates].sort().join(', ')}).` }
  }
  const catalog = { id: catalogID, displayName, definitions: mapped }
  return {
    ok: true,
    catalog,
    summary: [
      `Imported catalog "${displayName}" contains ${mapped.length} ${mapped.length === 1 ? 'weapon definition' : 'weapon definitions'}.`,
      'This replaces your current local compendium; it does not merge.',
      'Future autocomplete and add-weapon prefills will use the imported catalog.',
      'Existing character-owned weapons stay detached and unchanged.',
      'This action is destructive for the current local compendium.'
    ].join(' ')
  }
}

export function parseArmourCompendiumImport(payload: string):
  | { ok: true; catalog: ArmourCompendiumCatalog; summary: string }
  | { ok: false; error: string } {
  let parsed: unknown
  try {
    parsed = JSON.parse(payload)
  } catch {
    return { ok: false, error: 'Armour compendium import failed: malformed JSON or unsupported file structure.' }
  }

  if (!isRecord(parsed) || parsed.schemaVersion !== 1 || !isRecord(parsed.catalog)) {
    if (isRecord(parsed) && typeof parsed.schemaVersion === 'number' && parsed.schemaVersion !== 1) {
      return { ok: false, error: `Armour compendium import failed: unsupported schema version ${parsed.schemaVersion}.` }
    }
    return { ok: false, error: 'Armour compendium import failed: malformed JSON or unsupported file structure.' }
  }

  const catalogID = normalizeText(asString(parsed.catalog.id))
  const displayName = normalizeText(asString(parsed.catalog.displayName))
  const definitions = Array.isArray(parsed.catalog.definitions) ? parsed.catalog.definitions : null
  if (!catalogID) return { ok: false, error: 'Armour compendium import failed: catalog id is required.' }
  if (!displayName) return { ok: false, error: 'Armour compendium import failed: catalog display name is required.' }
  if (!definitions) return { ok: false, error: 'Armour compendium import failed: malformed JSON or unsupported file structure.' }

  const seen = new Set<string>()
  const duplicates = new Set<string>()
  const mapped: ArmourCompendiumDefinition[] = []
  for (const [index, item] of definitions.entries()) {
    if (!isRecord(item)) return { ok: false, error: 'Armour compendium import failed: malformed JSON or unsupported file structure.' }
    const id = normalizeText(asString(item.id))
    const name = normalizeText(asString(item.name))
    const armourPoints = typeof item.armourPoints === 'number' ? item.armourPoints : null
    if (!id) return { ok: false, error: `Armour compendium import failed: definition #${index + 1} is missing an id.` }
    if (!name) return { ok: false, error: `Armour compendium import failed: definition #${index + 1} is missing a name.` }
    if (armourPoints === null || armourPoints < 0) {
      return { ok: false, error: `Armour compendium import failed: definition #${index + 1} is missing valid armour points.` }
    }
    const lower = id.toLowerCase()
    if (seen.has(lower)) duplicates.add(id)
    seen.add(lower)
    mapped.push({
      id,
      catalogID,
      name,
      category: normalizeText(asString(item.category)),
      coverage: asStringArray(item.coverage),
      armourPoints,
      weight: normalizeText(asString(item.weight)),
      availability: normalizeText(asString(item.availability)),
      traits: asStringArray(item.traits),
      notes: normalizeText(asString(item.notes))
    })
  }
  if (duplicates.size > 0) {
    return { ok: false, error: `Armour compendium import failed: duplicate definition ids found (${[...duplicates].sort().join(', ')}).` }
  }
  const catalog = { id: catalogID, displayName, definitions: mapped }
  return {
    ok: true,
    catalog,
    summary: [
      `Imported catalog "${displayName}" contains ${mapped.length} ${mapped.length === 1 ? 'armour definition' : 'armour definitions'}.`,
      'This replaces your current local armour compendium; it does not merge.',
      'Future autocomplete and add-armour prefills will use the imported catalog.',
      'Existing character-owned armour stays detached and unchanged.',
      'This action is destructive for the current local armour compendium.'
    ].join(' ')
  }
}

export function composeDossier(character: Character): CharacterDossier {
  const title = normalizeText(character.profile.name, 'Unnamed Character')
  const subtitleParts = [character.profile.homeWorld, character.profile.background, character.profile.role]
    .map((item) => normalizeText(item))
    .filter(Boolean)
  const sections: DossierSection[] = [
    {
      title: 'Identity',
      subtitle: 'Profile and dossier summary',
      fields: [
        { label: 'Name', value: title },
        { label: 'Home World', value: normalizeText(character.profile.homeWorld, '—') },
        { label: 'Background', value: normalizeText(character.profile.background, '—') },
        { label: 'Role', value: normalizeText(character.profile.role, '—') },
        ...(character.profile.aptitudes.length > 0 ? [{ label: 'Aptitudes', value: character.profile.aptitudes.join(', ') }] : [])
      ],
      paragraphs: character.profile.description ? [character.profile.description] : [],
      bullets: []
    },
    {
      title: 'Characteristics',
      subtitle: 'Core thresholds and bonuses',
      fields: characteristicOrder.map((key) => ({
        label: characteristicLabels[key],
        value: `${character.characteristics[key]} (Bonus ${characteristicBonus(character.characteristics[key])})`
      })),
      paragraphs: [],
      bullets: []
    },
    {
      title: 'Resources',
      subtitle: 'Condition, fate, and experience',
      fields: [
        { label: 'Wounds', value: `${character.resources.currentWounds} / ${character.resources.maxWounds}` },
        { label: 'Fatigue', value: `${character.resources.fatigue}` },
        { label: 'Corruption', value: `${character.resources.corruption}` },
        { label: 'Insanity', value: `${character.resources.insanity}` },
        { label: 'Fate', value: `${character.resources.currentFate} / ${character.resources.maxFate}` },
        {
          label: 'Experience',
          value: `${character.resources.experienceSpent} spent / ${character.resources.experienceTotal} total / ${experienceAvailable(character)} available`
        }
      ],
      paragraphs: [],
      bullets: []
    }
  ]

  if (character.skills.length > 0) {
    sections.push({
      title: 'Skills',
      subtitle: `Operational competencies (${character.skills.length})`,
      fields: character.skills
        .slice()
        .sort((left, right) => left.name.localeCompare(right.name))
        .map((skill) => ({
          label: normalizeText(skill.name, 'Unnamed Skill'),
          value: [
            characteristicLabels[skill.characteristic],
            `${trainingLabels[skill.training]} (${signedValue(trainingModifiers[skill.training])})`,
            `Target ${skillTarget(skill, character.characteristics)}`,
            ...(skill.specialisations.length > 0 ? [`Specialisations: ${skill.specialisations.join(', ')}`] : [])
          ].join(' · ')
        })),
      paragraphs: [],
      bullets: []
    })
  }

  const noteFields = [
    ['Talents', character.notes.talents],
    ['Traits', character.notes.traits],
    ['Mutations', character.notes.mutations],
    ['Disorders', character.notes.disorders],
    ['Psychic Powers', character.notes.psychicPowers],
    ['Special Abilities', character.notes.specialAbilities]
  ].filter((entry): entry is [string, string[]] => entry[1].length > 0)

  if (noteFields.length > 0 || character.notes.notes.trim()) {
    sections.push({
      title: 'Notes and Abilities',
      subtitle: 'Traits, powers, and narrative context',
      fields: noteFields.map(([label, values]) => ({ label, value: values.join(', ') })),
      paragraphs: character.notes.notes.trim() ? [character.notes.notes.trim()] : [],
      bullets: []
    })
  }

  const equipmentFields = []
  if (character.equipment.movement.halfMove || character.equipment.movement.fullMove || character.equipment.movement.charge || character.equipment.movement.run) {
    equipmentFields.push({
      label: 'Movement',
      value: `Half ${character.equipment.movement.halfMove} · Full ${character.equipment.movement.fullMove} · Charge ${character.equipment.movement.charge} · Run ${character.equipment.movement.run}`
    })
  }
  equipmentFields.push(
    ...character.equipment.weapons.map((weapon) => ({
      label: normalizeText(weapon.name, 'Unnamed Weapon'),
      value: [weapon.type, weapon.range && `Range ${weapon.range}`, weapon.damage && `Damage ${weapon.damage}`, weapon.penetration && `Pen ${weapon.penetration}`, weapon.clip && `Clip ${weapon.clip}`, weapon.reload && `Reload ${weapon.reload}`, weapon.traits && `Traits ${weapon.traits}`]
        .filter(Boolean)
        .join(' · ')
    })),
    ...character.equipment.armour.map((armour) => ({
      label: normalizeText(armour.location, 'Armour'),
      value: `AP ${armour.armourPoints}`
    })),
    ...character.equipment.inventory.map((item) => ({
      label: normalizeText(item.name, 'Inventory Item'),
      value: [`Qty ${item.quantity}`, ...(item.weight > 0 ? [`Weight ${item.weight} kg`] : [])].join(' · ')
    }))
  )
  if (equipmentFields.length > 0) {
    sections.push({
      title: 'Equipment',
      subtitle: 'Loadout, armour, and carried items',
      fields: equipmentFields,
      paragraphs: [],
      bullets: []
    })
  }

  sections.push({
    title: 'Session Snapshot',
    subtitle: 'Current session and combat context',
    fields: [
      { label: 'Mode', value: character.session.modeEnabled ? 'Active' : 'Standby' },
      { label: 'Active Weapon', value: activeWeapon(character)?.name ?? 'None' },
      { label: 'Pinned Checks', value: character.session.pinnedChecks.join(', ') || 'None' },
      {
        label: 'Temporary Modifiers',
        value: Object.entries(character.session.temporaryModifiers)
          .sort(([left], [right]) => left.localeCompare(right))
          .map(([label, value]) => `${label}: ${signedValue(value)}`)
          .join(', ') || 'None'
      },
      { label: 'Combat Conditions', value: character.session.combatConditions.join(', ') || 'None' }
    ],
    paragraphs: [],
    bullets: []
  })

  if (character.history.length > 0) {
    sections.push({
      title: 'Recent History',
      subtitle: 'Newest entries first',
      fields: [],
      paragraphs: [],
      bullets: character.history
        .slice()
        .sort((left, right) => right.createdAt.localeCompare(left.createdAt))
        .slice(0, 5)
        .map((entry) => `${entry.title} (${entry.type})${entry.body ? ` — ${entry.body.split('\n')[0]}` : ''}`)
    })
  }

  return {
    title,
    subtitle: subtitleParts.length > 0 ? subtitleParts.join(' · ') : 'Dark Heresy II Character Dossier',
    metadataLine: `Updated ${new Date(character.updatedAt).toLocaleString()}`,
    filenameStem: `dh-dossier-${normalizedToken(title).replace(/ /g, '-') || 'unnamed-character'}-${character.id.slice(0, 8)}`,
    sections
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

function asString(value: unknown): string {
  return typeof value === 'string' ? value : ''
}

function asStringArray(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string').map((item) => item.trim()).filter(Boolean) : []
}

function clampNumber(value: unknown, fallback = 0): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback
}

function migratedCharacteristics(record: Record<string, unknown>): CharacteristicSet {
  const source = isRecord(record.characteristics) ? record.characteristics : record
  return {
    weaponSkill: clampNumber(source.weaponSkill ?? source.ws, 30),
    ballisticSkill: clampNumber(source.ballisticSkill ?? source.bs, 30),
    strength: clampNumber(source.strength ?? source.s, 30),
    toughness: clampNumber(source.toughness ?? source.t, 30),
    agility: clampNumber(source.agility ?? source.ag, 30),
    intelligence: clampNumber(source.intelligence ?? source.int, 30),
    perception: clampNumber(source.perception ?? source.per, 30),
    willpower: clampNumber(source.willpower ?? source.wp, 30),
    fellowship: clampNumber(source.fellowship ?? source.fel, 30)
  }
}

export function coerceCharacter(value: unknown): Character | null {
  if (!isRecord(value)) return null

  const id = normalizeText(asString(value.id))
  if (!id) return null

  const profileSource = isRecord(value.profile) ? value.profile : value
  const resourcesSource = isRecord(value.resources) ? value.resources : value
  const notesSource = isRecord(value.notes) ? value.notes : value
  const equipmentSource = isRecord(value.equipment) ? value.equipment : value
  const sessionSource = isRecord(value.session) ? value.session : value

  const skillsSource = Array.isArray(value.skills) ? value.skills : []
  const skills: Skill[] = skillsSource
    .map((item) => {
      if (!isRecord(item)) return null
      const name = normalizeText(asString(item.name))
      const characteristic = (characteristicOrder as readonly string[]).includes(asString(item.characteristic))
        ? (item.characteristic as CharacteristicKey)
        : 'perception'
      const training = (trainingOrder as readonly string[]).includes(asString(item.training))
        ? (item.training as SkillTrainingLevel)
        : 'untrained'
      return {
        id: normalizeText(asString(item.id), crypto.randomUUID()),
        name: name || 'Unnamed Skill',
        characteristic,
        training,
        specialisations: asStringArray(item.specialisations)
      }
    })
    .filter((item): item is Skill => item !== null)

  const weaponsSource = Array.isArray(equipmentSource.weapons ?? value.weapons) ? (equipmentSource.weapons ?? value.weapons) as unknown[] : []
  const armourSource = Array.isArray(equipmentSource.armour ?? value.armour) ? (equipmentSource.armour ?? value.armour) as unknown[] : []
  const inventorySource = Array.isArray(equipmentSource.inventory) ? equipmentSource.inventory as unknown[] : []
  const historySource = Array.isArray(value.history) ? value.history : []

  return {
    id,
    profile: {
      name: asString(profileSource.name),
      homeWorld: asString(profileSource.homeWorld),
      background: asString(profileSource.background),
      role: asString(profileSource.role),
      aptitudes: asStringArray(profileSource.aptitudes),
      description: asString(profileSource.description)
    },
    characteristics: migratedCharacteristics(value),
    resources: {
      currentWounds: clampNumber(resourcesSource.currentWounds ?? resourcesSource.wounds, 10),
      maxWounds: clampNumber(resourcesSource.maxWounds ?? resourcesSource.wounds, 10),
      fatigue: clampNumber(resourcesSource.fatigue, 0),
      corruption: clampNumber(resourcesSource.corruption, 0),
      insanity: clampNumber(resourcesSource.insanity, 0),
      currentFate: clampNumber(resourcesSource.currentFate, 1),
      maxFate: clampNumber(resourcesSource.maxFate, 1),
      experienceSpent: clampNumber(resourcesSource.experienceSpent, 0),
      experienceTotal: clampNumber(resourcesSource.experienceTotal ?? resourcesSource.xpAvailable, 400)
    },
    skills,
    notes: {
      talents: asStringArray(notesSource.talents),
      traits: asStringArray(notesSource.traits),
      mutations: asStringArray(notesSource.mutations),
      disorders: asStringArray(notesSource.disorders),
      psychicPowers: asStringArray(notesSource.psychicPowers),
      specialAbilities: asStringArray(notesSource.specialAbilities),
      notes: asString(notesSource.notes)
    },
    equipment: {
      weapons: weaponsSource
        .map((item) => {
          if (!isRecord(item)) return null
          return {
            id: normalizeText(asString(item.id), crypto.randomUUID()),
            name: asString(item.name),
            type: asString(item.type),
            range: asString(item.range),
            damage: asString(item.damage),
            penetration: asString(item.penetration),
            clip: asString(item.clip),
            reload: asString(item.reload),
            traits: asString(item.traits)
          }
        })
        .filter((item): item is Weapon => item !== null),
      armour: armourSource
        .map((item) => {
          if (!isRecord(item)) return null
          return {
            id: normalizeText(asString(item.id), crypto.randomUUID()),
            location: asString(item.location),
            armourPoints: clampNumber(item.armourPoints ?? item.ap, 0)
          }
        })
        .filter((item): item is Armour => item !== null),
      movement: {
        halfMove: clampNumber(isRecord(equipmentSource.movement) ? equipmentSource.movement.halfMove : undefined, 0),
        fullMove: clampNumber(isRecord(equipmentSource.movement) ? equipmentSource.movement.fullMove : undefined, 0),
        charge: clampNumber(isRecord(equipmentSource.movement) ? equipmentSource.movement.charge : undefined, 0),
        run: clampNumber(isRecord(equipmentSource.movement) ? equipmentSource.movement.run : undefined, 0)
      },
      inventory: inventorySource
        .map((item) => {
          if (!isRecord(item)) return null
          return {
            id: normalizeText(asString(item.id), crypto.randomUUID()),
            name: asString(item.name),
            quantity: clampNumber(item.quantity, 1),
            weight: clampNumber(item.weight, 0)
          }
        })
        .filter((item): item is EquipmentState['inventory'][number] => item !== null)
    },
    session: {
      modeEnabled: Boolean(sessionSource.modeEnabled),
      pinnedChecks: asStringArray(sessionSource.pinnedChecks),
      temporaryModifiers: isRecord(sessionSource.temporaryModifiers)
        ? Object.fromEntries(Object.entries(sessionSource.temporaryModifiers).map(([key, item]) => [key, clampNumber(item, 0)]))
        : {},
      activeWeaponID: normalizeText(asString(sessionSource.activeWeaponID)) || null,
      combatConditions: asStringArray(sessionSource.combatConditions)
    },
    history: historySource
      .map((item) => {
        if (!isRecord(item)) return null
        return {
          id: normalizeText(asString(item.id), crypto.randomUUID()),
          characterID: normalizeText(asString(item.characterID), id),
          createdAt: normalizeText(asString(item.createdAt), new Date().toISOString()),
          title: normalizeText(asString(item.title), 'Untitled Entry'),
          type: 'sessionNote',
          body: asString(item.body),
          tags: asStringArray(item.tags)
        }
      })
      .filter((item): item is CharacterHistoryEntry => item !== null),
    updatedAt: normalizeText(asString(value.updatedAt), new Date().toISOString())
  }
}
