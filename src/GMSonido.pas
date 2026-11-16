unit GMSonido;
{ Sintetizador minimo sobre waveOut: genera musica y efectos con ondas
  cuadradas, sin archivos externos. Si la tarjeta de sonido no responde, el
  juego sigue funcionando en silencio. }

{$MODE DELPHI}
{$H+}

interface

type
  TEfecto = (efNinguno, efSalto, efTuerca, efPisot, efEscudo, efMuerte, efNivel, efGolpe);

  TSonido = class
  private
    FActivo: Boolean;
    FSilencio: Boolean;
    procedure Detener;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Abrir;
    procedure Silenciar;
    procedure Efecto(Tipo: TEfecto);
    procedure Musica(Numero: Integer);
    property Activo: Boolean read FActivo;
  end;

implementation

uses
  Windows,
  MMSystem,
  SysUtils,
  Classes,
  Math;

const
  FRECUENCIA_MUESTREO = 22050;
  MUESTRAS_BLOQUE = 1024;
  TOTAL_BLOQUES = 4;

type
  TMezclador = class
  private
    FHandle: HWAVEOUT;
    FCabeceras: array[0..TOTAL_BLOQUES - 1] of TWAVEHDR;
    FDatos: array[0..TOTAL_BLOQUES - 1] of array[0..MUESTRAS_BLOQUE - 1] of SmallInt;
    FBloques: array[0..TOTAL_BLOQUES - 1] of Boolean;
    FAbierto: Boolean;
    FSfx: Integer;
    FSfxMuestra: Integer;
    FMusica: Integer;
    FMusicaMuestra: Integer;
    FSilencio: Boolean;
    procedure Preparar;
    procedure Rellenar(Bloque: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Abrir;
    procedure Cerrar;
    procedure Sonar(Tipo: Integer);
    procedure PonerMusica(Numero: Integer);
    procedure CambiarSilencio(Valor: Boolean);
    property Abierto: Boolean read FAbierto;
  end;

  THiloAudio = class(TThread)
  private
    FMezclador: TMezclador;
  protected
    procedure Execute; override;
  public
    constructor Create(Mezclador: TMezclador);
  end;

var
  GMezclador: TMezclador = nil;
  GHilo: THiloAudio = nil;

{ --------------------------- musica --------------------------- }

type
  TNota = record
    Semitono: Integer;   { distancia en semitonos desde La4; -99 es silencio }
    Duracion: Integer;   { duracion en muestras }
  end;

const
  MELODIA_PRADERA: array[0..15] of TNota = (
    (Semitono: 3; Duracion: 3300), (Semitono: 7; Duracion: 3300),
    (Semitono: 10; Duracion: 3300), (Semitono: 7; Duracion: 3300),
    (Semitono: 5; Duracion: 3300), (Semitono: 8; Duracion: 3300),
    (Semitono: 12; Duracion: 3300), (Semitono: 8; Duracion: 3300),
    (Semitono: 3; Duracion: 3300), (Semitono: 7; Duracion: 3300),
    (Semitono: 10; Duracion: 3300), (Semitono: 15; Duracion: 3300),
    (Semitono: 14; Duracion: 3300), (Semitono: 10; Duracion: 3300),
    (Semitono: 7; Duracion: 6600), (Semitono: -99; Duracion: 3300));

  MELODIA_NOCHE: array[0..15] of TNota = (
    (Semitono: 0; Duracion: 4400), (Semitono: 3; Duracion: 4400),
    (Semitono: 7; Duracion: 4400), (Semitono: 10; Duracion: 4400),
    (Semitono: 12; Duracion: 4400), (Semitono: 10; Duracion: 4400),
    (Semitono: 7; Duracion: 4400), (Semitono: 3; Duracion: 4400),
    (Semitono: 5; Duracion: 4400), (Semitono: 8; Duracion: 4400),
    (Semitono: 12; Duracion: 4400), (Semitono: 15; Duracion: 4400),
    (Semitono: 14; Duracion: 4400), (Semitono: 10; Duracion: 4400),
    (Semitono: 7; Duracion: 8800), (Semitono: -99; Duracion: 4400));

  MELODIA_FABRICA: array[0..15] of TNota = (
    (Semitono: 2; Duracion: 2600), (Semitono: 2; Duracion: 2600),
    (Semitono: 9; Duracion: 2600), (Semitono: 2; Duracion: 2600),
    (Semitono: 5; Duracion: 2600), (Semitono: 4; Duracion: 2600),
    (Semitono: 2; Duracion: 2600), (Semitono: -99; Duracion: 2600),
    (Semitono: 7; Duracion: 2600), (Semitono: 5; Duracion: 2600),
    (Semitono: 4; Duracion: 2600), (Semitono: 2; Duracion: 2600),
    (Semitono: 0; Duracion: 2600), (Semitono: 2; Duracion: 2600),
    (Semitono: 5; Duracion: 5200), (Semitono: -99; Duracion: 2600));

function Frecuencia(Semitono: Integer): Single;
begin
  if Semitono <= -90 then
    Result := 0
  else
    Result := 440 * Power(2, Semitono / 12);
end;

function NotaDeMusica(Numero: Integer; Indice: Integer): TNota;
begin
  if Numero = 2 then
    Result := MELODIA_NOCHE[Indice mod 16]
  else if Numero >= 3 then
    Result := MELODIA_FABRICA[Indice mod 16]
  else
    Result := MELODIA_PRADERA[Indice mod 16];
end;

{ --------------------------- mezclador --------------------------- }

constructor TMezclador.Create;
begin
  inherited Create;
  FHandle := 0;
  FAbierto := False;
  FSfx := 0;
  FSfxMuestra := 0;
  FMusica := 0;
  FMusicaMuestra := 0;
  FSilencio := False;
  FillChar(FBloques, SizeOf(FBloques), 0);
  FillChar(FCabeceras, SizeOf(FCabeceras), 0);
end;

destructor TMezclador.Destroy;
begin
  Cerrar;
  inherited Destroy;
end;

procedure TMezclador.Abrir;
var
  Formato: TWAVEFORMATEX;
  I: Integer;
begin
  if FAbierto then
    Exit;
  FillChar(Formato, SizeOf(Formato), 0);
  Formato.wFormatTag := WAVE_FORMAT_PCM;
  Formato.nChannels := 1;
  Formato.nSamplesPerSec := FRECUENCIA_MUESTREO;
  Formato.wBitsPerSample := 16;
  Formato.nBlockAlign := Formato.nChannels * Formato.wBitsPerSample div 8;
  Formato.nAvgBytesPerSec := Formato.nSamplesPerSec * Formato.nBlockAlign;
  if waveOutOpen(@FHandle, WAVE_MAPPER, @Formato, 0, 0, CALLBACK_NULL) <> MMSYSERR_NOERROR then
  begin
    FHandle := 0;
    Exit;
  end;
  FAbierto := True;
  for I := 0 to TOTAL_BLOQUES - 1 do
  begin
    FillChar(FCabeceras[I], SizeOf(TWAVEHDR), 0);
    with FCabeceras[I] do
    begin
      lpData := PAnsiChar(@FDatos[I][0]);
      dwBufferLength := MUESTRAS_BLOQUE * SizeOf(SmallInt);
      dwFlags := 0;
    end;
    waveOutPrepareHeader(FHandle, @FCabeceras[I], SizeOf(TWAVEHDR));
    FBloques[I] := True;
  end;
  Preparar;
end;

procedure TMezclador.Preparar;
var
  I: Integer;
begin
  for I := 0 to TOTAL_BLOQUES - 1 do
    if FBloques[I] then
    begin
      Rellenar(I);
      FBloques[I] := False;
      waveOutWrite(FHandle, @FCabeceras[I], SizeOf(TWAVEHDR));
    end;
end;

procedure TMezclador.Cerrar;
begin
  if not FAbierto then
    Exit;
  FAbierto := False;
  waveOutReset(FHandle);
  waveOutClose(FHandle);
  FHandle := 0;
end;

procedure TMezclador.CambiarSilencio(Valor: Boolean);
begin
  FSilencio := Valor;
end;

procedure TMezclador.Sonar(Tipo: Integer);
begin
  FSfx := Tipo;
  FSfxMuestra := 0;
end;

procedure TMezclador.PonerMusica(Numero: Integer);
begin
  if Numero <> FMusica then
  begin
    FMusica := Numero;
    FMusicaMuestra := 0;
  end;
end;

function OndaCuadrada(Fase: Single; Ciclo: Single): Single;
begin
  if Frac(Fase) < Ciclo then
    Result := 1
  else
    Result := -1;
end;

function MuestraEfecto(Tipo, Avance: Integer): Single;
var
  T, Frec, Amplitud: Single;
begin
  T := Avance / FRECUENCIA_MUESTREO;
  Result := 0;
  case Tipo of
    Ord(efSalto):
      begin
        Frec := 320 + 900 * T;
        Amplitud := 0.34 * (1 - T / 0.18);
        if T < 0.18 then
          Result := OndaCuadrada(T * Frec, 0.5) * Amplitud;
      end;
    Ord(efTuerca):
      begin
        if T < 0.06 then
          Frec := 988
        else
          Frec := 1319;
        Amplitud := 0.3 * (1 - T / 0.14);
        if T < 0.14 then
          Result := OndaCuadrada(T * Frec, 0.5) * Amplitud;
      end;
    Ord(efPisot):
      begin
        Frec := 260 - 900 * T;
        Amplitud := 0.36 * (1 - T / 0.11);
        if (T < 0.11) and (Frec > 40) then
          Result := OndaCuadrada(T * Frec, 0.25) * Amplitud;
      end;
    Ord(efEscudo):
      begin
        if T < 0.07 then
          Frec := 523
        else if T < 0.14 then
          Frec := 659
        else if T < 0.21 then
          Frec := 784
        else
          Frec := 1047;
        Amplitud := 0.3 * (1 - T / 0.3);
        if T < 0.3 then
          Result := OndaCuadrada(T * Frec, 0.5) * Amplitud;
      end;
    Ord(efMuerte):
      begin
        Frec := 520 * (1 - T / 0.9);
        Amplitud := 0.34 * (1 - T / 0.9);
        if (T < 0.9) and (Frec > 50) then
          Result := OndaCuadrada(T * Frec, 0.35) * Amplitud;
      end;
    Ord(efNivel):
      begin
        if T < 0.09 then
          Frec := 523
        else if T < 0.18 then
          Frec := 659
        else if T < 0.27 then
          Frec := 784
        else if T < 0.36 then
          Frec := 1047
        else
          Frec := 1319;
        Amplitud := 0.32 * (1 - T / 0.6);
        if T < 0.6 then
          Result := OndaCuadrada(T * Frec, 0.5) * Amplitud;
      end;
    Ord(efGolpe):
      begin
        Frec := 150;
        Amplitud := 0.32 * (1 - T / 0.08);
        if T < 0.08 then
          Result := OndaCuadrada(T * Frec, 0.15) * Amplitud;
      end;
  end;
end;

procedure TMezclador.Rellenar(Bloque: Integer);
var
  I, Indice: Integer;
  Total, Acumulado: Integer;
  Muestra, Melodia, Bajo, Sfx: Single;
  Nota: TNota;
  FrecuenciaNota: Single;
begin
  for I := 0 to MUESTRAS_BLOQUE - 1 do
  begin
    if FSilencio or (FMusica = 0) then
      Melodia := 0
    else
    begin
      { Se busca la nota activa recorriendo la melodia en bucle. }
      Total := 0;
      Indice := 0;
      Nota := NotaDeMusica(FMusica, 0);
      while Total + Nota.Duracion <= FMusicaMuestra do
      begin
        Inc(Total, Nota.Duracion);
        Inc(Indice);
        Nota := NotaDeMusica(FMusica, Indice);
      end;
      FrecuenciaNota := Frecuencia(Nota.Semitono);
      if FrecuenciaNota > 0 then
      begin
        Muestra := FMusicaMuestra - Total;
        Melodia := OndaCuadrada(Muestra * FrecuenciaNota / FRECUENCIA_MUESTREO, 0.4) * 0.14;
        { Envolvente suave al inicio de cada nota para que no chasquee. }
        if Muestra < 220 then
          Melodia := Melodia * (Muestra / 220);
        Bajo := OndaCuadrada(Muestra * (FrecuenciaNota / 2) / FRECUENCIA_MUESTREO, 0.5) * 0.07;
        Melodia := Melodia + Bajo;
      end
      else
        Melodia := 0;
      Inc(FMusicaMuestra);
    end;

    Sfx := MuestraEfecto(FSfx, FSfxMuestra);
    if FSfx <> 0 then
    begin
      Inc(FSfxMuestra);
      if FSfxMuestra > FRECUENCIA_MUESTREO * 2 then
      begin
        FSfx := 0;
        FSfxMuestra := 0;
      end;
    end;

    Muestra := Melodia + Sfx;
    if Muestra > 1 then
      Muestra := 1;
    if Muestra < -1 then
      Muestra := -1;
    Acumulado := Round(Muestra * 9000);
    FDatos[Bloque][I] := SmallInt(Acumulado);
  end;
  { Al terminar un bloque sin nota la melodia sigue avanzando. }
  if (FMusica = 0) or FSilencio then
    FMusicaMuestra := FMusicaMuestra + MUESTRAS_BLOQUE;
end;

constructor THiloAudio.Create(Mezclador: TMezclador);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FMezclador := Mezclador;
end;

procedure THiloAudio.Execute;
var
  I: Integer;
  Espera: Integer;
begin
  while not Terminated do
  begin
    if FMezclador.Abierto then
    begin
      for I := 0 to TOTAL_BLOQUES - 1 do
        if (FMezclador.FCabeceras[I].dwFlags and WHDR_DONE) <> 0 then
        begin
          FMezclador.Rellenar(I);
          FMezclador.FCabeceras[I].dwFlags := FMezclador.FCabeceras[I].dwFlags and not WHDR_DONE;
          waveOutWrite(FMezclador.FHandle, @FMezclador.FCabeceras[I], SizeOf(TWAVEHDR));
        end;
      Espera := 5;
    end
    else
      Espera := 50;
    Sleep(Espera);
  end;
end;

{ --------------------------- fachada --------------------------- }

constructor TSonido.Create;
begin
  inherited Create;
  FActivo := False;
  FSilencio := False;
end;

destructor TSonido.Destroy;
begin
  Detener;
  inherited Destroy;
end;

procedure TSonido.Detener;
begin
  if GHilo <> nil then
  begin
    GHilo.Terminate;
    GHilo.WaitFor;
    FreeAndNil(GHilo);
  end;
  if GMezclador <> nil then
  begin
    GMezclador.Cerrar;
    FreeAndNil(GMezclador);
  end;
  FActivo := False;
end;

procedure TSonido.Abrir;
begin
  if FActivo or FSilencio then
    Exit;
  GMezclador := TMezclador.Create;
  GMezclador.Abrir;
  if not GMezclador.Abierto then
  begin
    FreeAndNil(GMezclador);
    Exit;
  end;
  FActivo := True;
  GHilo := THiloAudio.Create(GMezclador);
  GHilo.Start;
end;

procedure TSonido.Silenciar;
begin
  FSilencio := True;
  if GMezclador <> nil then
    GMezclador.CambiarSilencio(True);
end;

procedure TSonido.Efecto(Tipo: TEfecto);
begin
  if not FActivo or (GMezclador = nil) then
    Exit;
  GMezclador.Sonar(Ord(Tipo));
end;

procedure TSonido.Musica(Numero: Integer);
begin
  if not FActivo or (GMezclador = nil) then
    Exit;
  GMezclador.PonerMusica(Numero);
end;

end.
