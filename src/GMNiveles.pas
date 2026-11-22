unit GMNiveles;
{ Definicion de los diez niveles. Cada nivel se arma encadenando piezas de
  16 columnas por 11 filas, de modo que el mapa se lee como un dibujo y se
  puede editar sin contar caracteres a mano.

  Leyenda del mapa:
    ' '  aire
    '='  tierra solida
    'B'  ladrillo rompible
    '?'  caja con sorpresa
    'U'  caja ya usada
    '#'  viga metalica
    '['  columna metalica, mitad izquierda
    ']'  columna metalica, mitad derecha
    'c'  tuerca dorada
    'g'  bicho caminante
    's'  pua giratoria
    'f'  mosca voladora
    'M'  posicion inicial del heroe
    'E'  compuerta de salida }

{$MODE DELPHI}
{$H+}

interface

uses
  SysUtils,
  GMCore;

type
  TFilasNivel = array of string;

  TTema = record
    Nombre: string;
    CieloArriba: TColor32;
    CieloAbajo: TColor32;
    ColinaLejos: TColor32;
    ColinaCerca: TColor32;
    Tierra: TColor32;
    TierraClara: TColor32;
    Ladrillo: TColor32;
    LadrilloJunta: TColor32;
    Columna: TColor32;
    ColumnaClara: TColor32;
    Nube: TColor32;
    Estrellas: Boolean;
    Astro: TColor32;
  end;

  TNivel = class
  private
    FFilas: TFilasNivel;
    FAncho: Integer;
    FTema: TTema;
    FNombre: string;
  public
    constructor Create(const Nombre: string; const Tema: TTema);
    procedure AgregarPieza(const Filas: array of string);
    function Caracter(Columna, Fila: Integer): Char;
    function BloqueSolido(Columna, Fila: Integer): Boolean;
    property Ancho: Integer read FAncho;
    property Tema: TTema read FTema;
    property Nombre: string read FNombre;
    property Filas: TFilasNivel read FFilas;
    function AnchoPixeles: Integer;
  end;

const
  TOTAL_NIVELES = 20;

function TemaDeNivel(Numero: Integer): TTema;

function NombreNivel(Numero: Integer): string;
function CrearNivel(Numero: Integer): TNivel;
function EsSolido(Caracter: Char): Boolean;

implementation

type
  TPieza = record
    Nombre: string;
    Filas: array[0..FILAS_NIVEL - 1] of string;
  end;

const
  PIEZAS: array[0..17] of TPieza = (
    (Nombre: 'inicio';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '   M            ',
      '================',
      '================')),
    (Nombre: 'piso';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '================',
      '================')),
    (Nombre: 'piso_monedas';
     Filas: (
      '                ',
      '                ',
      '                ',
      '      c c       ',
      '     c   c      ',
      '                ',
      '                ',
      '                ',
      '                ',
      '================',
      '================')),
    (Nombre: 'hueco';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '====   =========',
      '====   =========')),
    (Nombre: 'hueco_bricks';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '        BBBB    ',
      '                ',
      '                ',
      '                ',
      '===   ==========',
      '===   ==========')),
    (Nombre: 'bloques';
     Filas: (
      '                ',
      '                ',
      '                ',
      '       c        ',
      '                ',
      '    BB?BB   ?   ',
      '                ',
      '                ',
      '                ',
      '================',
      '================')),
    (Nombre: 'escalera';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '            ==  ',
      '          ====  ',
      '        ======  ',
      '      ========  ',
      '================',
      '================')),
    (Nombre: 'columna';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '      []        ',
      '      []        ',
      '================',
      '================')),
    (Nombre: 'columna_alta';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '      []        ',
      '      []        ',
      '      []        ',
      '================',
      '================')),
    (Nombre: 'plataformas';
     Filas: (
      '                ',
      '                ',
      '                ',
      '    ####        ',
      '                ',
      '            ####',
      '                ',
      '  ##            ',
      '                ',
      '================',
      '================')),
    (Nombre: 'enemigos';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '    g      g    ',
      '================',
      '================')),
    (Nombre: 'bicho_pua';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '     s          ',
      '   c       g    ',
      '================',
      '================')),
    (Nombre: 'final';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '            E   ',
      '================',
      '================')),
    (Nombre: 'cajas';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '   B?B?B        ',
      '                ',
      '                ',
      '    c      c    ',
      '================',
      '================')),
    (Nombre: 'pasillo';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '   BBBBBBBB     ',
      '                ',
      '     c    c     ',
      '================',
      '================')),
    (Nombre: 'plataformas_altas';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '    ####        ',
      '        ####    ',
      '  c          c  ',
      '================',
      '================')),
    (Nombre: 'puas';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '      c         ',
      '    s     s     ',
      '================',
      '================')),
    (Nombre: 'columnas';
     Filas: (
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '                ',
      '    []   []     ',
      '    []   []     ',
      '================',
      '================'))
  );

  PIEZA_MOSCA: TPieza = (Nombre: 'mosca';
     Filas: (
      '                ',
      '                ',
      '      f         ',
      '                ',
      '                ',
      '                ',
      '   ####         ',
      '                ',
      '                ',
      '================',
      '================'));

