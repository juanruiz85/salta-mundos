unit GMSuperficie;
{ Superficie de pixeles de 32 bits y utilidades de dibujo: rectangulos,
  copia de sprites y una fuente bitmap propia de 5x7 pixeles.
  Se usa tanto para la pantalla como para los sprites y las miniaturas. }

{$MODE DELPHI}
{$H+}

interface

uses
  SysUtils,
  Classes,
  GMCore;

type
  TSuperficie = class
  private
    FAncho: Integer;
    FAlto: Integer;
    FPixeles: PCardinal;
    FPropia: Boolean;
  public
    constructor Create(AAncho, AAlto: Integer); overload;
    constructor CreateDesdeMemoria(AAncho, AAlto: Integer; APixeles: PCardinal); overload;
    destructor Destroy; override;

    procedure Limpiar(C: TColor32);
    procedure Barra(X, Y, Ancho, Alto: Integer; C: TColor32);
    procedure Marco(X, Y, Ancho, Alto: Integer; C: TColor32);
    procedure Punto(X, Y: Integer; C: TColor32);
    procedure LineaH(X, Y, Largo: Integer; C: TColor32);
    procedure LineaV(X, Y, Alto: Integer; C: TColor32);
    procedure Degradado(Y0, Y1: Integer; C0, C1: TColor32);

    procedure Copiar(DestX, DestY: Integer; Fuente: TSuperficie; Espejo: Boolean = False);
    procedure CopiarColor(DestX, DestY: Integer; Fuente: TSuperficie;
      ColorTransp: TColor32; Espejo: Boolean = False);
    procedure CopiarRecorte(DestX, DestY, RecX, RecY, RecAncho, RecAlto: Integer;
      Fuente: TSuperficie; ColorTransp: TColor32);

    procedure Texto(X, Y: Integer; const Cadena: string; C: TColor32; Escala: Integer = 1);
    procedure TextoSombra(X, Y: Integer; const Cadena: string; C, Sombra: TColor32;
      Escala: Integer = 1);
    procedure TextoCentrado(Y: Integer; const Cadena: string; C: TColor32; Escala: Integer = 1);
    procedure TextoCentradoSombra(Y: Integer; const Cadena: string; C, Sombra: TColor32;
      Escala: Integer = 1);
    function AnchoTexto(const Cadena: string; Escala: Integer = 1): Integer;

    procedure GuardarBMP(const Archivo: string);

    property Ancho: Integer read FAncho;
    property Alto: Integer read FAlto;
    property Pixeles: PCardinal read FPixeles;
  end;

{ Funcion auxiliar para crear una superficie con la textura de un color. }
function SuperficieDeColor(Ancho, Alto: Integer; C: TColor32): TSuperficie;

implementation

type
  TTablaFuente = array[0..255, 0..6] of Byte;

var
  TablaFuente: TTablaFuente;

{ Devuelve el dibujo de un caracter como siete filas de cinco bits.
  Cada fila se escribe en hexadecimal: el bit 4 es el pixel de la izquierda. }
