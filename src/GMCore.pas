unit GMCore;
{ Tipos y utilidades base del juego. El unit no depende de la API de Windows
  para que la logica se pueda probar sin abrir una ventana. }

{$MODE DELPHI}
{$H+}

interface

const
  { Version que se muestra en pantalla y en el titulo de la ventana. }
  VERSION_JUEGO = '1.1.0';

  { Resolucion logica. Todo el juego se dibuja a 320x200 y la ventana
    escala esa imagen con un multiplo entero. }
  ANCHO_VIRTUAL = 320;
  ALTO_VIRTUAL = 200;

  { Franja superior reservada para el marcador. }
  ALTO_HUD = 24;
  ALTO_MUNDO = ALTO_VIRTUAL - ALTO_HUD;

  TAM_TILE = 16;
  FILAS_NIVEL = 11;
  COLUMNAS_VISIBLES = ANCHO_VIRTUAL div TAM_TILE;

  FPS_OBJETIVO = 60;
  MS_FOTOGRAMA = 1000 div FPS_OBJETIVO;

  { Color centinela que marca los pixeles transparentes de los sprites. }
  COLOR_TRANSPARENTE = $FFFF00FF;

type
  { Pixel en formato $00RRGGBB. La superficie se guarda como DIB de 32 bits,
    por lo que en memoria queda B, G, R y un byte sin uso. }
  TColor32 = Cardinal;

  TRectI = record
    X, Y, Ancho, Alto: Integer;
  end;

  { Opciones de linea de comandos que entiende el ejecutable. }
  TOpciones = record
    AutoPrueba: Boolean;
    Capturar: string;
    Mapa: string;
    Silencio: Boolean;
    NivelInicial: Integer;
    Ayuda: Boolean;
  end;

function RGBc(R, G, B: Byte): TColor32;
function MezclarColor(C1, C2: TColor32; T: Single): TColor32;
function Aclarar(C: TColor32; Cantidad: Integer): TColor32;
function Oscurecer(C: TColor32; Cantidad: Integer): TColor32;
function Limitar(Valor, Minimo, Maximo: Integer): Integer;
function LimitarF(Valor, Minimo, Maximo: Single): Single;
function RectI(X, Y, Ancho, Alto: Integer): TRectI;
function HaySolape(const A, B: TRectI): Boolean;
function Firmar(Valor: Single): Integer;
function LeerOpciones: TOpciones;
procedure EscribirAyuda;
procedure Registrar(const Linea: string);
function RutaRegistro: string;
function RutaEjecutable: string;

implementation

uses
  SysUtils;

function RGBc(R, G, B: Byte): TColor32;
begin
  Result := (Cardinal(R) shl 16) or (Cardinal(G) shl 8) or Cardinal(B);
end;

function ComponenteColor(C: TColor32; Desplazamiento: Integer): Integer;
begin
  Result := (C shr Desplazamiento) and $FF;
end;

function MezclarColor(C1, C2: TColor32; T: Single): TColor32;
var
  R, G, B: Integer;
  F: Single;
begin
  F := LimitarF(T, 0, 1);
  R := Round(ComponenteColor(C1, 16) + (ComponenteColor(C2, 16) - ComponenteColor(C1, 16)) * F);
  G := Round(ComponenteColor(C1, 8) + (ComponenteColor(C2, 8) - ComponenteColor(C1, 8)) * F);
  B := Round(ComponenteColor(C1, 0) + (ComponenteColor(C2, 0) - ComponenteColor(C1, 0)) * F);
  Result := RGBc(Limitar(R, 0, 255), Limitar(G, 0, 255), Limitar(B, 0, 255));
end;

function Aclarar(C: TColor32; Cantidad: Integer): TColor32;
begin
  Result := RGBc(
    Limitar(ComponenteColor(C, 16) + Cantidad, 0, 255),
    Limitar(ComponenteColor(C, 8) + Cantidad, 0, 255),
    Limitar(ComponenteColor(C, 0) + Cantidad, 0, 255));
end;

