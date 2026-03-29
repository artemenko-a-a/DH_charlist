import { useMemo, useState } from 'react'
import { Character, Weapon, Armour } from '../lib/types'
import {
  loadArmourCompendium,
  loadCharacters,
  loadWeaponCompendium,
  parseArmourCompendiumImport,
  parseWeaponCompendiumImport,
  saveArmourCompendium,
  saveCharacters,
  saveWeaponCompendium
} from '../lib/storage'

function detachedWeaponCopy(source: Weapon): Weapon {
  return { ...source, id: crypto.randomUUID() }
}

function detachedArmourCopy(source: Armour): Armour {
  return { ...source, id: crypto.randomUUID() }
}

export default function App() {
  const [characters, setCharacters] = useState<Character[]>(() => loadCharacters())
  const [selectedId, setSelectedId] = useState<string>(characters[0]?.id ?? '')
  const [weaponCompendium, setWeaponCompendium] = useState(() => loadWeaponCompendium())
  const [armourCompendium, setArmourCompendium] = useState(() => loadArmourCompendium())
  const selected = characters.find((c) => c.id === selectedId)

  const sortedWeapons = useMemo(() => [...weaponCompendium.entries].sort((a, b) => a.name.localeCompare(b.name)), [weaponCompendium])
  const sortedArmour = useMemo(() => [...armourCompendium.entries].sort((a, b) => a.name.localeCompare(b.name)), [armourCompendium])

  function updateCharacter(mutator: (c: Character) => Character) {
    setCharacters((prev) => {
      const next = prev.map((c) => (c.id === selectedId ? mutator(c) : c))
      saveCharacters(next)
      return next
    })
  }

  function createCharacter() {
    const newbie: Character = {
      id: crypto.randomUUID(),
      name: 'New Character',
      homeWorld: '',
      role: '',
      characteristics: { ws: 25, bs: 25, s: 25, t: 25, ag: 25, int: 25, per: 25, wp: 25, fel: 25 },
      wounds: 10,
      fatigue: 0,
      xpAvailable: 100,
      skills: [],
      notes: '',
      weapons: [],
      armour: []
    }
    const next = [...characters, newbie]
    setCharacters(next)
    setSelectedId(newbie.id)
    saveCharacters(next)
  }

  function importCompendium(kind: 'weapon' | 'armour', payload: string) {
    if (!confirm('Replace-all import. Existing compendium catalog will be replaced. Continue?')) return
    if (kind === 'weapon') {
      const next = parseWeaponCompendiumImport(payload)
      if (!next) {
        alert('Invalid weapon compendium payload. Expected {"entries": Weapon[]}.')
        return
      }
      setWeaponCompendium(next)
      saveWeaponCompendium(next)
      return
    }
    const next = parseArmourCompendiumImport(payload)
    if (!next) {
      alert('Invalid armour compendium payload. Expected {"entries": Armour[]}.')
      return
    }
    setArmourCompendium(next)
    saveArmourCompendium(next)
  }

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '280px 1fr', minHeight: '100vh', background: '#101318', color: '#e1e6ef', fontFamily: 'system-ui' }}>
      <aside style={{ borderRight: '1px solid #2a3446', padding: 16 }}>
        <h2>Characters</h2>
        <button onClick={createCharacter}>Create</button>
        {characters.map((c) => (
          <div key={c.id}>
            <button onClick={() => setSelectedId(c.id)} style={{ marginTop: 8, width: '100%', textAlign: 'left' }}>{c.name}</button>
          </div>
        ))}
      </aside>
      <main style={{ padding: 16 }}>
        {selected ? (
          <>
            <h1>{selected.name}</h1>
            <section>
              <h3>Profile</h3>
              <input value={selected.name} onChange={(e) => updateCharacter((c) => ({ ...c, name: e.target.value }))} placeholder="Name" />
              <input value={selected.homeWorld} onChange={(e) => updateCharacter((c) => ({ ...c, homeWorld: e.target.value }))} placeholder="Home World" />
              <input value={selected.role} onChange={(e) => updateCharacter((c) => ({ ...c, role: e.target.value }))} placeholder="Role" />
            </section>
            <section>
              <h3>Resources</h3>
              <label>Wounds <input type="number" value={selected.wounds} onChange={(e) => updateCharacter((c) => ({ ...c, wounds: Number(e.target.value) }))} /></label>
              <label>Fatigue <input type="number" value={selected.fatigue} onChange={(e) => updateCharacter((c) => ({ ...c, fatigue: Number(e.target.value) }))} /></label>
              <label>XP <input type="number" value={selected.xpAvailable} onChange={(e) => updateCharacter((c) => ({ ...c, xpAvailable: Number(e.target.value) }))} /></label>
            </section>
            <section>
              <h3>Quick mechanics (bounded)</h3>
              <p>Ranged target (BS + Per bonus): <strong>{selected.characteristics.bs + Math.floor((selected.characteristics.per - 30) / 10)}</strong></p>
            </section>
            <section>
              <h3>Weapons (detached copy add)</h3>
              <select onChange={(e) => {
                const source = sortedWeapons.find((w) => w.id === e.target.value)
                if (!source) return
                updateCharacter((c) => ({ ...c, weapons: [...c.weapons, detachedWeaponCopy(source)] }))
              }}>
                <option value="">Select weapon from compendium</option>
                {sortedWeapons.map((w) => <option key={w.id} value={w.id}>{w.name}</option>)}
              </select>
              <ul>{selected.weapons.map((w) => <li key={w.id}>{w.name} — {w.damage}</li>)}</ul>
            </section>
            <section>
              <h3>Armour (detached copy add)</h3>
              <select onChange={(e) => {
                const source = sortedArmour.find((a) => a.id === e.target.value)
                if (!source) return
                updateCharacter((c) => ({ ...c, armour: [...c.armour, detachedArmourCopy(source)] }))
              }}>
                <option value="">Select armour from compendium</option>
                {sortedArmour.map((a) => <option key={a.id} value={a.id}>{a.name}</option>)}
              </select>
              <ul>{selected.armour.map((a) => <li key={a.id}>{a.name} ({a.location}) AP {a.ap}</li>)}</ul>
            </section>
            <section>
              <h3>Compendium import (replace-all)</h3>
              <textarea id="weapon-json" placeholder='{"entries": [{"id":"w1","name":"Autogun","damage":"1d10+3 I","notes":""}]}' style={{ width: '100%', minHeight: 70 }} />
              <button onClick={() => importCompendium('weapon', (document.getElementById('weapon-json') as HTMLTextAreaElement).value)}>Import Weapon Compendium</button>
              <textarea id="armour-json" placeholder='{"entries": [{"id":"a1","name":"Mesh Vest","location":"Body","ap":5}]}' style={{ width: '100%', minHeight: 70 }} />
              <button onClick={() => importCompendium('armour', (document.getElementById('armour-json') as HTMLTextAreaElement).value)}>Import Armour Compendium</button>
            </section>
            <section>
              <h3>Dossier preview</h3>
              <pre>{JSON.stringify({ name: selected.name, role: selected.role, wounds: selected.wounds, weapons: selected.weapons, armour: selected.armour }, null, 2)}</pre>
            </section>
          </>
        ) : (
          <>
            <h1>Character dossier</h1>
            <p>No character selected. Create a character to continue.</p>
          </>
        )}
      </main>
    </div>
  )
}
