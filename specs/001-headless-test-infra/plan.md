# Implementation Plan: Infraestructura de tests headless del núcleo rítmico

**Branch**: `001-headless-test-infra` (trabajo en `claude/intelligent-edison-cph3n9`) | **Date**: 2026-11-04 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-headless-test-infra/spec.md`

## Summary

Instalar GUT 9.7.1 como addon de terceros y dejar una suite de tests unitarios que se ejecuta sin
ventana con un solo comando: importación previa más GUT por CLI. Un hook posterior a la suite
endurece el código de salida, porque GUT, por sí solo, devuelve 0 cuando un script de test no
carga. Primeros tests: el ajuste a la rejilla (`Conductor.get_nearest_subdivision` / `BeatSnap`) y
`MusicTrack`. Sin tocar `src/` ni `project.godot`. Detalle en [research.md](research.md).

## Technical Context

**Language/Version**: GDScript, Godot 4.7.1 stable

**Primary Dependencies**: GUT 9.7.1 (addon de terceros, MIT)

**Storage**: N/A

**Testing**: GUT por línea de comandos (`gut_cmdln.gd`) en modo headless

**Target Platform**: escritorio (Linux, macOS o Windows) con Godot 4.7.1; tests en headless

**Project Type**: juego 2D en Godot (un solo proyecto en `rythmbeasts-prototype/`)

**Performance Goals**: suite completa, con importación, en menos de 60 s en un clon limpio

**Constraints**: no modificar `src/`, `project.godot`, el Input Map, los autoloads ni ningún
`.uid`/`.import` existente; los tests no usan audio real ni la escena principal

**Scale/Scope**: 2 archivos de test (~10 casos), 1 hook y 1 archivo de configuración

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Regla | Estado | Nota |
|---|---|---|
| I. Fases guiadas por hipótesis | ✅ | La spec declara que es un habilitador de "suena musical, no a ruido" |
| II. El audio es el reloj | ✅ | No cambia el cálculo de tiempo; lo cubre con tests |
| III. Sistemas desacoplados | ✅ | Los tests usan la API pública; no se añaden autoloads |
| IV. Datos antes que código | ✅ | Valores esperados derivados de constantes con nombre y de la API |
| V. GDScript Godot 4 estricto | ✅ | Tests y hook tipados; el proyecto rechaza código sin tipos (R7) |
| VI. Tests del núcleo rítmico | ✅ | Esta feature lo implementa y cierra `TODO(TEST_FRAMEWORK)` |
| Restricción: addons con aprobación | ✅ | GUT aprobado por el usuario el 2026-11-04 |
| Restricción: `project.godot` / autoloads | ✅ | Sin cambios; el plugin del editor no se activa (R2) |
| Restricción: carpetas nuevas | ✅ | Solo subcarpetas dentro de `tests/` y `addons/`, que ya existen |
| Restricción: `.uid` / `.import` | ✅ | No se editan; los `.uid` nuevos los genera Godot y se commitean |
| Definición de hecho | ✅ | Validación headless sin cambios (R9) más la suite en verde |

**Post-diseño (tras la Fase 1)**: sin cambios; todas las reglas siguen en ✅. El hook es código de
infraestructura de tests, no de juego, y respeta los principios V y IV.

## Project Structure

### Documentation (this feature)

```text
specs/001-headless-test-infra/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── test-runner-cli.md
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
rythmbeasts-prototype/
├── .gutconfig.json              # NUEVO: configuración de GUT
├── addons/
│   └── gut/                     # NUEVO: GUT 9.7.1 sin modificar (tercero, MIT)
└── tests/
    ├── gut_post_run_hook.gd     # NUEVO: código de salida estricto
    ├── manual/                  # existente, sin cambios
    └── unit/                    # NUEVO
        ├── core/
        │   └── test_beat_snap.gd
        └── music/
            └── test_music_track.gd

CLAUDE.md                        # se añade el comando de tests
.specify/memory/constitution.md  # v1.0.1: cierra TODO(TEST_FRAMEWORK)
```

**Structure Decision**: proyecto Godot único. Los tests unitarios viven en
`rythmbeasts-prototype/tests/unit/` reflejando las features de `src/`; la infraestructura de GUT
(configuración y hook) queda en la raíz del proyecto y en `tests/`.

## Complexity Tracking

Sin violaciones de la constitución que justificar.
