unit GMNovedades;
{ Texto de novedades que se muestra en el menu. Va dentro del ejecutable para
  que la pantalla funcione sin conexion y sin archivos adicionales. }

{$MODE DELPHI}
{$H+}

interface

const
  TOTAL_NOVEDADES = 22;

  NOVEDADES: array[0..TOTAL_NOVEDADES - 1] of string = (
    'VERSION 1.2.0',
    '',
    '- VEINTE MUNDOS: SE SUMAN SELVA, CANON,',
    '  GLACIAR, CIUDAD, NUBES, PANTANO, CRISTAL,',
    '  MINA, ORBITA Y NUCLEO.',
    '- MENU INICIAL CON JUGAR, CODIGOS,',
    '  NOVEDADES Y SALIR.',
    '- CODIGOS DE MUNDO: AL TERMINAR CADA NIVEL',
    '  SE MUESTRA EL CODIGO DEL SIGUIENTE Y SE',
    '  PUEDE ESCRIBIR EN EL MENU PARA EMPEZAR',
    '  EN ESE MUNDO.',
    '- COMPROBACION DE VERSION NUEVA EN GITHUB',
    '  DESDE EL PROPIO JUEGO.',
    '',
    'VERSION 1.1.0',
    '',
    '- CUATRO MUNDOS NUEVOS Y CINCO PIEZAS DE',
    '  NIVEL ADICIONALES.',
    '- LA COMPUERTA DE SALIDA MIDE SEIS BLOQUES',
    '  Y SE ACTIVA AL ROZARLA.',
    '- LAS CAJAS SE ABREN AL GOLPEARLAS DESDE',
    '  ABAJO.');

implementation

end.
