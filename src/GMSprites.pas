unit GMSprites;
{ Sprites del juego dibujados con mapas de caracteres y tiles generados por
  codigo. Ningun grafico se carga de disco: todo viaja dentro del ejecutable,
  igual que en los juegos de la epoca de Turbo Pascal.

  El diseno es propio: un mecanico con casco naranja y gafas en lugar del
  fontanero clasico, bichos redondos morados, puas giratorias y moscas
  voladoras. Las monedas son tuercas doradas que giran. }

{$MODE DELPHI}
{$H+}

interface

uses
  SysUtils,
  Math,
  GMCore,
  GMSuperficie;

const
  LADO_SPRITE = 16;

type
  TPaleta = array[0..127] of TColor32;

  { Conjunto de imagenes de un nivel. Se reconstruye al cambiar de tema. }
  TTiles = class
  public
    Tierra: TSuperficie;
    Ladrillo: TSuperficie;
    Caja: array[0..2] of TSuperficie;
    CajaUsada: TSuperficie;
    ColumnaTapaIzq: TSuperficie;
    ColumnaTapaDer: TSuperficie;
    ColumnaCuerpoIzq: TSuperficie;
    ColumnaCuerpoDer: TSuperficie;
    Viga: TSuperficie;
    constructor Create;
    destructor Destroy; override;
  end;

  TSpritesHeroe = class
  public
    Quieto: TSuperficie;
    Corre: array[0..2] of TSuperficie;
    Salto: TSuperficie;
    Caida: TSuperficie;
    Muerto: TSuperficie;
    constructor Create;
    destructor Destroy; override;
    function CuadroCorre(Fotograma: Integer): TSuperficie;
  end;

  TSpritesEnemigos = class
  public
    Bicho: array[0..1] of TSuperficie;
    Pua: array[0..3] of TSuperficie;
    Mosca: array[0..1] of TSuperficie;
    constructor Create;
    destructor Destroy; override;
  end;

  TSpritesObjetos = class
  public
    Moneda: array[0..3] of TSuperficie;
    Chispa: array[0..2] of TSuperficie;
    Escudo: TSuperficie;
    constructor Create;
    destructor Destroy; override;
  end;

function PaletaBase: TPaleta;
function ConstruirSprite(const Filas: array of string; const Paleta: TPaleta): TSuperficie;
function ConstruirTiles(const Tierra, TierraClara, Ladrillo, LadrilloJunta,
  Columna, ColumnaClara: TColor32): TTiles;
function CrearMoneda(Fase: Integer): TSuperficie;
function CrearEscudo: TSuperficie;
function CrearPua(Fase: Integer): TSuperficie;
function CrearChispa(Fase: Integer): TSuperficie;
procedure LiberarSuperficie(var S: TSuperficie);

implementation

