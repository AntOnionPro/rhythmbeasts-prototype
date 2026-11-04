# Feature Specification: Infraestructura de tests headless del núcleo rítmico

**Feature Branch**: `001-headless-test-infra` (sin rama propia; se trabaja en `claude/intelligent-edison-cph3n9`)

**Created**: 2026-11-04

**Status**: Draft

**Input**: User description: "Infraestructura de tests automatizados headless para el núcleo rítmico, usando el addon GUT 9.7.1 (la versión para Godot 4.7.x), como exige el principio VI de la constitución (cierra TODO(TEST_FRAMEWORK)). Incluye: instalar GUT en addons/gut, configuración para ejecutar los tests desde la línea de comandos sin ventana, carpeta de tests unitarios dentro de tests/, un comando único documentado para correr la suite y un primer test del snapping a la rejilla (BeatSnap / Conductor.get_nearest_subdivision) y de MusicTrack. No incluye tests de game feel ni refactors del código existente. La spec pide tests explícitamente."

**Fase / qué valida** (constitución, principio I): habilitador técnico. No valida por sí mismo ningún
punto de "Qué se valida" de `docs/prototype.md`, pero protege el requisito del que dependen todos:
que cada golpe suene en la rejilla de beat ("la música resultante suena musical, no a ruido").

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ejecutar la suite con un solo comando (Priority: P1)

Como desarrollador (o agente IA), quiero ejecutar todos los tests automatizados del proyecto con un
único comando, sin abrir ninguna ventana, y saber al instante si pasan o fallan.

**Why this priority**: sin una forma fiable y rápida de ejecutar tests, el principio VI de la
constitución no se puede cumplir y ninguna feature del núcleo rítmico puede darse por terminada.

**Independent Test**: en un clon limpio del repositorio, ejecutar los comandos documentados y
comprobar que la suite corre, informa del número de tests y termina sola con código de salida 0.

**Acceptance Scenarios**:

1. **Given** un clon limpio del repositorio con Godot 4.7.1 disponible, **When** se ejecutan los
   comandos documentados desde la raíz del repo, **Then** la suite corre sin ventana, informa de
   cuántos tests pasaron y termina sola con código de salida 0.
2. **Given** un test que falla, **When** se ejecuta la suite, **Then** el resultado identifica el
   test fallido y el comando termina con un código de salida distinto de 0.
3. **Given** un archivo de test con un error de sintaxis o de tipos, **When** se ejecuta la suite,
   **Then** el comando informa del error y termina con un código de salida distinto de 0.

---

### User Story 2 - El snapping a la rejilla y la pista musical están protegidos (Priority: P2)

Como desarrollador, quiero que el cálculo que coloca cada instante en el paso más cercano de la
rejilla de beat, y el cálculo de la duración del pulso y del loop de una pista, estén cubiertos por
tests, para que cualquier cambio que los rompa se detecte antes de jugar.

**Why this priority**: es el primer uso real de la infraestructura y cubre la pieza de la que
dependen la cuantización de sonidos, el juicio de timing y los combos.

**Independent Test**: ejecutar la suite y ver los tests de snapping y de pista en verde; después
alterar a propósito el cálculo del snapping en una copia local y comprobar que al menos un test
falla.

**Acceptance Scenarios**:

1. **Given** un instante que cae exactamente sobre un paso de la rejilla, **When** se ajusta a la
   subdivisión, **Then** el resultado es ese paso con desviación cero.
2. **Given** un instante ligeramente tarde respecto a un paso, **When** se ajusta, **Then** el
   resultado es ese paso y la desviación es positiva e igual a la diferencia en milisegundos.
3. **Given** un instante ligeramente temprano respecto a un paso, **When** se ajusta, **Then** el
   resultado es ese paso y la desviación es negativa.
4. **Given** el mismo instante, **When** se ajusta a negra, corchea y semicorchea, **Then** cada
   resultado informa de su número de pasos por pulso y de la posición en pulsos coherente con él.
5. **Given** una pista con un BPM y una longitud en pulsos, **When** se calcula la duración del
   pulso y del loop, **Then** coinciden con 60 / BPM y con longitud × duración del pulso.

---

### User Story 3 - Añadir un test nuevo es trivial (Priority: P3)

Como desarrollador, quiero que añadir un test nuevo consista en crear un archivo siguiendo una
convención de carpeta y nombre, sin tocar ninguna configuración.

**Why this priority**: reduce la fricción para cumplir el principio VI en cada feature futura del
núcleo rítmico.

**Independent Test**: crear un archivo de test nuevo con un caso trivial en la carpeta de tests
unitarios, ejecutar la suite y comprobar que aparece y se ejecuta sin cambios de configuración.

