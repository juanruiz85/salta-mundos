unit GMVentana;
{ Ventana Win32 y presentacion del lienzo. El juego dibuja siempre sobre una
  imagen de 320x200 y esta unidad la estira a la ventana con un multiplo
  entero para que los pixeles queden nitidos. }

{$MODE DELPHI}
{$H+}

interface

uses
  Windows,
  Messages,
  SysUtils,
  GMCore,
  GMSuperficie;

type
  TPulsos = record
    Izquierda: Boolean;
    Derecha: Boolean;
    Arriba: Boolean;
    Abajo: Boolean;
    Salto: Boolean;
    Correr: Boolean;
    Enter: Boolean;
    Escape: Boolean;
    Pausa: Boolean;
  end;

  TVentana = class
  private
    FHandle: HWND;
    FDC: HDC;
    FMemDC: HDC;
    FBitmap: HBITMAP;
    FBitmapViejo: HGDIOBJ;
    FPixeles: PCardinal;
    FLienzo: TSuperficie;
    FEscala: Integer;
    FCerrada: Boolean;
    FFrecuencia: Int64;
    FUltimoTic: Int64;
    FVisible: Boolean;
    procedure CrearRecursos;
    procedure LiberarRecursos;
    function TikActual: Int64;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Abrir(const Titulo: string; Visible: Boolean = True);
    procedure Cerrar;
    function ProcesarMensajes: Boolean;
    procedure Presentar;
    procedure EsperarSiguienteFotograma;
    function LeerPulsos: TPulsos;
    procedure GuardarPantalla(const Archivo: string);
    property Lienzo: TSuperficie read FLienzo;
    property Escala: Integer read FEscala;
    property Handle: HWND read FHandle;
  end;

implementation

var
  GCerrarSolicitado: Boolean = False;
  GNombreClase: string = 'SaltaMundosVentana';
  GVentanaActiva: TVentana = nil;