const
  MAPA_HEROE_QUIETO: array[0..15] of string = (
    '................',
    '.....kkkkkk.....',
    '...kkhhhhhhkk...',
    '..khhhhhhhhhhk..',
    '..khHHHHHHHHhk..',
    '.kkggggggggggkk.',
    '..kGSSSSSSSSGk..',
    '..kSSkkSSkkSSk..',
    '..kSSSSSSSSSSk..',
    '...kSSSSSSSSk...',
    '..kcccccccccck..',
    '..kCccccccccCk..',
    '.kSccccccccccSk.',
    '..kcccccccccck..',
    '..kbbk....kbbk..',
    '..kkkk....kkkk..');

  MAPA_HEROE_CORRE1: array[0..15] of string = (
    '................',
    '.....kkkkkk.....',
    '...kkhhhhhhkk...',
    '..khhhhhhhhhhk..',
    '..khHHHHHHHHhk..',
    '.kkggggggggggkk.',
    '..kGSSSSSSSSGk..',
    '..kSSkkSSkkSSk..',
    '..kSSSSSSSSSSk..',
    '...kSSSSSSSSk...',
    '..kccccccccck...',
    '..kCcccccccck...',
    '.kScccccccck....',
    '..kccccccck.....',
    '...kbbk.kbbk....',
    '...kkkk.kkkk....');

  MAPA_HEROE_CORRE2: array[0..15] of string = (
    '................',
    '.....kkkkkk.....',
    '...kkhhhhhhkk...',
    '..khhhhhhhhhhk..',
    '..khHHHHHHHHhk..',
    '.kkggggggggggkk.',
    '..kGSSSSSSSSGk..',
    '..kSSkkSSkkSSk..',
    '..kSSSSSSSSSSk..',
    '...kSSSSSSSSk...',
    '...kcccccccck...',
    '...kCccccccCk...',
    '..kSccccccccSk..',
    '...kcccccccck...',
    '...kbbkkbbk.....',
    '...kkkkkkkk.....');

  MAPA_HEROE_CORRE3: array[0..15] of string = (
    '................',
    '.....kkkkkk.....',
    '...kkhhhhhhkk...',
    '..khhhhhhhhhhk..',
    '..khHHHHHHHHhk..',
    '.kkggggggggggkk.',
    '..kGSSSSSSSSGk..',
    '..kSSkkSSkkSSk..',
    '..kSSSSSSSSSSk..',
    '...kSSSSSSSSk...',
    '...kccccccck....',
    '...kCcccccck....',
    '....kcccccccck..',
    '.....kcccccck...',
    '....kbbk.kbbk...',
    '....kkkk.kkkk...');

  MAPA_HEROE_SALTO: array[0..15] of string = (
    '................',
    '.....kkkkkk.....',
    '...kkhhhhhhkk...',
    '..khhhhhhhhhhk..',
    '..khHHHHHHHHhk..',
    '.kkggggggggggkk.',
    '..kGSSSSSSSSGk..',
    '..kSSkkSSkkSSk..',
    '..kSSSSSSSSSSk..',
    '.kSkSSSSSSSkkSk.',
    '.kSkcccccccckSk.',
    '.kkkCccccccCkkk.',
    '..kcccccccccck..',
    '..kccck..kccck..',
    '..kbbk....kbbk..',
    '..kkkk....kkkk..');

  MAPA_HEROE_CAIDA: array[0..15] of string = (
    '................',
    '.....kkkkkk.....',
    '...kkhhhhhhkk...',
    '..khhhhhhhhhhk..',
    '..khHHHHHHHHhk..',
    '.kkggggggggggkk.',
    '..kGSSSSSSSSGk..',
    '..kSSkkSSkkSSk..',
    '..kSSSSSSSSSSk..',
    '.kkSSSSSSSSSSkk.',
    '.kSkcccccccckSk.',
    '..kCccccccccCk..',
    '..kcccccccccck..',
    '...kccckkccck...',
    '...kbbk..kbbk...',
    '...kkkk..kkkk...');

  MAPA_HEROE_MUERTO: array[0..15] of string = (
    '................',
    '.....kkkkkk.....',
    '...kkhhhhhhkk...',
    '..khhhhhhhhhhk..',
    '..khHHHHHHHHhk..',
    '.kkggggggggggkk.',
    '..kGSSSSSSSSGk..',
    '..kSSrrSSrrSSk..',
    '..kSSSSSSSSSSk..',
    '...kSSkkkkSSk...',
    '..kcccccccccck..',
    '.kSccccccccccSk.',
    '.kSccccccccccSk.',
    '..kcccccccccck..',
    '..kbbk....kbbk..',
    '..kkkk....kkkk..');

  MAPA_BICHO1: array[0..15] of string = (
    '................',
    '................',
    '.....kkkkkk.....',
    '...kkppppppkk...',
    '..kppppppppppk..',
    '.kppwwkkkkwwppk.',
    '.kpwwkkppkkwwpk.',
    '.kppkkppppkkppk.',
    '.kppppppppppppk.',
    '.kpppkkkkkkpppk.',
    '..kppppppppppk..',
    '...kkppppppkk...',
    '..kPk.kkkk.kPk..',
    '..kkk......kkk..',
    '................',
    '................');

  MAPA_BICHO2: array[0..15] of string = (
    '................',
    '................',
    '.....kkkkkk.....',
    '...kkppppppkk...',
    '..kppppppppppk..',
    '.kppwwkkkkwwppk.',
    '.kpwwkkppkkwwpk.',
    '.kppkkppppkkppk.',
    '.kppppppppppppk.',
    '.kpppkkkkkkpppk.',
    '..kppppppppppk..',
    '...kkppppppkk...',
    '.kPk..kkkk..kPk.',
    '.kkk........kkk.',
    '................',
    '................');

  MAPA_MOSCA1: array[0..15] of string = (
    '................',
    '................',
    '.....kk..kk.....',
    '...kkwwkkwwkk...',
    '..kwwwwwwwwwwk..',
    '.kwwkkwwwwkkwwk.',
    '.kwk..kwwk..kwk.',
    '..kk..kppk..kk..',
    '......kppk......',
    '...kkkkppkkkk...',
    '..kppppppppppk..',
    '..kpppkkkkpppk..',
    '...kkk....kkk...',
    '................',
    '................',
    '................');

  MAPA_MOSCA2: array[0..15] of string = (
    '................',
    '................',
    '................',
    '.....kk..kk.....',
    '...kkwwkkwwkk...',
    '..kwwwwwwwwwwk..',
    '.kwwkkwwwwkkwwk.',
    '.kwk..kwwk..kwk.',
    '..kk..kppk..kk..',
    '...kkkkppkkkk...',
    '..kppppppppppk..',
    '..kpppkkkkpppk..',
    '...kkk....kkk...',
    '................',
    '................',
    '................');

  MAPA_ESCUDO: array[0..15] of string = (
    '................',
    '....kkkkkkkk....',
    '..kkUUUUUUUUkk..',
    '.kUUUUUUUUUUUUk.',
    '.kUUwwUUUUwwUUk.',
    '.kUUwwUUUUwwUUk.',
    '.kUUUUUyyUUUUUk.',
    '.kUUUUUyyUUUUUk.',
    '.kUUUUyyyyUUUUk.',
    '..kUUUUyyUUUUk..',
    '..kUUUUUUUUUUk..',
    '...kUUUUUUUUk...',
    '....kUUUUUUk....',
    '.....kUUUUk.....',
    '......kkkk......',
    '................');

