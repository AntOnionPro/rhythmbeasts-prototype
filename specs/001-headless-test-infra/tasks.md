---

description: "Task list for 001-headless-test-infra"
---

# Tasks: Infraestructura de tests headless del núcleo rítmico

**Input**: Design documents from `/specs/001-headless-test-infra/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/test-runner-cli.md, quickstart.md

**Tests**: la spec pide tests explícitamente (FR-005, FR-006) y la constitución los exige para el
núcleo rítmico (principio VI). Los tests de US2 son el entregable en sí.

**Organization**: tareas agrupadas por historia de usuario para poder verificar cada una por separado.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Proyecto Godot en `rythmbeasts-prototype/`; todas las rutas `res://` son relativas a esa carpeta.
- Comando de tests (ver [contracts/test-runner-cli.md](contracts/test-runner-cli.md)), desde la raíz
  del repo: `godot --headless --path rythmbeasts-prototype --import && godot --headless --path rythmbeasts-prototype -s res://addons/gut/gut_cmdln.gd`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: instalar el addon y su configuración.

- [X] T001 Copiar sin modificar la carpeta `addons/gut/` del tag `v9.7.1` de https://github.com/bitwes/Gut a `rythmbeasts-prototype/addons/gut/` (incluidos sus `.uid`, `.import` y `LICENSE.md`); no activar el plugin ni editar `rythmbeasts-prototype/project.godot`
- [X] T002 [P] Crear `rythmbeasts-prototype/.gutconfig.json` con exactamente: `dirs: ["res://tests/unit/"]`, `include_subdirs: true`, `prefix: "test_"`, `suffix: ".gd"`, `should_exit: true`, `log_level: 1`, `post_run_script: "res://tests/gut_post_run_hook.gd"`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: el hook que garantiza códigos de salida fiables; bloquea todas las historias.

- [X] T003 Crear `rythmbeasts-prototype/tests/gut_post_run_hook.gd` que extienda `GutHookScript`, con docstring `##` que explique por qué existe (GUT termina con 0 si un script de test no carga) y la regla de data-model.md: "si `errors > 0`, `warnings > 0` o `tests == 0`, emite un error explicativo y fija el código de salida a 1"; código de salida en una constante con nombre, tipado estático completo
- [X] T004 Importar el proyecto (`godot --headless --path rythmbeasts-prototype --import`) para generar `rythmbeasts-prototype/tests/gut_post_run_hook.gd.uid`, y comprobar con `git status` que no cambió ningún archivo existente (ni de `addons/gut/` ni del resto del proyecto)

**Checkpoint**: infraestructura lista; una ejecución sin tests debe terminar con código 1 (`tests == 0`).

---

## Phase 3: User Story 1 - Ejecutar la suite con un solo comando (Priority: P1) 🎯 MVP

**Goal**: un único comando ejecuta la suite sin ventana y su código de salida es fiable.

**Independent Test**: con un test temporal, el comando devuelve 0 si pasa, 1 si falla y 1 si no carga.

- [X] T005 [US1] Verificar el contrato con un archivo temporal `rythmbeasts-prototype/tests/unit/test_tmp_probe.gd` (`extends GutTest`): (a) una aserción que pasa → código 0 y "All tests passed"; (b) una aserción que falla → código 1 con el test identificado; (c) una variable sin tipo → "Test run rejected" y código 1. Después borrar el archivo y su `.uid`
- [X] T006 [US1] Verificar SC-001 en una copia del proyecto sin `.godot/` (en un directorio temporal fuera del repo): el comando completo (importación más GUT) termina en menos de 60 s; con la suite vacía debe devolver 1 por la regla `tests == 0`

**Checkpoint**: US1 funcional; el comando es fiable aunque aún no haya tests permanentes.

---

## Phase 4: User Story 2 - El snapping a la rejilla y la pista musical están protegidos (Priority: P2)

**Goal**: tests permanentes del ajuste a la rejilla y de `MusicTrack`.

**Independent Test**: la suite pasa en verde; si se altera el redondeo del ajuste, falla al menos un test.

