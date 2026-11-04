# Research: Infraestructura de tests headless del núcleo rítmico

Todas las decisiones se verificaron con Godot 4.7.1 headless sobre una copia del proyecto
(2026-11-04).

## R1. Framework de tests

- **Decision**: GUT 9.7.1 (rama `godot_4_7`).
- **Rationale**: elección del usuario. Es la versión que el propio proyecto GUT declara para
  Godot 4.7.x, es solo GDScript, tiene licencia MIT y ejecución por línea de comandos.
- **Alternatives considered**: gdUnit4 (más funciones, como el scene runner y el soporte de C#, pero
  más pesado y sin necesidad actual).

## R2. Forma de instalación

- **Decision**: copiar `addons/gut/` del tag `v9.7.1` tal cual (incluye sus `.uid` e `.import`)
  a `rythmbeasts-prototype/addons/gut/`. No se activa el plugin del editor.
- **Rationale**: la ejecución por CLI no necesita el plugin, y activarlo modificaría
  `project.godot` (requiere aprobación aparte). Se verificó que importar el proyecto no altera
  ningún archivo del addon.
- **Alternatives considered**: Asset Library (solo ofrece la última versión de GUT; no permite
  fijar la 9.7.1); submódulo git (complica los clones y mete el repo entero de GUT, no solo el addon).

## R3. Importación previa obligatoria

- **Decision**: el comando de tests siempre importa el proyecto antes de ejecutar GUT
  (`--import && ... -s gut_cmdln.gd`).
- **Rationale**: en un clon sin `.godot/`, los autoloads registrados por UID no cargan y GUT no
  llega a ejecutarse, pero Godot **termina con código 0** (falso positivo verificado). Importar
  tarda unos 8 s en frío y 2–3 s con caché.
- **Alternatives considered**: documentar "abre el editor una vez" (no sirve para agentes ni CI);
  confiar en que exista `.godot/` (falso positivo silencioso).

## R4. Scripts de test que no cargan

- **Decision**: hook post-ejecución de GUT (`tests/gut_post_run_hook.gd`) que fija el código de
  salida 1 si el resumen tiene errores o warnings de GUT, o si se ejecutaron cero tests.
- **Rationale**: GUT trata un script con errores de sintaxis o de tipos como "no extiende
  GutTest": lo ignora con un warning y **termina con 0** (verificado). El hook detecta los tres
  casos (sintaxis, variable sin tipo, script que no extiende `GutTest`) y también la suite vacía.
  En una ejecución limpia el resumen tiene 0 warnings, así que no hay falsos negativos.
- **Alternatives considered**: script de shell envolvente con `--check-only` por archivo
  (depende del sistema operativo y duplica la configuración de carpetas); ignorar el problema
  (incumple FR-003).

## R5. Configuración

- **Decision**: `rythmbeasts-prototype/.gutconfig.json` (ubicación por defecto `res://.gutconfig.json`)
  con `dirs: ["res://tests/unit/"]`, `include_subdirs: true`, `prefix: "test_"`, `suffix: ".gd"`,
  `should_exit: true`, `log_level: 1` y `post_run_script` apuntando al hook.
- **Rationale**: el comando queda corto y la convención de descubrimiento vive en un solo sitio.
- **Alternatives considered**: pasar todo por argumentos (comando largo y frágil).

## R6. Estructura y convención de tests

- **Decision**: tests unitarios en `rythmbeasts-prototype/tests/unit/`, con subcarpetas que reflejan
  `src/` (`tests/unit/core/`, `tests/unit/music/`). Archivos `test_<pieza>.gd` que extienden
  `GutTest`, con métodos `test_<comportamiento>()`.
- **Rationale**: encontrar el test de una pieza es inmediato y añadir uno nuevo es crear un archivo.
- **Alternatives considered**: carpeta plana (escala peor); tests junto al código en `src/`
  (mezcla código de producción y de test en las features).

## R7. Tipado estricto en los tests

- **Decision**: no hace falta configuración extra: el proyecto trata `untyped_declaration` como
  error y eso se aplica también a los tests. Un test sin tipos falla al cargar y el hook (R4)
  rechaza la ejecución.
- **Rationale**: verificado. `--check-only -s <script>` solo sirve para scripts que no usan
  autoloads: en ese modo no se cargan, y un test que usa `Conductor` da "Identifier not found"
  aunque sea correcto. La comprobación fiable es ejecutar la suite.

## R8. Qué se testea y cómo, sin audio

- **Decision**: probar `Conductor.get_nearest_subdivision()` sobre el autoload detenido (solo
  depende de la duración del pulso) y `MusicTrack` con instancias creadas en el test. Los valores
  esperados se derivan de `Conductor.get_seconds_per_beat()`, de `Conductor.Subdivision` y de
  constantes con nombre del propio test.
- **Rationale**: cumple FR-007 y FR-011 sin tocar `src/`. Separar la lógica pura queda para
  futuras features (constitución, principio VI, SHOULD).
- **Alternatives considered**: instanciar un `Conductor` nuevo (no se puede fijar su BPM sin
  reproducir audio); refactorizar el cálculo a una función estática (fuera de alcance).

## R9. Impacto en la validación del proyecto

- **Decision**: ninguno. Con el addon instalado, `godot --headless --path rythmbeasts-prototype
  --quit` produce exactamente la misma salida que la línea base (código 0 más el aviso
  preexistente de fuga de audio al salir).
- **Rationale**: verificado. GUT no registra autoloads si el plugin no está activado.

## Notas

- Godot genera un `.uid` para cada script nuevo al importar; se commitean junto a su script.