function PaletaBase: TPaleta;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result[Ord('.')] := COLOR_TRANSPARENTE;
  Result[Ord('k')] := RGBc(26, 22, 40);      { contorno }
  Result[Ord('K')] := RGBc(70, 66, 96);      { contorno suave }
  Result[Ord('h')] := RGBc(226, 126, 44);    { casco }
  Result[Ord('H')] := RGBc(255, 176, 78);    { casco claro }
  Result[Ord('S')] := RGBc(242, 194, 148);   { piel }
  Result[Ord('s')] := RGBc(198, 142, 100);   { piel sombra }
  Result[Ord('g')] := RGBc(52, 96, 140);     { gafas }
  Result[Ord('G')] := RGBc(120, 226, 246);   { brillo de gafas }
  Result[Ord('c')] := RGBc(38, 148, 158);    { traje }
  Result[Ord('C')] := RGBc(86, 206, 208);    { traje claro }
  Result[Ord('b')] := RGBc(112, 70, 40);     { botas }
  Result[Ord('B')] := RGBc(158, 104, 58);    { botas claras }
  Result[Ord('w')] := RGBc(246, 246, 250);   { blanco }
  Result[Ord('y')] := RGBc(246, 198, 52);    { amarillo }
  Result[Ord('Y')] := RGBc(255, 236, 128);   { amarillo claro }
  Result[Ord('o')] := RGBc(232, 128, 40);    { naranja }
  Result[Ord('r')] := RGBc(212, 58, 58);     { rojo }
  Result[Ord('p')] := RGBc(120, 78, 168);    { morado }
  Result[Ord('P')] := RGBc(158, 116, 206);   { morado claro }
  Result[Ord('x')] := RGBc(120, 120, 136);   { gris }
  Result[Ord('X')] := RGBc(186, 190, 204);   { gris claro }
  Result[Ord('m')] := RGBc(84, 88, 104);     { metal }
  Result[Ord('M')] := RGBc(148, 154, 172);   { metal claro }
  Result[Ord('n')] := RGBc(60, 44, 32);      { marron oscuro }
  Result[Ord('u')] := RGBc(56, 88, 176);     { azul }
  Result[Ord('U')] := RGBc(112, 152, 232);   { azul claro }
  Result[Ord('e')] := RGBc(64, 152, 72);     { verde }
  Result[Ord('E')] := RGBc(118, 202, 104);   { verde claro }