- [X] T007 [P] [US2] Crear `rythmbeasts-prototype/tests/unit/music/test_music_track.gd`: duración del pulso igual a `MusicTrack.SECONDS_PER_MINUTE / bpm` para un BPM de prueba con nombre (p. ej. `TEST_BPM: float = 150.0`); duración del loop igual a `length_beats * get_seconds_per_beat()`; un recurso nuevo usa `MusicTrack.DEFAULT_BPM` y `MusicTrack.DEFAULT_LENGTH_BEATS`. Recursos creados con `MusicTrack.new()`, sin cargar `.tres` ni audio
- [X] T008 [P] [US2] Crear `rythmbeasts-prototype/tests/unit/core/test_beat_snap.gd` sobre `Conductor.get_nearest_subdivision(time_sec, sub)` con el autoload detenido, derivando la duración de paso de `Conductor.get_seconds_per_beat() / sub`: (1) instante exacto sobre un paso → ese `step`, `time_sec` igual y `offset_ms` ≈ 0; (2) ligeramente tarde (`SMALL_OFFSET_SEC` con nombre) → mismo paso y `offset_ms` ≈ +offset·1000; (3) ligeramente temprano → mismo paso y `offset_ms` negativo; (4) justo antes del beat 0 → `step` 0 y `offset_ms` negativo; (5) negra, corchea y semicorchea → `steps_per_beat` igual a `Conductor.Subdivision.*` y `beat == float(step) / steps_per_beat`. Usar `assert_almost_eq` con una tolerancia con nombre para los flotantes
- [X] T009 [US2] Importar (genera los `.uid` de T007 y T008) y ejecutar la suite: todos los tests en verde y código 0
- [X] T010 [US2] Verificar SC-003: cambiar temporalmente `roundi` por `floori` en `get_nearest_subdivision()` de `rythmbeasts-prototype/src/core/conductor.gd`, ejecutar la suite (debe fallar al menos un test y devolver 1), y restaurar con `git checkout -- rythmbeasts-prototype/src/core/conductor.gd`; confirmar que `git diff` sobre `src/` queda vacío

**Checkpoint**: US1 y US2 funcionan; el núcleo de la rejilla está protegido.

---

## Phase 5: User Story 3 - Añadir un test nuevo es trivial (Priority: P3)

**Goal**: la convención basta para que la suite descubra un test nuevo.

**Independent Test**: un archivo nuevo en una subcarpeta de `tests/unit/` se ejecuta sin tocar la configuración.

- [X] T011 [US3] Crear temporalmente `rythmbeasts-prototype/tests/unit/tmp/test_tmp_trivial.gd` con `func test_trivial() -> void: assert_true(true)`, ejecutar la suite y comprobar que aparece y pasa sin tocar `rythmbeasts-prototype/.gutconfig.json`; después borrar la carpeta `tmp/` con su `.uid`

**Checkpoint**: las tres historias verificadas.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T012 [P] Actualizar `CLAUDE.md`: en "Validación", añadir el comando de tests, la convención (`tests/unit/<feature>/test_<pieza>.gd`, que extiende `GutTest`) y que una tarea del núcleo rítmico no está hecha con tests en rojo
- [X] T013 [P] Constitución v1.0.1 en `.specify/memory/constitution.md`: sustituir el punto `TODO(TEST_FRAMEWORK)` del principio VI por el framework elegido (GUT 9.7.1, sin plugin del editor) y la referencia al comando en `CLAUDE.md`; actualizar la línea de versión (1.0.1, enmienda 2026-11-04)
- [X] T014 Ejecutar `godot --headless --path rythmbeasts-prototype --quit` y comparar con la línea base (código 0 más el aviso preexistente de fuga de audio): sin errores ni warnings nuevos (FR-009, SC-005)
- [X] T015 Revisión final: `git status` muestra solo los archivos nuevos del plan (addon, `.gutconfig.json`, hook, tests y sus `.uid`) más `CLAUDE.md` y la constitución; nada en `src/`, `project.godot` ni en `.uid`/`.import` existentes (FR-001, FR-011)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sin dependencias. T001 y T002 son independientes.
- **Foundational (Phase 2)**: depende de T001 y T002; bloquea todas las historias.
- **US1 (Phase 3)**: depende de la fase 2.
- **US2 (Phase 4)**: depende de la fase 2; no necesita US1 para funcionar, pero su verificación usa
  el mismo comando.
- **US3 (Phase 5)**: depende de la fase 2.
- **Polish (Phase 6)**: depende de todas las historias.

### Within Each User Story

- US2: T007 y T008 en paralelo → T009 → T010.

### Parallel Opportunities

- T001 ∥ T002 (archivos distintos).
- T007 ∥ T008 (archivos de test distintos).
- T012 ∥ T013 (documentos distintos).

---

## Parallel Example: User Story 2

```bash
Task: "Crear rythmbeasts-prototype/tests/unit/music/test_music_track.gd"
Task: "Crear rythmbeasts-prototype/tests/unit/core/test_beat_snap.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Fases 1 y 2: addon, configuración y hook.
2. Fase 3: verificar el contrato del comando con un test temporal.
3. **STOP and VALIDATE**: el comando es fiable (0, 1, 1).

### Incremental Delivery

1. MVP (US1) → comando fiable.
2. US2 → primeros tests permanentes del núcleo rítmico.
3. US3 → confirmación de la convención.
4. Polish → documentación (CLAUDE.md, constitución v1.0.1) y validación final.
