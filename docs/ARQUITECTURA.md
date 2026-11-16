# Arquitectura de Salta Mundos

Documento técnico para quien mantiene o extiende el juego: explica cómo se organiza el código, cómo se dibuja cada fotograma y dónde están las constantes que definen el comportamiento.

Alcance: versión 1.0.0 del repositorio, código de `src/`. No describe el empaquetado de GitHub Actions salvo en lo que afecta a la autoprueba. Las afirmaciones sobre la ventana y el audio provienen de la lectura del código; no se verificaron en ejecución sobre hardware.

Versión 1.0.0 · 16 de noviembre de 2026

## 1. Vista general del código

El programa se divide en siete units y un `.dpr`. Cada unit tiene una responsabilidad acotada y las dependencias van de abajo hacia arriba: `GMCore` no conoce a nadie, `GMJuego` conoce a todas.

| Unit | Responsabilidad | Tipos y rutinas principales |
| --- | --- | --- |
| `GMCore.pas` | Constantes globales, opciones de consola y registro en disco | `TOpciones`, `LeerOpciones`, `Registrar`, `RGBc`, `Limitar` |
| `GMSuperficie.pas` | Superficie de píxeles de 32 bits, primitivas de dibujo, fuente 5x7 y exportación BMP | `TSuperficie` |
| `GMVentana.pas` | Ventana Win32, DIB section, lectura de teclado y reloj de fotogramas | `TVentana`, `TPulsos` |
| `GMSprites.pas` | Paleta, sprites por mapas de caracteres y tiles generados | `TPaleta`, `TTiles`, `TSpritesHeroe`, `TSpritesEnemigos`, `TSpritesObjetos` |
| `GMNiveles.pas` | Temas visuales, piezas de mapa y ensamblado de los seis niveles | `TTema`, `TNivel`, `CrearNivel` |
| `GMSonido.pas` | Sintetizador de música y efectos sobre waveOut | `TSonido`, `TMezclador`, `THiloAudio` |
| `GMJuego.pas` | Estados, física, colisiones, cámara, marcador y dibujo | `TJuego`, `TEntidad`, `TParticula` |
| `SaltaMundos.dpr` | Punto de entrada, selección de modo y códigos de salida | `Principal` |

Flujo de datos de un fotograma:

```
teclado (GMVentana) ──► TJuego.Actualizar ──► estado del mundo
                                               │
                                               ▼
                        TJuego.Dibujar ──► TSuperficie 320x200 ──► StretchBlt ──► ventana
                                               │
                                               └──► GuardarBMP (--capturar, --mapa)
```

`SaltaMundos.dpr` lee las opciones con `LeerOpciones`. Si se pidió `--autoprueba`, `--capturar` o `--mapa`, crea el juego con `TJuego.Create(nil, Sonido)`, ejecuta el modo correspondiente y termina con `Halt(0)` o `Halt(1)`. En caso contrario abre el audio, crea la ventana, crea el juego con esa ventana y entra en `Ejecutar`.

## 2. Bucle principal y paso fijo

El bucle vive en `TJuego.Ejecutar` y repite cinco pasos mientras la ventana siga abierta:

```pascal
while FVentana.ProcesarMensajes do
begin
  LeerTeclas;
  Actualizar;
  Dibujar;
  FVentana.Presentar;
  FVentana.EsperarSiguienteFotograma;
end;
```

`ProcesarMensajes` vacía la cola con `PeekMessageA` y devuelve `False` cuando llega `WM_QUIT` o se pidió cerrar. `Actualizar` avanza un paso de simulación: lee el estado del teclado, cambia de estado si corresponde y actualiza héroe, entidades, partículas y cámara. `Dibujar` compone el fotograma completo sobre el lienzo de 320x200. `Presentar` lo escala a la ventana.

El ritmo se fija con dos constantes de `GMCore.pas`:

```pascal
FPS_OBJETIVO = 60;
MS_FOTOGRAMA = 1000 div FPS_OBJETIVO;   { 16 ms }
```

