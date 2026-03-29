export type Weapon = { id: string; name: string; damage: string; notes: string }
export type Armour = { id: string; name: string; location: string; ap: number }

export type Character = {
  id: string
  name: string
  homeWorld: string
  role: string
  characteristics: { ws: number; bs: number; s: number; t: number; ag: number; int: number; per: number; wp: number; fel: number }
  wounds: number
  fatigue: number
  xpAvailable: number
  skills: Array<{ name: string; value: number }>
  notes: string
  weapons: Weapon[]
  armour: Armour[]
}

export type Compendium<T> = { updatedAt: string; entries: T[] }
