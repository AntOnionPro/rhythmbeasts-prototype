# Data Model: Infraestructura de tests headless del núcleo rítmico

Esta feature no añade datos de juego ni recursos `.tres`. Sus "entidades" son piezas de
configuración de la suite de tests.

## Configuración de la suite (`rythmbeasts-prototype/.gutconfig.json`)

| Campo | Valor | Regla |
|---|---|---|
| `dirs` | `["res://tests/unit/"]` | Única raíz de tests unitarios |
| `include_subdirs` | `true` | Descubre tests en subcarpetas (FR-004) |
| `prefix` / `suffix` | `"test_"` / `".gd"` | Convención de nombre de archivo |
| `should_exit` | `true` | La ejecución termina sola (FR-002) |
| `log_level` | `1` | Salida resumida: un renglón por test más el resumen |
| `post_run_script` | `"res://tests/gut_post_run_hook.gd"` | Endurece el código de salida (FR-003) |

## Hook post-ejecución (`rythmbeasts-prototype/tests/gut_post_run_hook.gd`)

- Extiende `GutHookScript` y se ejecuta una vez al final de la suite.
- Lee el resumen de GUT (`errors`, `warnings`, `tests`).
- Regla: si `errors > 0`, `warnings > 0` o `tests == 0`, emite un error explicativo y fija el
  código de salida a 1. En otro caso, no toca el código de salida, así que GUT devuelve 0 si todo
  pasa y 1 si algún test falla.

## Archivo de test

- Ruta: `rythmbeasts-prototype/tests/unit/<feature de src>/test_<pieza>.gd`.
- Extiende `GutTest`; los métodos de test se llaman `test_<comportamiento>()` y devuelven `void`.
- Cumple la constitución: tipado estático, sin números mágicos (constantes con nombre al inicio
  del archivo) y sin depender de audio real ni de la escena principal.

## Estados de una ejecución

```text
importar proyecto ──fallo──▶ código ≠ 0 (no se ejecutan tests)
        │ ok
        ▼
GUT descubre y ejecuta tests
        │
        ▼
hook post-ejecución ──errores/warnings/0 tests──▶ código 1
        │ limpio
        ▼
código 0 si todos pasan · código 1 si alguno falla
```
