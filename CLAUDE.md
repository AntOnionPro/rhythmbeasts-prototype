# CLAUDE.md — Rhythm Beasts

Juego de pelea 2D rítmico en Godot 4.7.1 (GDScript): cada golpe y combo construye una pista de
dubstep en tiempo real y el escenario reacciona a la música.

## Antes de nada

- Lee `.specify/memory/constitution.md` antes de proponer o tocar código: sus reglas MUST son
  obligatorias y prevalecen sobre este archivo.
- Lee `rythmbeasts-prototype/docs/prototype.md` antes de proponer features (hipótesis y alcance
  de la fase actual).
- Las features no triviales siguen el flujo de Spec Kit (`/speckit-specify` → `/speckit-plan` →
  `/speckit-tasks` → `/speckit-implement`); las specs viven en `specs/`.

## Comunicación y forma de trabajar

- Responde en español. Código, identificadores, comentarios y mensajes de commit en inglés.
- Antes de cambiar nada fuera de un comando `/speckit-*`: resume qué harás y en qué archivos, y
  espera aprobación.
- Toca solo lo pedido: sin refactors ni renombrados de paso.
- No hagas commit, push, ni abras issues o PRs salvo que se pida.
- Al terminar: muestra el diff o las líneas cambiadas y el resultado de la validación. Sé conciso.

## Validación

- Tras cada cambio en el proyecto Godot, desde la raíz del repo:
  `godot --headless --path rythmbeasts-prototype --quit`
- Informa de errores y warnings. Una tarea no está hecha mientras la validación falle.
- No abras el editor ni la ventana del juego salvo que se pida.

## Nunca

- Editar o borrar `.godot/`, `*.import`, `*.uid`, atributos `uid=` o ids de `ext_resource`.
- Mover o renombrar archivos del proyecto Godot desde la terminal: pide al usuario que lo haga
  desde el editor.
- Instalar addons, cambiar la versión de Godot o editar `project.godot`, el Input Map o los
  autoloads sin preguntar.
- Editar a mano `.tscn` complejos: describe el árbol de nodos y pide al usuario que lo monte en
  el editor.
