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

export function loadCharacters(): Character[] {
  const raw = localStorage.getItem(CHAR_KEY)
  if (!raw) return [baseCharacter()]
  return JSON.parse(raw) as Character[]
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
  return raw ? (JSON.parse(raw) as Compendium<Weapon>) : defaultWeapons()
}

export function saveWeaponCompendium(data: Compendium<Weapon>) {
  localStorage.setItem(WEAPON_KEY, JSON.stringify(data))
}

export function loadArmourCompendium(): Compendium<Armour> {
  const raw = localStorage.getItem(ARMOUR_KEY)
  return raw ? (JSON.parse(raw) as Compendium<Armour>) : defaultArmour()
}

export function saveArmourCompendium(data: Compendium<Armour>) {
  localStorage.setItem(ARMOUR_KEY, JSON.stringify(data))
}
