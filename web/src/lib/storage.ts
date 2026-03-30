import {
  ArmourCompendiumCatalog,
  Character,
  StorageLoadReport,
  WeaponCompendiumCatalog
} from './types'
import {
  coerceCharacter,
  createDefaultCharacter,
  demoArmourCatalog,
  demoWeaponCatalog
} from './domain'

const CHARACTER_KEY = 'dh.web.characters.v2'
const LEGACY_CHARACTER_KEY = 'dh.web.characters.v1'
const WEAPON_KEY = 'dh.web.weapons.v2'
const LEGACY_WEAPON_KEY = 'dh.web.weapons.v1'
const ARMOUR_KEY = 'dh.web.armour.v2'
const LEGACY_ARMOUR_KEY = 'dh.web.armour.v1'

function safeParse(raw: string): unknown {
  try {
    return JSON.parse(raw) as unknown
  } catch {
    return null
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

function loadCharactersWithWarnings(warnings: string[]): Character[] {
  const raw = localStorage.getItem(CHARACTER_KEY) ?? localStorage.getItem(LEGACY_CHARACTER_KEY)
  if (!raw) return [createDefaultCharacter()]

  const parsed = safeParse(raw)
  if (!Array.isArray(parsed)) {
    warnings.push('Character storage was malformed. Browser state was reset to a safe default roster.')
    return [createDefaultCharacter()]
  }

  const characters = parsed.map(coerceCharacter).filter((item): item is Character => item !== null)
  if (characters.length === 0 && parsed.length > 0) {
    warnings.push('Stored characters could not be recovered. Browser state was reset to a safe default roster.')
    return [createDefaultCharacter()]
  }

  return characters
}

function coerceWeaponCatalog(parsed: unknown): WeaponCompendiumCatalog | null {
  if (!isRecord(parsed)) return null
  const catalog = isRecord(parsed.catalog) ? parsed.catalog : parsed
  const definitions = Array.isArray(catalog.definitions ?? catalog.entries) ? (catalog.definitions ?? catalog.entries) as unknown[] : null
  const id = typeof catalog.id === 'string' ? catalog.id.trim() : ''
  const displayName = typeof catalog.displayName === 'string' ? catalog.displayName.trim() : ''
  if (!definitions || !id || !displayName) return null

  return {
    id,
    displayName,
    definitions: definitions.flatMap((item) => {
      if (!isRecord(item)) return []
      const definitionID = typeof item.id === 'string' ? item.id.trim() : ''
      const name = typeof item.name === 'string' ? item.name.trim() : ''
      if (!definitionID || !name) return []
      return [{
        id: definitionID,
        catalogID: typeof item.catalogID === 'string' && item.catalogID.trim() ? item.catalogID.trim() : id,
        name,
        type: typeof item.type === 'string' ? item.type.trim() : '',
        range: typeof item.range === 'string' ? item.range.trim() : '',
        damage: typeof item.damage === 'string' ? item.damage.trim() : '',
        penetration: typeof item.penetration === 'string' ? item.penetration.trim() : '',
        clip: typeof item.clip === 'string' ? item.clip.trim() : '',
        reload: typeof item.reload === 'string' ? item.reload.trim() : '',
        traits: Array.isArray(item.traits) ? item.traits.filter((entry): entry is string => typeof entry === 'string').map((entry) => entry.trim()).filter(Boolean) : [],
        notes: typeof item.notes === 'string' ? item.notes.trim() : ''
      }]
    })
  }
}

function coerceArmourCatalog(parsed: unknown): ArmourCompendiumCatalog | null {
  if (!isRecord(parsed)) return null
  const catalog = isRecord(parsed.catalog) ? parsed.catalog : parsed
  const definitions = Array.isArray(catalog.definitions ?? catalog.entries) ? (catalog.definitions ?? catalog.entries) as unknown[] : null
  const id = typeof catalog.id === 'string' ? catalog.id.trim() : ''
  const displayName = typeof catalog.displayName === 'string' ? catalog.displayName.trim() : ''
  if (!definitions || !id || !displayName) return null

  return {
    id,
    displayName,
    definitions: definitions.flatMap((item) => {
      if (!isRecord(item)) return []
      const definitionID = typeof item.id === 'string' ? item.id.trim() : ''
      const name = typeof item.name === 'string' ? item.name.trim() : ''
      const armourPoints = typeof item.armourPoints === 'number' ? item.armourPoints : typeof item.ap === 'number' ? item.ap : null
      if (!definitionID || !name || armourPoints === null) return []
      return [{
        id: definitionID,
        catalogID: typeof item.catalogID === 'string' && item.catalogID.trim() ? item.catalogID.trim() : id,
        name,
        category: typeof item.category === 'string' ? item.category.trim() : '',
        coverage: Array.isArray(item.coverage) ? item.coverage.filter((entry): entry is string => typeof entry === 'string').map((entry) => entry.trim()).filter(Boolean) : [],
        armourPoints,
        weight: typeof item.weight === 'string' ? item.weight.trim() : '',
        availability: typeof item.availability === 'string' ? item.availability.trim() : '',
        traits: Array.isArray(item.traits) ? item.traits.filter((entry): entry is string => typeof entry === 'string').map((entry) => entry.trim()).filter(Boolean) : [],
        notes: typeof item.notes === 'string' ? item.notes.trim() : ''
      }]
    })
  }
}

export function loadAppState(): StorageLoadReport {
  const warnings: string[] = []
  const characters = loadCharactersWithWarnings(warnings)

  const rawWeaponCatalog = localStorage.getItem(WEAPON_KEY) ?? localStorage.getItem(LEGACY_WEAPON_KEY)
  const weaponCatalog = rawWeaponCatalog ? coerceWeaponCatalog(safeParse(rawWeaponCatalog)) ?? demoWeaponCatalog : demoWeaponCatalog
  if (rawWeaponCatalog && weaponCatalog === demoWeaponCatalog) {
    warnings.push('Weapon compendium storage was malformed. The demo weapon catalog was restored.')
  }

  const rawArmourCatalog = localStorage.getItem(ARMOUR_KEY) ?? localStorage.getItem(LEGACY_ARMOUR_KEY)
  const armourCatalog = rawArmourCatalog ? coerceArmourCatalog(safeParse(rawArmourCatalog)) ?? demoArmourCatalog : demoArmourCatalog
  if (rawArmourCatalog && armourCatalog === demoArmourCatalog) {
    warnings.push('Armour compendium storage was malformed. The demo armour catalog was restored.')
  }

  return {
    characters,
    weaponCatalog,
    armourCatalog,
    warnings
  }
}

export function saveCharacters(characters: Character[]): void {
  localStorage.setItem(CHARACTER_KEY, JSON.stringify(characters))
}

export function saveWeaponCatalog(catalog: WeaponCompendiumCatalog): void {
  localStorage.setItem(WEAPON_KEY, JSON.stringify(catalog))
}

export function saveArmourCatalog(catalog: ArmourCompendiumCatalog): void {
  localStorage.setItem(ARMOUR_KEY, JSON.stringify(catalog))
}
