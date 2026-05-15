import {
  ArmourCompendiumCatalog,
  Character,
  StorageLoadReport,
  WeaponCompendiumCatalog
} from './types'
import {
  coerceCharacter,
  demoArmourCatalog,
  demoWeaponCatalog
} from './domain'

const CHARACTER_KEY = 'dh.web.characters.v2'
const LEGACY_CHARACTER_KEY = 'dh.web.characters.v1'
const WEAPON_KEY = 'dh.web.weapons.v2'
const LEGACY_WEAPON_KEY = 'dh.web.weapons.v1'
const ARMOUR_KEY = 'dh.web.armour.v2'
const LEGACY_ARMOUR_KEY = 'dh.web.armour.v1'
const RAIBOS_CHARACTER_ID = 'raibos-2-d2'

function safeParse(raw: string): unknown {
  try {
    return JSON.parse(raw) as unknown
  } catch {
    return null
  }
}

function createRaibosCharacter(): Character {
  return {
    id: RAIBOS_CHARACTER_ID,
    profile: {
      name: 'Райбос-2 Д-2',
      homeWorld: 'Мир-кузница Райбос',
      background: '',
      role: 'Хирургеон',
      aptitudes: ['Общая', 'Интеллект', 'Техно', 'Полевое', 'Внимательность', 'Познание'],
      description: [
        'Возраст: 27. Пол: М. Комплекция: худой. Кожа: бледная. Волосы: лысый.',
        'Внесено с бумажного чарника и сверено по пользовательским уточнениям перед игровой сессией.'
      ].join('\n')
    },
    characteristics: {
      weaponSkill: 31,
      ballisticSkill: 31,
      strength: 30,
      toughness: 40,
      agility: 34,
      intelligence: 52,
      perception: 43,
      willpower: 34,
      fellowship: 22
    },
    resources: {
      currentWounds: 14,
      maxWounds: 14,
      fatigue: 0,
      corruption: 0,
      insanity: 2,
      currentFate: 3,
      maxFate: 3,
      experienceSpent: 0,
      experienceTotal: 0
    },
    skills: [
      { id: 'skill-awareness', name: 'Бдительность', characteristic: 'perception', training: 'trained', specialisations: [] },
      { id: 'skill-dodge', name: 'Уклонение', characteristic: 'agility', training: 'known', specialisations: [] },
      { id: 'skill-logic', name: 'Логика', characteristic: 'intelligence', training: 'known', specialisations: [] },
      { id: 'skill-medicae', name: 'Медика', characteristic: 'intelligence', training: 'veteran', specialisations: [] },
      { id: 'skill-operate-voidship', name: 'Управление (Космическое)', characteristic: 'agility', training: 'known', specialisations: ['Космическое'] },
      { id: 'skill-scrutiny', name: 'Проницательность', characteristic: 'perception', training: 'known', specialisations: [] },
      { id: 'skill-tech-use', name: 'Технопользование', characteristic: 'intelligence', training: 'veteran', specialisations: [] },
      { id: 'skill-trade-chemist', name: 'Ремесло', characteristic: 'intelligence', training: 'veteran', specialisations: ['Химик'] },
      { id: 'skill-trade-armourer', name: 'Ремесло', characteristic: 'intelligence', training: 'known', specialisations: ['Оружейник'] }
    ],
    notes: {
      talents: [
        'Искусный Стук',
        'Сопротивление (радиация) (+10 сопротивляемость)',
        'Выучка с Оружием (твердотельное)',
        'Использование Мехадендритов',
        'Превосходный Хирургеон (+20 медика)',
        'Мастер Брони',
        'Крепкое телосложение (1)',
        'Импланты Механикус',
        'Медицинский Мехадендрит (+10 медицина и допрос)',
        'Оптический Мехадендрит (+10 восприятие)',
        'Баллистический мехадендрит',
        'Бионическая дыхательная система (+20 сопротивляемость)',
        'Монозадачный сервочереп (+10 технопользование)'
      ],
      traits: [],
      mutations: [],
      disorders: [],
      psychicPowers: [],
      specialAbilities: [
        'Замена слабой плоти (кибернетика на 2 уровня ниже)',
        'Преданный Целитель: можно потратить очко Судьбы для автоматического успеха на проваленной проверке Первой Помощи; степени успеха равны бонусу Интеллекта Хирургеона.'
      ],
      notes: [
        'Оружие из чарника: лазпистолет и лазган. Для обоих прочитана лазерная настройка: Ус: +1 урон, x2 БК; П: +2 урон, +2 пробивание, x4 БК.',
        'Сверено пользователем: Искусный Стук — корректное название таланта; Преданный Целитель — базовый бонус роли Хирургеона; боезапас лазгана оставлен как 60x3.'
      ].join('\n')
    },
    equipment: {
      weapons: [
        {
          id: 'weapon-laspistol',
          name: 'Лазпистолет',
          type: 'Pistol',
          range: '30m',
          damage: '1d10+2 E',
          penetration: '0',
          clip: '30',
          reload: 'Free',
          traits: 'Лазерное; Ус: +1 урон, x2 БК; П: +2 урон, +2 пробивание, x4 БК'
        },
        {
          id: 'weapon-lasgun',
          name: 'Лазган',
          type: 'Basic',
          range: '100m',
          damage: '1d10+3 E',
          penetration: '0',
          clip: '60x3',
          reload: 'Full',
          traits: 'Лазерное; Ус: +1 урон, x2 БК; П: +2 урон, +2 пробивание, x4 БК'
        }
      ],
      armour: [
        { id: 'armour-head', location: 'Голова', armourPoints: 0 },
        { id: 'armour-body', location: 'Корпус', armourPoints: 4 },
        { id: 'armour-right-arm', location: 'Правая рука', armourPoints: 7 },
        { id: 'armour-left-arm', location: 'Левая рука', armourPoints: 7 },
        { id: 'armour-right-leg', location: 'Правая нога', armourPoints: 3 },
        { id: 'armour-left-leg', location: 'Левая нога', armourPoints: 3 }
      ],
      movement: { halfMove: 3, fullMove: 6, charge: 9, run: 18 },
      inventory: []
    },
    session: {
      modeEnabled: false,
      pinnedChecks: ['Медика', 'Технопользование', 'Бдительность', 'Проницательность'],
      temporaryModifiers: {},
      activeWeaponID: 'weapon-lasgun',
      combatConditions: []
    },
    history: [
      {
        id: 'history-import-raibos-sheet',
        characterID: RAIBOS_CHARACTER_ID,
        createdAt: '2026-05-15T00:00:00.000Z',
        title: 'Импортирован бумажный чарник',
        type: 'sessionNote',
        body: 'Персонаж внесён по двум фотографиям бумажного листа Dark Heresy II и уточнён по пользовательской сверке с рульником.',
        tags: ['import', 'paper-sheet']
      }
    ],
    updatedAt: '2026-05-15T00:00:00.000Z'
  }
}