function BuscarPieza(const Nombre: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := Low(PIEZAS) to High(PIEZAS) do
    if PIEZAS[I].Nombre = Nombre then
    begin
      Result := I;
      Exit;
    end;
end;

function EsSolido(Caracter: Char): Boolean;
begin
  { La compuerta de salida no es solida: se resuelve como una zona de
    contacto que ocupa toda su altura. }
  Result := Caracter in ['=', 'B', '?', 'U', '#', '[', ']'];
end;

function TemaDeNivel(Numero: Integer): TTema;
{ Un tema es un juego de colores; la funcion auxiliar evita repetir doce
  asignaciones por cada mundo. }

  function Tema(const Nombre: string; CieloArriba, CieloAbajo, ColinaLejos,
    ColinaCerca, Tierra, TierraClara, Ladrillo, LadrilloJunta, Columna,
    ColumnaClara, Nube, Astro: TColor32; Estrellas: Boolean): TTema;
  begin
    Result.Nombre := Nombre;
    Result.CieloArriba := CieloArriba;
    Result.CieloAbajo := CieloAbajo;
    Result.ColinaLejos := ColinaLejos;
    Result.ColinaCerca := ColinaCerca;
    Result.Tierra := Tierra;
    Result.TierraClara := TierraClara;
    Result.Ladrillo := Ladrillo;
    Result.LadrilloJunta := LadrilloJunta;
    Result.Columna := Columna;
    Result.ColumnaClara := ColumnaClara;
    Result.Nube := Nube;
    Result.Astro := Astro;
    Result.Estrellas := Estrellas;
  end;

begin
  case Numero of
    1: Result := Tema('PRADERA',
      RGBc(84, 152, 232), RGBc(196, 228, 252),
      RGBc(126, 182, 152), RGBc(72, 148, 102),
      RGBc(158, 102, 56), RGBc(96, 170, 74),
      RGBc(188, 96, 52), RGBc(96, 50, 28),
      RGBc(126, 132, 152), RGBc(196, 204, 222),
      RGBc(252, 254, 255), RGBc(255, 246, 190), False);
    2: Result := Tema('ATARDECER',
      RGBc(226, 118, 96), RGBc(252, 208, 156),
      RGBc(166, 108, 124), RGBc(112, 68, 92),
      RGBc(146, 84, 62), RGBc(206, 138, 78),
      RGBc(154, 72, 60), RGBc(78, 36, 30),
      RGBc(150, 108, 96), RGBc(214, 172, 148),
      RGBc(255, 226, 208), RGBc(255, 216, 120), False);
    3: Result := Tema('NOCHE',
      RGBc(20, 24, 60), RGBc(62, 76, 128),
      RGBc(52, 60, 104), RGBc(30, 38, 74),
      RGBc(72, 82, 112), RGBc(112, 126, 156),
      RGBc(96, 84, 142), RGBc(44, 38, 76),
      RGBc(98, 106, 146), RGBc(168, 178, 214),
      RGBc(150, 160, 196), RGBc(238, 240, 220), True);
    4: Result := Tema('CUEVA',
      RGBc(18, 16, 28), RGBc(46, 40, 58),
      RGBc(52, 46, 70), RGBc(32, 28, 46),
      RGBc(86, 74, 98), RGBc(126, 108, 142),
      RGBc(124, 94, 66), RGBc(58, 40, 28),
      RGBc(120, 112, 134), RGBc(188, 180, 204),
      RGBc(70, 62, 88), RGBc(120, 220, 210), True);
    5: Result := Tema('DESIERTO',
      RGBc(244, 196, 108), RGBc(252, 238, 196),
      RGBc(226, 186, 122), RGBc(204, 158, 100),
      RGBc(212, 168, 104), RGBc(240, 210, 152),
      RGBc(198, 138, 82), RGBc(104, 66, 36),
      RGBc(172, 140, 98), RGBc(228, 206, 162),
      RGBc(255, 250, 240), RGBc(255, 250, 220), False);
    6: Result := Tema('FABRICA',
      RGBc(30, 34, 46), RGBc(74, 82, 102),
      RGBc(60, 66, 84), RGBc(40, 46, 62),
      RGBc(98, 102, 118), RGBc(146, 152, 174),
      RGBc(152, 112, 82), RGBc(70, 50, 36),
      RGBc(142, 148, 166), RGBc(208, 214, 232),
      RGBc(96, 104, 122), RGBc(255, 214, 140), False);
    7: Result := Tema('BOSQUE',
      RGBc(88, 148, 118), RGBc(186, 214, 178),
      RGBc(72, 112, 84), RGBc(44, 78, 58),
      RGBc(92, 70, 46), RGBc(82, 148, 86),
      RGBc(116, 86, 58), RGBc(54, 38, 26),
      RGBc(108, 96, 80), RGBc(168, 152, 130),
      RGBc(226, 240, 222), RGBc(238, 246, 200), False);
    8: Result := Tema('VOLCAN',
      RGBc(62, 24, 28), RGBc(186, 78, 44),
      RGBc(62, 32, 36), RGBc(38, 20, 26),
      RGBc(72, 52, 56), RGBc(122, 62, 54),
      RGBc(98, 54, 50), RGBc(42, 20, 22),
      RGBc(72, 66, 74), RGBc(142, 134, 144),
      RGBc(92, 60, 60), RGBc(255, 150, 90), False);
    9: Result := Tema('HIELO',
      RGBc(118, 168, 220), RGBc(226, 244, 255),
      RGBc(152, 190, 220), RGBc(206, 232, 250),
      RGBc(150, 180, 200), RGBc(232, 248, 255),
      RGBc(130, 168, 196), RGBc(70, 100, 128),
      RGBc(140, 160, 180), RGBc(214, 232, 246),
      RGBc(250, 254, 255), RGBc(255, 255, 240), False);
    10: Result := Tema('ESPACIO',
      RGBc(10, 10, 26), RGBc(48, 30, 76),
      RGBc(38, 28, 64), RGBc(26, 18, 48),
      RGBc(58, 50, 86), RGBc(108, 96, 150),
      RGBc(86, 70, 120), RGBc(38, 28, 58),
      RGBc(110, 100, 140), RGBc(180, 170, 210),
      RGBc(60, 50, 90), RGBc(220, 210, 255), True);
    11: Result := Tema('SELVA',
      RGBc(40, 110, 70), RGBc(150, 200, 140),
      RGBc(30, 90, 55), RGBc(20, 60, 40),
      RGBc(80, 62, 40), RGBc(60, 140, 70),
      RGBc(110, 80, 50), RGBc(32, 20, 16),
      RGBc(90, 100, 80), RGBc(140, 152, 120),
      RGBc(140, 200, 126), RGBc(184, 220, 150), False);
    12: Result := Tema('CANON',
      RGBc(120, 80, 60), RGBc(230, 180, 150),
      RGBc(150, 90, 70), RGBc(110, 60, 50),
      RGBc(160, 90, 60), RGBc(200, 130, 90),
      RGBc(140, 80, 60), RGBc(56, 32, 26),
      RGBc(150, 120, 100), RGBc(188, 156, 130),
      RGBc(232, 200, 168), RGBc(255, 180, 130), False);
    13: Result := Tema('GLACIAR',
      RGBc(90, 140, 180), RGBc(200, 230, 245),
      RGBc(140, 180, 200), RGBc(180, 210, 230),
      RGBc(160, 190, 210), RGBc(230, 245, 255),
      RGBc(120, 160, 180), RGBc(46, 70, 88),
      RGBc(130, 150, 170), RGBc(192, 216, 232),
      RGBc(240, 250, 255), RGBc(255, 255, 255), False);
    14: Result := Tema('CIUDAD',
      RGBc(50, 60, 100), RGBc(140, 120, 160),
      RGBc(60, 60, 90), RGBc(40, 40, 70),
      RGBc(90, 90, 110), RGBc(130, 130, 160),
      RGBc(130, 100, 90), RGBc(58, 38, 32),
      RGBc(120, 130, 150), RGBc(192, 198, 216),
      RGBc(110, 110, 130), RGBc(255, 210, 160), False);
    15: Result := Tema('NUBES',
      RGBc(120, 180, 240), RGBc(240, 248, 255),
      RGBc(200, 220, 245), RGBc(170, 200, 235),
      RGBc(190, 205, 230), RGBc(240, 248, 255),
      RGBc(170, 180, 210), RGBc(90, 100, 130),
      RGBc(180, 195, 220), RGBc(224, 236, 250),
      RGBc(252, 254, 255), RGBc(255, 255, 224), False);
    16: Result := Tema('PANTANO',
      RGBc(60, 80, 60), RGBc(140, 160, 120),
      RGBc(70, 90, 60), RGBc(45, 60, 45),
      RGBc(70, 60, 40), RGBc(90, 120, 60),
      RGBc(90, 80, 50), RGBc(36, 26, 16),
      RGBc(100, 110, 90), RGBc(168, 180, 150),
      RGBc(74, 90, 70), RGBc(200, 216, 160), False);
    17: Result := Tema('CRISTAL',
      RGBc(30, 20, 60), RGBc(90, 60, 140),
      RGBc(60, 40, 100), RGBc(40, 25, 70),
      RGBc(80, 70, 120), RGBc(150, 130, 210),
      RGBc(110, 90, 160), RGBc(38, 26, 58),
      RGBc(120, 110, 170), RGBc(210, 198, 240),
      RGBc(60, 50, 100), RGBc(156, 230, 220), True);
    18: Result := Tema('MINA',
      RGBc(20, 18, 20), RGBc(60, 50, 45),
      RGBc(50, 42, 40), RGBc(30, 25, 25),
      RGBc(70, 60, 50), RGBc(120, 100, 70),
      RGBc(100, 80, 60), RGBc(42, 30, 22),
      RGBc(110, 100, 90), RGBc(184, 172, 158),
      RGBc(60, 50, 42), RGBc(255, 210, 140), True);
    19: Result := Tema('ORBITA',
      RGBc(8, 8, 20), RGBc(60, 20, 70),
      RGBc(40, 20, 60), RGBc(20, 10, 40),
      RGBc(50, 40, 80), RGBc(120, 80, 180),
      RGBc(90, 60, 120), RGBc(30, 16, 38),
      RGBc(140, 130, 170), RGBc(210, 198, 234),
      RGBc(60, 40, 80), RGBc(255, 210, 240), True);
  else
    Result := Tema('NUCLEO',
      RGBc(40, 0, 10), RGBc(200, 40, 40),
      RGBc(80, 10, 20), RGBc(50, 5, 15),
      RGBc(90, 30, 30), RGBc(220, 90, 60),
      RGBc(140, 50, 40), RGBc(42, 10, 8),
      RGBc(160, 120, 110), RGBc(230, 192, 180),
      RGBc(110, 30, 30), RGBc(255, 255, 200), False);
  end;
end;

function NombreNivel(Numero: Integer): string;
begin
  Result := IntToStr(Numero) + ' - ' + TemaDeNivel(Numero).Nombre;
end;

constructor TNivel.Create(const Nombre: string; const Tema: TTema);
begin
  inherited Create;
  FNombre := Nombre;
  FTema := Tema;
  FAncho := 0;
  SetLength(FFilas, FILAS_NIVEL);
  SetLength(FFilas[0], 0);
end;

procedure TNivel.AgregarPieza(const Filas: array of string);
var
  Fila: Integer;
  Cadena: string;
begin
  for Fila := 0 to FILAS_NIVEL - 1 do
  begin
    Cadena := '';
    if Fila <= High(Filas) then
      Cadena := Filas[Fila];
    while Length(Cadena) < 16 do
      Cadena := Cadena + ' ';
    FFilas[Fila] := FFilas[Fila] + Copy(Cadena, 1, 16);
  end;
  Inc(FAncho, 16);
end;

function TNivel.Caracter(Columna, Fila: Integer): Char;
begin
  if (Columna < 0) or (Columna >= FAncho) or (Fila < 0) or (Fila >= FILAS_NIVEL) then
  begin
    { Fuera del mapa: el borde inferior y los costados son solidos para que
      nadie pueda salirse del escenario. }
    if (Fila >= FILAS_NIVEL) then
      Result := '='
    else
      Result := ' ';
    Exit;
  end;
  Result := FFilas[Fila][Columna + 1];
end;

function TNivel.BloqueSolido(Columna, Fila: Integer): Boolean;
begin
  Result := EsSolido(Caracter(Columna, Fila));
end;

function TNivel.AnchoPixeles: Integer;
begin
  Result := FAncho * TAM_TILE;
end;

procedure AgregarPorNombre(Nivel: TNivel; const Nombre: string);
var
  Indice: Integer;
begin
  if Nombre = 'mosca' then
  begin
    Nivel.AgregarPieza(PIEZA_MOSCA.Filas);
    Exit;
  end;
  Indice := BuscarPieza(Nombre);
  if Indice < 0 then
    raise Exception.Create('Pieza desconocida: ' + Nombre);
  Nivel.AgregarPieza(PIEZAS[Indice].Filas);
end;

function CrearNivel(Numero: Integer): TNivel;
begin
  Result := TNivel.Create(NombreNivel(Numero), TemaDeNivel(Numero));
  case Numero of
    1:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'piso');
        AgregarPorNombre(Result, 'bloques');
        AgregarPorNombre(Result, 'piso_monedas');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'piso');
        AgregarPorNombre(Result, 'columna');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'piso');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'plataformas');
        AgregarPorNombre(Result, 'columna_alta');
        AgregarPorNombre(Result, 'piso');
        AgregarPorNombre(Result, 'final');
      end;
    2:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'piso');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'columna');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'bloques');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'piso_monedas');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'columna_alta');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'final');
      end;
    3:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'piso_monedas');
        AgregarPorNombre(Result, 'columna');
        AgregarPorNombre(Result, 'bloques');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'plataformas');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'columna_alta');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'final');
      end;
    4:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'plataformas');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'columna_alta');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'plataformas');
        AgregarPorNombre(Result, 'bloques');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'final');
      end;
    5:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'piso_monedas');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'columna');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'plataformas');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'columna_alta');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'final');
      end;
    6:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'columna_alta');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'plataformas');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'bloques');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'columna');
        AgregarPorNombre(Result, 'plataformas');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'final');
      end;
    7:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'cajas');
        AgregarPorNombre(Result, 'piso_monedas');
        AgregarPorNombre(Result, 'columnas');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'pasillo');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'final');
      end;
    8:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'puas');
        AgregarPorNombre(Result, 'bloques');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'columnas');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'pasillo');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'piso_monedas');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'final');
      end;
    9:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'cajas');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'puas');
        AgregarPorNombre(Result, 'columna_alta');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'pasillo');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'final');
      end;
    11:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'cajas');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'pasillo');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'puas');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'columna');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'final');
      end;
    12:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'puas');
        AgregarPorNombre(Result, 'bloques');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'columnas');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'pasillo');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'final');
      end;
    13:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'cajas');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'columnas');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'puas');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'pasillo');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'columna_alta');
        AgregarPorNombre(Result, 'final');
      end;
    14:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'pasillo');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'columnas');
        AgregarPorNombre(Result, 'cajas');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'puas');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'final');
      end;
    15:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'columnas');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'cajas');
        AgregarPorNombre(Result, 'puas');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'final');
      end;
    16:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'puas');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'pasillo');
        AgregarPorNombre(Result, 'columnas');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'cajas');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'columna_alta');
        AgregarPorNombre(Result, 'final');
      end;
    17:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'cajas');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'columnas');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'pasillo');
        AgregarPorNombre(Result, 'puas');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'final');
      end;
    18:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'pasillo');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'puas');
        AgregarPorNombre(Result, 'columnas');
        AgregarPorNombre(Result, 'cajas');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'final');
      end;
    19:
      begin
        AgregarPorNombre(Result, 'inicio');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'plataformas_altas');
        AgregarPorNombre(Result, 'columnas');
        AgregarPorNombre(Result, 'enemigos');
        AgregarPorNombre(Result, 'pasillo');
        AgregarPorNombre(Result, 'hueco_bricks');
        AgregarPorNombre(Result, 'puas');
        AgregarPorNombre(Result, 'cajas');
        AgregarPorNombre(Result, 'escalera');
        AgregarPorNombre(Result, 'hueco');
        AgregarPorNombre(Result, 'bicho_pua');
        AgregarPorNombre(Result, 'mosca');
        AgregarPorNombre(Result, 'final');
      end;
  else
    begin
      AgregarPorNombre(Result, 'inicio');
      AgregarPorNombre(Result, 'enemigos');
      AgregarPorNombre(Result, 'hueco');
      AgregarPorNombre(Result, 'puas');
      AgregarPorNombre(Result, 'columnas');
      AgregarPorNombre(Result, 'mosca');
      AgregarPorNombre(Result, 'pasillo');
      AgregarPorNombre(Result, 'hueco_bricks');
      AgregarPorNombre(Result, 'plataformas_altas');
      AgregarPorNombre(Result, 'enemigos');
      AgregarPorNombre(Result, 'cajas');
      AgregarPorNombre(Result, 'escalera');
      AgregarPorNombre(Result, 'hueco');
      AgregarPorNombre(Result, 'bicho_pua');
      AgregarPorNombre(Result, 'final');
    end;
  end;
end;

end.
