# Weapon Compendium Format

Batch 44 adds a local JSON import path for replacing the weapon compendium used by `Equipment` autocomplete.

Scope:
- local-first JSON import only
- replace-all semantics for the local compendium
- imported definitions affect future autocomplete/add-weapon flows only
- existing character-owned weapons remain detached and unchanged

## Schema v1

```json
{
  "schemaVersion": 1,
  "catalog": {
    "id": "my-catalog",
    "displayName": "My Local Catalog",
    "definitions": [
      {
        "id": "my-catalog.mnemonic-pistol",
        "name": "Mnemonic Pistol",
        "type": "Pistol",
        "range": "25m",
        "damage": "1d10+3 E",
        "penetration": "3",
        "clip": "12",
        "reload": "Half",
        "traits": ["Compact", "Reliable"],
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

All required string fields must be non-empty after trimming.

## Validation behavior

The import is all-or-nothing. The app rejects the file if any of the following are true:
- malformed JSON
- unsupported `schemaVersion`
- empty catalog id or display name
- empty weapon definition id or name
- duplicate weapon definition ids within the imported catalog

The app does not silently partially import or repair malformed input.

## Replace semantics

Current import policy:
- replaces the current local compendium
- does not merge with the existing compendium
- requires explicit destructive confirmation before replacement
- does not mutate existing character-owned weapon instances

## Content boundary

This repository does not ship a bulk copyrighted rulebook catalog.
The import path is intended for user-supplied structured local data and bounded safe demo content only.
