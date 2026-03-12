# Armour Compendium Format

Batch 46 adds a local JSON import path for replacing the armour compendium used by `Equipment` autocomplete.

Scope:
- local-first JSON import only
- replace-all semantics for the local compendium
- imported definitions affect future autocomplete/add-armour flows only
- existing character-owned armour remains detached and unchanged

## Schema v1

```json
{
  "schemaVersion": 1,
  "catalog": {
    "id": "my-armour-catalog",
    "displayName": "My Local Armour Catalog",
    "definitions": [
      {
        "id": "my-armour-catalog.mnemonic-mesh",
        "name": "Mnemonic Mesh",
        "category": "Body Armour",
        "coverage": ["Body"],
        "armourPoints": 5,
        "weight": "6kg",
        "availability": "Rare",
        "traits": ["Flexible"],
        "notes": "Optional freeform note"
      }
    ]
  }
}
```

## Required fields

- `schemaVersion`
- `catalog.id`
- `catalog.displayName`
- `catalog.definitions`
- for each definition:
  - `id`
  - `name`
  - `armourPoints`

All required string fields must be non-empty after trimming. `armourPoints` must be zero or greater.

## Validation behavior

The import is all-or-nothing. The app rejects the file if any of the following are true:
- malformed JSON
- unsupported `schemaVersion`
- empty catalog id or display name
- empty armour definition id or name
- missing or negative armour points
- duplicate armour definition ids within the imported catalog

The app does not silently partially import or repair malformed input.

## Replace semantics

Current import policy:
- replaces the current local armour compendium
- does not merge with the existing compendium
- requires explicit destructive confirmation before replacement
- does not mutate existing character-owned armour instances

## Content boundary

This repository does not ship a bulk copyrighted rulebook catalogue.
The import path is intended for user-supplied structured local data and bounded safe demo content only.