`EsperarSiguienteFotograma` usa `QueryPerformanceCounter` y `QueryPerformanceFrequency` para calcular el instante objetivo (`último + frecuencia * 16 / 1000`), duerme en tramos de 1 a 16 ms hasta alcanzarlo y adelanta la referencia. Si el sistema se atrasó más de 200 ms, reinicia la referencia para no acumular retraso.

El paso es fijo en el sentido de que cada vuelta del bucle ejecuta exactamente un paso de simulación, sin delta time ni acumulador. Con 16 ms por fotograma el techo real es de 62,5 fotogramas por segundo, ligeramente por encima de 60. Todas las constantes de física están expresadas por fotograma, no por segundo. Si un fotograma tarda más de lo previsto, el juego se ralentiza en lugar de dar pasos extra.

El teclado se lee una sola vez por fotograma: `Ejecutar` no toca la entrada y deja que `Actualizar` llame a `LeerTeclas` al empezar. Esto es importante porque `LeerTeclas` copia el estado vigente a `FTeclasAntes` antes de leer; si el bucle volviera a leer, `FTeclasAntes` quedaría igual a `FTeclas` y `RecienPulsada` no podría detectar ningún flanco, con lo que el salto, la pausa y el cambio de pantalla dejarían de responder. La autoprueba incluye un paso dedicado a vigilar ese camino.

Estados de `TJuego` y sus transiciones:

| Estado | Se entra por | Se sale por |
| --- | --- | --- |
| `ejTitulo` | Arranque del programa o Esc desde el juego | Enter o salto: `IniciarPartida` |
| `ejJugando` | Inicio de partida o reanudación | P: pausa; muerte: `ejMuere`; meta: `ejFinNivel`; Esc: título |
| `ejPausa` | P durante el juego | P o Enter: vuelve a `ejJugando`; Esc: título |
| `ejMuere` | Contacto con enemigo sin escudo, caída o tiempo agotado | 96 fotogramas después: resta vida y reinicia el nivel o pasa a `ejGameOver` |
| `ejFinNivel` | Tocar la compuerta de salida | 130 fotogramas después: siguiente nivel o `ejVictoria` |
| `ejGameOver` | Última vida perdida | Enter tras 40 fotogramas: título |
| `ejVictoria` | Terminar el nivel 6 | Enter tras 40 fotogramas: título |

La tabla describe las transiciones programadas en `TJuego.Actualizar`; en el bucle interactivo actual las que dependen de un flanco de teclado no llegan a dispararse por la lectura duplicada descrita en el párrafo anterior.

## 3. Superficie de 32 bits y presentación

`TSuperficie` es un bloque de píxeles de 32 bits con ancho, alto y un puntero `PCardinal`. El color se representa como `$00RRGGBB` y, al guardarse en memoria little-endian, cada píxel queda en orden B, G, R, 0, que es el formato que espera una DIB de 32 bits con compresión `BI_RGB`.

La clase reserva memoria con `GetMem` en el constructor normal y no la libera si se construyó con `CreateDesdeMemoria`, que se limita a tomar un puntero ajeno. Las primitivas son:

- `Limpiar`, `Barra`, `Marco`, `Punto`, `LineaH` y `LineaV`, todas con recorte a los límites de la superficie.
- `Degradado`, que interpola el color fila por fila con `MezclarColor`.
- `Copiar` y `CopiarColor`, que copian un sprite completo y admiten color transparente y espejo horizontal.
- `CopiarRecorte`, que copia un rectángulo de origen y se usa para el bicho aplastado.
- `Texto`, `TextoSombra`, `TextoCentrado` y `TextoCentradoSombra`, con una fuente propia de 5x7 píxeles y avance de 6 píxeles por carácter.
- `GuardarBMP`, que escribe un BMP de 24 bits con las filas de abajo hacia arriba y el relleno de 4 bytes por fila.

La fuente está en `GMSuperficie.pas`: `DatosGlifo` define cada carácter como siete filas de cinco bits en hexadecimal y `IniciarTablaFuente` llena la tabla en la sección `initialization`. La escala se limita entre 1 y 8.

### Ventana y DIB section

`TVentana.Abrir` registra la clase `SaltaMundosVentana` con `CS_OWNDC`, crea una ventana `WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX` y la centra en la pantalla. La escala se calcula a partir del monitor:

