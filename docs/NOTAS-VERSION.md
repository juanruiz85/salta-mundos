# Salta Mundos 1.1.0

Segunda entrega del juego: cuatro mundos nuevos, piezas de nivel adicionales y
una compuerta de salida más clara, lista para jugar en Windows de 64 bits.

## Qué incluye el zip

- `SaltaMundos.exe`: el juego completo, sin instalador ni dependencias.
- `LEEME.txt`: controles, reglas y cómo compilar el código.
- `LICENCIA.txt`: licencia MIT.

## Novedades de esta versión

- Cuatro mundos nuevos con tema propio: bosque, volcán, hielo y espacio. El
  juego pasa de seis a diez niveles.
- Cinco piezas de nivel nuevas: fila de cajas, pasillo con techo de ladrillos,
  plataformas altas, pareja de púas y pareja de columnas.
- La compuerta de salida ahora mide seis bloques de alto, no se puede saltar y
  se activa al rozarla en cualquier punto de su superficie.

## Correcciones

- Las cajas con sorpresa ya se abren al golpearlas desde abajo; antes el
  cálculo de la fila del bloque fallaba por un píxel.
- La meta se detecta con toda la caja del héroe en lugar de un solo punto, de
  modo que no hace falta colocarse en el centro exacto.

## Notas

- El juego se dibuja a 320x200 y se escala con un múltiplo entero, sin filtros,
  para conservar el aspecto de pixel art.
- Si el equipo no tiene salida de audio disponible, el juego arranca en
  silencio sin mostrar errores.
- Para compilar hace falta Free Pascal 3.2.2 o superior; el repositorio incluye
  el script `build.ps1` y el flujo de GitHub Actions que compila y prueba cada
  versión.
