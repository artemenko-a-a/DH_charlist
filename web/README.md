# DH CharList Web

## Run

```bash
cd web
npm install
npm run dev
```

## Validate

```bash
cd web
npm run typecheck
npm run test
npm run build
```

## Scope
- local-first Dark Heresy II character workspace
- character lifecycle, editing, session helpers, progression, compendium flows, and dossier preview
- bounded rules behavior only; the web app does not claim complete rules-engine coverage

## Trust notes
- malformed browser-local data falls back safely with warnings
- compendium replace-all imports are previewed before confirmation
- character-owned equipment stays detached from compendium definitions