**Acceptance Scenarios**:

1. **Given** la convención documentada, **When** se crea un archivo de test nuevo en la carpeta de
   tests unitarios (o en una subcarpeta), **Then** la suite lo descubre y lo ejecuta automáticamente.

---

### Edge Cases

- Clon recién hecho, sin la caché que genera el motor al importar el proyecto: los comandos
  documentados incluyen el paso de importación previo, de modo que la suite funciona igual.
- Instante justo antes del beat 0 (desviación negativa respecto al paso 0): el ajuste devuelve el
  paso 0 con desviación negativa, sin errores.
- La presencia del addon de tests no debe añadir errores ni warnings nuevos a la validación
  headless del proyecto (la línea base ya muestra un aviso de fuga de audio al salir).
- Los tests no deben depender de reproducción de audio real ni de que haya una partida en curso.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El proyecto MUST incluir el framework de tests elegido (GUT 9.7.1, compatible con
  Godot 4.7.x) como plugin de terceros dentro de la carpeta de addons, sin modificar
  `project.godot`, el Input Map ni los autoloads.
- **FR-002**: MUST existir un comando único y documentado que ejecute toda la suite sin ventana
  desde la raíz del repositorio y termine por sí solo.
- **FR-003**: El comando MUST terminar con código de salida 0 si todos los tests pasan, y distinto
  de 0 si algún test falla o no se puede cargar.
- **FR-004**: Los tests unitarios MUST vivir en una carpeta dedicada dentro de `tests/` y
  descubrirse automáticamente por convención de nombre, incluidas subcarpetas.
- **FR-005**: MUST existir tests del ajuste a la rejilla que cubran: instante exacto sobre un paso,
  ligeramente tarde, ligeramente temprano, antes del beat 0 y las tres subdivisiones (negra,
  corchea y semicorchea).
- **FR-006**: MUST existir tests de la pista musical que cubran la duración del pulso para un BPM
  dado y la duración del loop.
- **FR-007**: Los tests MUST NOT depender de audio real, de la escena principal ni de una partida
  en curso, y MUST derivar los valores esperados de constantes del proyecto o de datos con nombre
  creados en el propio test (sin números mágicos).
- **FR-008**: Los tests MUST cumplir las reglas de código de la constitución (GDScript de Godot 4
  con tipado estático y guía de estilo).
- **FR-009**: La validación headless existente MUST seguir terminando sin errores ni warnings
  nuevos con el addon instalado.
- **FR-010**: La constitución y `CLAUDE.md` MUST documentar el comando de tests, y la constitución
  MUST cerrar `TODO(TEST_FRAMEWORK)`.
- **FR-011**: El código existente de `src/` MUST NOT modificarse en esta feature.

### Key Entities

- **Suite de tests**: conjunto de todos los archivos de test unitario del proyecto; se ejecuta
  completa con un comando y produce un resultado global (pasa/falla) y un recuento.
- **Archivo de test**: agrupa casos sobre una pieza del núcleo rítmico; se descubre por su
  ubicación y nombre.
- **Caso de test**: comprobación individual con nombre descriptivo; su fallo identifica qué
  comportamiento se rompió.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: En un clon limpio, la suite completa se ejecuta con los comandos documentados en
  menos de 60 segundos, incluida la importación inicial.
- **SC-002**: El 100 % de los tests pasan sobre el código actual.
- **SC-003**: Alterar a propósito el cálculo del ajuste a la rejilla hace fallar al menos un test y
  el comando informa de fallo (verificado una vez durante la implementación, sin dejar el cambio).
- **SC-004**: Añadir un test nuevo requiere crear exactamente un archivo, sin cambios de
  configuración.
- **SC-005**: La validación headless del proyecto muestra la misma salida que la línea base, sin
  errores ni warnings nuevos.

## Assumptions

- El framework (GUT 9.7.1, rama `godot_4_7`) lo eligió el usuario el 2026-11-04; su licencia es MIT.
- El plugin de editor de GUT no se activa en esta feature, porque activarlo modifica
  `project.godot`. El usuario puede activarlo después desde el editor si quiere el panel gráfico;
  la ejecución por línea de comandos no lo necesita.
- Los tests usan la API pública actual (ajuste del `Conductor` detenido, con su BPM por defecto, y
  recursos `MusicTrack` creados en el propio test). Separar la lógica pura del núcleo rítmico de
  los nodos queda para features futuras.
- La escena de prueba manual existente (`tests/manual/`) se mantiene sin cambios.
- No se configura integración continua (CI) en esta feature.
