# Quickstart: validar la infraestructura de tests

## Prerrequisitos

- Godot 4.7.1 accesible como `godot` (o sustituir `godot` por la ruta al ejecutable).
- Trabajar desde la raíz del repositorio.

## 1. Ejecutar la suite (US1, SC-001, SC-002)

Comando definido en [contracts/test-runner-cli.md](contracts/test-runner-cli.md):

```bash
godot --headless --path rythmbeasts-prototype --import && godot --headless --path rythmbeasts-prototype -s res://addons/gut/gut_cmdln.gd
```

**Esperado**: los tests de `tests/unit/core/` y `tests/unit/music/` aparecen en verde,
`---- All tests passed! ----`, código de salida `0`, en menos de 60 s también en un clon limpio.

## 2. Un test que falla se detecta (US1 escenario 2, SC-003)

1. En una copia local, cambiar temporalmente el redondeo de `Conductor.get_nearest_subdivision()`
   (por ejemplo, `roundi` → `floori`).
2. Ejecutar la suite.

**Esperado**: al menos un test de `test_beat_snap.gd` falla y el código de salida es `1`.
Deshacer el cambio después.

## 3. Un test que no carga se detecta (US1 escenario 3)

1. Crear temporalmente `rythmbeasts-prototype/tests/unit/test_tmp_broken.gd` con
   `extends GutTest` y una variable sin tipo (`var x = 1`) dentro de un método `test_`.
2. Ejecutar la suite.

**Esperado**: `ERROR: Test run rejected: ...` y código de salida `1`. Borrar el archivo (y su `.uid`).

## 4. Añadir un test nuevo no requiere configuración (US3, SC-004)

1. Crear `rythmbeasts-prototype/tests/unit/test_tmp_trivial.gd` con un método
   `test_trivial() -> void` que haga `assert_true(true)`.
2. Ejecutar la suite.

**Esperado**: el test aparece y pasa, sin tocar `.gutconfig.json`. Borrar el archivo (y su `.uid`).

## 5. La validación del proyecto no cambia (FR-009, SC-005)

```bash
godot --headless --path rythmbeasts-prototype --quit
```

**Esperado**: la misma salida que la línea base: código `0` con el aviso preexistente de fuga de
audio al salir (3 instancias de ObjectDB y 1 recurso en uso), sin errores ni warnings nuevos.