end;

function ConstruirSprite(const Filas: array of string; const Paleta: TPaleta): TSuperficie;
var
  Fila, Columna, Filas2: Integer;
  Cadena: string;
  Caracter: Char;
begin
  Filas2 := Length(Filas);
  Result := TSuperficie.Create(LADO_SPRITE, LADO_SPRITE);
  Result.Limpiar(COLOR_TRANSPARENTE);
  for Fila := 0 to Filas2 - 1 do
  begin
    Cadena := Filas[Fila];
    for Columna := 0 to Limitar(Length(Cadena), 0, LADO_SPRITE) - 1 do
    begin
      Caracter := Cadena[Columna + 1];
      if Caracter = '.' then
        Continue;
      Result.Punto(Columna, Fila, Paleta[Ord(Caracter)]);
    end;
  end;
end;

procedure LiberarSuperficie(var S: TSuperficie);
begin
  FreeAndNil(S);
end;

{ ------------------------------------------------------------------ }
{ Tiles generados por codigo                                          }
{ ------------------------------------------------------------------ }

function CrearTierra(Base, Clara, Oscura: TColor32): TSuperficie;
var
  I: Integer;
begin
  Result := TSuperficie.Create(TAM_TILE, TAM_TILE);
  Result.Limpiar(Base);
  Result.Barra(0, 0, TAM_TILE, 2, Clara);
  Result.Barra(0, 2, TAM_TILE, 1, Aclarar(Clara, 10));
  Result.LineaH(0, TAM_TILE - 1, TAM_TILE, Oscura);
  Result.LineaV(TAM_TILE - 1, 0, TAM_TILE, Oscura);
  { Cuatro motas para dar textura al bloque. }
  for I := 1 to 4 do
    Result.Barra((I * 5) mod 12 + 2, (I * 7) mod 10 + 3, 2, 2, Oscurecer(Base, 18));
end;

function CrearLadrillo(Base, Junta: TColor32): TSuperficie;
var
  Fila: Integer;
begin
  Result := TSuperficie.Create(TAM_TILE, TAM_TILE);
  Result.Limpiar(Base);
  { Lineas de mortero horizontales y verticales alternadas. }
  for Fila := 0 to 3 do
  begin
    Result.LineaH(0, Fila * 4, TAM_TILE, Junta);
    if Odd(Fila) then
      Result.LineaV(4, Fila * 4, 4, Junta)
    else
      Result.LineaV(12, Fila * 4, 4, Junta);
  end;
  Result.LineaH(0, 0, TAM_TILE, Aclarar(Base, 28));
  Result.LineaV(0, 0, TAM_TILE, Aclarar(Base, 14));
  Result.LineaH(0, TAM_TILE - 1, TAM_TILE, Oscurecer(Base, 34));
  Result.LineaV(TAM_TILE - 1, 0, TAM_TILE, Oscurecer(Base, 34));
end;

function CrearCaja(Fase: Integer): TSuperficie;
var
  Brillo: TColor32;
