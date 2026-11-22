unit GMActualizacion;
{ Comprobacion de version nueva en GitHub. La consulta se hace en un hilo
  aparte con WinInet para no congelar el juego, y el resultado se guarda en
  un estado que el menu consulta cada fotograma.

  Si no hay red, el certificado falla o la cuenta no responde, el estado queda
  en error y el juego sigue funcionando con normalidad. }

{$MODE DELPHI}
{$H+}

interface

uses
  Windows,
  SysUtils,
  Classes,
  SyncObjs;

type
  TEstadoActualizacion = (acSinComprobar, acConsultando, acAlDia, acDisponible, acError);

  TComprobadorActualizaciones = class
  private
    FCerrojo: TCriticalSection;
    FEstado: TEstadoActualizacion;
    FEtiqueta: string;
    FVersionLocal: string;
    FHilo: TThread;
    procedure FijarResultado(NuevoEstado: TEstadoActualizacion; const Etiqueta: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Consultar;
    function Estado: TEstadoActualizacion;
    function Etiqueta: string;
    function TextoEstado: string;
    function HayVersionNueva: Boolean;
    { Version contra la que se compara; por omision la del ejecutable. }
    property VersionLocal: string read FVersionLocal write FVersionLocal;
  end;

const
  URL_ULTIMA_VERSION = 'https://api.github.com/repos/juanruiz85/salta-mundos/releases/latest';

implementation

uses
  StrUtils,
  GMCore;

const
  INTERNET_OPEN_TYPE_PRECONFIG = 0;
  INTERNET_FLAG_RELOAD = $80000000;
  INTERNET_OPTION_CONNECT_TIMEOUT = 2;
  INTERNET_OPTION_RECEIVE_TIMEOUT = 6;

type
  HINTERNET = Pointer;

function InternetOpenA(lpszAgent: PAnsiChar; dwAccessType: DWORD;
  lpszProxy, lpszProxyBypass: PAnsiChar; dwFlags: DWORD): HINTERNET;
  stdcall; external 'wininet.dll' name 'InternetOpenA';
function InternetOpenUrlA(hInternet: HINTERNET; lpszUrl: PAnsiChar;
  lpszHeaders: PAnsiChar; dwHeadersLength: DWORD; dwFlags: DWORD;
  dwContext: DWORD_PTR): HINTERNET; stdcall; external 'wininet.dll' name 'InternetOpenUrlA';
function InternetReadFile(hFile: HINTERNET; lpBuffer: Pointer;
  dwNumberOfBytesToRead: DWORD; var lpdwNumberOfBytesRead: DWORD): BOOL;
  stdcall; external 'wininet.dll' name 'InternetReadFile';
function InternetCloseHandle(hInternet: HINTERNET): BOOL;
  stdcall; external 'wininet.dll' name 'InternetCloseHandle';
function InternetSetOptionA(hInternet: HINTERNET; dwOption: DWORD;
  lpBuffer: Pointer; dwBufferLength: DWORD): BOOL;
  stdcall; external 'wininet.dll' name 'InternetSetOptionA';

function DescargarTexto(const Url: string; out Texto: string): Boolean;
var
  Sesion, Peticion: HINTERNET;
  Tiempo: DWORD;
  Buffer: array[0..2047] of AnsiChar;
  Leidos: DWORD;
  Cabeceras: AnsiString;
begin
  Result := False;
  Texto := '';
  Sesion := InternetOpenA('SaltaMundos', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Sesion = nil then
    Exit;
  try
    Tiempo := 2500;
    InternetSetOptionA(Sesion, INTERNET_OPTION_CONNECT_TIMEOUT, @Tiempo, SizeOf(Tiempo));
    Tiempo := 4000;
    InternetSetOptionA(Sesion, INTERNET_OPTION_RECEIVE_TIMEOUT, @Tiempo, SizeOf(Tiempo));
    { GitHub exige identificar al cliente. }
    Cabeceras := 'User-Agent: SaltaMundos' + #13#10 +
      'Accept: application/vnd.github+json' + #13#10;
    Peticion := InternetOpenUrlA(Sesion, PAnsiChar(AnsiString(Url)),
      PAnsiChar(Cabeceras), Length(Cabeceras), INTERNET_FLAG_RELOAD, 0);
    if Peticion = nil then
      Exit;
    try
      repeat
        Leidos := 0;
        if not InternetReadFile(Peticion, @Buffer[0], SizeOf(Buffer), Leidos) then
          Exit;
        if Leidos > 0 then
        begin
          Buffer[Leidos] := #0;
          Texto := Texto + string(PAnsiChar(@Buffer[0]));
        end;
      until Leidos = 0;
      Result := Texto <> '';
    finally
      InternetCloseHandle(Peticion);
    end;
  finally
    InternetCloseHandle(Sesion);
  end;
end;

function CompararVersiones(const A, B: string): Integer;
var
  ValorA, ValorB: array[0..3] of Integer;
  I, Numero, Posicion: Integer;
  Cadena: string;

  procedure Leer(const Texto: string; var Destino: array of Integer);
  var
    J, K, Acumulado: Integer;
    Actual: string;
  begin
    for J := Low(Destino) to High(Destino) do
      Destino[J] := 0;
    K := Low(Destino);
    Actual := '';
    for J := 1 to Length(Texto) + 1 do
    begin
      if (J <= Length(Texto)) and (Texto[J] >= '0') and (Texto[J] <= '9') then
        Actual := Actual + Texto[J]
      else
      begin
        if Actual <> '' then
        begin
          Acumulado := StrToIntDef(Actual, 0);
          if K <= High(Destino) then
            Destino[K] := Acumulado;
          Inc(K);
          Actual := '';
        end
        else if (J <= Length(Texto)) and (Texto[J] = '.') then
        begin
          if K <= High(Destino) then
            Destino[K] := 0;
          Inc(K);
        end;
      end;
    end;
  end;

begin
  Leer(A, ValorA);
  Leer(B, ValorB);
  Result := 0;
  for I := Low(ValorA) to High(ValorA) do
  begin
    if ValorA[I] > ValorB[I] then
    begin
      Result := 1;
      Exit;
    end;
    if ValorA[I] < ValorB[I] then
    begin
      Result := -1;
      Exit;
    end;
  end;
end;

function ExtraerEtiqueta(const Json: string): string;
var
  Inicio, Fin: Integer;
  Marca: string;
begin
  Result := '';
  Marca := '"tag_name"';
  Inicio := Pos(Marca, Json);
  if Inicio = 0 then
    Exit;
  Inicio := PosEx('"', Json, Inicio + Length(Marca));
  if Inicio = 0 then
    Exit;
  Fin := PosEx('"', Json, Inicio + 1);
  if Fin = 0 then
    Exit;
  Result := Copy(Json, Inicio + 1, Fin - Inicio - 1);
end;

type
  THiloConsulta = class(TThread)
  private
    FDuenio: TComprobadorActualizaciones;
  protected
    procedure Execute; override;
  public
    constructor Create(Duenio: TComprobadorActualizaciones);
  end;

constructor THiloConsulta.Create(Duenio: TComprobadorActualizaciones);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FDuenio := Duenio;
end;

procedure THiloConsulta.Execute;
var
  Texto, Etiqueta, Remota: string;
begin
  if not DescargarTexto(URL_ULTIMA_VERSION, Texto) then
  begin
    FDuenio.FijarResultado(acError, '');
    Exit;
  end;
  Etiqueta := ExtraerEtiqueta(Texto);
  if Etiqueta = '' then
  begin
    FDuenio.FijarResultado(acError, '');
    Exit;
  end;
  Remota := Etiqueta;
  if (Remota <> '') and (Remota[1] = 'v') then
    Delete(Remota, 1, 1);
  { Solo se avisa cuando la version publicada es realmente mas nueva. }
  if CompararVersiones(Remota, FDuenio.VersionLocal) > 0 then
    FDuenio.FijarResultado(acDisponible, Etiqueta)
  else
    FDuenio.FijarResultado(acAlDia, Etiqueta);
end;

constructor TComprobadorActualizaciones.Create;
begin
  inherited Create;
  FCerrojo := TCriticalSection.Create;
  FEstado := acSinComprobar;
  FEtiqueta := '';
  FVersionLocal := VERSION_JUEGO;
  FHilo := nil;
end;

destructor TComprobadorActualizaciones.Destroy;
begin
  if FHilo <> nil then
  begin
    FHilo.Terminate;
    FHilo.WaitFor;
    FHilo.Free;
    FHilo := nil;
  end;
  FCerrojo.Free;
  inherited Destroy;
end;

procedure TComprobadorActualizaciones.FijarResultado(NuevoEstado: TEstadoActualizacion;
  const Etiqueta: string);
begin
  FCerrojo.Enter;
  try
    FEtiqueta := Etiqueta;
    FEstado := NuevoEstado;
  finally
    FCerrojo.Leave;
  end;
end;

procedure TComprobadorActualizaciones.Consultar;
begin
  if FEstado = acConsultando then
    Exit;
  if FHilo <> nil then
  begin
    FHilo.WaitFor;
    FreeAndNil(FHilo);
  end;
  FijarResultado(acConsultando, '');
  FHilo := THiloConsulta.Create(Self);
  FHilo.Start;
end;

function TComprobadorActualizaciones.Estado: TEstadoActualizacion;
begin
  FCerrojo.Enter;
  try
    Result := FEstado;
  finally
    FCerrojo.Leave;
  end;
end;

function TComprobadorActualizaciones.Etiqueta: string;
begin
  FCerrojo.Enter;
  try
    Result := FEtiqueta;
  finally
    FCerrojo.Leave;
  end;
end;

function TComprobadorActualizaciones.HayVersionNueva: Boolean;
begin
  Result := Estado = acDisponible;
end;

function TComprobadorActualizaciones.TextoEstado: string;
begin
  case Estado of
    acConsultando: Result := 'BUSCANDO ACTUALIZACIONES...';
    acAlDia: Result := 'TIENES LA ULTIMA VERSION';
    acDisponible: Result := 'VERSION NUEVA DISPONIBLE: ' + Etiqueta;
    acError: Result := 'NO SE PUDO CONSULTAR GITHUB';
  else
    Result := 'PULSA R PARA BUSCAR ACTUALIZACIONES';
  end;
end;

end.