function VentanaProc(Handle: HWND; Mensaje: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  Pintura: PAINTSTRUCT;
begin
  case Mensaje of
    WM_PAINT:
      begin
        { Al descubrir o restaurar la ventana hay que volver a pintar el
          ultimo fotograma, porque el dibujo no pasa por el sistema de
          repintado clasico. }
        BeginPaint(Handle, Pintura);
        if GVentanaActiva <> nil then
          GVentanaActiva.Presentar;
        EndPaint(Handle, Pintura);
        Result := 0;
      end;
    WM_CLOSE:
      begin
        GCerrarSolicitado := True;
        Result := 0;
      end;
    WM_DESTROY:
      begin
        GCerrarSolicitado := True;
        PostQuitMessage(0);
        Result := 0;
      end;
    WM_ERASEBKGND:
      Result := 1;
  else
    Result := DefWindowProcA(Handle, Mensaje, WParam, LParam);
  end;
end;

constructor TVentana.Create;
begin
  inherited Create;
  FLienzo := TSuperficie.Create(ANCHO_VIRTUAL, ALTO_VIRTUAL);
  FEscala := 2;
  FCerrada := False;
  FVisible := True;
end;

destructor TVentana.Destroy;
begin
  Cerrar;
  FLienzo.Free;
  inherited Destroy;
end;

function TVentana.TikActual: Int64;
begin
  QueryPerformanceCounter(Result);
end;

procedure TVentana.CrearRecursos;
var
  Info: BITMAPINFO;
begin
  FDC := GetDC(FHandle);
  FMemDC := CreateCompatibleDC(FDC);
  FillChar(Info, SizeOf(Info), 0);
  Info.bmiHeader.biSize := SizeOf(TBITMAPINFOHEADER);
  Info.bmiHeader.biWidth := ANCHO_VIRTUAL;
  Info.bmiHeader.biHeight := -ALTO_VIRTUAL;
  Info.bmiHeader.biPlanes := 1;
  Info.bmiHeader.biBitCount := 32;
  Info.bmiHeader.biCompression := BI_RGB;
  FPixeles := nil;
  FBitmap := CreateDIBSection(FMemDC, Info, DIB_RGB_COLORS, Pointer(FPixeles), 0, 0);
  FBitmapViejo := SelectObject(FMemDC, FBitmap);

  { El lienzo debe escribir directamente sobre la memoria del DIB; si no, el
    juego dibujaria en un buffer aparte y la ventana quedaria en negro. }
  FLienzo.Free;
  FLienzo := TSuperficie.CreateDesdeMemoria(ANCHO_VIRTUAL, ALTO_VIRTUAL, FPixeles);
  FLienzo.Limpiar(RGBc(0, 0, 0));
end;

procedure TVentana.LiberarRecursos;
begin
  if FMemDC <> 0 then
  begin
    if FBitmapViejo <> 0 then
      SelectObject(FMemDC, FBitmapViejo);
    if FBitmap <> 0 then
      DeleteObject(FBitmap);
    DeleteDC(FMemDC);
    FMemDC := 0;
    FBitmap := 0;
    FBitmapViejo := 0;
  end;
  if FDC <> 0 then
  begin
    ReleaseDC(FHandle, FDC);
    FDC := 0;
  end;
end;

procedure TVentana.Abrir(const Titulo: string; Visible: Boolean);
var
  Clase: WNDCLASSA;
  Estilo: DWORD;
  Rectangulo: TRect;
  AnchoVentana, AltoVentana: Integer;
  PantallaAncho, PantallaAlto: Integer;
  NombreClase: PAnsiChar;
  NombreVentana: PAnsiChar;
begin
  FVisible := Visible;
  PantallaAncho := GetSystemMetrics(SM_CXSCREEN);
  PantallaAlto := GetSystemMetrics(SM_CYSCREEN);
  FEscala := Limitar((PantallaAncho - 120) div ANCHO_VIRTUAL, 2, 4);
  if (PantallaAlto - 160) div ALTO_VIRTUAL < FEscala then
    FEscala := Limitar((PantallaAlto - 160) div ALTO_VIRTUAL, 1, 4);
  if FEscala < 1 then
    FEscala := 1;

  FillChar(Clase, SizeOf(Clase), 0);
  Clase.style := CS_HREDRAW or CS_VREDRAW or CS_OWNDC;
  Clase.lpfnWndProc := @VentanaProc;
  Clase.hInstance := GetModuleHandleA(nil);
  Clase.hCursor := LoadCursorA(0, IDC_ARROW);
  Clase.hbrBackground := GetStockObject(BLACK_BRUSH);
  { Se trabaja con las funciones ANSI del API para no depender de conversiones
    temporales de cadena al crear la ventana. }
  NombreClase := PAnsiChar(GNombreClase);
  Clase.lpszClassName := NombreClase;
  RegisterClassA(Clase);

  Estilo := WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX;
  Rectangulo.Left := 0;
  Rectangulo.Top := 0;
  Rectangulo.Right := ANCHO_VIRTUAL * FEscala;
  Rectangulo.Bottom := ALTO_VIRTUAL * FEscala;
  AdjustWindowRectEx(Rectangulo, Estilo, False, 0);
  AnchoVentana := Rectangulo.Right - Rectangulo.Left;
  AltoVentana := Rectangulo.Bottom - Rectangulo.Top;

  NombreVentana := PAnsiChar(Titulo);
  FHandle := CreateWindowExA(0, NombreClase, NombreVentana, Estilo,
    (PantallaAncho - AnchoVentana) div 2, (PantallaAlto - AltoVentana) div 2,
    AnchoVentana, AltoVentana, 0, 0, GetModuleHandleA(nil), nil);

  CrearRecursos;
  if FVisible then
  begin
    ShowWindow(FHandle, SW_SHOW);
    UpdateWindow(FHandle);
  end;
  SetStretchBltMode(FDC, COLORONCOLOR);
  GVentanaActiva := Self;
  QueryPerformanceFrequency(FFrecuencia);
  FUltimoTic := TikActual;
  GCerrarSolicitado := False;
end;

procedure TVentana.Cerrar;
begin
  if FCerrada then
    Exit;
  FCerrada := True;
  if GVentanaActiva = Self then
    GVentanaActiva := nil;
  LiberarRecursos;
  if FHandle <> 0 then
  begin
    DestroyWindow(FHandle);
    FHandle := 0;
  end;
end;

function TVentana.ProcesarMensajes: Boolean;
var
  Mensaje: TMsg;
begin
  while PeekMessageA(Mensaje, 0, 0, 0, PM_REMOVE) do
  begin
    if Mensaje.message = WM_QUIT then
    begin
      Result := False;
      Exit;
    end;
    TranslateMessage(Mensaje);
    DispatchMessageA(Mensaje);
  end;
  Result := not GCerrarSolicitado;
end;

procedure TVentana.Presentar;
begin
  if (FDC = 0) or (FMemDC = 0) then
    Exit;
  SetStretchBltMode(FDC, COLORONCOLOR);
  StretchBlt(FDC, 0, 0, ANCHO_VIRTUAL * FEscala, ALTO_VIRTUAL * FEscala,
    FMemDC, 0, 0, ANCHO_VIRTUAL, ALTO_VIRTUAL, SRCCOPY);
end;

procedure TVentana.EsperarSiguienteFotograma;
var
  Objetivo, Ahora, Espera: Int64;
begin
  if FFrecuencia = 0 then
  begin
    Sleep(MS_FOTOGRAMA);
    Exit;
  end;
  Objetivo := FUltimoTic + (FFrecuencia * MS_FOTOGRAMA) div 1000;
  repeat
    Ahora := TikActual;
    Espera := (Objetivo - Ahora) * 1000 div FFrecuencia;
    if Espera > 0 then
      Sleep(Limitar(Espera, 1, MS_FOTOGRAMA))
    else
      Break;
  until False;
  FUltimoTic := Objetivo;
  { Si el sistema se atraso demasiado, se reinicia la referencia. }
  if (TikActual - FUltimoTic) * 1000 div FFrecuencia > 200 then
    FUltimoTic := TikActual;
end;

function TVentana.LeerPulsos: TPulsos;

  function Activa(Tecla: Integer): Boolean;
  begin
    Result := (GetAsyncKeyState(Tecla) and $8000) <> 0;
  end;

var
  ActivaVentana: Boolean;
begin
  FillChar(Result, SizeOf(Result), 0);
  ActivaVentana := GetForegroundWindow = FHandle;
  if not ActivaVentana then
    Exit;
  Result.Izquierda := Activa(VK_LEFT) or Activa(Ord('A'));
  Result.Derecha := Activa(VK_RIGHT) or Activa(Ord('D'));
  Result.Arriba := Activa(VK_UP) or Activa(Ord('W'));
  Result.Abajo := Activa(VK_DOWN) or Activa(Ord('S'));
  Result.Salto := Activa(VK_SPACE) or Activa(VK_UP) or Activa(Ord('W')) or Activa(Ord('Z'));
  Result.Correr := Activa(VK_SHIFT) or Activa(Ord('X'));
  Result.Enter := Activa(VK_RETURN) or Activa(VK_SPACE);
  Result.Escape := Activa(VK_ESCAPE);
  Result.Pausa := Activa(Ord('P'));
end;

procedure TVentana.GuardarPantalla(const Archivo: string);
begin
  FLienzo.GuardarBMP(Archivo);
end;

end.
