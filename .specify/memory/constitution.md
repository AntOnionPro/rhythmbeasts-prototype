# Constitución de Rhythm Beasts

## Principios fundamentales

### I. Fases guiadas por hipótesis

- El proyecto avanza por fases. Cada fase MUST tener un documento de diseño con hipótesis,
  qué se valida, alcance y fuera de alcance. Fase actual: prototipo, descrita en
  `rythmbeasts-prototype/docs/prototype.md`.
- Cada spec MUST indicar qué punto de "Qué se valida" de la fase actual aborda.
- Lo listado en "Fuera del alcance" MUST NOT implementarse sin actualizar antes el documento de
  fase con aprobación del usuario.
- Lo provisional es el contenido, no el código: arte, animación, menús y samples MAY ser
  placeholders (formas y colores dibujados por código, samples de prueba). El código MUST tener
  calidad de producción: es la semilla del juego final y no se reescribirá al cerrar el prototipo.

**Razón**: el objetivo es validar que pelear construyendo música en tiempo real es divertido,
sin gastar esfuerzo en contenido que cambiará, pero sin acumular deuda en el código que
heredará el juego final.

### II. El audio es el reloj (NO NEGOCIABLE)

- El tiempo musical MUST salir solo del autoload `Conductor`, derivado de la reproducción de
  audio: `get_playback_position() + AudioServer.get_time_since_last_mix()
  - AudioServer.get_output_latency()`.
- MUST NOT medirse tiempo musical acumulando `delta` ni con temporizadores independientes.
- Visuales y juicio de input MUST usar tiempo audible; el disparo de sonidos MUST usar el
  tiempo con lookahead del `Conductor` para que se oigan en la rejilla.
- Todo sonido disparado por el juego MUST caer en la rejilla de beat. La dificultad
  (`DifficultyProfile`) solo decide si un golpe cuenta para el combo musical, nunca si suena
  fuera de tiempo.
- El reloj musical MUST correr siempre durante la partida: la pista base se reproduce desde el
  inicio, silenciada por volumen o bus si hace falta, para que toda entrada posterior quede
  en fase.
- Los samples superpuestos MUST usar `AudioStreamPolyphonic` o un pool de reproductores, sobre
  los buses `Music` y `SFX`.

**Razón**: el juego entero depende de que golpes, música y escenario estén en fase. Un reloj
derivado de `delta` deriva respecto al audio y rompe la sensación de ritmo.

### III. Sistemas desacoplados

- El combate MUST NOT conocer la música ni el escenario. El flujo es: combate emite eventos →
  `MusicDirector` juzga, cuantiza y reproduce → emite eventos musicales → escenario y HUD
  reaccionan.
- La comunicación entre sistemas MUST pasar por el autoload `EventBus`. Dentro de una escena:
  los padres llaman a métodos de los hijos y los hijos emiten señales ("call down, signal up").
- El estado global MUST vivir solo en autoloads de `src/core/` (hoy `Conductor` y `EventBus`).
  Añadir un autoload requiere aprobación del usuario.
- MUST NOT usarse rutas largas de `get_node()` ni cadenas de `get_parent()`: usar referencias
  `@export`, `%UniqueName` o señales.
- Composición sobre herencia profunda: nodos y componentes pequeños con una sola
  responsabilidad, que dependen de señales y `Resource`s, no de nodos concretos.

**Razón**: permite cambiar música, escenario o luchadores sin romper el combate, y es la base
para crecer hacia el juego final (más personajes, escenarios y pistas).

### IV. Datos antes que código

- Todo valor ajustable (ataques, combos, sound banks, dificultad, perfiles de CPU, configuración
  de partida, pistas) MUST vivir en clases `Resource` personalizadas guardadas como `.tres`.
- Los samples MUST referenciarse a través de recursos `SoundBank`; MUST NOT escribirse rutas de
  samples en la lógica.
- MUST NOT haber números mágicos: usar constantes o variables `@export`.
- El input MUST leerse solo mediante acciones del Input Map, nunca con teclas fijas.

**Razón**: el diseño se ajusta jugando; los datos se cambian sin tocar código y los samples
provisionales se sustituirán por la música final.

### V. GDScript de Godot 4 estricto

