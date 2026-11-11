# Repository Guidelines

## Project Structure & Module Organization

GameMaker LTS 2026 project (GML 2.3+): one room, `rm_room_1` at 640×360, view 320×180. The IDE
opens `ProjectXY.yyp`.

- `objects/` — one directory per object, one file per event: `Create_0.gml`, `Step_0.gml`,
  `Step_1.gml`, `Other_75.gml` (async system event).
- `scripts/` — constructors and helpers: `scr_vector_2`, `scr_input*`, `scr_state*`,
  `scr_physics`.
- `sprites/`, `rooms/`, `options/`, `datafiles/` — art, rooms, settings.
- `docs/` — per-subsystem reference (`vector2.md`, `movimento.md`, `input.md`, `estado.md`,
  `camera.md`). Read the matching document before changing that subsystem.

## Build, Test, and Development Commands

GameMaker compiles only inside the IDE (press **F5**); there is no CLI build, test runner, or
linter. Static checks before committing:

```sh
rg -n ".{101,}" --glob '*.gml'               # lines over 100 columns
rg -n "[ \t]+$|\t" --glob '*.gml'            # trailing whitespace and tabs
rg -n "TODO: remover depois" --glob '*.gml'  # leftover test code
```

## Coding Style & Naming Conventions

- 4 spaces, never tabs; 100 columns; no trailing whitespace; LF endings, enforced by
  `.gitattributes`. No formatter is configured.
- `snake_case` throughout; `UPPER_CASE` only for macros (`GRAVITY`, `WATER_FACTOR`).
- `_` prefixes locals and parameters; `__` marks private members, read only by the owning struct.
- `#region` inside Create events that mix concerns; `self.` only in `return self;`.
- Document with `///` and singular `@desc`/`@param`/`@return`. Temporary test code uses
  `// TODO: remover depois` so it never reads as JSDoc.

## Testing Guidelines

No test framework or coverage target. Verification is playtesting in the IDE: state what
must be observed (heights, counts, alignment). Confirm numbers quoted in
`docs/` by simulation first.

## Commit & Pull Request Guidelines

Conventional Commits in Portuguese, imperative mood, short bullets ending in a period:

```
refactor: Fecha o acesso aos privados e unifica a velocidade do ar

- Faz as fontes do controle guardarem o gerenciador.
```

Never mention `.yyp`, JSDoc, file names, or method counts. Show the message and wait for explicit
approval before committing — a request to implement is not permission to commit. Work lands on
`main`; no PR workflow.

## Agent-Specific Instructions

- Existing `.yy` metadata may be edited, never created. New objects, scripts, sprites and rooms
  are created by the user in the IDE: when one is required, say so emphatically, naming the
  resource and its contents, so it is not forgotten. Do not touch `.yyp`.
- Update docs only while preparing a commit, auditing code against doc: names, fields, numbers,
  stale references.