```pascal
FEscala := Limitar((PantallaAncho - 120) div ANCHO_VIRTUAL, 2, 4);
if (PantallaAlto - 160) div ALTO_VIRTUAL < FEscala then
  FEscala := Limitar((PantallaAlto - 160) div ALTO_VIRTUAL, 1, 4);
```

`CrearRecursos` crea un DC de memoria y una DIB section de 320x200 píxeles, 32 bits, `BI_RGB`, con `biHeight = -ALTO_VIRTUAL` para que la memoria quede en orden de arriba hacia abajo. La DIB se selecciona en el DC de memoria y su puntero se guarda en `FPixeles`. `Presentar` ajusta el modo de estirado a `COLORONCOLOR` y copia con `StretchBlt` desde el DC de memoria al DC de la ventana, al tamaño `320 * escala` por `200 * escala`.

El modo `COLORONCOLOR` descarta píxeles en lugar de promediarlos, de modo que el escalado por múltiplo entero no introduce filtros ni bordes borrosos.

### Punto a revisar en la presentación

En el código actual, el lienzo del juego se crea con memoria propia en `TVentana.Create`:

```pascal
FLienzo := TSuperficie.Create(ANCHO_VIRTUAL, ALTO_VIRTUAL);
```

`CrearRecursos` obtiene después el puntero de la DIB en `FPixeles`, pero ese puntero no se usa en ninguna otra parte y `TSuperficie.CreateDesdeMemoria` no se llama nunca. `Presentar` copia la DIB a la ventana, mientras el juego dibuja en el bloque de `FLienzo`. Las capturas BMP salen correctas porque `GuardarBMP` lee del lienzo, no de la DIB.

La corrección es enlazar ambos: después de `CreateDIBSection`, crear el lienzo con `TSuperficie.CreateDesdeMemoria(ANCHO_VIRTUAL, ALTO_VIRTUAL, FPixeles)`, o mover la creación del lienzo a ese momento. No se modificó el código en esta tarea; el hallazgo queda anotado en la sección 12.

## 4. Sprites por mapas de caracteres

Los sprites de mapa de caracteres se declaran como un arreglo de 16 cadenas de 16 caracteres. Cada carácter indexa una paleta de 128 colores y el punto (`.`) marca transparencia:

```pascal
MAPA_HEROE_QUIETO: array[0..15] of string = (
  '................',
  '.....kkkkkk.....',
  ...
  '..kkkk....kkkk..');
```

`PaletaBase` asigna colores a las letras minúsculas y mayúsculas por separado, de modo que `S` y `s` son colores distintos. Extracto de la paleta:

| Carácter | Uso | RGB |
| --- | --- | --- |
| `k` | Contorno | 26, 22, 40 |
| `h` | Casco | 226, 126, 44 |
| `H` | Casco claro | 255, 176, 78 |
| `S` | Piel | 242, 194, 148 |
| `c` | Traje | 38, 148, 158 |
| `C` | Traje claro | 86, 206, 208 |
| `g` | Gafas | 52, 96, 140 |
| `p` | Morado de enemigos | 120, 78, 168 |
| `w` | Blanco | 246, 246, 250 |
| `y` | Amarillo | 246, 198, 52 |
| `r` | Rojo | 212, 58, 58 |
| `U` | Azul claro | 112, 152, 232 |

`ConstruirSprite` crea una superficie de 16x16, la limpia con `COLOR_TRANSPARENTE` (`$FFFF00FF`) y escribe un píxel por carácter distinto de `.`. Ese mismo valor se pasa como color de transparencia a `CopiarColor`, que lo compara píxel a píxel antes de copiar.

Conjuntos de sprites:

| Conjunto | Cuadros | Detalle |
| --- | --- | --- |
| Héroe | Quieto, 3 de carrera, salto, caída y muerto | Mapas de 16x16; el dibujo aplica espejo según la dirección |
| Bicho | 2 | Alterna cada 6 fotogramas; aplastado se dibuja recortando las primeras 6 filas |
| Púa | 4 | Generada por código con 8 puntas y giro por fase |
| Mosca | 2 | Alterna cada 5 fotogramas |
| Tuerca | 4 | Generada por código con 8 dientes y giro por fase |
| Escudo | 1 | Mapa de caracteres con el símbolo `U` |
| Chispa | 3 | 8x8, generada por código para el aura del escudo |

