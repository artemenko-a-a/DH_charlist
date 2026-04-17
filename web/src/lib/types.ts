export const characteristicOrder = [
  'weaponSkill',
  'ballisticSkill',
  'strength',
  'toughness',
  'agility',
  'intelligence',
  'perception',
  'willpower',
  'fellowship'
] as const

export type CharacteristicKey = (typeof characteristicOrder)[number]

export const trainingOrder = ['untrained', 'known', 'trained', 'experienced', 'veteran'] as const
export type SkillTrainingLevel = (typeof trainingOrder)[number]

export const historyEntryTypes = [
  'sessionNote',
  'advancement',
  'injury',
  'corruptionOrInsanity',
  'equipmentChange',
  'storyNote',
  'custom'
] as const

export type CharacterHistoryEntryType = (typeof historyEntryTypes)[number]

export type Profile = {
  name: string
  homeWorld: string
  background: string
  role: string
  aptitudes: string[]
  description: string
}

export type CharacteristicSet = Record<CharacteristicKey, number>

export type ResourceState = {
  currentWounds: number
  maxWounds: number
  fatigue: number
  corruption: number
  insanity: number
  currentFate: number
  maxFate: number
  experienceSpent: number
  experienceTotal: number
}

export type Skill = {
  id: string
  name: string
  characteristic: CharacteristicKey
  training: SkillTrainingLevel
  specialisations: string[]
}

export type NotesState = {
  talents: string[]
  traits: string[]
  mutations: string[]
  disorders: string[]
  psychicPowers: string[]
  specialAbilities: string[]
  notes: string
}

export type Weapon = {
  id: string
  name: string
  type: string
  range: string
  damage: string
  penetration: string
  clip: string
  reload: string
  traits: string
}

export type Armour = {
  id: string
  location: string
  armourPoints: number
}

export type MovementProfile = {
  halfMove: number
  fullMove: number
  charge: number
  run: number
}

export type InventoryItem = {
  id: string
  name: string
  quantity: number
  weight: number
}

export type EquipmentState = {
  weapons: Weapon[]
  armour: Armour[]
  movement: MovementProfile
  inventory: InventoryItem[]
}

export type SessionState = {
  modeEnabled: boolean
  pinnedChecks: string[]
  temporaryModifiers: Record<string, number>
  activeWeaponID: string | null
  combatConditions: string[]
}

export type CharacterHistoryEntry = {
  id: string
  characterID: string
  createdAt: string
  title: string
  type: CharacterHistoryEntryType
  body: string
  tags: string[]
}

export type Character = {
  id: string
  profile: Profile
  characteristics: CharacteristicSet
  resources: ResourceState
  skills: Skill[]
  notes: NotesState
  equipment: EquipmentState
  session: SessionState
  history: CharacterHistoryEntry[]
  updatedAt: string
}

export type WeaponCompendiumDefinition = {
  id: string
  catalogID: string
  name: string
  type: string
  range: string
  damage: string
  penetration: string
  clip: string
  reload: string
  traits: string[]
  notes: string
}

export type WeaponCompendiumCatalog = {
  id: string
  displayName: string
  definitions: WeaponCompendiumDefinition[]
}

export type ArmourCompendiumDefinition = {
  id: string
  catalogID: string
  name: string
  category: string
  coverage: string[]
  armourPoints: number
  weight: string
  availability: string
  traits: string[]
  notes: string
}

export type ArmourCompendiumCatalog = {
  id: string
  displayName: string
  definitions: ArmourCompendiumDefinition[]
}

export type StorageLoadReport = {
  characters: Character[]
  weaponCatalog: WeaponCompendiumCatalog
  armourCatalog: ArmourCompendiumCatalog
  warnings: string[]
}

export type MechanicsContribution = {
  kind: 'derivedBonus' | 'training' | 'modifier'
  label: string
  value: number
  appliesToFinalTarget: boolean
}

export type MechanicsResult = {
  checkName: string
  sourceName: string
  baseValue: number
  derivedBonus: number
  trainingContribution: number | null
  appliedModifier: number
  contributions: MechanicsContribution[]
  finalTarget: number
  conditions: string[]
}

export type CombatFlow = {
  title: string
  subtitle: string
  weaponName: string | null
  result: MechanicsResult
  visibleConditions: string[]
  pinnedChecks: string[]
  autoAppliedModifiers: Array<{ label: string; value: number }>
}

export type DamageBreakdown = {
  rawDamage: number
  penetration: number
  effectiveArmour: number
  toughnessBonus: number
  totalMitigation: number
  appliedDamage: number
  woundsBefore: number
  woundsAfter: number
  overflowDamage: number
}

export type DamageResult = {
  sourceLabel: string
  breakdown: DamageBreakdown
}

export type XPPrerequisite =
  | { kind: 'availableExperience'; required: number }
  | { kind: 'minimumCharacteristic'; characteristic: CharacteristicKey; value: number }
  | { kind: 'requiredSkill'; name: string; minimumTraining: SkillTrainingLevel }
  | { kind: 'requiredAptitude'; value: string }
  | { kind: 'requiredTalent'; value: string }
  | { kind: 'requiredTrait'; value: string }

export type CharacteristicAdvance = {
  kind: 'characteristicAdvance'
  characteristic: CharacteristicKey
  delta: number
  cost: number
  prerequisites: XPPrerequisite[]
}

export type SkillAdvance = {
  kind: 'skillAdvance'
  skillID: string
  skillName: string
  targetTraining: SkillTrainingLevel
  cost: number
  prerequisites: XPPrerequisite[]
}

export type TalentUnlock = {
  kind: 'talentUnlock'
  talentName: string
  cost: number
  prerequisites: XPPrerequisite[]
}

export type XPUpgrade = CharacteristicAdvance | SkillAdvance | TalentUnlock

export type XPEvaluation = {
  label: string
  isSatisfied: boolean
  detail: string
}

export type XPSpendResult = {
  isValid: boolean
  cost: number
  availableExperience: number
  projectedRemainingExperience: number
  validationErrors: string[]
  prerequisiteEvaluations: XPEvaluation[]
  appliedCharacter: Character | null
  historyTitle: string | null
  historyBody: string | null
}

export type DossierField = {
  label: string
  value: string
}

export type DossierSection = {
  title: string
  subtitle: string | null
  fields: DossierField[]
  paragraphs: string[]
  bullets: string[]
}

export type CharacterDossier = {
  title: string
  subtitle: string
  metadataLine: string
  filenameStem: string
  sections: DossierSection[]
}
