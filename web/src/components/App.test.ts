import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import App from './App'
import { loadCharacters, loadWeaponCompendium, parseArmourCompendiumImport, parseWeaponCompendiumImport } from '../lib/storage'

const storage = new Map<string, string>()

const localStorageMock = {
  getItem: vi.fn((key: string) => storage.get(key) ?? null),
  setItem: vi.fn((key: string, value: string) => {
    storage.set(key, value)
  }),
  removeItem: vi.fn((key: string) => {
    storage.delete(key)
  }),
  clear: vi.fn(() => {
    storage.clear()
  })
}

beforeEach(() => {
  storage.clear()
  vi.clearAllMocks()
  Object.defineProperty(globalThis, 'localStorage', {
    value: localStorageMock,
    configurable: true,
    writable: true
  })
})

describe('storage guards', () => {
  it('falls back to a default character when persisted character JSON is malformed', () => {
    storage.set('dh.web.characters.v1', '{bad json')

    const characters = loadCharacters()

    expect(characters).toHaveLength(1)
    expect(characters[0]?.name).toBe('New Acolyte')
  })

  it('falls back to default compendium data when persisted compendium JSON is malformed', () => {
    storage.set('dh.web.weapons.v1', '{"entries":{}}')

    const compendium = loadWeaponCompendium()

    expect(compendium.entries).toHaveLength(1)
    expect(compendium.entries[0]?.name).toBe('Lasgun')
  })

  it('rejects malformed compendium imports before state update', () => {
    expect(parseWeaponCompendiumImport('{"entries":{}}')).toBeNull()
    expect(parseArmourCompendiumImport('{"entries":[{}]}')).toBeNull()
  })
})

describe('empty selection recovery', () => {
  it('keeps the create action visible when the stored character list is empty', () => {
    storage.set('dh.web.characters.v1', '[]')

    const markup = renderToStaticMarkup(createElement(App))

    expect(markup).toContain('Create')
    expect(markup).toContain('No character selected. Create a character to continue.')
  })
})