La tuerca y la púa no usan mapas de caracteres: `CrearMoneda` y `CrearPua` recorren los 16x16 píxeles, calculan radio y ángulo con `ArcTan2`, y dibujan dientes o puntas según la distancia angular al eje de giro. La fase que reciben desplaza ese eje, lo que produce la animación de rotación.

Las animaciones se eligen por contador de fotogramas: el bicho usa `(Fase div 6) mod 2`, la púa `(Fase div 3) mod 4`, la mosca `(Fase div 5) mod 2`, la tuerca del mapa `((FFotograma div 8) + Col) mod 4` y el héroe `Trunc(FHeroeAnim) mod 3`.

## 5. Tiles generados por código

`ConstruirTiles` recibe los seis colores del tema y construye diez superficies de 16x16 en `TTiles`. No hay atlas ni archivos: cada tile se pinta con barras y líneas.

| Tile | Construcción |
| --- | --- |
| Tierra | Relleno base, banda superior clara de 2 px, línea más clara de 1 px, borde inferior y derecho oscuro, cuatro motas de textura |
| Ladrillo | Relleno base, cuatro líneas horizontales de mortero cada 4 px, junta vertical alternada en x=4 y x=12, bisel claro arriba e izquierda y oscuro abajo y derecha |
| Caja | Tres variantes de brillo, bisel, cuatro remaches y una tuerca dibujada en el centro |
| Caja usada | Relleno apagado, bisel y remaches, sin símbolo central |
| Columna, capitel izquierdo | Cuerpo con margen transparente exterior, banda de aviso amarilla y negra, baliza y remaches |
| Columna, capitel derecho | Igual, con el brillo en el lado opuesto |
| Columna, cuerpo izquierdo | Cuerpo con margen de 3 px, borde claro y dos remaches |
| Columna, cuerpo derecho | Igual, con las bandas invertidas |
| Viga | Relleno metálico, banda clara arriba, banda oscura abajo y cuatro remaches |

Los tiles se reconstruyen al cargar cada nivel (`FreeAndNil(FTiles)` y `ConstruirTiles` con el tema), porque los colores cambian de un mundo a otro. En el dibujo, una columna usa el capitel si el tile de arriba no es otra columna y el cuerpo si lo es.

## 6. Formato de los niveles

Un nivel es una rejilla de 11 filas por N columnas de tiles de 16x16, es decir, 176 píxeles de alto, que es exactamente el área de mundo visible (`ALTO_MUNDO = 200 - 24`). Se arma encadenando piezas de 16 columnas por 11 filas: `TNivel.AgregarPieza` recorta o rellena cada fila a 16 caracteres y la añade a la derecha, sin necesidad de contar columnas a mano.

Leyenda de caracteres:

| Carácter | Significado | ¿Sólido? |
| --- | --- | --- |
| `' '` | Aire | No |
| `=` | Tierra | Sí |
| `B` | Ladrillo rompible | Sí |
| `?` | Caja con sorpresa | Sí |
| `U` | Caja ya usada | Sí |
| `#` | Viga metálica | Sí |
| `[` | Columna metálica, mitad izquierda | Sí |
| `]` | Columna metálica, mitad derecha | Sí |
| `c` | Tuerca dorada | No |
| `g` | Bicho caminante | No |
| `s` | Púa giratoria | No |
| `f` | Mosca voladora | No |
| `M` | Posición inicial del héroe | No |
| `E` | Compuerta de salida (dos columnas, cuatro filas) | No |

`EsSolido` reconoce `=`, `B`, `?`, `U`, `#`, `[` y `]`. Fuera del mapa, `TNivel.Caracter` devuelve `'='` por debajo de la última fila y `' '` por arriba o a los costados; el motor de juego, en cambio, trata los costados como sólidos en `SolidoEn` para que nadie salga del escenario.

