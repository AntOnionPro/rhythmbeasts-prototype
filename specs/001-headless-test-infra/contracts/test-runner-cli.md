# Contract: comando de tests (CLI)

Interfaz que la feature expone a desarrolladores, agentes y una futura CI.

## Invocación

Desde la raíz del repositorio, con Godot 4.7.1 disponible como `godot`:

```bash
godot --headless --path rythmbeasts-prototype --import && godot --headless --path rythmbeasts-prototype -s res://addons/gut/gut_cmdln.gd
```

- La primera parte importa el proyecto (crea o actualiza `.godot/`). Es obligatoria: ver
  [research.md](../research.md) R3.
- La segunda ejecuta GUT con `rythmbeasts-prototype/.gutconfig.json`.
- Opciones de GUT útiles durante el desarrollo, añadidas al final de la segunda parte:
  `-gselect=<texto>` (solo scripts cuyo nombre contiene el texto),
  `-gunit_test_name=<texto>` (solo tests cuyo nombre contiene el texto).

## Precondiciones

- Godot **4.7.1** (otra versión menor no está soportada por GUT 9.7.1).
- No hace falta abrir el editor ni activar el plugin de GUT.

## Salida

- Por cada script, su ruta y un renglón por test (`* test_...`), con el detalle de las aserciones
  que fallan.
- Al final, un bloque `Run Summary` con los totales (scripts, tests, tests que pasan, aserciones y
  tiempo) y `---- All tests passed! ----` si todo pasa.
- Si el hook rechaza la ejecución: `ERROR: Test run rejected: N GUT error(s), M GUT warning(s), K test(s).`

## Códigos de salida

| Situación | Código |
|---|---|
| Todos los tests pasan y GUT no registra errores ni warnings | `0` |
| Algún test falla | `1` |
| Algún script de test no carga (error de sintaxis o de tipos, o no extiende `GutTest`) | `1` |
| No se ejecutó ningún test | `1` |
| Falla la importación | ≠ `0` (los tests no llegan a ejecutarse) |
