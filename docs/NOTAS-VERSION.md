# Salta Mundos 1.2.0

Tercera entrega del juego: veinte mundos, menú inicial con códigos de nivel,
pantalla de novedades y comprobación de versión contra GitHub desde el propio
juego.

## Qué incluye el zip

- `SaltaMundos.exe`: el juego completo, sin instalador ni dependencias.
- `LEEME.txt`: controles, códigos, reglas y cómo compilar el código.
- `LICENCIA.txt`: licencia MIT.

## Novedades de esta versión

- Diez mundos nuevos: selva, cañón, glaciar, ciudad, nubes, pantano, cristal,
  mina, órbita y núcleo. El juego pasa de diez a veinte niveles.
- Menú inicial con cuatro opciones: jugar, códigos, novedades y salir.
- Códigos de nivel: al terminar cada mundo se muestra el código del siguiente,
  y la pantalla de códigos permite empezar directamente en ese mundo.
- Comprobación de versión nueva en GitHub desde el menú, con la tecla R para
  repetir la consulta. La petición corre en un hilo aparte con WinInet y, si no
  hay red, el juego avisa y sigue funcionando.
- Pantalla de novedades con el detalle de esta entrega y de la anterior.
- El cartel de fin de nivel muestra el código del mundo siguiente.

## Correcciones

- La comparación de versiones es numérica por segmentos: una etiqueta más
  antigua ya no se anuncia como versión nueva.
- Las pantallas de códigos y novedades pintan su propio fondo y ajustan el
  texto al ancho del panel.

## Notas

- El juego se dibuja a 320x200 y se escala con un múltiplo entero, sin filtros,
  para conservar el aspecto de pixel art.
- Las letras y los números de los códigos excluyen I, O, 0 y 1 para que no se
  confundan al leerlos.
- Para compilar hace falta Free Pascal 3.2.2 o superior; el repositorio incluye
  el script `build.ps1` y el flujo de GitHub Actions que compila y prueba cada
  versión.
