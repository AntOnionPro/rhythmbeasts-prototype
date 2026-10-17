# AGENTS.md — Rhythm Beasts (prototype)

## Project
- Rhythmic 2D fighting game prototype. Goal: validate that hits and combos generating
  dubstep music in real time, with a reactive stage, is fun. Scope, hypothesis and
  out-of-scope items live in `docs/prototype.md` — read it before proposing features.
- Engine: **Godot 4.7.1 stable**. Language: **GDScript only** (no C#).
- Visuals are placeholders drawn by code (shapes, colors, `_draw()`, simple shaders).
  Do not spend effort on art, animation polish or menus unless explicitly asked.

## Communication & workflow
- Respond in Spanish. Code, identifiers, comments and commit messages in English.
- Before changing anything: summarize what you will do and which files, then wait for approval.
- Touch only what was requested. No drive-by refactors or renames.
- Do not install addons, change the Godot version, or edit `project.godot`, the Input Map
  or autoload registration without asking.
- Do not commit, push, or open issues/PRs unless asked.
- When done: show the diff or changed lines and the validation result. Be concise.

## Project layout (feature-based)
```
addons/          third-party plugins only
assets/          shared raw assets (audio/samples, audio/sfx, fonts)
docs/            design docs
src/core/        autoloads: Conductor (beat clock), EventBus (cross-system signals)
src/combat/      attacks, hitbox/hurtbox, combos, damage
src/fighters/    base fighter scene + per-animal config resources
src/music/       SoundBank, MusicDirector, quantization, DifficultyProfile
src/stage/       reactive stage
src/match/       match flow: 3-minute timer, round result
src/ui/          HUD
src/main/        main scene / entry point
tests/           automated tests (later)
```
- Each feature folder keeps its scenes (`.tscn`), scripts (`.gd`) and data (`.tres`) together.
- Do not create new top-level folders or new `src/` features without asking.
- Never move or rename existing files from the terminal: references and `.uid` files break.
  Ask the user to do it from the Godot editor.

## Naming (Godot style guide)
- Files and folders: `snake_case` (`fighter.gd`, `sound_bank.gd`, `main.tscn`).
- `class_name` and node names: `PascalCase`. Functions and variables: `snake_case`.
  Constants and enum members: `CONSTANT_CASE`. Private members: leading underscore.
- Signals in past tense: `hit_landed`, `combo_finished`, `beat_ticked`.
- Script order: `class_name`/`extends`, `##` docstring, signals, enums, constants, `@export`,
  public vars, private vars, `@onready`, built-in callbacks, public methods, private methods.

## GDScript rules (Godot 4 only)
- Use `@export`, `@onready`, `await`, `super()`, `signal.connect(callable)`, `CharacterBody2D`.
  Never Godot 3 syntax: `export`, `onready`, `yield`, `setget`, `KinematicBody2D`,
  `connect("signal", obj, "method")`.
- Static typing everywhere: variables, parameters, return types (`-> void`), typed arrays
  (`Array[AttackData]`) and typed dictionaries.
- No magic numbers: use constants or `@export` vars.
- Input only through Input Map actions, never hardcoded keys.
- No long `get_node()` paths or `get_parent()` chains: use `@export` node refs, `%UniqueName` or signals.
- "Call down, signal up": parents call children's methods; children emit signals.

## Architecture
- SOLID adapted to Godot: small single-purpose nodes/components composed in scenes;
  composition over deep inheritance; depend on signals and Resources, not concrete nodes.
- Global state only in autoloads under `src/core/`. Keep them few (Conductor, EventBus).
- Tunable data (attacks, combos, sound banks, difficulty) in custom `Resource` classes saved as `.tres`.
- Systems stay decoupled: combat knows nothing about music. Combat emits events ->
  MusicDirector quantizes and plays samples -> emits musical events -> stage reacts.

## Timing & audio (critical)
- Musical time comes only from the Conductor, derived from audio playback:
  `get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()`.
  Never accumulate `delta` to track musical time.
- The Conductor exposes BPM, current beat and subdivision, and beat signals.
- Hit sounds are triggered on the beat grid according to the active `DifficultyProfile`.
- Overlapping samples: `AudioStreamPolyphonic` or a player pool. Use buses `Music` and `SFX`.
- Samples are placeholders: never hardcode sample paths in logic; reference them via `SoundBank` resources.

## Validation
- After every change run: `godot --headless --path . --quit`
- Report errors and warnings. A task is not done while validation fails.
- Do not launch the editor or the game window unless asked.

## Never touch
- `.godot/`, `*.import` files.
- `*.uid` files: never edit or delete them; they are committed with their script.
- `uid=` attributes and `ext_resource` ids inside `.tscn`/`.tres`.
- Hand-edit `.tscn` only for small, safe changes. For complex scenes, describe the node
  tree and ask the user to build it in the editor.
