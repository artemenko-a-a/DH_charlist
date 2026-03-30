import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import App from './App'
import { createDefaultCharacter } from '../lib/domain'

const storage = new Map<string, string>()

const localStorageMock = {
  getItem: vi.fn((key: string) => storage.get(key) ?? null),
  setItem: vi.fn((key: string, value: string) => {
    storage.set(key, value)
  }),
  removeItem: vi.fn((key: string) => {
    storage.delete(key)
  }),
  clear: vi.fn(() => storage.clear())
}

beforeEach(() => {
  storage.clear()
  vi.clearAllMocks()
  Object.defineProperty(globalThis, 'localStorage', {
    value: localStorageMock,
    configurable: true
  })
  Object.defineProperty(window, 'confirm', {
    value: vi.fn(() => true),
    configurable: true
  })
  Object.defineProperty(window, 'print', {
    value: vi.fn(),
    configurable: true
  })
})

afterEach(() => {
  cleanup()
})

describe('web workspace smoke', () => {
  it('renders the expanded character workspace and allows character creation', async () => {
    const user = userEvent.setup()

    render(<App />)

    expect(screen.getByRole('heading', { name: 'DH CharList Web' })).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'New Acolyte' })).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Create Character' }))

    expect(screen.getByRole('heading', { name: 'Acolyte 2' })).toBeInTheDocument()
  })

  it('keeps detached weapon copies stable when the compendium is replaced', async () => {
    const user = userEvent.setup()

    render(<App />)

    await user.click(screen.getAllByRole('button', { name: 'Equipment' })[0]!)
    await user.type(screen.getByPlaceholderText('Search weapon catalog'), 'Lasgun')
    await user.click(screen.getByRole('button', { name: /Lasgun/i }))

    const payload = JSON.stringify({
      schemaVersion: 1,
      catalog: {
        id: 'replacement',
        displayName: 'Replacement',
        definitions: [
          {
            id: 'replacement.lasgun',
            name: 'Lasgun',
            type: 'Basic',
            range: '150m',
            damage: '1d10+4 E',
            penetration: '1',
            clip: '80',
            reload: 'Full',
            traits: ['Reliable']
          }
        ]
      }
    })

    fireEvent.change(
      screen.getByPlaceholderText('{"schemaVersion":1,"catalog":{"id":"custom","displayName":"Custom Weapons","definitions":[]}}'),
      { target: { value: payload } }
    )
    await user.click(screen.getByRole('button', { name: 'Preview Weapon Replace-All' }))
    await user.click(screen.getByRole('button', { name: 'Confirm Weapon Replace-All' }))

    expect(screen.getByDisplayValue('1d10+3 E')).toBeInTheDocument()
    expect(screen.getByText(/existing character-owned weapons remain detached/i)).toBeInTheDocument()
  })

  it('rejects malformed compendium imports before confirmation state is reached', async () => {
    const user = userEvent.setup()

    render(<App />)
    await user.click(screen.getAllByRole('button', { name: 'Equipment' })[0]!)
    fireEvent.change(
      screen.getByPlaceholderText('{"schemaVersion":1,"catalog":{"id":"custom","displayName":"Custom Weapons","definitions":[]}}'),
      { target: { value: '{' } }
    )
    await user.click(screen.getByRole('button', { name: 'Preview Weapon Replace-All' }))

    expect(screen.getByText(/weapon compendium import failed/i)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Confirm Weapon Replace-All' })).not.toBeInTheDocument()
  })

  it('refreshes updatedAt when overview edits are saved', async () => {
    const user = userEvent.setup()
    const seeded = createDefaultCharacter('Timestamp Test')
    seeded.updatedAt = '2026-03-01T00:00:00.000Z'
    storage.set('dh.web.characters.v2', JSON.stringify([seeded]))

    render(<App />)

    const nameInput = screen.getByLabelText('Name')
    await user.clear(nameInput)
    await user.type(nameInput, 'Timestamp Updated')

    const persisted = JSON.parse(storage.get('dh.web.characters.v2') ?? '[]') as Array<{ updatedAt: string; profile: { name: string } }>

    expect(persisted[0]?.profile.name).toBe('Timestamp Updated')
    expect(persisted[0]?.updatedAt).not.toBe('2026-03-01T00:00:00.000Z')
  })
})