function Oscurecer(C: TColor32; Cantidad: Integer): TColor32;
begin
  Result := Aclarar(C, -Cantidad);
end;

function Limitar(Valor, Minimo, Maximo: Integer): Integer;
begin
  if Valor < Minimo then
    Result := Minimo
  else if Valor > Maximo then
    Result := Maximo
  else
    Result := Valor;
end;

function LimitarF(Valor, Minimo, Maximo: Single): Single;
begin
  if Valor < Minimo then
    Result := Minimo
  else if Valor > Maximo then
    Result := Maximo
  else
    Result := Valor;
end;

function RectI(X, Y, Ancho, Alto: Integer): TRectI;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Ancho := Ancho;
  Result.Alto := Alto;
end;

function HaySolape(const A, B: TRectI): Boolean;
begin
  Result := (A.X < B.X + B.Ancho) and (A.X + A.Ancho > B.X) and
    (A.Y < B.Y + B.Alto) and (A.Y + A.Alto > B.Y);
end;

function Firmar(Valor: Single): Integer;
begin
  if Valor < 0 then
    Result := -1
  else if Valor > 0 then
    Result := 1
  else
    Result := 0;
end;

function RutaEjecutable: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

function RutaRegistro: string;
begin
  Result := IncludeTrailingPathDelimiter(RutaEjecutable) + 'salta-mundos.log';
end;

procedure Registrar(const Linea: string);
var
  Archivo: TextFile;
  Ruta: string;
begin
  Ruta := RutaRegistro;
  try
    AssignFile(Archivo, Ruta);
    if FileExists(Ruta) then
      Append(Archivo)
    else
      Rewrite(Archivo);
    try
      Writeln(Archivo, Linea);
      Flush(Archivo);
    finally
      CloseFile(Archivo);
    end;
  except
    { Sin registro en disco el juego sigue funcionando. }
  end;
  try
    Writeln(Linea);
    Flush(Output);
  except
  end;
end;

function LeerOpciones: TOpciones;
var
  I: Integer;
  Argumento, Valor: string;

  procedure TomarValor(var Destino: string);
  begin
    Inc(I);
    if I <= ParamCount then
      Destino := ParamStr(I);
  end;

begin
  Result.AutoPrueba := False;
  Result.Capturar := '';
  Result.Mapa := '';
  Result.Silencio := False;
  Result.NivelInicial := 0;
  Result.Ayuda := False;

  I := 1;
  while I <= ParamCount do
  begin
    Argumento := LowerCase(ParamStr(I));
    if (Argumento = '--autoprueba') or (Argumento = '--selftest') then
      Result.AutoPrueba := True
    else if (Argumento = '--capturar') or (Argumento = '--capture') then
      TomarValor(Result.Capturar)
    else if (Argumento = '--mapa') or (Argumento = '--map') then
      TomarValor(Result.Mapa)
    else if (Argumento = '--silencio') or (Argumento = '--mute') then
      Result.Silencio := True
    else if (Argumento = '--nivel') or (Argumento = '--level') then
    begin
      TomarValor(Valor);
      Result.NivelInicial := StrToIntDef(Valor, 0);
    end
    else if (Argumento = '--ayuda') or (Argumento = '-h') or (Argumento = '--help') then
      Result.Ayuda := True;
    Inc(I);
  end;
end;

procedure EscribirAyuda;
begin
  Writeln('Salta Mundos ', VERSION_JUEGO, ' - juego de plataformas en Object Pascal');
  Writeln;
  Writeln('Uso: SaltaMundos.exe [opciones]');
  Writeln;
  Writeln('  --autoprueba        ejecuta la prueba interna sin abrir ventana');
  Writeln('  --capturar CARPETA  guarda fotogramas de muestra en BMP y termina');
  Writeln('  --mapa CARPETA      guarda el mapa completo de cada nivel y termina');
  Writeln('  --nivel N           empieza en el nivel N (1..6)');
  Writeln('  --silencio          desactiva el audio');
  Writeln('  --ayuda             muestra este texto');
end;

end.