Hay trece piezas con nombre (`inicio`, `piso`, `piso_monedas`, `hueco`, `hueco_bricks`, `bloques`, `escalera`, `columna`, `columna_alta`, `plataformas`, `enemigos`, `bicho_pua`, `final`) y una pieza adicional, `mosca`, que se agrega con `AgregarPorNombre` sin estar en la tabla. Cada nivel encadena entre 14 y 17 piezas:

| Nivel | Tema | Piezas | Columnas | Ancho en píxeles |
| --- | --- | --- | --- | --- |
| 1 | Pradera | 15 | 240 | 3840 |
| 2 | Atardecer | 14 | 224 | 3584 |
| 3 | Noche | 16 | 256 | 4096 |
| 4 | Cueva | 14 | 224 | 3584 |
| 5 | Desierto | 15 | 240 | 3840 |
| 6 | Fábrica | 17 | 272 | 4352 |

Temas visuales de `TemaDeNivel`:

| Nivel | Tema | Cielo, arriba a abajo | Estrellas |
| --- | --- | --- | --- |
| 1 | Pradera | `#5498E8` a `#C4E4FC` | No |
| 2 | Atardecer | `#E27660` a `#FCD09C` | No |
| 3 | Noche | `#14183C` a `#3E4C80` | Sí |
| 4 | Cueva | `#12101C` a `#2E283A` | Sí |
| 5 | Desierto | `#F4C46C` a `#FCEEC4` | No |
| 6 | Fábrica | `#1E222E` a `#4A5266` | No |

Al cargar un nivel, `CargarNivel` copia las filas a `FMapa`, reconstruye los tiles, borra entidades y llama a `SembrarEntidades`, que convierte las `g`, `s` y `f` en objetos `TEntidad` y borra esos caracteres del mapa. La `M` se usa para colocar al héroe en `columna * 16 + 2` y `fila * 16 + 1`, y también se borra. La `c` y la `E` permanecen como tiles y se dibujan o se consultan en cada fotograma.

## 7. Física del héroe

Todas las constantes están en la interfaz de `GMJuego.pas` y se expresan por fotograma. Los valores se muestran tal como están en el código, con punto decimal.

| Constante | Valor | Uso |
| --- | --- | --- |
| `GRAVEDAD` | `0.42` | Aceleración vertical normal, en píxeles por fotograma al cuadrado |
| `GRAVEDAD_SALTO` | `0.34` | Gravedad reducida mientras se mantiene el salto y el héroe sube |
| `IMPULSO_SALTO` | `-6.7` | Velocidad vertical inicial del salto, en píxeles por fotograma |
| `VEL_ANDAR` | `1.7` | Velocidad horizontal máxima al caminar |
| `VEL_CORRER` | `2.7` | Velocidad horizontal máxima al correr |
| `ACELERACION` | `0.17` | Incremento de velocidad horizontal por fotograma con dirección pulsada |
| `ROCE` | `0.24` | Reducción de velocidad horizontal por fotograma sin dirección |
| `VEL_CAIDA_MAX` | `8.2` | Velocidad vertical máxima de caída |
| `HEROE_ANCHO` | `12` | Ancho de la caja de colisión |
| `HEROE_ALTO` | `15` | Alto de la caja de colisión |

El sprite del héroe mide 16x16, pero la caja de colisión es de 12x15 y se dibuja con un desplazamiento de 2 píxeles a la izquierda y 1 hacia arriba. La posición `FHeroeX`, `FHeroeY` corresponde a la esquina superior izquierda de la caja.

`ActualizarHeroe` ejecuta estos pasos en orden:

