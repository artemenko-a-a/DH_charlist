import { ChangeEvent, ReactNode, useEffect, useMemo, useState } from 'react'
import {
  addDetachedArmour,
  addDetachedWeapon,
  armourAutocomplete,
  characteristicLabels,
  composeDossier,
  createDefaultCharacter,
  duplicateCharacter,
  experienceAvailable,
  normalizeText,
  parseArmourCompendiumImport,
  parseWeaponCompendiumImport,
  resolveAttackFlow,
  resolveCharacteristicCheck,
  resolveDamage,
  resolveReactionFlow,
  resolveSkillCheck,
  signedValue,
  skillTarget,
  suggestedSkillAdvanceCost,
  trainingLabels,
  nextTrainingLevel,
  validateOrApplyXPSpend,
  weaponAutocomplete,
  xpUpgradeSummary
} from '../lib/domain'
import { loadAppState, saveArmourCatalog, saveCharacters, saveWeaponCatalog } from '../lib/storage'
import {
  Armour,
  ArmourCompendiumCatalog,
  Character,
  CharacteristicKey,
  Skill,
  SkillTrainingLevel,
  Weapon,
  WeaponCompendiumCatalog
} from '../lib/types'
import { characteristicOrder, trainingOrder } from '../lib/types'

type WorkspaceSection =
  | 'overview'
  | 'resources'
  | 'skills'
  | 'notes'
  | 'equipment'
  | 'session'
  | 'progression'
  | 'dossier'

const sections: Array<{ id: WorkspaceSection; label: string }> = [
  { id: 'overview', label: 'Profile' },
  { id: 'resources', label: 'Characteristics' },
  { id: 'skills', label: 'Skills' },
  { id: 'notes', label: 'Notes' },
  { id: 'equipment', label: 'Equipment' },
  { id: 'session', label: 'Session' },
  { id: 'progression', label: 'Progression' },
  { id: 'dossier', label: 'Dossier' }
]

function parseLineList(value: string): string[] {
  return value
    .split('\n')
    .map((item) => item.trim())
    .filter(Boolean)
}

function parseCsvList(value: string): string[] {
  return value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean)
}

function numberInput(event: ChangeEvent<HTMLInputElement>): number {
  const next = Number(event.target.value)
  return Number.isFinite(next) ? next : 0
}

function App() {
  const [appState] = useState(() => loadAppState())
  const [characters, setCharacters] = useState<Character[]>(appState.characters)
  const [weaponCatalog, setWeaponCatalog] = useState<WeaponCompendiumCatalog>(appState.weaponCatalog)
  const [armourCatalog, setArmourCatalog] = useState<ArmourCompendiumCatalog>(appState.armourCatalog)
  const [warnings, setWarnings] = useState<string[]>(appState.warnings)
  const [selectedId, setSelectedId] = useState<string>(appState.characters[0]?.id ?? '')
  const [activeSection, setActiveSection] = useState<WorkspaceSection>('overview')
  const [statusMessage, setStatusMessage] = useState<string>('Ready. Local-first browser state is active.')

  useEffect(() => {
    if (!selectedId && characters[0]) {
      setSelectedId(characters[0].id)
    }
  }, [characters, selectedId])

  const selectedCharacter = useMemo(
    () => characters.find((character) => character.id === selectedId) ?? null,
    [characters, selectedId]
  )

  const updateCharacter = (updater: (character: Character) => Character) => {
    setCharacters((current) => {
      const next = current.map((character) => {
        if (character.id !== selectedId) return character
        return {
          ...updater(character),
          updatedAt: new Date().toISOString()
        }
      })
      saveCharacters(next)
      return next
    })
    setStatusMessage('Character changes saved to browser-local storage.')
  }

  const replaceCharacter = (replacement: Character) => {
    setCharacters((current) => {
      const next = current.map((character) => (character.id === replacement.id ? replacement : character))
      saveCharacters(next)
      return next
    })
    setStatusMessage('Character changes saved to browser-local storage.')
  }

  const createCharacter = () => {
    const created = createDefaultCharacter(`Acolyte ${characters.length + 1}`)
    const next = [...characters, created]
    setCharacters(next)
    setSelectedId(created.id)
    saveCharacters(next)
    setStatusMessage('New character created in browser-local storage.')
  }

  const duplicateSelectedCharacter = () => {
    if (!selectedCharacter) return
    const duplicated = duplicateCharacter(selectedCharacter)
    const next = [...characters, duplicated]
    setCharacters(next)
    setSelectedId(duplicated.id)
    saveCharacters(next)
    setStatusMessage('Character duplicated with detached local state.')
  }

  const deleteSelectedCharacter = () => {
    if (!selectedCharacter) return
    if (!window.confirm(`Delete ${normalizeText(selectedCharacter.profile.name, 'this character')} from browser-local storage?`)) {
      return
    }
    const next = characters.filter((character) => character.id !== selectedCharacter.id)
    setCharacters(next)
    setSelectedId(next[0]?.id ?? '')
    saveCharacters(next)
    setStatusMessage('Character deleted from browser-local storage.')
  }

  const clearWarning = (index: number) => {
    setWarnings((current) => current.filter((_, warningIndex) => warningIndex !== index))
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="sidebar-header">
          <p className="eyebrow">Dark Heresy II</p>
          <h1>DH CharList Web</h1>
          <p className="sidebar-copy">Local-first browser workspace built against the accepted iOS data model.</p>
          <button className="primary-button" onClick={createCharacter}>Create Character</button>
        </div>

        <div className="sidebar-actions">
          <button onClick={duplicateSelectedCharacter} disabled={!selectedCharacter}>Duplicate</button>
          <button onClick={deleteSelectedCharacter} disabled={!selectedCharacter}>Delete</button>
        </div>

        <nav className="character-list" aria-label="Characters">
          {characters.map((character) => (
            <button
              key={character.id}
              className={character.id === selectedId ? 'character-card selected' : 'character-card'}
              onClick={() => setSelectedId(character.id)}
            >
              <strong>{normalizeText(character.profile.name, 'Unnamed Character')}</strong>
              <span>{[character.profile.homeWorld, character.profile.background, character.profile.role].map((item) => item.trim()).filter(Boolean).join(' · ') || 'No profile summary yet'}</span>
            </button>
          ))}
          {characters.length === 0 && (
            <div className="empty-panel">
              <strong>No characters yet</strong>
              <p>Create a character to begin the browser-local roster.</p>
            </div>
          )}
        </nav>

        <div className="sidebar-footer">
          <p className="status-line">{statusMessage}</p>
          <p className="meta-line">Weapon catalog: {weaponCatalog.displayName} ({weaponCatalog.definitions.length})</p>
          <p className="meta-line">Armour catalog: {armourCatalog.displayName} ({armourCatalog.definitions.length})</p>
        </div>
      </aside>

      <main className="workspace">
        {warnings.length > 0 && (
          <section className="warning-stack" aria-label="Storage warnings">
            {warnings.map((warning, index) => (
              <div key={`${warning}-${index}`} className="warning-banner">
                <div>
                  <strong>Recovery Notice</strong>
                  <p>{warning}</p>
                </div>
                <button onClick={() => clearWarning(index)}>Dismiss</button>
              </div>
            ))}
          </section>
        )}

        {selectedCharacter ? (
          <>
            <header className="workspace-header">
              <div>
                <p className="eyebrow">Selected Character</p>
                <h2>{normalizeText(selectedCharacter.profile.name, 'Unnamed Character')}</h2>
                <p>{selectedCharacter.profile.homeWorld || 'Unknown home world'} · XP available {experienceAvailable(selectedCharacter)}</p>
              </div>
              <div className="section-tabs">
                {sections.map((section) => (
                  <button
                    key={section.id}
                    className={activeSection === section.id ? 'tab active' : 'tab'}
                    onClick={() => setActiveSection(section.id)}
                  >
                    {section.label}
                  </button>
                ))}
              </div>
            </header>

            {activeSection === 'overview' && (
              <OverviewPanel character={selectedCharacter} onChange={updateCharacter} />
            )}
            {activeSection === 'resources' && (
              <CharacteristicsPanel character={selectedCharacter} onChange={updateCharacter} />
            )}
            {activeSection === 'skills' && (
              <SkillsPanel character={selectedCharacter} onChange={updateCharacter} />
            )}
            {activeSection === 'notes' && (
              <NotesPanel character={selectedCharacter} onChange={updateCharacter} />
            )}
            {activeSection === 'equipment' && (
              <EquipmentPanel
                character={selectedCharacter}
                weaponCatalog={weaponCatalog}
                armourCatalog={armourCatalog}
                onChange={updateCharacter}
                onWeaponCatalogChange={(catalog) => {
                  setWeaponCatalog(catalog)
                  saveWeaponCatalog(catalog)
                  setStatusMessage('Weapon compendium replaced locally. Existing character-owned weapons remain detached.')
                }}
                onArmourCatalogChange={(catalog) => {
                  setArmourCatalog(catalog)
                  saveArmourCatalog(catalog)
                  setStatusMessage('Armour compendium replaced locally. Existing character-owned armour remains detached.')
                }}
              />
            )}
            {activeSection === 'session' && (
              <SessionPanel character={selectedCharacter} onChange={updateCharacter} />
            )}
            {activeSection === 'progression' && (
              <ProgressionPanel character={selectedCharacter} onApply={replaceCharacter} />
            )}
            {activeSection === 'dossier' && (
              <DossierPanel character={selectedCharacter} />
            )}
          </>
        ) : (
          <section className="empty-workspace">
            <h2>No character selected</h2>
            <p>Create a character to continue.</p>
            <button className="primary-button" onClick={createCharacter}>Create Character</button>
          </section>
        )}
      </main>
    </div>
  )
}