begin
  Result := TSuperficie.Create(TAM_TILE, TAM_TILE);
  case Fase mod 3 of
    0: Brillo := RGBc(255, 206, 62);
    1: Brillo := RGBc(238, 178, 44);
  else
    Brillo := RGBc(214, 150, 30);
  end;
  Result.Limpiar(Brillo);
  Result.Barra(1, 1, TAM_TILE - 2, 1, Aclarar(Brillo, 40));
  Result.LineaH(0, 0, TAM_TILE, RGBc(120, 78, 16));
  Result.LineaV(0, 0, TAM_TILE, RGBc(120, 78, 16));
  Result.LineaH(0, TAM_TILE - 1, TAM_TILE, RGBc(96, 60, 12));
  Result.LineaV(TAM_TILE - 1, 0, TAM_TILE, RGBc(96, 60, 12));
  { Remaches en las esquinas. }
  Result.Barra(2, 2, 2, 2, RGBc(255, 244, 190));
  Result.Barra(12, 2, 2, 2, RGBc(255, 244, 190));
  Result.Barra(2, 12, 2, 2, RGBc(255, 244, 190));
  Result.Barra(12, 12, 2, 2, RGBc(255, 244, 190));
  { Simbolo central: una tuerca pequena. }
  Result.Barra(7, 5, 2, 6, RGBc(120, 78, 16));
  Result.Barra(5, 7, 6, 2, RGBc(120, 78, 16));
  Result.Barra(6, 6, 4, 4, RGBc(255, 240, 170));
  Result.Barra(7, 7, 2, 2, RGBc(120, 78, 16));
end;

function CrearCajaUsada(Base: TColor32): TSuperficie;
begin
  Result := TSuperficie.Create(TAM_TILE, TAM_TILE);
  Result.Limpiar(Base);
  Result.LineaH(0, 0, TAM_TILE, Aclarar(Base, 22));
  Result.LineaV(0, 0, TAM_TILE, Aclarar(Base, 10));
  Result.LineaH(0, TAM_TILE - 1, TAM_TILE, Oscurecer(Base, 30));
  Result.LineaV(TAM_TILE - 1, 0, TAM_TILE, Oscurecer(Base, 30));
  Result.Barra(2, 2, 2, 2, Oscurecer(Base, 20));
  Result.Barra(12, 2, 2, 2, Oscurecer(Base, 20));
  Result.Barra(2, 12, 2, 2, Oscurecer(Base, 20));
  Result.Barra(12, 12, 2, 2, Oscurecer(Base, 20));
end;

function CrearColumna(Base, Clara: TColor32; EsIzquierda, EsTapa: Boolean): TSuperficie;
var
  X0, X1, I: Integer;
