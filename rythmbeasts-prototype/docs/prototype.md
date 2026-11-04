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
- Pelea 1 contra 1: el jugador (P1) contra un oponente CPU. Dos luchadores placeholder
  (formas geométricas de color) con el mismo moveset.
- Siguiente feature: 1 contra 1 local entre dos humanos (necesita las acciones de input de P2).
- Formato platform fighter: plataformas atravesables, 3 vidas por jugador, % de daño que
  escala el knockback y pérdida de una vida al caer del escenario.
- Movimiento (correr, salto y doble salto), golpe ligero, golpe fuerte y bloqueo.
- Oponente CPU definido en datos (`CpuProfile`): persigue, vuelve al escenario, ataca sobre la
  rejilla de corcheas siguiendo un patrón y a veces bloquea.
- Combos simples definidos en datos (`Resource`), no en código.
- Cada golpe que conecta dispara un sample cuantizado a la rejilla de beat; los combos disparan capas o frases.
- Escenario reactivo básico: pulsos de color y escala al beat y al impacto.
- Partida de 3 minutos con temporizador y cuenta atrás sincronizada al compás. Termina cuando
  alguien se queda sin vidas o se acaba el tiempo; con tiempo agotado gana quien tenga más
  vidas y, a igualdad, quien tenga menos daño; si no, empate.
- Dificultad seleccionable que define qué tan estricto es el timing.

## Fuera del alcance
- Estilo visual final (chibi), arte, animaciones y personajes definitivos (cerdito, lobo, vaca, etc.).
- Movesets distintos por personaje, online, menús completos.
- Música final del juego. La pista "Hard Mode Engaged" es la pista de referencia del prototipo:
  sus cortes se usan como samples y las canciones y stems originales quedan fuera de git. Los
  samples sintéticos CC0 se mantienen para pruebas.

## Diseño de audio
- Pista de referencia: "Hard Mode Engaged" a 150 BPM. El BPM vive en el recurso `MusicTrack`
  (datos), nunca en código.
- No hay beat audible al inicio: la música sale de los golpes.
- El reloj musical corre siempre. La pista base se reproduce desde el inicio en volumen 0
  (o bus silenciado) para que el Conductor tenga fuente de reloj y cualquier entrada
  posterior quede en fase.
- El drop desbloquea la pista base: mientras suena el drop la pista base se silencia y, al
  terminar, entra con su volumen y ya no se vuelve a apagar salvo bajo otro drop.
- Cada jugador tiene su propia voz: un `SoundBank` por jugador con samples distintos.
- Mapeo de samples (vía `SoundBank`):
  - Golpe ligero → percusión / hit corto.
  - Golpe fuerte → bajo.
  - Combo → wobble.
  - Finisher de combo → drop.

## Dificultad (valores iniciales, a ajustar jugando)
El sonido de un golpe siempre cae en la rejilla de beat, sea cual sea la dificultad
(se programa en el siguiente paso de la rejilla). La dificultad solo decide si el golpe
cuenta para el combo musical.

| Nivel   | Ventana de timing | Golpe fuera de ventana |
|---------|-------------------|------------------------|
| Fácil   | Amplia            | Suena en la rejilla y cuenta para el combo |
| Normal  | Media             | Suena en la rejilla, pero no suma al combo musical |
| Difícil | Estrecha          | Suena en la rejilla, pero rompe el combo |

Cada nivel es un `DifficultyProfile` (.tres). No aplica a un futuro modo online.

## Ideas futuras (fuera de esta fase)
- Último minuto: el escenario y la música cambian para meter presión por el tiempo.

## Decisiones tomadas
- Sin beat audible, el jugador percibe el tiempo porque el escenario pulsa visualmente al beat
  desde el inicio.
- Cada jugador tiene su propia "voz" (samples distintos), no comparten la misma.