1. Calcula la velocidad máxima: `VEL_CORRER` si se pulsa correr, `VEL_ANDAR` si no.
2. Aplica la entrada horizontal: resta `ACELERACION` al ir a la izquierda, la suma al ir a la derecha, y aplica `ROCE` hacia cero cuando no hay dirección. Luego limita la velocidad a `±VelMax`.
3. Gestiona el salto: si se acaba de pulsar salto, carga el buffer; descuenta buffer y coyote; si hay buffer y el héroe está en suelo o dentro del coyote, aplica `IMPULSO_SALTO`, lo marca como fuera del suelo y limpia ambos contadores.
4. Aplica gravedad: si se mantiene salto y la velocidad vertical es negativa, suma `GRAVEDAD_SALTO`; en cualquier otro caso suma `GRAVEDAD`. Limita la caída a `VEL_CAIDA_MAX`.
5. Desplaza en horizontal con colisión y anula la velocidad si choca.
6. Desplaza en vertical con colisión. Si choca subiendo, busca la caja o el ladrillo golpeado con la cabeza y anula la velocidad vertical; si choca bajando, también la anula.
7. Actualiza el estado de suelo: al tocar suelo marca `FHeroeEnSuelo` y recarga el coyote en 6; si está cayendo, lo desmarca.
8. Comprueba el suelo un píxel más abajo cuando el héroe queda justo sobre un borde.
9. Avanza la animación de carrera según la velocidad y descuenta la invulnerabilidad.
10. Recoge tuercas, limita la posición a los bordes del mapa, comprueba la meta y la caída al vacío.

El salto variable no corta la velocidad al soltar: mientras se mantiene la tecla y el héroe sube, la gravedad es menor (`0.34` en lugar de `0.42`), de modo que un toque produce un salto corto y una pulsación mantenida un salto alto. El tiempo de coyote es de 6 fotogramas (unos 100 ms a 60 fps) y el buffer de salto de 8 fotogramas (unos 133 ms); ambos permiten pulsar salto un poco antes o un poco después de tocar el suelo sin perder la acción. La autoprueba exige que el salto máximo quede entre 24 y 80 píxeles.

El escudo cambia el daño: `HerirHeroe` ignora el golpe si hay invulnerabilidad, consume el escudo si lo hay y otorga 90 fotogramas de invulnerabilidad con partículas azules, o mata al héroe si no hay escudo. La muerte fija una velocidad vertical de `-5.4`, detiene la música y entra en `ejMuere`.

## 8. Colisiones por movimiento píxel a píxel

La consulta base es `HaySolido(R: TRectI)`, que convierte el rectángulo a un rango de tiles:

```pascal
C1 := Floor(R.X / TAM_TILE);
C2 := Floor((R.X + R.Ancho - 1) / TAM_TILE);
F1 := Floor(R.Y / TAM_TILE);
F2 := Floor((R.Y + R.Alto - 1) / TAM_TILE);
```

y devuelve `True` si algún tile del rango es sólido según `SolidoEn`. Esta función trata las columnas fuera del mapa como sólidas, la fila negativa como aire y las filas por debajo del nivel como sólidas.

`DesplazarX` y `DesplazarY` no usan barrido continuo: dividen el desplazamiento en pasos de un píxel (`Pasos := Ceil(Abs(DX))`), avanzan de a uno, comprueban `HaySolido` con la posición redondeada y, si hay choque, retroceden un píxel y detienen el movimiento. `DesplazarY` marca `EnSuelo` cuando el choque ocurre bajando. Con las velocidades del juego, el coste es de una a tres comprobaciones horizontales y hasta nueve verticales por fotograma, y no hay riesgo de atravesar un tile.

Las entidades usan las mismas rutinas con su propia caja: el bicho mide 14x12 y además comprueba el tile delante y debajo del borde para girar antes de caerse de una plataforma; la púa mide 14x14 y solo gira al chocar con una pared; la mosca mide 12x10, colisiona solo en horizontal y se mueve en vertical con una onda `Sin(Fase / 26) * 0.9`, limitada entre 8 y `ALTO_MUNDO - 24`.

El contacto héroe-enemigo se resuelve con intersección de rectángulos. El pisotón exige tres condiciones: la velocidad vertical del héroe es mayor que `0.6`, el borde inferior del héroe no supera en más de 16 píxeles el borde superior del enemigo y el enemigo no es una púa. Si se cumple, el héroe rebota con `-4.6`, suma 100 puntos y el bicho queda aplastado 16 fotogramas o la mosca desaparece. La púa siempre hiere.

## 9. Cámara y fondo

La cámara es un solo valor horizontal, `FCamaraX`, en píxeles de mundo. Al cargar el nivel se inicializa en `FHeroeX - 112`, limitado entre 0 y `anchoTotal - 320`. En cada fotograma se calcula un objetivo y se interpola:

