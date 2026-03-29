import { Character, Compendium, Weapon, Armour } from './types'

const CHAR_KEY = 'dh.web.characters.v1'
const WEAPON_KEY = 'dh.web.weapons.v1'
const ARMOUR_KEY = 'dh.web.armour.v1'

const baseCharacter = (): Character => ({
  id: crypto.randomUUID(),
  name: 'New Acolyte',
  homeWorld: '',
  role: '',
  characteristics: { ws: 30, bs: 30, s: 30, t: 30, ag: 30, int: 30, per: 30, wp: 30, fel: 30 },
  wounds: 10,
  fatigue: 0,
  xpAvailable: 0,
  skills: [{ name: 'Awareness', value: 30 }],
  notes: '',
  weapons: [],
  armour: []
})

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

function isCharacteristicBlock(value: unknown): value is Character['characteristics'] {
  if (!isRecord(value)) return false
  return ['ws', 'bs', 's', 't', 'ag', 'int', 'per', 'wp', 'fel'].every((key) => typeof value[key] === 'number')
}

function isSkill(value: unknown): value is Character['skills'][number] {
  return isRecord(value) && typeof value.name === 'string' && typeof value.value === 'number'
}

function isWeapon(value: unknown): value is Weapon {
  return isRecord(value) &&
    typeof value.id === 'string' &&
    typeof value.name === 'string' &&
    typeof value.damage === 'string' &&
    typeof value.notes === 'string'
}

function isArmour(value: unknown): value is Armour {
  return isRecord(value) &&
    typeof value.id === 'string' &&
    typeof value.name === 'string' &&
    typeof value.location === 'string' &&
    typeof value.ap === 'number'
}

function isCharacter(value: unknown): value is Character {
  return isRecord(value) &&
    typeof value.id === 'string' &&
    typeof value.name === 'string' &&
    typeof value.homeWorld === 'string' &&
    typeof value.role === 'string' &&
    isCharacteristicBlock(value.characteristics) &&
    typeof value.wounds === 'number' &&
    typeof value.fatigue === 'number' &&
    typeof value.xpAvailable === 'number' &&
    Array.isArray(value.skills) &&
    value.skills.every(isSkill) &&
    typeof value.notes === 'string' &&
    Array.isArray(value.weapons) &&
    value.weapons.every(isWeapon) &&
    Array.isArray(value.armour) &&
    value.armour.every(isArmour)
}

function safeParse<T>(raw: string, validator: (value: unknown) => value is T): T | null {
  try {
    const parsed = JSON.parse(raw) as unknown
    return validator(parsed) ? parsed : null
  } catch {
    return null
  }
}

function isCompendium<T>(value: unknown, itemValidator: (entry: unknown) => entry is T): value is Compendium<T> {
  return isRecord(value) &&
    typeof value.updatedAt === 'string' &&
    Array.isArray(value.entries) &&
    value.entries.every(itemValidator)
}

export function parseWeaponCompendiumImport(payload: string): Compendium<Weapon> | null {
  const parsed = safeParse(payload, (value): value is { entries: Weapon[] } => isRecord(value) && Array.isArray(value.entries) && value.entries.every(isWeapon))
  if (!parsed) return null
  return { updatedAt: new Date().toISOString(), entries: parsed.entries }
}

export function parseArmourCompendiumImport(payload: string): Compendium<Armour> | null {
  const parsed = safeParse(payload, (value): value is { entries: Armour[] } => isRecord(value) && Array.isArray(value.entries) && value.entries.every(isArmour))
  if (!parsed) return null
  return { updatedAt: new Date().toISOString(), entries: parsed.entries }
}

export function loadCharacters(): Character[] {
  const raw = localStorage.getItem(CHAR_KEY)
  if (!raw) return [baseCharacter()]
  return safeParse(raw, (value): value is Character[] => Array.isArray(value) && value.every(isCharacter)) ?? [baseCharacter()]
}

export function saveCharacters(chars: Character[]) {
  localStorage.setItem(CHAR_KEY, JSON.stringify(chars))
}

function defaultWeapons(): Compendium<Weapon> {
  return { updatedAt: new Date().toISOString(), entries: [{ id: 'w-lasgun', name: 'Lasgun', damage: '1d10+3 E', notes: 'Reliable' }] }
}

function defaultArmour(): Compendium<Armour> {
  return { updatedAt: new Date().toISOString(), entries: [{ id: 'a-flak-body', name: 'Flak Coat', location: 'Body', ap: 4 }] }
}

export function loadWeaponCompendium(): Compendium<Weapon> {
  const raw = localStorage.getItem(WEAPON_KEY)
  return raw ? (safeParse(raw, (value): value is Compendium<Weapon> => isCompendium(value, isWeapon)) ?? defaultWeapons()) : defaultWeapons()
}

export function saveWeaponCompendium(data: Compendium<Weapon>) {
  localStorage.setItem(WEAPON_KEY, JSON.stringify(data))
}

export function loadArmourCompendium(): Compendium<Armour> {
  const raw = localStorage.getItem(ARMOUR_KEY)
  return raw ? (safeParse(raw, (value): value is Compendium<Armour> => isCompendium(value, isArmour)) ?? defaultArmour()) : defaultArmour()
}

export function saveArmourCompendium(data: Compendium<Armour>) {
  localStorage.setItem(ARMOUR_KEY, JSON.stringify(data))
}