begin
  Result := TSuperficie.Create(TAM_TILE, TAM_TILE);
  Result.Limpiar(COLOR_TRANSPARENTE);
  { Columna metalica de dos tiles de ancho, con aire a los lados, costura
    central y remaches. No lleva labio ni boca, para que se lea como una
    estructura industrial y no como una tuberia. }
  if EsIzquierda then
  begin
    X0 := 3;
    X1 := TAM_TILE - 1;
  end
  else
  begin
    X0 := 0;
    X1 := TAM_TILE - 4;
  end;

  Result.Barra(X0, 0, X1 - X0 + 1, TAM_TILE, Base);
  if EsIzquierda then
  begin
    Result.Barra(X0, 0, 2, TAM_TILE, Clara);
    Result.Barra(X0 + 2, 0, 1, TAM_TILE, Aclarar(Base, 18));
    Result.LineaV(X1, 0, TAM_TILE, Oscurecer(Base, 46));
  end
  else
  begin
    Result.Barra(X1 - 1, 0, 2, TAM_TILE, Clara);
    Result.Barra(X1 - 3, 0, 1, TAM_TILE, Aclarar(Base, 18));
    Result.LineaV(X0, 0, TAM_TILE, Oscurecer(Base, 46));
  end;

  { Dos remaches por tile. }
  for I := 0 to 1 do
    if EsIzquierda then
    begin
      Result.Barra(X0 + 4, 2 + I * 7, 2, 2, Aclarar(Base, 60));
      Result.Barra(X0 + 4, 4 + I * 7, 2, 1, Oscurecer(Base, 44));
    end
    else
    begin
      Result.Barra(X1 - 6, 2 + I * 7, 2, 2, Aclarar(Base, 60));
      Result.Barra(X1 - 6, 4 + I * 7, 2, 1, Oscurecer(Base, 44));
    end;

  if EsTapa then
  begin
    { Capitel con franjas de aviso y una luz de baliza. }
    Result.Barra(X0, 0, X1 - X0 + 1, 6, RGBc(56, 48, 40));
    for I := 0 to 3 do
    begin
      Result.Barra(X0 + I * 4, 1, 2, 4, RGBc(230, 188, 62));
      Result.Barra(X0 + I * 4 + 2, 1, 2, 4, RGBc(70, 58, 38));
    end;
    Result.LineaH(X0, 0, X1 - X0 + 1, Aclarar(Clara, 20));
    Result.LineaH(X0, 6, X1 - X0 + 1, Oscurecer(Base, 34));
    Result.Barra(X0 + 2, 9, 3, 3, RGBc(186, 224, 246));
    Result.Barra(X0 + 3, 10, 1, 1, RGBc(250, 252, 255));
  end
  else
    Result.LineaH(X0, 0, X1 - X0 + 1, Aclarar(Base, 12));
end;

function CrearViga(Base: TColor32): TSuperficie;
begin
  Result := TSuperficie.Create(TAM_TILE, TAM_TILE);
  Result.Limpiar(Base);
  Result.Barra(0, 1, TAM_TILE, 2, Aclarar(Base, 34));
  Result.Barra(0, TAM_TILE - 3, TAM_TILE, 2, Oscurecer(Base, 34));
  Result.Barra(2, 5, 2, 2, RGBc(220, 224, 236));
  Result.Barra(11, 5, 2, 2, RGBc(220, 224, 236));
  Result.Barra(2, 10, 2, 2, RGBc(220, 224, 236));
  Result.Barra(11, 10, 2, 2, RGBc(220, 224, 236));
end;

constructor TTiles.Create;
begin
  inherited Create;
end;

destructor TTiles.Destroy;
var
  I: Integer;
begin
  LiberarSuperficie(Tierra);
  LiberarSuperficie(Ladrillo);
  for I := 0 to 2 do
    LiberarSuperficie(Caja[I]);
  LiberarSuperficie(CajaUsada);
  LiberarSuperficie(ColumnaTapaIzq);
  LiberarSuperficie(ColumnaTapaDer);
  LiberarSuperficie(ColumnaCuerpoIzq);
  LiberarSuperficie(ColumnaCuerpoDer);
  LiberarSuperficie(Viga);
  inherited Destroy;
end;

function ConstruirTiles(const Tierra, TierraClara, Ladrillo, LadrilloJunta,
  Columna, ColumnaClara: TColor32): TTiles;
var
  I: Integer;
begin
  Result := TTiles.Create;
  Result.Tierra := CrearTierra(Tierra, TierraClara, Oscurecer(Tierra, 40));
  Result.Ladrillo := CrearLadrillo(Ladrillo, LadrilloJunta);
  for I := 0 to 2 do
    Result.Caja[I] := CrearCaja(I);
  Result.CajaUsada := CrearCajaUsada(RGBc(150, 108, 66));
  Result.ColumnaTapaIzq := CrearColumna(Columna, ColumnaClara, True, True);
  Result.ColumnaTapaDer := CrearColumna(Columna, ColumnaClara, False, True);
  Result.ColumnaCuerpoIzq := CrearColumna(Columna, ColumnaClara, True, False);
  Result.ColumnaCuerpoDer := CrearColumna(Columna, ColumnaClara, False, False);
  Result.Viga := CrearViga(RGBc(96, 104, 128));