function DatosGlifo(C: Char): string;
begin
  case UpCase(C) of
    'A': Result := '0E11111F111111';
    'B': Result := '1E11111E11111E';
    'C': Result := '0E1110101011 0E';
    'D': Result := '1E11111111111E';
    'E': Result := '1F10101E10101F';
    'F': Result := '1F10101E101010';
    'G': Result := '0E11101711110E';
    'H': Result := '1111111F111111';
    'I': Result := '0E04040404040E';
    'J': Result := '070404041212 0C';
    'K': Result := '11121418141211';
    'L': Result := '1010101010101F';
    'M': Result := '111B1511111111';
    'N': Result := '111915131111 11';
    'O': Result := '0E11111111110E';
    'P': Result := '1E11111E101010';
    'Q': Result := '0E11111115120D';
    'R': Result := '1E11111E141211';
    'S': Result := '0F10100E01011E';
    'T': Result := '1F040404040404';
    'U': Result := '1111111111110E';
    'V': Result := '11111111110A04';
    'W': Result := '11111115151B11';
    'X': Result := '11110A040A1111';
    'Y': Result := '11110A04040404';
    'Z': Result := '1F01020408101F';
    '0': Result := '0E11131519110E';
    '1': Result := '040C040404040E';
    '2': Result := '0E11010204081F';
    '3': Result := '1F02040201110E';
    '4': Result := '02060A121F0202';
    '5': Result := '1F101E0101110E';
    '6': Result := '0608101E11110E';
    '7': Result := '1F010204080808';
    '8': Result := '0E11110E11110E';
    '9': Result := '0E11110F01020C';
    '.': Result := '00000000000C0C';
    ':': Result := '000C0C000C0C00';
    '-': Result := '0000001F000000';
    '!': Result := '04040404040004';
    '?': Result := '0E110102040004';
    '(': Result := '02040808080402';
    ')': Result := '08040202020408';
    '/': Result := '01020204080810';
    ',': Result := '000000000C0C08';
    '<': Result := '02040810080402';
    '>': Result := '08040201020408';
    '+': Result := '0004041F040400';
    '=': Result := '00001F001F0000';
    'x': Result := '00110A040A1100';
    '*': Result := '0004150E150400';
    '''': Result := '04040400000000';
    '"': Result := '0A0A0A00000000';
    '%': Result := '1112040811 1100';
  else
    Result := '';
  end;
end;

procedure IniciarTablaFuente;
var
  Caracter: Integer;
  Fila: Integer;
  Datos, Par: string;
begin
  FillChar(TablaFuente, SizeOf(TablaFuente), 0);
  for Caracter := 0 to 255 do
  begin
    Datos := StringReplace(DatosGlifo(Chr(Caracter)), ' ', '', [rfReplaceAll]);
    if Datos = '' then
      Continue;
    for Fila := 0 to 6 do
    begin
      Par := Copy(Datos, Fila * 2 + 1, 2);
      if Length(Par) = 2 then
        TablaFuente[Caracter][Fila] := StrToIntDef('$' + Par, 0);
    end;
  end;
end;

function SuperficieDeColor(Ancho, Alto: Integer; C: TColor32): TSuperficie;
begin
  Result := TSuperficie.Create(Ancho, Alto);
  Result.Limpiar(C);
end;

constructor TSuperficie.Create(AAncho, AAlto: Integer);
begin
  inherited Create;
  FAncho := AAncho;
  FAlto := AAlto;
  GetMem(FPixeles, FAncho * FAlto * SizeOf(Cardinal));
  FPropia := True;
  Limpiar(0);
end;

constructor TSuperficie.CreateDesdeMemoria(AAncho, AAlto: Integer; APixeles: PCardinal);
begin
  inherited Create;
  FAncho := AAncho;
  FAlto := AAlto;
  FPixeles := APixeles;
  FPropia := False;
end;

destructor TSuperficie.Destroy;
begin
  if FPropia and (FPixeles <> nil) then
    FreeMem(FPixeles);
  inherited Destroy;
end;

procedure TSuperficie.Limpiar(C: TColor32);
var
  I: Integer;
  P: PCardinal;
begin
  P := FPixeles;
  for I := 0 to FAncho * FAlto - 1 do
  begin
    P^ := C;
    Inc(P);
  end;
end;

procedure TSuperficie.Barra(X, Y, Ancho, Alto: Integer; C: TColor32);
var
  Fila: Integer;
  P: PCardinal;
  Izquierda, Derecha, Arriba, Abajo: Integer;
begin
  Izquierda := Limitar(X, 0, FAncho);
  Derecha := Limitar(X + Ancho, 0, FAncho);
  Arriba := Limitar(Y, 0, FAlto);
  Abajo := Limitar(Y + Alto, 0, FAlto);
  if (Izquierda >= Derecha) or (Arriba >= Abajo) then
    Exit;
  for Fila := Arriba to Abajo - 1 do
  begin
    P := FPixeles + Fila * FAncho + Izquierda;
    FillChar(P^, (Derecha - Izquierda) * SizeOf(Cardinal), 0);
    FillDWord(P^, Derecha - Izquierda, C);
  end;
end;

procedure TSuperficie.Marco(X, Y, Ancho, Alto: Integer; C: TColor32);
begin
  LineaH(X, Y, Ancho, C);
  LineaH(X, Y + Alto - 1, Ancho, C);
  LineaV(X, Y, Alto, C);
  LineaV(X + Ancho - 1, Y, Alto, C);
end;

procedure TSuperficie.Punto(X, Y: Integer; C: TColor32);
begin
  if (X < 0) or (Y < 0) or (X >= FAncho) or (Y >= FAlto) then
    Exit;
  (FPixeles + Y * FAncho + X)^ := C;
end;

procedure TSuperficie.LineaH(X, Y, Largo: Integer; C: TColor32);
begin
  Barra(X, Y, Largo, 1, C);
end;

procedure TSuperficie.LineaV(X, Y, Alto: Integer; C: TColor32);
begin
  Barra(X, Y, 1, Alto, C);
end;

procedure TSuperficie.Degradado(Y0, Y1: Integer; C0, C1: TColor32);
var
  Fila, Tope, Fondo: Integer;
  T: Single;
begin
  Tope := Limitar(Y0, 0, FAlto);
  Fondo := Limitar(Y1, 0, FAlto);
  if Tope >= Fondo then
    Exit;
  for Fila := Tope to Fondo - 1 do
  begin
    if Fondo - Tope = 1 then
      T := 0
    else
      T := (Fila - Tope) / (Fondo - Tope - 1);
    Barra(0, Fila, FAncho, 1, MezclarColor(C0, C1, T));
  end;
end;

procedure TSuperficie.Copiar(DestX, DestY: Integer; Fuente: TSuperficie; Espejo: Boolean);
begin
  CopiarColor(DestX, DestY, Fuente, $FFFFFFFF, Espejo);
end;

procedure TSuperficie.CopiarColor(DestX, DestY: Integer; Fuente: TSuperficie;
  ColorTransp: TColor32; Espejo: Boolean);
var
  Fila, Columna, OrigenX, OrigenY: Integer;
  Origen, Destino: PCardinal;
begin
  if Fuente = nil then
    Exit;
  for Fila := 0 to Fuente.Alto - 1 do
  begin
    OrigenY := DestY + Fila;
    if (OrigenY < 0) or (OrigenY >= FAlto) then
      Continue;
    if Espejo then
      Origen := Fuente.Pixeles + Fila * Fuente.Ancho + (Fuente.Ancho - 1)
    else
      Origen := Fuente.Pixeles + Fila * Fuente.Ancho;
    for Columna := 0 to Fuente.Ancho - 1 do
    begin
      OrigenX := DestX + Columna;
      if (OrigenX >= 0) and (OrigenX < FAncho) and (Origen^ <> ColorTransp) then
      begin
        Destino := FPixeles + OrigenY * FAncho + OrigenX;
        Destino^ := Origen^;
      end;
      if Espejo then
        Dec(Origen)
      else
        Inc(Origen);
    end;
  end;
end;

procedure TSuperficie.CopiarRecorte(DestX, DestY, RecX, RecY, RecAncho, RecAlto: Integer;
  Fuente: TSuperficie; ColorTransp: TColor32);
var
  Fila, Columna: Integer;
  Origen, Destino: PCardinal;
begin
  if Fuente = nil then
    Exit;
  for Fila := 0 to RecAlto - 1 do
  begin
    if (DestY + Fila < 0) or (DestY + Fila >= FAlto) then
      Continue;
    if (RecY + Fila < 0) or (RecY + Fila >= Fuente.Alto) then
      Continue;
    for Columna := 0 to RecAncho - 1 do
    begin
      if (DestX + Columna < 0) or (DestX + Columna >= FAncho) then
        Continue;
      if (RecX + Columna < 0) or (RecX + Columna >= Fuente.Ancho) then
        Continue;
      Origen := Fuente.Pixeles + (RecY + Fila) * Fuente.Ancho + (RecX + Columna);
      if Origen^ = ColorTransp then
        Continue;
      Destino := FPixeles + (DestY + Fila) * FAncho + (DestX + Columna);
      Destino^ := Origen^;
    end;
  end;
end;

procedure TSuperficie.Texto(X, Y: Integer; const Cadena: string; C: TColor32; Escala: Integer);
var
  I, Fila, Columna: Integer;
  Bits: Byte;
  Letra: Char;
  BaseX: Integer;
  EscalaFinal: Integer;
begin
  EscalaFinal := Limitar(Escala, 1, 8);
  BaseX := X;
  for I := 1 to Length(Cadena) do
  begin
    Letra := Cadena[I];
    if Letra = ' ' then
    begin
      Inc(BaseX, 6 * EscalaFinal);
      Continue;
    end;
    for Fila := 0 to 6 do
    begin
      Bits := TablaFuente[Ord(Letra)][Fila];
      if Bits = 0 then
        Continue;
      for Columna := 0 to 4 do
        if (Bits and (16 shr Columna)) <> 0 then
          Barra(BaseX + Columna * EscalaFinal, Y + Fila * EscalaFinal,
            EscalaFinal, EscalaFinal, C);
    end;
    Inc(BaseX, 6 * EscalaFinal);
  end;
end;

procedure TSuperficie.TextoSombra(X, Y: Integer; const Cadena: string; C, Sombra: TColor32;
  Escala: Integer);
begin
  Self.Texto(X + Escala, Y + Escala, Cadena, Sombra, Escala);
  Self.Texto(X, Y, Cadena, C, Escala);
end;

procedure TSuperficie.TextoCentrado(Y: Integer; const Cadena: string; C: TColor32;
  Escala: Integer);
begin
  Self.Texto((FAncho - AnchoTexto(Cadena, Escala)) div 2, Y, Cadena, C, Escala);
end;

procedure TSuperficie.TextoCentradoSombra(Y: Integer; const Cadena: string; C, Sombra: TColor32;
  Escala: Integer);
begin
  TextoSombra((FAncho - AnchoTexto(Cadena, Escala)) div 2, Y, Cadena, C, Sombra, Escala);
end;

function TSuperficie.AnchoTexto(const Cadena: string; Escala: Integer = 1): Integer;
begin
  if Cadena = '' then
    Result := 0
  else
    Result := (Length(Cadena) * 6 - 1) * Limitar(Escala, 1, 8);
end;

procedure TSuperficie.GuardarBMP(const Archivo: string);
var
  Flujo: TFileStream;
  Cabecera: array[0..53] of Byte;
  Fila, Columna, Relleno: Integer;
  P: PCardinal;
  Linea: array of Byte;
  TamanoImagen: Integer;
begin
  Relleno := (4 - (FAncho * 3) mod 4) mod 4;
  TamanoImagen := (FAncho * 3 + Relleno) * FAlto;
  FillChar(Cabecera, SizeOf(Cabecera), 0);
  Cabecera[0] := Ord('B');
  Cabecera[1] := Ord('M');
  PInteger(@Cabecera[2])^ := 54 + TamanoImagen;
  PInteger(@Cabecera[10])^ := 54;
  PInteger(@Cabecera[14])^ := 40;
  PInteger(@Cabecera[18])^ := FAncho;
  PInteger(@Cabecera[22])^ := FAlto;
  PWord(@Cabecera[26])^ := 1;
  PWord(@Cabecera[28])^ := 24;
  PInteger(@Cabecera[34])^ := TamanoImagen;
  PInteger(@Cabecera[38])^ := 2835;
  PInteger(@Cabecera[42])^ := 2835;

  Flujo := TFileStream.Create(Archivo, fmCreate);
  try
    Flujo.WriteBuffer(Cabecera, 54);
    SetLength(Linea, FAncho * 3 + Relleno);
    for Fila := FAlto - 1 downto 0 do
    begin
      FillChar(Linea[0], Length(Linea), 0);
      P := FPixeles + Fila * FAncho;
      for Columna := 0 to FAncho - 1 do
      begin
        Linea[Columna * 3 + 0] := Byte(P^ and $FF);
        Linea[Columna * 3 + 1] := Byte((P^ shr 8) and $FF);
        Linea[Columna * 3 + 2] := Byte((P^ shr 16) and $FF);
        Inc(P);
      end;
      Flujo.WriteBuffer(Linea[0], Length(Linea));
    end;
  finally
    Flujo.Free;
  end;
end;

initialization
  IniciarTablaFuente;

end.
