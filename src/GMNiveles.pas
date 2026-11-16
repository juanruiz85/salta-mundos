unit GMNiveles;
{ Definicion de los seis niveles. Cada nivel se arma encadenando piezas de
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
  TOTAL_NIVELES = 6;

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
  PIEZAS: array[0..12] of TPieza = (
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
  Result := Caracter in ['=', 'B', '?', 'U', '#', '[', ']'];
end;

function TemaDeNivel(Numero: Integer): TTema;
begin
  case Numero of
    1:
      begin
        Result.Nombre := 'PRADERA';
        Result.CieloArriba := RGBc(84, 152, 232);
        Result.CieloAbajo := RGBc(196, 228, 252);
        Result.ColinaLejos := RGBc(126, 182, 152);
        Result.ColinaCerca := RGBc(72, 148, 102);
        Result.Tierra := RGBc(158, 102, 56);
        Result.TierraClara := RGBc(96, 170, 74);
        Result.Ladrillo := RGBc(188, 96, 52);
        Result.LadrilloJunta := RGBc(96, 50, 28);
        Result.Columna := RGBc(126, 132, 152);
        Result.ColumnaClara := RGBc(196, 204, 222);
        Result.Nube := RGBc(252, 254, 255);
        Result.Estrellas := False;
        Result.Astro := RGBc(255, 246, 190);
      end;
    2:
      begin
        Result.Nombre := 'ATARDECER';
        Result.CieloArriba := RGBc(226, 118, 96);
        Result.CieloAbajo := RGBc(252, 208, 156);
        Result.ColinaLejos := RGBc(166, 108, 124);
        Result.ColinaCerca := RGBc(112, 68, 92);
        Result.Tierra := RGBc(146, 84, 62);
        Result.TierraClara := RGBc(206, 138, 78);
        Result.Ladrillo := RGBc(154, 72, 60);
        Result.LadrilloJunta := RGBc(78, 36, 30);
        Result.Columna := RGBc(150, 108, 96);
        Result.ColumnaClara := RGBc(214, 172, 148);
        Result.Nube := RGBc(255, 226, 208);
        Result.Estrellas := False;
        Result.Astro := RGBc(255, 216, 120);
      end;
    3:
      begin
        Result.Nombre := 'NOCHE';
        Result.CieloArriba := RGBc(20, 24, 60);
        Result.CieloAbajo := RGBc(62, 76, 128);
        Result.ColinaLejos := RGBc(52, 60, 104);
        Result.ColinaCerca := RGBc(30, 38, 74);
        Result.Tierra := RGBc(72, 82, 112);
        Result.TierraClara := RGBc(112, 126, 156);
        Result.Ladrillo := RGBc(96, 84, 142);
        Result.LadrilloJunta := RGBc(44, 38, 76);
        Result.Columna := RGBc(98, 106, 146);
        Result.ColumnaClara := RGBc(168, 178, 214);
        Result.Nube := RGBc(150, 160, 196);
        Result.Estrellas := True;
        Result.Astro := RGBc(238, 240, 220);
      end;
    4:
      begin
        Result.Nombre := 'CUEVA';
        Result.CieloArriba := RGBc(18, 16, 28);
        Result.CieloAbajo := RGBc(46, 40, 58);
        Result.ColinaLejos := RGBc(52, 46, 70);
        Result.ColinaCerca := RGBc(32, 28, 46);
        Result.Tierra := RGBc(86, 74, 98);
        Result.TierraClara := RGBc(126, 108, 142);
        Result.Ladrillo := RGBc(124, 94, 66);
        Result.LadrilloJunta := RGBc(58, 40, 28);
        Result.Columna := RGBc(120, 112, 134);
        Result.ColumnaClara := RGBc(188, 180, 204);
        Result.Nube := RGBc(70, 62, 88);
        Result.Estrellas := True;
        Result.Astro := RGBc(120, 220, 210);
      end;
    5:
      begin
        Result.Nombre := 'DESIERTO';
        Result.CieloArriba := RGBc(244, 196, 108);
        Result.CieloAbajo := RGBc(252, 238, 196);
        Result.ColinaLejos := RGBc(226, 186, 122);
        Result.ColinaCerca := RGBc(204, 158, 100);
        Result.Tierra := RGBc(212, 168, 104);
        Result.TierraClara := RGBc(240, 210, 152);
        Result.Ladrillo := RGBc(198, 138, 82);
        Result.LadrilloJunta := RGBc(104, 66, 36);
        Result.Columna := RGBc(172, 140, 98);
        Result.ColumnaClara := RGBc(228, 206, 162);
        Result.Nube := RGBc(255, 250, 240);
        Result.Estrellas := False;
        Result.Astro := RGBc(255, 250, 220);
      end;
  else
    begin
      Result.Nombre := 'FABRICA';
      Result.CieloArriba := RGBc(30, 34, 46);
      Result.CieloAbajo := RGBc(74, 82, 102);
      Result.ColinaLejos := RGBc(60, 66, 84);
      Result.ColinaCerca := RGBc(40, 46, 62);
      Result.Tierra := RGBc(98, 102, 118);
      Result.TierraClara := RGBc(146, 152, 174);
      Result.Ladrillo := RGBc(152, 112, 82);
      Result.LadrilloJunta := RGBc(70, 50, 36);
      Result.Columna := RGBc(142, 148, 166);
      Result.ColumnaClara := RGBc(208, 214, 232);
      Result.Nube := RGBc(96, 104, 122);
      Result.Estrellas := False;
      Result.Astro := RGBc(255, 214, 140);
    end;
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
  else
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
  end;
end;

end.