- Solo GDScript (sin C#), con sintaxis de Godot 4: `@export`, `@onready`, `await`, `super()`,
  `signal.connect(callable)`, `CharacterBody2D`. MUST NOT usarse sintaxis de Godot 3 (`export`,
  `onready`, `yield`, `setget`, `KinematicBody2D`, `connect("signal", obj, "method")`).
- Tipado estático MUST aplicarse en todo: variables, parámetros, tipos de retorno (`-> void`),
  arrays y diccionarios tipados. El proyecto trata las declaraciones sin tipo como error.
- Nombres según la guía de estilo de Godot: archivos y carpetas en `snake_case`; `class_name`
  y nodos en `PascalCase`; funciones y variables en `snake_case`; constantes y miembros de enum
  en `CONSTANT_CASE`; miembros privados con `_` inicial; señales en pasado (`hit_landed`).
- Orden del script: `class_name`/`extends`, docstring `##`, señales, enums, constantes,
  `@export`, variables públicas, privadas, `@onready`, callbacks del motor, métodos públicos,
  métodos privados.

**Razón**: el tipado detecta errores en el editor y en la validación headless, y un estilo
único mantiene legible un código que va a crecer.

### VI. Tests automatizados del núcleo rítmico

- La lógica de tiempo y cuantización (`Conductor`, `BeatSnap`), el juicio de timing
  (`DifficultyProfile`, `MusicDirector`) y los combos (`ComboTracker`) MUST tener tests
  automatizados que se ejecuten en modo headless.
- Toda spec que cree o modifique esa lógica MUST pedir tests de forma explícita, para que
  `/speckit-tasks` los genere, y la feature MUST NOT darse por terminada con esos tests fallando.
- La lógica pura del núcleo rítmico SHOULD separarse de nodos y escenas (funciones estáticas o
  clases `RefCounted`) para poder testearla sin audio real.
- El resto (game feel, movimiento, escenario, HUD) se valida con playtest manual siguiendo los
  criterios de aceptación de la spec. Las escenas de `tests/manual/` se mantienen como apoyo.
- TODO(TEST_FRAMEWORK): el addon de tests (GUT o gdUnit4) aún no está elegido ni instalado; se
  decide e instala en su propia feature antes de cualquier otra que toque el núcleo rítmico.

**Razón**: el timing es el riesgo crítico del juego y verificarlo de oído es lento y poco
fiable; el resto se juzga mejor jugando.

## Restricciones técnicas

- **Motor**: Godot 4.7.1 estable, renderizador GL Compatibility, juego 2D. Cambiar de versión
  requiere aprobación del usuario.
- **Estructura**: el proyecto Godot vive en `rythmbeasts-prototype/`, organizado por features:
  `src/core/` (autoloads), `src/combat/`, `src/fighters/`, `src/music/`, `src/stage/`,
  `src/match/`, `src/ui/`, `src/main/`; además `assets/` (assets compartidos), `docs/`,
  `tests/` y `addons/` (solo plugins de terceros). Cada feature guarda juntos sus `.tscn`, `.gd`
  y `.tres`. Crear carpetas de primer nivel o features nuevas en `src/` requiere aprobación.
- **Requieren aprobación explícita**: instalar addons, editar `project.godot`, el Input Map o el
  registro de autoloads.
- **Intocables**: `.godot/`, archivos `*.import`, archivos `*.uid` (se commitean junto a su
  script), atributos `uid=` e ids de `ext_resource` dentro de `.tscn`/`.tres`.
- **Mover o renombrar** archivos del proyecto Godot MUST hacerse desde el editor de Godot, nunca
  desde la terminal: se rompen referencias y `.uid`.
- **Escenas**: editar `.tscn` a mano solo para cambios pequeños y seguros. Para escenas
  complejas se describe el árbol de nodos y el usuario lo construye en el editor.
- **Audio original**: canciones completas y stems quedan fuera de git
  (`assets/audio/source/`); solo se commitean los cortes usados por el juego.

## Flujo de desarrollo y puertas de calidad

- **Flujo**: toda feature no trivial pasa por Spec Kit: `/speckit-specify` → `/speckit-clarify`
  (opcional) → `/speckit-plan` → `/speckit-tasks` → `/speckit-analyze` (opcional) →
  `/speckit-implement`. Las specs viven en `specs/NNN-nombre/` en la raíz del repo.
- **Idioma**: constitución, specs, planes, tareas y documentos de diseño en español. Código,
  identificadores, comentarios y mensajes de commit en inglés.
- **Definición de hecho**: una tarea o feature está terminada solo si:
  1. `godot --headless --path rythmbeasts-prototype --quit` termina sin errores ni warnings
     nuevos;
  2. los tests automatizados del núcleo rítmico pasan (principio VI);
  3. los criterios de aceptación de la spec están verificados, con playtest cuando dependan
     del game feel.
- **Documentación viva**: si una feature cambia la hipótesis, el alcance o el diseño de audio,
  el documento de fase MUST actualizarse en la misma feature.
- **Alcance de los cambios**: cada cambio toca solo lo que su spec o tarea pide; sin
  refactors ni renombrados de paso.

## Gobernanza

- Esta constitución prevalece sobre cualquier otra práctica. `CLAUDE.md` contiene la guía
  operativa del agente y MUST NOT contradecirla.
- **Enmiendas**: se hacen con `/speckit-constitution`, requieren aprobación del usuario y se
  registran en git junto con el motivo.
- **Versionado semántico**: MAJOR para eliminar o redefinir principios de forma incompatible;
  MINOR para añadir un principio o sección, o ampliar materialmente una guía; PATCH para
  aclaraciones y redacción.
- **Cumplimiento**: cada plan pasa el "Constitution Check" de `/speckit-plan`; toda violación
  MUST justificarse en la tabla "Complexity Tracking" del plan. `/speckit-analyze` trata las
  violaciones de reglas MUST como críticas.
- **Revisión**: la constitución se revisa al cerrar cada fase del proyecto.

**Version**: 1.0.0 | **Ratified**: 2026-11-04 | **Last Amended**: 2026-11-04