function Panel({ title, subtitle, children }: { title: string; subtitle: string; children: ReactNode }) {
  return (
    <section className="panel">
      <div className="panel-header">
        <h3>{title}</h3>
        <p>{subtitle}</p>
      </div>
      <div className="panel-content">{children}</div>
    </section>
  )
}

function OverviewPanel({ character, onChange }: { character: Character; onChange: (updater: (character: Character) => Character) => void }) {
  return (
    <div className="panel-grid">
      <Panel title="Profile" subtitle="Identity, aptitudes, and narrative context">
        <label>
          Name
          <input
            value={character.profile.name}
            onChange={(event) => onChange((current) => ({
              ...current,
              profile: { ...current.profile, name: event.target.value }
            }))}
          />
        </label>
        <label>
          Home World
          <input
            value={character.profile.homeWorld}
            onChange={(event) => onChange((current) => ({
              ...current,
              profile: { ...current.profile, homeWorld: event.target.value }
            }))}
          />
        </label>
        <label>
          Background
          <input
            value={character.profile.background}
            onChange={(event) => onChange((current) => ({
              ...current,
              profile: { ...current.profile, background: event.target.value }
            }))}
          />
        </label>
        <label>
          Role
          <input
            value={character.profile.role}
            onChange={(event) => onChange((current) => ({
              ...current,
              profile: { ...current.profile, role: event.target.value }
            }))}
          />
        </label>
        <label>
          Aptitudes (comma separated)
          <input
            value={character.profile.aptitudes.join(', ')}
            onChange={(event) => onChange((current) => ({
              ...current,
              profile: { ...current.profile, aptitudes: parseCsvList(event.target.value) }
            }))}
          />
        </label>
        <label>
          Description
          <textarea
            value={character.profile.description}
            onChange={(event) => onChange((current) => ({
              ...current,
              profile: { ...current.profile, description: event.target.value }
            }))}
          />
        </label>
      </Panel>

      <Panel title="Read Summary" subtitle="High-level trust view from the current character state">
        <dl className="summary-list">
          <div><dt>XP Available</dt><dd>{experienceAvailable(character)}</dd></div>
          <div><dt>Wounds</dt><dd>{character.resources.currentWounds} / {character.resources.maxWounds}</dd></div>
          <div><dt>Fate</dt><dd>{character.resources.currentFate} / {character.resources.maxFate}</dd></div>
          <div><dt>Skills</dt><dd>{character.skills.length}</dd></div>
          <div><dt>Weapons</dt><dd>{character.equipment.weapons.length}</dd></div>
          <div><dt>History</dt><dd>{character.history.length}</dd></div>
        </dl>
        <div className="history-preview">
          <h4>Recent history</h4>
          {character.history.length === 0 ? (
            <p className="muted">No history entries yet. XP application adds advancement history here.</p>
          ) : (
            <ul>
              {character.history.slice(0, 5).map((entry) => (
                <li key={entry.id}>
                  <strong>{entry.title}</strong>
                  <span>{entry.type}</span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </Panel>
    </div>
  )
}

function CharacteristicsPanel({ character, onChange }: { character: Character; onChange: (updater: (character: Character) => Character) => void }) {
  const [checkCharacteristic, setCheckCharacteristic] = useState<CharacteristicKey>('agility')
  const [checkModifier, setCheckModifier] = useState<number>(0)
  const [skillId, setSkillId] = useState<string>(character.skills[0]?.id ?? '')
  const [skillModifier, setSkillModifier] = useState<number>(0)

  const characteristicCheck = resolveCharacteristicCheck(character.characteristics, checkCharacteristic, checkModifier)
  const selectedSkill = character.skills.find((skill) => skill.id === skillId) ?? character.skills[0] ?? null
  const skillCheck = selectedSkill ? resolveSkillCheck(selectedSkill, character.characteristics, skillModifier) : null

  return (
    <div className="panel-grid">
      <Panel title="Characteristics" subtitle="Accepted thresholds and derived bonuses">
        <div className="stat-grid">
          {characteristicOrder.map((key) => (
            <label key={key}>
              {characteristicLabels[key]}
              <input
                type="number"
                value={character.characteristics[key]}
                onChange={(event) => onChange((current) => ({
                  ...current,
                  characteristics: {
                    ...current.characteristics,
                    [key]: numberInput(event)
                  }
                }))}
              />
              <span className="field-help">Bonus {Math.floor(character.characteristics[key] / 10)}</span>
            </label>
          ))}
        </div>
      </Panel>

      <Panel title="Resources" subtitle="Condition, fate, and experience">
        <div className="stat-grid">
          {[
            ['currentWounds', 'Current Wounds'],
            ['maxWounds', 'Max Wounds'],
            ['fatigue', 'Fatigue'],
            ['corruption', 'Corruption'],
            ['insanity', 'Insanity'],
            ['currentFate', 'Current Fate'],
            ['maxFate', 'Max Fate'],
            ['experienceSpent', 'XP Spent'],
            ['experienceTotal', 'XP Total']
          ].map(([key, label]) => (
            <label key={key}>
              {label}
              <input
                type="number"
                value={character.resources[key as keyof Character['resources']]}
                onChange={(event) => onChange((current) => ({
                  ...current,
                  resources: {
                    ...current.resources,
                    [key]: numberInput(event)
                  }
                }))}
              />
            </label>
          ))}
        </div>
        <p className="callout">XP available: {experienceAvailable(character)}</p>
      </Panel>

      <Panel title="Quick Mechanics" subtitle="Explainable checks over the current character state">
        <div className="inline-grid">
          <label>
            Characteristic Check
            <select value={checkCharacteristic} onChange={(event) => setCheckCharacteristic(event.target.value as CharacteristicKey)}>
              {characteristicOrder.map((key) => <option key={key} value={key}>{characteristicLabels[key]}</option>)}
            </select>
          </label>
          <label>
            Modifier
            <input type="number" value={checkModifier} onChange={(event) => setCheckModifier(numberInput(event))} />
          </label>
        </div>
        <CheckResultView result={characteristicCheck} />

        <div className="spacer" />
        <div className="inline-grid">
          <label>
            Skill Check
            <select value={selectedSkill?.id ?? ''} onChange={(event) => setSkillId(event.target.value)}>
              {character.skills.map((skill) => (
                <option key={skill.id} value={skill.id}>{skill.name || 'Unnamed Skill'}</option>
              ))}
            </select>
          </label>
          <label>
            Modifier
            <input type="number" value={skillModifier} onChange={(event) => setSkillModifier(numberInput(event))} />
          </label>
        </div>
        {skillCheck ? <CheckResultView result={skillCheck} /> : <p className="muted">Add a skill to use the skill-based quick check helper.</p>}
      </Panel>
    </div>
  )
}

function SkillsPanel({ character, onChange }: { character: Character; onChange: (updater: (character: Character) => Character) => void }) {
  return (
    <Panel title="Skills" subtitle="Editable skills with training-aware target summaries">
      <div className="stack">
        {character.skills.map((skill) => (
          <div key={skill.id} className="card-row">
            <label>
              Name
              <input
                value={skill.name}
                onChange={(event) => onChange((current) => ({
                  ...current,
                  skills: current.skills.map((entry) => entry.id === skill.id ? { ...entry, name: event.target.value } : entry)
                }))}
              />
            </label>
            <label>
              Characteristic
              <select
                value={skill.characteristic}
                onChange={(event) => onChange((current) => ({
                  ...current,
                  skills: current.skills.map((entry) => entry.id === skill.id ? { ...entry, characteristic: event.target.value as CharacteristicKey } : entry)
                }))}
              >
                {characteristicOrder.map((key) => <option key={key} value={key}>{characteristicLabels[key]}</option>)}
              </select>
            </label>
            <label>
              Training
              <select
                value={skill.training}
                onChange={(event) => onChange((current) => ({
                  ...current,
                  skills: current.skills.map((entry) => entry.id === skill.id ? { ...entry, training: event.target.value as SkillTrainingLevel } : entry)
                }))}
              >
                {trainingOrder.map((training) => <option key={training} value={training}>{trainingLabels[training]}</option>)}
              </select>
            </label>
            <label>
              Specialisations (comma separated)
              <input
                value={skill.specialisations.join(', ')}
                onChange={(event) => onChange((current) => ({
                  ...current,
                  skills: current.skills.map((entry) => entry.id === skill.id ? { ...entry, specialisations: parseCsvList(event.target.value) } : entry)
                }))}
              />
            </label>
            <div className="row-end">
              <span className="pill">Target {skillTarget(skill, character.characteristics)}</span>
              <button onClick={() => onChange((current) => ({
                ...current,
                skills: current.skills.filter((entry) => entry.id !== skill.id)
              }))}>Remove</button>
            </div>
          </div>
        ))}
      </div>
      <button onClick={() => onChange((current) => ({
        ...current,
        skills: [
          ...current.skills,
          {
            id: crypto.randomUUID(),
            name: '',
            characteristic: 'perception',
            training: 'untrained',
            specialisations: []
          }
        ]
      }))}>Add Skill</button>
    </Panel>
  )
}

function NotesPanel({ character, onChange }: { character: Character; onChange: (updater: (character: Character) => Character) => void }) {
  const noteSections: Array<'talents' | 'traits' | 'mutations' | 'disorders' | 'psychicPowers' | 'specialAbilities'> = [
    'talents',
    'traits',
    'mutations',
    'disorders',
    'psychicPowers',
    'specialAbilities'
  ]

  return (
    <Panel title="Notes and Textual Sections" subtitle="One-per-line editing for narrative and rules-adjacent sections">
      <div className="notes-grid">
        {noteSections.map((key) => (
          <label key={key}>
            {key}
            <textarea
              value={character.notes[key].join('\n')}
              onChange={(event) => onChange((current) => ({
                ...current,
                notes: {
                  ...current.notes,
                  [key]: parseLineList(event.target.value)
                }
              }))}
            />
          </label>
        ))}
        <label className="notes-wide">
          Freeform Notes
          <textarea
            value={character.notes.notes}
            onChange={(event) => onChange((current) => ({
              ...current,
              notes: {
                ...current.notes,
                notes: event.target.value
              }
            }))}
          />
        </label>
      </div>
    </Panel>
  )
}

function EquipmentPanel(props: {
  character: Character
  weaponCatalog: WeaponCompendiumCatalog
  armourCatalog: ArmourCompendiumCatalog
  onChange: (updater: (character: Character) => Character) => void
  onWeaponCatalogChange: (catalog: WeaponCompendiumCatalog) => void
  onArmourCatalogChange: (catalog: ArmourCompendiumCatalog) => void
}) {
  const { character, weaponCatalog, armourCatalog, onChange, onWeaponCatalogChange, onArmourCatalogChange } = props
  const [weaponQuery, setWeaponQuery] = useState('')
  const [armourQuery, setArmourQuery] = useState('')
  const [weaponImportPayload, setWeaponImportPayload] = useState('')
  const [armourImportPayload, setArmourImportPayload] = useState('')
  const [weaponImportPreview, setWeaponImportPreview] = useState<{ catalog: WeaponCompendiumCatalog; summary: string } | null>(null)
  const [armourImportPreview, setArmourImportPreview] = useState<{ catalog: ArmourCompendiumCatalog; summary: string } | null>(null)
  const [importError, setImportError] = useState<string>('')

  const matchingWeapons = useMemo(() => weaponAutocomplete(weaponCatalog.definitions, weaponQuery), [weaponCatalog, weaponQuery])
  const matchingArmour = useMemo(() => armourAutocomplete(armourCatalog.definitions, armourQuery), [armourCatalog, armourQuery])

  return (
    <div className="panel-grid">
      <Panel title="Weapons and Armour" subtitle="Character-owned equipment remains detached from the compendium">
        <div className="stack">
          <h4>Weapons</h4>
          {character.equipment.weapons.map((weapon) => (
            <WeaponEditorCard key={weapon.id} weapon={weapon} onChange={(next) => onChange((current) => ({
              ...current,
              equipment: {
                ...current.equipment,
                weapons: current.equipment.weapons.map((entry) => entry.id === weapon.id ? next : entry)
              }
            }))} onDelete={() => onChange((current) => ({
              ...current,
              equipment: {
                ...current.equipment,
                weapons: current.equipment.weapons.filter((entry) => entry.id !== weapon.id)
              }
            }))} />
          ))}
          <button onClick={() => onChange((current) => ({
            ...current,
            equipment: {
              ...current.equipment,
              weapons: [
                ...current.equipment.weapons,
                { id: crypto.randomUUID(), name: '', type: '', range: '', damage: '', penetration: '', clip: '', reload: '', traits: '' }
              ]
            }
          }))}>Add Manual Weapon</button>

          <label>
            Weapon Compendium Search
            <input value={weaponQuery} onChange={(event) => setWeaponQuery(event.target.value)} placeholder="Search weapon catalog" />
          </label>
          <div className="search-results">
            {matchingWeapons.map((definition) => (
              <button key={definition.id} className="search-result" onClick={() => onChange((current) => addDetachedWeapon(current, definition))}>
                <strong>{definition.name}</strong>
                <span>{[definition.type, definition.range, definition.damage, definition.penetration && `Pen ${definition.penetration}`].filter(Boolean).join(' · ')}</span>
              </button>
            ))}
          </div>

          <h4>Armour</h4>
          {character.equipment.armour.map((armour) => (
            <ArmourEditorCard key={armour.id} armour={armour} onChange={(next) => onChange((current) => ({
              ...current,
              equipment: {
                ...current.equipment,
                armour: current.equipment.armour.map((entry) => entry.id === armour.id ? next : entry)
              }
            }))} onDelete={() => onChange((current) => ({
              ...current,
              equipment: {
                ...current.equipment,
                armour: current.equipment.armour.filter((entry) => entry.id !== armour.id)
              }
            }))} />
          ))}
          <button onClick={() => onChange((current) => ({
            ...current,
            equipment: {
              ...current.equipment,
              armour: [...current.equipment.armour, { id: crypto.randomUUID(), location: '', armourPoints: 0 }]
            }
          }))}>Add Manual Armour</button>

          <label>
            Armour Compendium Search
            <input value={armourQuery} onChange={(event) => setArmourQuery(event.target.value)} placeholder="Search armour catalog" />
          </label>
          <div className="search-results">
            {matchingArmour.map((definition) => (
              <button key={definition.id} className="search-result" onClick={() => onChange((current) => addDetachedArmour(current, definition))}>
                <strong>{definition.name}</strong>
                <span>{[definition.category, definition.coverage.join(', '), `AP ${definition.armourPoints}`].filter(Boolean).join(' · ')}</span>
              </button>
            ))}
          </div>
        </div>
      </Panel>

      <Panel title="Movement and Inventory" subtitle="Operational movement profile and carried items">
        <div className="inline-grid four-up">
          {[
            ['halfMove', 'Half'],
            ['fullMove', 'Full'],
            ['charge', 'Charge'],
            ['run', 'Run']
          ].map(([key, label]) => (
            <label key={key}>
              {label}
              <input
                type="number"
                value={character.equipment.movement[key as keyof Character['equipment']['movement']]}
                onChange={(event) => onChange((current) => ({
                  ...current,
                  equipment: {
                    ...current.equipment,
                    movement: {
                      ...current.equipment.movement,
                      [key]: numberInput(event)
                    }
                  }
                }))}
              />
            </label>
          ))}
        </div>
        <div className="stack">
          {character.equipment.inventory.map((item) => (
            <div className="card-row" key={item.id}>
              <label>
                Item
                <input
                  value={item.name}
                  onChange={(event) => onChange((current) => ({
                    ...current,
                    equipment: {
                      ...current.equipment,
                      inventory: current.equipment.inventory.map((entry) => entry.id === item.id ? { ...entry, name: event.target.value } : entry)
                    }
                  }))}
                />
              </label>
              <label>
                Quantity
                <input
                  type="number"
                  value={item.quantity}
                  onChange={(event) => onChange((current) => ({
                    ...current,
                    equipment: {
                      ...current.equipment,
                      inventory: current.equipment.inventory.map((entry) => entry.id === item.id ? { ...entry, quantity: numberInput(event) } : entry)
                    }
                  }))}
                />
              </label>
              <label>
                Weight
                <input
                  type="number"
                  step="0.1"
                  value={item.weight}
                  onChange={(event) => onChange((current) => ({
                    ...current,
                    equipment: {
                      ...current.equipment,
                      inventory: current.equipment.inventory.map((entry) => entry.id === item.id ? { ...entry, weight: numberInput(event) } : entry)
                    }
                  }))}
                />
              </label>
              <button onClick={() => onChange((current) => ({
                ...current,
                equipment: {
                  ...current.equipment,
                  inventory: current.equipment.inventory.filter((entry) => entry.id !== item.id)
                }
              }))}>Remove</button>
            </div>
          ))}
        </div>
        <button onClick={() => onChange((current) => ({
          ...current,
          equipment: {
            ...current.equipment,
            inventory: [...current.equipment.inventory, { id: crypto.randomUUID(), name: '', quantity: 1, weight: 0 }]
          }
        }))}>Add Inventory Item</button>
      </Panel>

      <Panel title="Compendium Imports" subtitle="Replace-all imports with explicit confirmation and detached-copy guarantees">
        {importError ? <p className="error-text">{importError}</p> : null}
        <label>
          Weapon Compendium JSON
          <textarea value={weaponImportPayload} onChange={(event) => setWeaponImportPayload(event.target.value)} placeholder='{"schemaVersion":1,"catalog":{"id":"custom","displayName":"Custom Weapons","definitions":[]}}' />
        </label>
        <div className="inline-actions">
          <button onClick={() => {
            const result = parseWeaponCompendiumImport(weaponImportPayload)
            if (!result.ok) {
              setImportError(result.error)
              setWeaponImportPreview(null)
              return
            }
            setImportError('')
            setWeaponImportPreview({ catalog: result.catalog, summary: result.summary })
          }}>Preview Weapon Replace-All</button>
          {weaponImportPreview ? (
            <button className="danger-button" onClick={() => {
              onWeaponCatalogChange(weaponImportPreview.catalog)
              setWeaponImportPreview(null)
              setWeaponImportPayload('')
            }}>Confirm Weapon Replace-All</button>
          ) : null}
        </div>
        {weaponImportPreview ? <p className="callout">{weaponImportPreview.summary}</p> : null}

        <label>
          Armour Compendium JSON
          <textarea value={armourImportPayload} onChange={(event) => setArmourImportPayload(event.target.value)} placeholder='{"schemaVersion":1,"catalog":{"id":"custom-armour","displayName":"Custom Armour","definitions":[]}}' />
        </label>
        <div className="inline-actions">
          <button onClick={() => {
            const result = parseArmourCompendiumImport(armourImportPayload)
            if (!result.ok) {
              setImportError(result.error)
              setArmourImportPreview(null)
              return
            }
            setImportError('')
            setArmourImportPreview({ catalog: result.catalog, summary: result.summary })
          }}>Preview Armour Replace-All</button>
          {armourImportPreview ? (
            <button className="danger-button" onClick={() => {
              onArmourCatalogChange(armourImportPreview.catalog)
              setArmourImportPreview(null)
              setArmourImportPayload('')
            }}>Confirm Armour Replace-All</button>
          ) : null}
        </div>
        {armourImportPreview ? <p className="callout">{armourImportPreview.summary}</p> : null}
      </Panel>
    </div>
  )
}

function WeaponEditorCard({ weapon, onChange, onDelete }: { weapon: Weapon; onChange: (weapon: Weapon) => void; onDelete: () => void }) {
  return (
    <div className="card-row">
      <label>Name<input value={weapon.name} onChange={(event) => onChange({ ...weapon, name: event.target.value })} /></label>
      <label>Type<input value={weapon.type} onChange={(event) => onChange({ ...weapon, type: event.target.value })} /></label>
      <label>Range<input value={weapon.range} onChange={(event) => onChange({ ...weapon, range: event.target.value })} /></label>
      <label>Damage<input value={weapon.damage} onChange={(event) => onChange({ ...weapon, damage: event.target.value })} /></label>
      <label>Penetration<input value={weapon.penetration} onChange={(event) => onChange({ ...weapon, penetration: event.target.value })} /></label>
      <label>Clip<input value={weapon.clip} onChange={(event) => onChange({ ...weapon, clip: event.target.value })} /></label>
      <label>Reload<input value={weapon.reload} onChange={(event) => onChange({ ...weapon, reload: event.target.value })} /></label>
      <label>Traits<input value={weapon.traits} onChange={(event) => onChange({ ...weapon, traits: event.target.value })} /></label>
      <button onClick={onDelete}>Remove</button>
    </div>
  )
}

function ArmourEditorCard({ armour, onChange, onDelete }: { armour: Armour; onChange: (armour: Armour) => void; onDelete: () => void }) {
  return (
    <div className="card-row">
      <label>Location<input value={armour.location} onChange={(event) => onChange({ ...armour, location: event.target.value })} /></label>
      <label>Armour Points<input type="number" value={armour.armourPoints} onChange={(event) => onChange({ ...armour, armourPoints: numberInput(event) })} /></label>
      <button onClick={onDelete}>Remove</button>
    </div>
  )
}

function SessionPanel({ character, onChange }: { character: Character; onChange: (updater: (character: Character) => Character) => void }) {
  const [characteristicCheck, setCharacteristicCheck] = useState<CharacteristicKey>('ballisticSkill')
  const [characteristicModifier, setCharacteristicModifier] = useState(0)
  const [attackModifier, setAttackModifier] = useState(0)
  const [reactionModifier, setReactionModifier] = useState(0)
  const [reactionKind, setReactionKind] = useState<'dodge' | 'parry'>('dodge')
  const [rawDamage, setRawDamage] = useState(12)
  const [targetWounds, setTargetWounds] = useState(10)
  const [targetArmour, setTargetArmour] = useState(4)
  const [targetToughness, setTargetToughness] = useState(3)

  const temporaryModifiers = Object.entries(character.session.temporaryModifiers).map(([label, value]) => ({ label, value }))
  const quickCheck = resolveCharacteristicCheck(
    character.characteristics,
    characteristicCheck,
    characteristicModifier,
    temporaryModifiers,
    character.session.combatConditions
  )
  const attackFlow = resolveAttackFlow(character, attackModifier)
  const reactionFlow = resolveReactionFlow(character, reactionKind, reactionModifier)
  const damage = resolveDamage(
    attackFlow?.weaponName ?? 'Manual Damage',
    rawDamage,
    targetWounds,
    targetArmour,
    targetToughness,
    Number.parseInt(character.equipment.weapons.find((weapon) => weapon.id === character.session.activeWeaponID)?.penetration || '0', 10) || 0
  )

  return (
    <div className="panel-grid">
      <Panel title="Session Workspace" subtitle="Mode toggle, active weapon, pinned checks, modifiers, and conditions">
        <label className="toggle-row">
          <input
            type="checkbox"
            checked={character.session.modeEnabled}
            onChange={(event) => onChange((current) => ({
              ...current,
              session: { ...current.session, modeEnabled: event.target.checked }
            }))}
          />
          Session mode active
        </label>

        <label>
          Active Weapon
          <select
            value={character.session.activeWeaponID ?? ''}
            onChange={(event) => onChange((current) => ({
              ...current,
              session: {
                ...current.session,
                activeWeaponID: event.target.value || null
              }
            }))}
          >
            <option value="">None</option>
            {character.equipment.weapons.map((weapon) => <option key={weapon.id} value={weapon.id}>{weapon.name || 'Unnamed Weapon'}</option>)}
          </select>
        </label>

        <label>
          Pinned Checks (one per line)
          <textarea
            value={character.session.pinnedChecks.join('\n')}
            onChange={(event) => onChange((current) => ({
              ...current,
              session: { ...current.session, pinnedChecks: parseLineList(event.target.value) }
            }))}
          />
        </label>

        <label>
          Combat Conditions (one per line)
          <textarea
            value={character.session.combatConditions.join('\n')}
            onChange={(event) => onChange((current) => ({
              ...current,
              session: { ...current.session, combatConditions: parseLineList(event.target.value) }
            }))}
          />
        </label>

        <ModifierEditor
          modifiers={character.session.temporaryModifiers}
          onChange={(next) => onChange((current) => ({
            ...current,
            session: { ...current.session, temporaryModifiers: next }
          }))}
        />
      </Panel>

      <Panel title="Quick Mechanics" subtitle="Transparent characteristic check inside the session context">
        <div className="inline-grid">
          <label>
            Check
            <select value={characteristicCheck} onChange={(event) => setCharacteristicCheck(event.target.value as CharacteristicKey)}>
              {characteristicOrder.map((key) => <option key={key} value={key}>{characteristicLabels[key]}</option>)}
            </select>
          </label>
          <label>
            Manual Modifier
            <input type="number" value={characteristicModifier} onChange={(event) => setCharacteristicModifier(numberInput(event))} />
          </label>
        </div>
        <CheckResultView result={quickCheck} />
      </Panel>

      <Panel title="Combat Shortcuts" subtitle="Bounded attack/reaction helpers and explainable damage handoff">
        <div className="combat-grid">
          <div>
            <div className="inline-grid">
              <label>
                Attack Modifier
                <input type="number" value={attackModifier} onChange={(event) => setAttackModifier(numberInput(event))} />
              </label>
              <label>
                Reaction
                <select value={reactionKind} onChange={(event) => setReactionKind(event.target.value as 'dodge' | 'parry')}>
                  <option value="dodge">Dodge</option>
                  <option value="parry">Parry</option>
                </select>
              </label>
              <label>
                Reaction Modifier
                <input type="number" value={reactionModifier} onChange={(event) => setReactionModifier(numberInput(event))} />
              </label>
            </div>

            {attackFlow ? (
              <div className="callout">
                <strong>{attackFlow.title}</strong>
                <p>{attackFlow.subtitle}</p>
                <p>Active weapon: {attackFlow.weaponName}</p>
                <p>Auto modifiers: {attackFlow.autoAppliedModifiers.map((item) => `${item.label} ${signedValue(item.value)}`).join(', ') || 'None'}</p>
                <CheckResultView result={attackFlow.result} />
              </div>
            ) : (
              <p className="muted">Choose an active weapon in session state to unlock the attack shortcut.</p>
            )}

            <div className="callout">
              <strong>{reactionFlow.title}</strong>
              <p>{reactionFlow.subtitle}</p>
              <p>Visible conditions: {reactionFlow.visibleConditions.join(', ') || 'None'}</p>
              <CheckResultView result={reactionFlow.result} />
            </div>
          </div>

          <div className="callout">
            <strong>Damage Helper</strong>
            <div className="inline-grid">
              <label>Raw Damage<input type="number" value={rawDamage} onChange={(event) => setRawDamage(numberInput(event))} /></label>
              <label>Target Wounds<input type="number" value={targetWounds} onChange={(event) => setTargetWounds(numberInput(event))} /></label>
              <label>Target Armour<input type="number" value={targetArmour} onChange={(event) => setTargetArmour(numberInput(event))} /></label>
              <label>Target TB<input type="number" value={targetToughness} onChange={(event) => setTargetToughness(numberInput(event))} /></label>
            </div>
            <dl className="summary-list">
              <div><dt>Source</dt><dd>{damage.sourceLabel}</dd></div>
              <div><dt>Effective Armour</dt><dd>{damage.breakdown.effectiveArmour}</dd></div>
              <div><dt>Total Mitigation</dt><dd>{damage.breakdown.totalMitigation}</dd></div>
              <div><dt>Applied Damage</dt><dd>{damage.breakdown.appliedDamage}</dd></div>
              <div><dt>Wounds After</dt><dd>{damage.breakdown.woundsAfter}</dd></div>
              <div><dt>Overflow</dt><dd>{damage.breakdown.overflowDamage}</dd></div>
            </dl>
          </div>
        </div>
      </Panel>
    </div>
  )
}

function ModifierEditor({
  modifiers,
  onChange
}: {
  modifiers: Record<string, number>
  onChange: (modifiers: Record<string, number>) => void
}) {
  const entries = Object.entries(modifiers)
  return (
    <div className="stack">
      <h4>Temporary Modifiers</h4>
      {entries.map(([label, value]) => (
        <div className="card-row" key={label}>
          <label>
            Label
            <input value={label} readOnly />
          </label>
          <label>
            Value
            <input type="number" value={value} onChange={(event) => onChange({ ...modifiers, [label]: numberInput(event) })} />
          </label>
          <button
            onClick={() => {
              const next = { ...modifiers }
              delete next[label]
              onChange(next)
            }}
          >
            Remove
          </button>
        </div>
      ))}
      <button onClick={() => {
        const base = entries.length + 1
        onChange({ ...modifiers, [`Modifier ${base}`]: 10 })
      }}>Add Modifier</button>
    </div>
  )
}

function ProgressionPanel({ character, onApply }: { character: Character; onApply: (character: Character) => void }) {
  const [kind, setKind] = useState<'characteristicAdvance' | 'skillAdvance' | 'talentUnlock'>('characteristicAdvance')
  const [characteristic, setCharacteristic] = useState<CharacteristicKey>('strength')
  const [delta, setDelta] = useState(5)
  const [cost, setCost] = useState(0)
  const [skillID, setSkillID] = useState(character.skills[0]?.id ?? '')
  const [targetTraining, setTargetTraining] = useState<SkillTrainingLevel>('known')
  const [talentName, setTalentName] = useState('')
  const [requiredAptitudesText, setRequiredAptitudesText] = useState('')
  const [requiredTalent, setRequiredTalent] = useState('')
  const [requiredTrait, setRequiredTrait] = useState('')
  const [requiredSkillName, setRequiredSkillName] = useState('')
  const [requiredSkillTraining, setRequiredSkillTraining] = useState<SkillTrainingLevel>('known')
  const [minimumEnabled, setMinimumEnabled] = useState(false)
  const [minimumCharacteristic, setMinimumCharacteristic] = useState<CharacteristicKey>('toughness')
  const [minimumValue, setMinimumValue] = useState(30)

  const prerequisites = [
    ...parseCsvList(requiredAptitudesText).map((value) => ({ kind: 'requiredAptitude', value } as const)),
    ...(requiredTalent.trim() ? [{ kind: 'requiredTalent', value: requiredTalent } as const] : []),
    ...(requiredTrait.trim() ? [{ kind: 'requiredTrait', value: requiredTrait } as const] : []),
    ...(requiredSkillName.trim() ? [{ kind: 'requiredSkill', name: requiredSkillName, minimumTraining: requiredSkillTraining } as const] : []),
    ...(minimumEnabled ? [{ kind: 'minimumCharacteristic', characteristic: minimumCharacteristic, value: minimumValue } as const] : [])
  ]

  const skill = character.skills.find((entry) => entry.id === skillID) ?? character.skills[0]
  const allowedTargetTraining = skill ? [nextTrainingLevel(skill.training) ?? skill.training] : ['known' as const]
  const suggestedSkillCost = kind === 'skillAdvance' && skill
    ? suggestedSkillAdvanceCost(character, skill, targetTraining)
    : null

  useEffect(() => {
    if (kind === 'characteristicAdvance') {
      setDelta(5)
      setCost(0)
      return
    }

    if (kind !== 'skillAdvance') {
      return
    }

    const allowed = allowedTargetTraining[0]
    if (allowed && targetTraining !== allowed) {
      setTargetTraining(allowed)
      return
    }

    setCost(suggestedSkillCost ?? 0)
  }, [
    kind,
    skill?.id,
    skill?.training,
    targetTraining,
    allowedTargetTraining,
    suggestedSkillCost
  ])

  const upgrade =
    kind === 'characteristicAdvance'
      ? { kind, characteristic, delta, cost, prerequisites }
      : kind === 'skillAdvance'
        ? { kind, skillID: skill?.id ?? '', skillName: skill?.name ?? '', targetTraining, cost, prerequisites }
        : { kind, talentName, cost, prerequisites }

  const validation = validateOrApplyXPSpend(character, upgrade, false)

  return (
    <div className="panel-grid">
      <Panel title="XP Spending" subtitle="Bounded apply flow with explainable prerequisite validation">
        <div className="inline-grid">
          <label>
            Upgrade Type
            <select value={kind} onChange={(event) => setKind(event.target.value as typeof kind)}>
              <option value="characteristicAdvance">Characteristic</option>
              <option value="skillAdvance">Skill</option>
              <option value="talentUnlock">Talent</option>
            </select>
          </label>
          <label>
            XP Cost
            <input type="number" value={cost} onChange={(event) => setCost(numberInput(event))} />
          </label>
        </div>
        <p className="meta-line">
          {kind === 'characteristicAdvance'
            ? 'DH2 characteristic advances are one +5 step at a time. XP stays manual here because characteristic advance tiers are not yet tracked.'
            : kind === 'skillAdvance'
              ? 'DH2 skill advances are one rank at a time. The XP field is auto-suggested only for verified canonical aptitude pairs.'
              : 'Talent XP remains a bounded manual entry with explicit prerequisite validation.'}
        </p>

        {kind === 'characteristicAdvance' ? (
          <div className="inline-grid">
            <label>
              Characteristic
              <select value={characteristic} onChange={(event) => setCharacteristic(event.target.value as CharacteristicKey)}>
                {characteristicOrder.map((key) => <option key={key} value={key}>{characteristicLabels[key]}</option>)}
              </select>
            </label>
            <label>
              Increase
              <input type="number" value={delta} readOnly />
            </label>
          </div>
        ) : null}

        {kind === 'skillAdvance' ? (
          <div className="inline-grid">
            <label>
              Skill
              <select value={skill?.id ?? ''} onChange={(event) => setSkillID(event.target.value)}>
                {character.skills.map((entry) => <option key={entry.id} value={entry.id}>{entry.name || 'Unnamed Skill'}</option>)}
              </select>
            </label>
            <label>
              Target Training
              <select value={targetTraining} onChange={(event) => setTargetTraining(event.target.value as SkillTrainingLevel)}>
                {allowedTargetTraining.map((training) => <option key={training} value={training}>{trainingLabels[training]}</option>)}
              </select>
            </label>
          </div>
        ) : null}

        {kind === 'talentUnlock' ? (
          <label>
            Talent Name
            <input value={talentName} onChange={(event) => setTalentName(event.target.value)} />
          </label>
        ) : null}

        <div className="stack">
          <h4>Prerequisites</h4>
          <label>Required Aptitudes (comma separated)<input value={requiredAptitudesText} onChange={(event) => setRequiredAptitudesText(event.target.value)} /></label>
          <label>Required Talent<input value={requiredTalent} onChange={(event) => setRequiredTalent(event.target.value)} /></label>
          <label>Required Trait<input value={requiredTrait} onChange={(event) => setRequiredTrait(event.target.value)} /></label>
          <div className="inline-grid">
            <label>Required Skill<input value={requiredSkillName} onChange={(event) => setRequiredSkillName(event.target.value)} /></label>
            <label>
              Minimum Training
              <select value={requiredSkillTraining} onChange={(event) => setRequiredSkillTraining(event.target.value as SkillTrainingLevel)}>
                {trainingOrder.map((training) => <option key={training} value={training}>{trainingLabels[training]}</option>)}
              </select>
            </label>
          </div>
          <label className="toggle-row">
            <input type="checkbox" checked={minimumEnabled} onChange={(event) => setMinimumEnabled(event.target.checked)} />
            Require minimum characteristic
          </label>
          {minimumEnabled ? (
            <div className="inline-grid">
              <label>
                Characteristic
                <select value={minimumCharacteristic} onChange={(event) => setMinimumCharacteristic(event.target.value as CharacteristicKey)}>
                  {characteristicOrder.map((key) => <option key={key} value={key}>{characteristicLabels[key]}</option>)}
                </select>
              </label>
              <label>
                Minimum Value
                <input type="number" value={minimumValue} onChange={(event) => setMinimumValue(numberInput(event))} />
              </label>
            </div>
          ) : null}
        </div>
      </Panel>

      <Panel title="Validation" subtitle="Explainable breakdown before applying XP">
        <dl className="summary-list">
          <div><dt>Upgrade</dt><dd>{xpUpgradeSummary(upgrade)}</dd></div>
          <div><dt>Cost</dt><dd>{validation.cost} XP</dd></div>
          <div><dt>Available</dt><dd>{validation.availableExperience} XP</dd></div>
          <div><dt>Projected Remaining</dt><dd>{validation.projectedRemainingExperience} XP</dd></div>
          <div><dt>Status</dt><dd>{validation.isValid ? 'Ready' : 'Blocked'}</dd></div>
        </dl>
        <div className="stack">
          {validation.prerequisiteEvaluations.map((entry) => (
            <div key={`${entry.label}-${entry.detail}`} className={entry.isSatisfied ? 'check-line ok' : 'check-line blocked'}>
              <strong>{entry.label}</strong>
              <p>{entry.detail}</p>
            </div>
          ))}
        </div>
        {validation.validationErrors.length > 0 ? (
          <ul className="error-list">
            {validation.validationErrors.map((error) => <li key={error}>{error}</li>)}
          </ul>
        ) : null}
        <button
          className="primary-button"
          disabled={!validation.isValid}
          onClick={() => {
            const result = validateOrApplyXPSpend(character, upgrade, true)
            if (result.appliedCharacter) {
              onApply(result.appliedCharacter)
            }
          }}
        >
          Apply XP Spend
        </button>
      </Panel>
    </div>
  )
}

function DossierPanel({ character }: { character: Character }) {
  const dossier = composeDossier(character)
  return (
    <Panel title="Dossier Preview" subtitle="Browser-friendly equivalent of the accepted dossier/export flow">
      <div className="inline-actions">
        <button className="primary-button" onClick={() => window.print()}>Print / Share</button>
        <span className="meta-line">{dossier.metadataLine}</span>
      </div>
      <article className="dossier">
        <header className="dossier-header">
          <h2>{dossier.title}</h2>
          <p>{dossier.subtitle}</p>
          <small>{dossier.filenameStem}</small>
        </header>
        {dossier.sections.map((section) => (
          <section key={section.title} className="dossier-section">
            <h3>{section.title}</h3>
            {section.subtitle ? <p className="muted">{section.subtitle}</p> : null}
            {section.fields.map((field) => (
              <div key={`${section.title}-${field.label}`} className="dossier-field">
                <dt>{field.label}</dt>
                <dd>{field.value}</dd>
              </div>
            ))}
            {section.paragraphs.map((paragraph) => <p key={paragraph}>{paragraph}</p>)}
            {section.bullets.length > 0 ? (
              <ul>
                {section.bullets.map((bullet) => <li key={bullet}>{bullet}</li>)}
              </ul>
            ) : null}
          </section>
        ))}
      </article>
    </Panel>
  )
}

function CheckResultView({ result }: { result: ReturnType<typeof resolveCharacteristicCheck> }) {
  return (
    <div className="callout">
      <dl className="summary-list">
        <div><dt>Check</dt><dd>{result.checkName}</dd></div>
        <div><dt>Source</dt><dd>{result.sourceName}</dd></div>
        <div><dt>Base</dt><dd>{result.baseValue}</dd></div>
        <div><dt>Derived Bonus</dt><dd>{result.derivedBonus}</dd></div>
        {result.trainingContribution !== null ? <div><dt>Training</dt><dd>{signedValue(result.trainingContribution)}</dd></div> : null}
        <div><dt>Applied Modifier</dt><dd>{signedValue(result.appliedModifier)}</dd></div>
        <div><dt>Final Target</dt><dd>{result.finalTarget}</dd></div>
      </dl>
      <ul className="contribution-list">
        {result.contributions.map((contribution, index) => (
          <li key={`${contribution.label}-${index}`}>
            <strong>{contribution.label}</strong>
            <span>{signedValue(contribution.value)}{contribution.appliesToFinalTarget ? ' to final target' : ' informational'}</span>
          </li>
        ))}
      </ul>
      {result.conditions.length > 0 ? <p className="muted">Conditions: {result.conditions.join(', ')}</p> : null}
    </div>
  )
}

export default App
