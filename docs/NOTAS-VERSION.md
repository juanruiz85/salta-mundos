# Salta Mundos 1.0.0

Primera version publica del juego, lista para jugar en Windows de 64 bits.

## Que incluye el zip

- `SaltaMundos.exe`: el juego completo, sin instalador ni dependencias.
- `LEEME.txt`: controles, reglas y como compilar el codigo.
- `LICENCIA.txt`: licencia MIT.

## Novedades

- Seis mundos con ambientacion propia: pradera, atardecer, noche, cueva,
  desierto y fabrica.
- Heroe con salto de altura variable, tiempo de coyote y buffer de salto para
  que el control responda con precision.
- Tres tipos de enemigo: bicho caminante, pua giratoria y mosca voladora.
- Tuercas doradas como moneda, escudo que protege un golpe y permite romper
  ladrillos, cajas con sorpresa y compuerta de salida que se abre al tocarla.
- Musica y efectos de sonido sintetizados en tiempo real con waveOut.
- Marcador con puntos, tuercas, vidas, mundo y tiempo.

## Notas

- El juego se dibuja a 320x200 y se escala con un multiplo entero, sin filtros,
  para conservar el aspecto de pixel art.
- Si el equipo no tiene tarjeta de sonido disponible, el juego arranca en
  silencio sin mostrar errores.
- Para compilar hace falta Free Pascal 3.2.2 o superior; el repositorio incluye
  el script `build.ps1` y el flujo de GitHub Actions que compila y prueba cada
  version.