end;

{ ------------------------------------------------------------------ }
{ Dibujos geometricos: tuerca, escudo, pua y chispa                   }
{ ------------------------------------------------------------------ }

function AnguloCercano(A, B: Single): Single;
var
  D: Single;
begin
  { Distancia angular minima entre dos angulos expresados en radianes. }
  D := A - B;
  while D > Pi do
    D := D - 2 * Pi;
  while D < -Pi do
    D := D + 2 * Pi;
  Result := Abs(D);
end;

function CrearMoneda(Fase: Integer): TSuperficie;
const
  DIENTES = 8;
var
  X, Y, Diente: Integer;
  DX, DY, Radio, Angulo, Distancia: Single;
  Base, Clara, Oscura, Borde: TColor32;
begin
  Result := TSuperficie.Create(TAM_TILE, TAM_TILE);
  Result.Limpiar(COLOR_TRANSPARENTE);
  Base := RGBc(238, 190, 44);
  Clara := RGBc(255, 236, 140);
  Oscura := RGBc(186, 128, 20);
  Borde := RGBc(96, 62, 10);
  for Y := 0 to TAM_TILE - 1 do
    for X := 0 to TAM_TILE - 1 do
    begin
      DX := X - 7.5;
      DY := Y - 7.5;
      Radio := Sqrt(DX * DX + DY * DY);
      Angulo := ArcTan2(DY, DX);
      Distancia := 999;
      for Diente := 0 to DIENTES - 1 do
        Distancia := Min(Distancia, AnguloCercano(Angulo,
          Diente * 2 * Pi / DIENTES + Fase * Pi / 16));
      if Radio <= 4.6 then
        Result.Punto(X, Y, Base)
      else if Radio <= 5.6 then
        Result.Punto(X, Y, Borde)
      else if (Radio <= 7.2) and (Distancia < 0.26) then
        Result.Punto(X, Y, Base)
      else if (Radio <= 7.8) and (Distancia < 0.26) then
        Result.Punto(X, Y, Borde);
    end;
  { Brillo superior izquierdo y hueco central. }
  for Y := 4 to 8 do
    for X := 4 to 8 do
      if Result.Pixeles[Y * TAM_TILE + X] = Base then
        if (X + Y) < 12 then
          Result.Punto(X, Y, Clara);
  Result.Barra(6, 6, 4, 4, COLOR_TRANSPARENTE);
  Result.Barra(6, 6, 1, 1, Oscura);
  Result.Barra(9, 9, 1, 1, Oscura);
end;

function CrearEscudo: TSuperficie;
var
  P: TPaleta;
begin
  P := PaletaBase;
  Result := ConstruirSprite(MAPA_ESCUDO, P);
end;

function CrearPua(Fase: Integer): TSuperficie;
const
  PUNTAS = 8;
var
  X, Y, Punta: Integer;
  DX, DY, Radio, Angulo, Distancia: Single;
  Cuerpo, Brillo, Borde, Pincho: TColor32;
begin
  Result := TSuperficie.Create(TAM_TILE, TAM_TILE);
  Result.Limpiar(COLOR_TRANSPARENTE);
  Cuerpo := RGBc(132, 92, 176);
  Brillo := RGBc(196, 160, 236);
  Borde := RGBc(52, 34, 78);
  Pincho := RGBc(206, 210, 226);
  for Y := 0 to TAM_TILE - 1 do
    for X := 0 to TAM_TILE - 1 do
    begin
      DX := X - 7.5;
      DY := Y - 7.5;
      Radio := Sqrt(DX * DX + DY * DY);
      Angulo := ArcTan2(DY, DX);
      Distancia := 999;
      for Punta := 0 to PUNTAS - 1 do
        Distancia := Min(Distancia, AnguloCercano(Angulo,
          Punta * 2 * Pi / PUNTAS + Fase * Pi / 14));
      if Radio <= 4.2 then
      begin
        if (DX + DY) < -2 then
          Result.Punto(X, Y, Brillo)
        else
          Result.Punto(X, Y, Cuerpo);
      end
      else if Radio <= 5.2 then
        Result.Punto(X, Y, Borde)
      else if (Radio <= 7.6) and (Distancia < 0.22) then
        Result.Punto(X, Y, Pincho);
    end;
  Result.Barra(6, 6, 4, 4, Borde);
  Result.Barra(7, 7, 2, 2, RGBc(232, 226, 250));