function isRaibosCharacter(character: Character): boolean {
  return character.id === RAIBOS_CHARACTER_ID || character.profile.name === 'Райбос-2 Д-2'
}

function mergeRaibosSeed(existing: Character): Character {
  const seed = createRaibosCharacter()
  return {
    ...seed,
    id: existing.id,
    resources: existing.resources,
    history: existing.history.length > 0 ? existing.history : seed.history,
    updatedAt: new Date().toISOString()
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

function loadCharactersWithWarnings(warnings: string[]): Character[] {
  const raw = localStorage.getItem(CHARACTER_KEY) ?? localStorage.getItem(LEGACY_CHARACTER_KEY)
  if (!raw) return [createRaibosCharacter()]

  const parsed = safeParse(raw)
  if (!Array.isArray(parsed)) {
    warnings.push('Character storage was malformed. Browser state was reset to a safe default roster.')
    return [createRaibosCharacter()]
  }

  const characters = parsed.map(coerceCharacter).filter((item): item is Character => item !== null)
  if (characters.length === 0 && parsed.length > 0) {
    warnings.push('Stored characters could not be recovered. Browser state was reset to a safe default roster.')
    return [createRaibosCharacter()]
  }

  if (characters.some(isRaibosCharacter)) {
    return characters.map((character) => isRaibosCharacter(character) ? mergeRaibosSeed(character) : character)
  }

  return [createRaibosCharacter(), ...characters]
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
