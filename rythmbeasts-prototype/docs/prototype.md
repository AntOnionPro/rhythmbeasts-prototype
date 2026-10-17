# Prototipo — Rhythm Beasts

## Hipótesis
Pelear se siente bien cuando cada golpe y cada combo construyen una pista de dubstep en
tiempo real, y el escenario reacciona a esa música.

## Qué se valida
- Golpear se siente bien y la música resultante suena musical, no a ruido.
- Los combos producen frases reconocibles (golpes rítmicos, wobble, drop).
- El escenario reactivo refuerza la sensación de impacto y ritmo.
- Los jugadores buscan hacer combos también por cómo suenan.

## Dentro del alcance
- Pelea 1 vs 1 local, dos luchadores placeholder (formas geométricas de color) con el mismo moveset.
- Movimiento, golpe ligero, golpe fuerte y bloqueo.
- Combos simples definidos en datos (`Resource`), no en código.
- Cada golpe que conecta dispara un sample cuantizado a la rejilla de beat; los combos disparan capas o frases.
- Escenario reactivo básico: pulsos de color y escala al beat y al impacto.
- Pelea de 3 minutos con temporizador.
- Dificultad seleccionable que define qué tan estricto es el timing.

## Fuera del alcance
- Estilo visual final (chibi), arte, animaciones y personajes definitivos (cerdito, lobo, vaca, etc.).
- Movesets distintos por personaje, online, menús completos.
- Música final: la producirá el usuario. Los samples actuales son placeholders CC0.

## Diseño de audio
- BPM base: 140 (ajustable en datos).
- No hay beat audible al inicio: la música sale de los golpes.
- El reloj musical corre siempre. La pista base se reproduce desde el inicio en volumen 0
  (o bus silenciado) para que el Conductor tenga fuente de reloj y cualquier entrada
  posterior quede en fase.
- Mapeo inicial de samples (vía `SoundBank`):
  - Golpe ligero → percusión / hit corto.
  - Golpe fuerte → bajo.
  - Combo → wobble.
  - Finisher de combo → drop.

## Dificultad (valores iniciales, a ajustar jugando)
| Nivel   | Ventana de timing | Golpe fuera de tiempo |
|---------|-------------------|-----------------------|
| Fácil   | Amplia            | Se cuantiza al beat más cercano |
| Normal  | Media             | Suena, pero no suma al combo musical |
| Difícil | Estrecha          | No suena y rompe el combo |

Cada nivel es un `DifficultyProfile` (.tres). No aplica a un futuro modo online.

## Fase 2 (no entra en el prototipo inicial)
- Último minuto: entra el beat de fondo y el escenario cambia para meter presión por el tiempo.

## Preguntas abiertas
- Sin beat audible, ¿cómo percibe el jugador el tiempo? Propuesta: el escenario pulsa visualmente al beat desde el inicio.
- ¿Ambos jugadores construyen la misma pista o cada uno tiene su propia "voz" (capas o tonos distintos)?