```pascal
Objetivo := FHeroeX + HEROE_ANCHO / 2 - 118;
if FHeroeMirandoIzq then
  Objetivo := Objetivo + 20;
FCamaraX := FCamaraX + (Objetivo - FCamaraX) * 0.18;
```

El resultado se limita otra vez al rango válido. El factor `0.18` produce un seguimiento suave, sin saltos, y el desplazamiento de 20 píxeles al mirar a la izquierda deja más espacio visible hacia delante. No hay cámara vertical: el mundo siempre ocupa los 176 píxeles bajo el marcador.

El fondo se dibuja antes que los tiles y usa la cámara con factores distintos para dar profundidad: las colinas lejanas a `0.35` y las cercanas a `0.6` con un desfase de 40 píxeles; las nubes a `0.42`, con un ciclo de 460 píxeles que las repite; las estrellas y el sol o la luna quedan fijos. Las colinas se generan columna a columna sumando dos senos y se recortan contra el borde superior del área de mundo.

## 10. Sintetizador de audio

`GMSonido.pas` implementa un mezclador mínimo sobre `waveOut`, sin archivos ni bibliotecas de audio. La salida se abre con `waveOutOpen` sobre `WAVE_MAPPER`, formato PCM de 16 bits, mono y 22050 Hz, con `CALLBACK_NULL`. Se preparan cuatro búferes de 1024 muestras cada uno (unos 46 ms por búfer) y un hilo (`THiloAudio`) revisa cada 5 ms si alguno terminó (`WHDR_DONE`), lo rellena y lo vuelve a encolar.

La música se define en tres tablas de 16 notas. Cada nota guarda un semitono relativo a La4 (440 Hz) y una duración en muestras; el silencio se representa con `-99`. La frecuencia se calcula con `440 * Power(2, semitono / 12)`. La melodía se sintetiza con una onda cuadrada de ciclo 0.4 y un bajo a la octava inferior con ciclo 0.5; las amplitudes son 0.14 y 0.07, y las primeras 220 muestras de cada nota llevan una rampa de ataque para evitar chasquidos. Las tres melodías son `MELODIA_PRADERA`, `MELODIA_NOCHE` y `MELODIA_FABRICA`; `NotaDeMusica` elige la segunda para la pista 2 y la tercera para pistas 3 o mayores.

Los efectos se generan muestra a muestra en `MuestraEfecto`:

| Efecto | Síntesis |
| --- | --- |
| `efSalto` | Barrido ascendente de 320 a unos 480 Hz durante 0.18 s, ciclo 0.5 |
| `efTuerca` | Dos tonos de 988 y 1319 Hz durante 0.14 s, ciclo 0.5 |
| `efPisot` | Barrido descendente de 260 a unos 160 Hz durante 0.11 s, ciclo 0.25 |
| `efEscudo` | Arpegio de 523, 659, 784 y 1047 Hz durante 0.3 s |
| `efMuerte` | Tono descendente de 520 Hz a cero durante 0.9 s, ciclo 0.35 |
| `efNivel` | Arpegio de 523, 659, 784, 1047 y 1319 Hz durante 0.6 s |
| `efGolpe` | Tono de 150 Hz durante 0.08 s, ciclo 0.15 |

La mezcla suma melodía y efecto, recorta el resultado a `[-1, 1]` y lo escala a `±9000` sobre el rango de 16 bits, con un margen amplio para no saturar. Si `waveOutOpen` falla, el mezclador se libera y el juego continúa en silencio; `--silencio` impide abrir el dispositivo. El flag interno `FSilencio` del mezclador solo apaga la melodía, no los efectos, pero la fachada `TSonido` no llega a abrir el dispositivo cuando se pidió silencio.

## 11. Autoprueba

La autoprueba se ejecuta con `--autoprueba` o `--selftest`. El `.dpr` crea `TJuego.Create(nil, Sonido)`, de modo que el juego usa un lienzo propio y no abre ventana, y llama a `TJuego.AutoPrueba`. El resultado se traduce en `Halt(0)` si pasó y `Halt(1)` si falló.