end;

function CrearChispa(Fase: Integer): TSuperficie;
var
  R: Integer;
begin
  Result := TSuperficie.Create(8, 8);
  Result.Limpiar(COLOR_TRANSPARENTE);
  R := 3 - Fase;
  Result.Barra(4 - R, 4 - R, R * 2, R * 2, RGBc(255, 236, 140));
  Result.Barra(3, 3, 2, 2, RGBc(255, 252, 214));
end;

{ ------------------------------------------------------------------ }
{ Animaciones de personajes y objetos                                 }
{ ------------------------------------------------------------------ }

constructor TSpritesHeroe.Create;
var
  P: TPaleta;
begin
  inherited Create;
  P := PaletaBase;
  Quieto := ConstruirSprite(MAPA_HEROE_QUIETO, P);
  Corre[0] := ConstruirSprite(MAPA_HEROE_CORRE1, P);
  Corre[1] := ConstruirSprite(MAPA_HEROE_CORRE2, P);
  Corre[2] := ConstruirSprite(MAPA_HEROE_CORRE3, P);
  Salto := ConstruirSprite(MAPA_HEROE_SALTO, P);
  Caida := ConstruirSprite(MAPA_HEROE_CAIDA, P);
  Muerto := ConstruirSprite(MAPA_HEROE_MUERTO, P);
end;

destructor TSpritesHeroe.Destroy;
var
  I: Integer;
begin
  LiberarSuperficie(Quieto);
  for I := 0 to 2 do
    LiberarSuperficie(Corre[I]);
  LiberarSuperficie(Salto);
  LiberarSuperficie(Caida);
  LiberarSuperficie(Muerto);
  inherited Destroy;
end;

function TSpritesHeroe.CuadroCorre(Fotograma: Integer): TSuperficie;
begin
  Result := Corre[Abs(Fotograma) mod 3];
end;

constructor TSpritesEnemigos.Create;
var
  P: TPaleta;
  I: Integer;
begin
  inherited Create;
  P := PaletaBase;
  Bicho[0] := ConstruirSprite(MAPA_BICHO1, P);
  Bicho[1] := ConstruirSprite(MAPA_BICHO2, P);
  Mosca[0] := ConstruirSprite(MAPA_MOSCA1, P);
  Mosca[1] := ConstruirSprite(MAPA_MOSCA2, P);
  { La pua gira sobre si misma, asi que cada cuadro se dibuja por codigo. }
  for I := 0 to 3 do
    Pua[I] := CrearPua(I);
end;

destructor TSpritesEnemigos.Destroy;
var
  I: Integer;
begin
  for I := 0 to 1 do
  begin
    LiberarSuperficie(Bicho[I]);
    LiberarSuperficie(Mosca[I]);
  end;
  for I := 0 to 3 do
    LiberarSuperficie(Pua[I]);
  inherited Destroy;
end;

constructor TSpritesObjetos.Create;
var
  I: Integer;
begin
  inherited Create;
  for I := 0 to 3 do
    Moneda[I] := CrearMoneda(I);
  for I := 0 to 2 do
    Chispa[I] := CrearChispa(I);
  Escudo := CrearEscudo;
end;

destructor TSpritesObjetos.Destroy;
var
  I: Integer;
begin
  for I := 0 to 3 do
    LiberarSuperficie(Moneda[I]);
  for I := 0 to 2 do
    LiberarSuperficie(Chispa[I]);
  LiberarSuperficie(Escudo);
  inherited Destroy;
end;

end.