`AutoPrueba` activa `FSimulacion` y alimenta el motor con `DarPulsos`, que sustituye la lectura real del teclado por un `TPulsos` armado a mano. Cada comprobación se declara con `Comprobar(Condicion, Descripcion)`, donde `Condicion` es la condición de error: si es verdadera, se agrega una línea `FALLA: ...` a la lista. Los pasos son:

1. Estructura de los seis niveles: ancho de al menos 100 columnas, exactamente una `M` y exactamente una `E` por nivel.
2. Física en reposo: 40 fotogramas sin entrada deben dejar al héroe sobre el suelo, y 30 fotogramas más no deben moverlo más de 1,5 píxeles.
3. Salto: con salto pulsado, la altura máxima debe quedar entre 24 y 80 píxeles y el héroe debe volver al suelo con un margen de 2 píxeles.
4. Pared: se construye un muro de cuatro columnas por tres filas, se corre a la derecha 90 fotogramas y el héroe no debe atravesarlo ni quedarse sin avanzar.
5. Partida automática: 2400 fotogramas corriendo a la derecha y saltando cinco de cada treinta deben recoger al menos una tuerca y avanzar más de 96 píxeles.
6. Dibujo: se cargan los seis niveles, se simulan tres fotogramas en cada uno y se llama a `Dibujar` sin ventana.
7. Fin de nivel: se coloca al héroe junto a la compuerta, se comprueba que el estado pasa a `ejFinNivel`, que las hojas se abren y que tras 140 fotogramas el juego avanza al mundo 2.
8. Muerte: se deja caer al héroe fuera del mapa, se comprueba que entra en `ejMuere` y que tras 130 fotogramas pierde una vida y reanuda la partida.
9. Recorrido: un bot corre a la derecha y salta ante paredes, huecos y enemigos; con los enemigos desactivados debe llegar a la compuerta en los seis mundos, lo que demuestra que ninguna pared ni ningún hueco impide avanzar.
10. Entrada por flanco: pulsando salto un solo fotograma, el héroe debe despegar del suelo; pulsando avance, su velocidad horizontal debe dejar de ser cero.

El paso 1 mide el ancho en tiles (`Nivel.Ancho`), no en píxeles. El paso 5 no exige terminar el nivel: comprueba que el bucle de juego, la recogida de tuercas y el avance funcionan juntos. El paso 6 no tiene aserciones; su valor es que cualquier excepción de dibujo hace fallar la ejecución. El paso 9 usa `FMortalInactivo` para desactivar el daño de los enemigos, de modo que mide la geometría del nivel y no la puntería del bot.

Cada paso escribe una línea en `salta-mundos.log`, junto al ejecutable, y en la salida estándar. Al final se registra `RESULTADO: OK` o `RESULTADO: FALLO` con el detalle de las fallas. Si se produce una excepción no controlada, el bloque `try` del `.dpr` la registra y termina con código 2.

## 12. Observaciones de implementación

Estos puntos se detectaron al leer el código y no forman parte del comportamiento documentado arriba:

- Lectura duplicada del teclado. `Ejecutar` llama a `LeerTeclas` y `Actualizar` vuelve a llamarla; la segunda lectura iguala `FTeclasAntes` a `FTeclas` y anula la detección de flancos de `RecienPulsada`. Afecta al salto, la pausa, la salida al título y el inicio de partida en el bucle interactivo. La corrección es quitar una de las dos llamadas: la de `Ejecutar` o la de `Actualizar`.
- El lienzo no está enlazado a la DIB section. `TVentana.Create` crea `FLienzo` con memoria propia y `CrearRecursos` guarda el puntero de la DIB en `FPixeles` sin usarlo; `Presentar` copia la DIB. Es el punto a revisar de la sección 3 y afecta solo a la presentación en ventana, no a las capturas BMP.
- El motor pide siempre la pista de música 1 al iniciar la partida y al avanzar de nivel, y la pista 0 al morir o terminar. Las melodías de noche y fábrica existen en el sintetizador, pero ningún camino de `GMJuego.pas` las solicita.
- La constante `MARGEN_META = 26` está declarada y no se usa; la meta se detecta por el tile `E` bajo el centro del héroe.
- El contador muestra 300 unidades, pero baja una unidad cada 24 fotogramas: a 60 fps son 120 segundos reales por nivel.
