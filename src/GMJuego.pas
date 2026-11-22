unit GMJuego;
{ Motor del juego: estados de pantalla, fisica del heroe, enemigos, colisiones
  con el mapa, camara, marcador y dibujo de todas las capas. }

{$MODE DELPHI}
{$H+}

interface

uses
  SysUtils,
  Classes,
  Contnrs,
  Math,
  GMCore,
  GMSuperficie,
  GMSprites,
  GMNiveles,
  GMSonido,
  GMVentana;

type
  TEstadoJuego = (ejTitulo, ejJugando, ejPausa, ejMuere, ejFinNivel, ejGameOver, ejVictoria);
  TTipoEntidad = (teBicho, tePua, teMosca, teTuerca, teEscudo);

const
  GRAVEDAD = 0.42;
  GRAVEDAD_SALTO = 0.34;
  IMPULSO_SALTO = -6.7;
  VEL_ANDAR = 1.7;
  VEL_CORRER = 2.7;
  ACELERACION = 0.17;
  ROCE = 0.24;
  VEL_CAIDA_MAX = 8.2;
  HEROE_ANCHO = 12;
  HEROE_ALTO = 15;
  MARGEN_META = 26;

type
  TEntidad = class
  public
    Tipo: TTipoEntidad;
    X, Y, VX, VY: Single;
    Ancho, Alto: Integer;
    Viva: Boolean;
    EnSuelo: Boolean;
    MirandoIzq: Boolean;
    Fase: Single;
    OrigenY: Single;
    Vida: Integer;
    constructor Create(ATipo: TTipoEntidad; AX, AY: Single);
    destructor Destroy; override;
  end;

  TParticula = class
  public
    X, Y, VX, VY: Single;
    Vida: Integer;
    Color: TColor32;
    Tamano: Integer;
  end;

  TBote = record
    Columna: Integer;
    Fila: Integer;
    Tiempo: Single;
  end;

  TJuego = class
  private
    FVentana: TVentana;
    FSonido: TSonido;
    FLienzo: TSuperficie;
    FLienzoPropio: Boolean;

    FHeroe: TSpritesHeroe;
    FEnemigos: TSpritesEnemigos;
    FObjetos: TSpritesObjetos;
    FTiles: TTiles;

    FNivel: TNivel;
    FNivelActual: Integer;
    FMapa: array of string;
    FAnchoMapa: Integer;

    FEstado: TEstadoJuego;
    FEntidades: TObjectList;
    FParticulas: TObjectList;
    FBotes: array of TBote;

    FHeroeX, FHeroeY, FHeroeVX, FHeroeVY: Single;
    FHeroeEnSuelo: Boolean;
    FHeroeMirandoIzq: Boolean;
    FHeroeReforzado: Boolean;
    FHeroeInvulnerable: Integer;
    FHeroeAnim: Single;
    FCoyote: Integer;
    FBufferSalto: Integer;
    FMuerto: Boolean;

    FPuntos: Integer;
    FTuercas: Integer;
    FVidas: Integer;
    FTiempo: Integer;
    FTiempoAcum: Integer;
    FCamaraX: Single;
    FFotograma: Integer;
    FTiempoEstado: Integer;
    FCajasGolpeadas: Integer;
    FAperturaPuerta: Single;

    FTeclas: TPulsos;
    FTeclasAntes: TPulsos;
    FSimulacion: Boolean;
    FTeclasSimuladas: TPulsos;
    FBotActivo: Boolean;
    FBotSalto: Integer;
    FMortalInactivo: Boolean;

    procedure LeerTeclas;
    function Pulsada(Tecla: Char): Boolean;
    function RecienPulsada(Tecla: Char): Boolean;

    procedure CargarNivel(Numero: Integer);
    procedure IniciarPartida;
    procedure ReiniciarNivel;
    procedure SembrarEntidades;
    procedure LimpiarEntidades;

    function TileEn(Columna, Fila: Integer): Char;
    procedure PonerTile(Columna, Fila: Integer; C: Char);
    function SolidoEn(Columna, Fila: Integer): Boolean;
    function HaySolido(const R: TRectI): Boolean;
    function RectHeroe: TRectI;

    procedure DesplazarX(var X: Single; DX: Single; Ancho, Alto, Y: Integer;
      var Choque: Boolean); overload;
    procedure DesplazarX(var X: Single; DX: Single; const R: TRectI;
      var Choque: Boolean); overload;
    procedure DesplazarY(var Y: Single; DY: Single; Ancho, Alto, X: Integer;
      var Choque, EnSuelo: Boolean); overload;
    procedure DesplazarY(var Y: Single; DY: Single; const R: TRectI;
      var Choque, EnSuelo: Boolean); overload;

    procedure ActualizarHeroe;
    procedure ActualizarEntidades;
    procedure ActualizarParticulas;
    procedure GolpearBloque(Columna, Fila: Integer);
    procedure GolpearCaja(Columna, Fila: Integer);
    procedure RecogerTuercas;
    procedure AgregarBote(Columna, Fila: Integer);
    procedure DispararParticulas(X, Y: Integer; Color: TColor32; Cantidad: Integer);
    procedure SumarPuntos(Cantidad: Integer);
    procedure SumarTuerca;
    procedure HerirHeroe(DesdeX: Single);
    procedure MatarHeroe;
    procedure TerminarNivel;
    procedure AvanzarNivel;
    procedure EsparcirEscudo(X, Y: Integer);

    procedure ActualizarTitulo;
    procedure ActualizarJugando;
    procedure ActualizarMuerte;
    procedure ActualizarFinNivel;
    procedure ActualizarMensajeFinal;

    procedure Dibujar;
    procedure DibujarFondo;
    procedure DibujarTiles;
    procedure DibujarEntidades;
    procedure DibujarHeroe;
    procedure DibujarParticulas;
    procedure DibujarHud;
    procedure DibujarIconoTuerca(X, Y: Integer);
    procedure DibujarTitulo;
    procedure DibujarPausa;
    procedure DibujarGameOver;
    procedure DibujarVictoria;
    procedure DibujarFinNivel;
    procedure DibujarBanner(const Titulo, Linea1, Linea2: string; Color: TColor32);
    procedure DibujarColina(Desplazamiento: Single; Color: TColor32; Altura, Base: Integer);
    procedure DibujarNubes(Desplazamiento: Single);
    procedure DibujarEstrellas;
    procedure DibujarAstro;
    procedure DibujarCirculo(CX, CY, Radio: Integer; Color: TColor32);
    procedure DibujarPuerta(Pantalla: TSuperficie; X, Y: Integer);
    function RectPuerta(Columna, Fila: Integer): TRectI;
    procedure DibujarSpriteEntidad(E: TEntidad);
    function SpriteBicho(E: TEntidad): TSuperficie;
    function SpritePua(E: TEntidad): TSuperficie;
    function SpriteMosca(E: TEntidad): TSuperficie;

  public
    constructor Create(Ventana: TVentana; Sonido: TSonido);
    destructor Destroy; override;
    procedure Ejecutar;
    procedure Capturar(const Carpeta: string);
    procedure GuardarMapas(const Carpeta: string);
    function AutoPrueba: Boolean;
    procedure PulsosDelBot(var P: TPulsos);
    procedure Actualizar;
    procedure DibujarCuadro;
    procedure EmpezarEnNivel(Numero: Integer);
    procedure DarPulsos(const P: TPulsos);
    property Estado: TEstadoJuego read FEstado;
    property Puntos: Integer read FPuntos;
    property Tuercas: Integer read FTuercas;
  end;

implementation

{ ----------------------------- entidades ----------------------------- }

constructor TEntidad.Create(ATipo: TTipoEntidad; AX, AY: Single);
begin
  inherited Create;
  Tipo := ATipo;
  X := AX;
  Y := AY;
  OrigenY := AY;
  VX := 0;
  VY := 0;
  Viva := True;
  EnSuelo := False;
  MirandoIzq := True;
  Fase := 0;
  Vida := 0;
  case ATipo of
    teBicho:
      begin
        Ancho := 14;
        Alto := 12;
        VX := -0.55;
      end;
    tePua:
      begin
        Ancho := 14;
        Alto := 14;
        VX := -0.85;
      end;
    teMosca:
      begin
        Ancho := 12;
        Alto := 10;
        VX := -0.5;
      end;
    teTuerca:
      begin
        Ancho := 12;
        Alto := 12;
        VY := -3.2;
        Viva := False;
      end;
    teEscudo:
      begin
        Ancho := 12;
        Alto := 14;
        VY := -2.2;
        Viva := True;
      end;
  end;
end;

destructor TEntidad.Destroy;
begin
  inherited Destroy;
end;

{ ----------------------------- construccion ----------------------------- }

constructor TJuego.Create(Ventana: TVentana; Sonido: TSonido);
begin
  inherited Create;
  FVentana := Ventana;
  FSonido := Sonido;
  if Ventana <> nil then
  begin
    FLienzo := Ventana.Lienzo;
    FLienzoPropio := False;
  end
  else
  begin
    FLienzo := TSuperficie.Create(ANCHO_VIRTUAL, ALTO_VIRTUAL);
    FLienzoPropio := True;
  end;
  FHeroe := TSpritesHeroe.Create;
  FEnemigos := TSpritesEnemigos.Create;
  FObjetos := TSpritesObjetos.Create;
  FEntidades := TObjectList.Create(True);
  FParticulas := TObjectList.Create(True);
  FEstado := ejTitulo;
  FNivelActual := 1;
  FVidas := 3;
  FPuntos := 0;
  FTuercas := 0;
  FFotograma := 0;
  FMuerto := False;
  FSimulacion := False;
  FBotActivo := False;
  FBotSalto := 0;
  FMortalInactivo := False;
  FTeclasSimuladas := Default(TPulsos);
  FTiempo := 300;
  FillChar(FTeclas, SizeOf(FTeclas), 0);
  FillChar(FTeclasAntes, SizeOf(FTeclasAntes), 0);
  Randomize;
end;

destructor TJuego.Destroy;
begin
  LimpiarEntidades;
  FEntidades.Free;
  FParticulas.Free;
  FHeroe.Free;
  FEnemigos.Free;
  FObjetos.Free;
  FTiles.Free;
  FNivel.Free;
  if FLienzoPropio then
    FLienzo.Free;
  inherited Destroy;
end;

{ ----------------------------- teclado ----------------------------- }

procedure TJuego.LeerTeclas;
begin
  FTeclasAntes := FTeclas;
  if FSimulacion then
    FTeclas := FTeclasSimuladas
  else if FVentana <> nil then
    FTeclas := FVentana.LeerPulsos;
end;

function TJuego.Pulsada(Tecla: Char): Boolean;
begin
  case Tecla of
    'I': Result := FTeclas.Izquierda;
    'D': Result := FTeclas.Derecha;
    'A': Result := FTeclas.Arriba;
    'B': Result := FTeclas.Abajo;
    'S': Result := FTeclas.Salto;
    'C': Result := FTeclas.Correr;
    'E': Result := FTeclas.Enter;
    'X': Result := FTeclas.Escape;
    'P': Result := FTeclas.Pausa;
  else
    Result := False;
  end;
end;

function TJuego.RecienPulsada(Tecla: Char): Boolean;
var
  Antes: Boolean;
begin
  case Tecla of
    'I': Antes := FTeclasAntes.Izquierda;
    'D': Antes := FTeclasAntes.Derecha;
    'A': Antes := FTeclasAntes.Arriba;
    'B': Antes := FTeclasAntes.Abajo;
    'S': Antes := FTeclasAntes.Salto;
    'C': Antes := FTeclasAntes.Correr;
    'E': Antes := FTeclasAntes.Enter;
    'X': Antes := FTeclasAntes.Escape;
    'P': Antes := FTeclasAntes.Pausa;
  else
    Antes := False;
  end;
  Result := Pulsada(Tecla) and not Antes;
end;

procedure TJuego.DarPulsos(const P: TPulsos);
begin
  FSimulacion := True;
  FTeclasSimuladas := P;
end;

{ ----------------------------- mapa ----------------------------- }

function TJuego.TileEn(Columna, Fila: Integer): Char;
begin
  if (Columna < 0) or (Columna >= FAnchoMapa) then
  begin
    Result := ' ';
    Exit;
  end;
  if Fila < 0 then
  begin
    Result := ' ';
    Exit;
  end;
  if Fila >= FILAS_NIVEL then
  begin
    Result := '=';
    Exit;
  end;
  Result := FMapa[Fila][Columna + 1];
end;

procedure TJuego.PonerTile(Columna, Fila: Integer; C: Char);
var
  Cadena: string;
begin
  if (Columna < 0) or (Columna >= FAnchoMapa) or (Fila < 0) or (Fila >= FILAS_NIVEL) then
    Exit;
  Cadena := FMapa[Fila];
  Cadena[Columna + 1] := C;
  FMapa[Fila] := Cadena;
end;

function TJuego.SolidoEn(Columna, Fila: Integer): Boolean;
begin
  if (Columna < 0) or (Columna >= FAnchoMapa) then
    Result := True
  else if Fila < 0 then
    Result := False
  else if Fila >= FILAS_NIVEL then
    Result := True
  else
    Result := EsSolido(TileEn(Columna, Fila));
end;

function TJuego.HaySolido(const R: TRectI): Boolean;
var
  C, F, C1, C2, F1, F2: Integer;
begin
  C1 := Floor(R.X / TAM_TILE);
  C2 := Floor((R.X + R.Ancho - 1) / TAM_TILE);
  F1 := Floor(R.Y / TAM_TILE);
  F2 := Floor((R.Y + R.Alto - 1) / TAM_TILE);
  for F := F1 to F2 do
    for C := C1 to C2 do
      if SolidoEn(C, F) then
      begin
        Result := True;
        Exit;
      end;
  Result := False;
end;

function TJuego.RectHeroe: TRectI;
begin
  Result := RectI(Round(FHeroeX), Round(FHeroeY), HEROE_ANCHO, HEROE_ALTO);
end;

procedure TJuego.DesplazarX(var X: Single; DX: Single; Ancho, Alto, Y: Integer;
  var Choque: Boolean);
var
  I, Signo, Pasos: Integer;
begin
  Choque := False;
  if DX = 0 then
    Exit;
  Signo := Firmar(DX);
  Pasos := Ceil(Abs(DX));
  for I := 1 to Pasos do
  begin
    X := X + Signo;
    if HaySolido(RectI(Round(X), Y, Ancho, Alto)) then
    begin
      X := X - Signo;
      Choque := True;
      Exit;
    end;
  end;
end;

procedure TJuego.DesplazarX(var X: Single; DX: Single; const R: TRectI;
  var Choque: Boolean);
begin
  DesplazarX(X, DX, R.Ancho, R.Alto, R.Y, Choque);
end;

procedure TJuego.DesplazarY(var Y: Single; DY: Single; Ancho, Alto, X: Integer;
  var Choque, EnSuelo: Boolean);
var
  I, Signo, Pasos: Integer;
begin
  Choque := False;
  EnSuelo := False;
  if DY = 0 then
    Exit;
  Signo := Firmar(DY);
  Pasos := Ceil(Abs(DY));
  for I := 1 to Pasos do
  begin
    Y := Y + Signo;
    if HaySolido(RectI(X, Round(Y), Ancho, Alto)) then
    begin
      Y := Y - Signo;
      Choque := True;
      if Signo > 0 then
        EnSuelo := True;
      Exit;
    end;
  end;
end;

procedure TJuego.DesplazarY(var Y: Single; DY: Single; const R: TRectI;
  var Choque, EnSuelo: Boolean);
begin
  DesplazarY(Y, DY, R.Ancho, R.Alto, R.X, Choque, EnSuelo);
end;

{ ----------------------------- niveles ----------------------------- }

procedure TJuego.LimpiarEntidades;
begin
  FEntidades.Clear;
  FParticulas.Clear;
  SetLength(FBotes, 0);
end;

procedure TJuego.CargarNivel(Numero: Integer);
var
  Fila, Columna: Integer;
  Cadena: string;
  Tema: TTema;
begin
  FNivelActual := Limitar(Numero, 1, TOTAL_NIVELES);
  FreeAndNil(FNivel);
  FNivel := CrearNivel(FNivelActual);
  Tema := FNivel.Tema;
  FAnchoMapa := FNivel.Ancho;
  SetLength(FMapa, FILAS_NIVEL);
  for Fila := 0 to FILAS_NIVEL - 1 do
  begin
    Cadena := FNivel.Filas[Fila];
    while Length(Cadena) < FAnchoMapa do
      Cadena := Cadena + ' ';
    FMapa[Fila] := Copy(Cadena, 1, FAnchoMapa);
  end;

  FreeAndNil(FTiles);
  FTiles := ConstruirTiles(Tema.Tierra, Tema.TierraClara, Tema.Ladrillo,
    Tema.LadrilloJunta, Tema.Columna, Tema.ColumnaClara);
  LimpiarEntidades;
  SembrarEntidades;

  { La posicion inicial se marca con una M en el mapa. }
  FHeroeX := 48;
  FHeroeY := 8 * TAM_TILE;
  for Fila := 0 to FILAS_NIVEL - 1 do
    for Columna := 0 to FAnchoMapa - 1 do
      if FMapa[Fila][Columna + 1] = 'M' then
      begin
        FHeroeX := Columna * TAM_TILE + 2;
        FHeroeY := Fila * TAM_TILE + (TAM_TILE - HEROE_ALTO);
        PonerTile(Columna, Fila, ' ');
      end;

  FHeroeVX := 0;
  FHeroeVY := 0;
  FHeroeEnSuelo := False;
  FHeroeMirandoIzq := False;
  FHeroeReforzado := False;
  FHeroeInvulnerable := 0;
  FHeroeAnim := 0;
  FCoyote := 0;
  FBufferSalto := 0;
  FMuerto := False;
  FTiempo := 300;
  FTiempoAcum := 0;
  FCajasGolpeadas := 0;
  FCamaraX := LimitarF(FHeroeX - 112, 0, Max(0, FAnchoMapa * TAM_TILE - ANCHO_VIRTUAL));
  FAperturaPuerta := 0;
  FTiempoEstado := 0;
end;

procedure TJuego.SembrarEntidades;
var
  Fila, Columna: Integer;
  Caracter: Char;
  E: TEntidad;
begin
  for Fila := 0 to FILAS_NIVEL - 1 do
    for Columna := 0 to FAnchoMapa - 1 do
    begin
      Caracter := FMapa[Fila][Columna + 1];
      case Caracter of
        'g':
          begin
            E := TEntidad.Create(teBicho, Columna * TAM_TILE + 1,
              Fila * TAM_TILE + 4);
            FEntidades.Add(E);
            PonerTile(Columna, Fila, ' ');
          end;
        's':
          begin
            E := TEntidad.Create(tePua, Columna * TAM_TILE + 1,
              Fila * TAM_TILE + 2);
            FEntidades.Add(E);
            PonerTile(Columna, Fila, ' ');
          end;
        'f':
          begin
            E := TEntidad.Create(teMosca, Columna * TAM_TILE + 2,
              Fila * TAM_TILE + 3);
            FEntidades.Add(E);
            PonerTile(Columna, Fila, ' ');
          end;
      end;
    end;
end;

procedure TJuego.IniciarPartida;
begin
  FPuntos := 0;
  FTuercas := 0;
  FVidas := 3;
  CargarNivel(1);
  FEstado := ejJugando;
  if FSonido <> nil then
    FSonido.Musica(1);
end;

procedure TJuego.ReiniciarNivel;
begin
  CargarNivel(FNivelActual);
  FEstado := ejJugando;
end;

{ ----------------------------- juego ----------------------------- }

procedure TJuego.SumarPuntos(Cantidad: Integer);
begin
  FPuntos := FPuntos + Cantidad;
  if FPuntos > 999999 then
    FPuntos := 999999;
end;

procedure TJuego.SumarTuerca;
begin
  Inc(FTuercas);
  SumarPuntos(20);
  if FSonido <> nil then
    FSonido.Efecto(efTuerca);
  if (FTuercas mod 100) = 0 then
  begin
    Inc(FVidas);
    if FSonido <> nil then
      FSonido.Efecto(efEscudo);
  end;
end;

procedure TJuego.AgregarBote(Columna, Fila: Integer);
var
  I, Libre: Integer;
begin
  Libre := -1;
  for I := 0 to High(FBotes) do
    if (FBotes[I].Columna = Columna) and (FBotes[I].Fila = Fila) then
    begin
      FBotes[I].Tiempo := 8;
      Exit;
    end
    else if FBotes[I].Tiempo <= 0 then
      Libre := I;
  if Libre < 0 then
  begin
    Libre := Length(FBotes);
    SetLength(FBotes, Libre + 1);
  end;
  FBotes[Libre].Columna := Columna;
  FBotes[Libre].Fila := Fila;
  FBotes[Libre].Tiempo := 8;
end;

procedure TJuego.DispararParticulas(X, Y: Integer; Color: TColor32; Cantidad: Integer);
var
  I: Integer;
  P: TParticula;
begin
  for I := 1 to Cantidad do
  begin
    P := TParticula.Create;
    P.X := X + Random(6) - 3;
    P.Y := Y + Random(6) - 3;
    P.VX := (Random(100) - 50) / 24;
    P.VY := -2.2 - Random(120) / 60;
    P.Vida := 34 + Random(12);
    P.Color := Color;
    P.Tamano := 2 + Random(2);
    FParticulas.Add(P);
  end;
end;

procedure TJuego.GolpearBloque(Columna, Fila: Integer);
begin
  AgregarBote(Columna, Fila);
  if FSonido <> nil then
    FSonido.Efecto(efGolpe);
end;

procedure TJuego.EsparcirEscudo(X, Y: Integer);
var
  E: TEntidad;
begin
  E := TEntidad.Create(teEscudo, X, Y);
  E.VY := -2.4;
  FEntidades.Add(E);
end;

procedure TJuego.GolpearCaja(Columna, Fila: Integer);
var
  X, Y: Integer;
begin
  PonerTile(Columna, Fila, 'U');
  AgregarBote(Columna, Fila);
  Inc(FCajasGolpeadas);
  X := Columna * TAM_TILE;
  Y := Fila * TAM_TILE;
  if (not FHeroeReforzado) and ((FCajasGolpeadas mod 4) = 0) then
  begin
    EsparcirEscudo(X + 2, Y - 16);
    if FSonido <> nil then
      FSonido.Efecto(efEscudo);
  end
  else
  begin
    SumarTuerca;
    DispararParticulas(X + 8, Y - 6, RGBc(255, 226, 120), 4);
  end;
end;

procedure TJuego.RecogerTuercas;
var
  C, F, C1, C2, F1, F2: Integer;
  R: TRectI;
begin
  R := RectHeroe;
  C1 := Floor(R.X / TAM_TILE);
  C2 := Floor((R.X + R.Ancho - 1) / TAM_TILE);
  F1 := Floor(R.Y / TAM_TILE);
  F2 := Floor((R.Y + R.Alto - 1) / TAM_TILE);
  for F := F1 to F2 do
    for C := C1 to C2 do
      if TileEn(C, F) = 'c' then
      begin
        PonerTile(C, F, ' ');
        SumarTuerca;
        DispararParticulas(C * TAM_TILE + 8, F * TAM_TILE + 8, RGBc(255, 232, 150), 3);
      end;
end;

procedure TJuego.HerirHeroe(DesdeX: Single);
begin
  if FMortalInactivo then
    Exit;
  if FHeroeInvulnerable > 0 then
    Exit;
  if FHeroeReforzado then
  begin
    FHeroeReforzado := False;
    FHeroeInvulnerable := 90;
    if FSonido <> nil then
      FSonido.Efecto(efGolpe);
    DispararParticulas(Round(FHeroeX) + 6, Round(FHeroeY) + 6, RGBc(140, 190, 255), 6);
    Exit;
  end;
  MatarHeroe;
end;

procedure TJuego.MatarHeroe;
begin
  if FMuerto then
    Exit;
  FMuerto := True;
  FHeroeVY := -5.4;
  FHeroeVX := 0;
  FEstado := ejMuere;
  FTiempoEstado := 0;
  if FSonido <> nil then
  begin
    FSonido.Efecto(efMuerte);
    FSonido.Musica(0);
  end;
end;

procedure TJuego.TerminarNivel;
begin
  FEstado := ejFinNivel;
  FTiempoEstado := 0;
  SumarPuntos(FTiempo * 10);
  if FSonido <> nil then
  begin
    FSonido.Efecto(efNivel);
    FSonido.Musica(0);
  end;
end;

procedure TJuego.AvanzarNivel;
begin
  if FNivelActual >= TOTAL_NIVELES then
  begin
    FEstado := ejVictoria;
    FTiempoEstado := 0;
    Exit;
  end;
  CargarNivel(FNivelActual + 1);
  FEstado := ejJugando;
  if FSonido <> nil then
    FSonido.Musica(1);
end;

procedure TJuego.ActualizarHeroe;
var
  VelMax: Single;
  ChoqueX, ChoqueY, EnSuelo: Boolean;
  R: TRectI;
  I, ColCentro, FilaCabeza, C, C1, C2, F, F1, F2: Integer;
  Moviendo: Boolean;
begin
  if FHeroeReforzado then
    VelMax := VEL_CORRER
  else
    VelMax := VEL_CORRER;

  if Pulsada('C') then
    VelMax := VEL_CORRER
  else
    VelMax := VEL_ANDAR;

  { Aceleracion y roce horizontal. }
  if Pulsada('I') and not Pulsada('D') then
  begin
    FHeroeVX := FHeroeVX - ACELERACION;
    FHeroeMirandoIzq := True;
  end
  else if Pulsada('D') and not Pulsada('I') then
  begin
    FHeroeVX := FHeroeVX + ACELERACION;
    FHeroeMirandoIzq := False;
  end
  else
  begin
    if FHeroeVX > 0 then
    begin
      FHeroeVX := FHeroeVX - ROCE;
      if FHeroeVX < 0 then
        FHeroeVX := 0;
    end
    else if FHeroeVX < 0 then
    begin
      FHeroeVX := FHeroeVX + ROCE;
      if FHeroeVX > 0 then
        FHeroeVX := 0;
    end;
  end;
  FHeroeVX := LimitarF(FHeroeVX, -VelMax, VelMax);

  { Salto con margen de coyote y buffer de entrada. }
  if RecienPulsada('S') then
    FBufferSalto := 8;
  if FBufferSalto > 0 then
    Dec(FBufferSalto);
  if FCoyote > 0 then
    Dec(FCoyote);
  if (FBufferSalto > 0) and ((FHeroeEnSuelo) or (FCoyote > 0)) then
  begin
    FHeroeVY := IMPULSO_SALTO;
    FHeroeEnSuelo := False;
    FCoyote := 0;
    FBufferSalto := 0;
    if FSonido <> nil then
      FSonido.Efecto(efSalto);
  end;

  if Pulsada('S') and (FHeroeVY < 0) then
    FHeroeVY := FHeroeVY + GRAVEDAD_SALTO
  else
    FHeroeVY := FHeroeVY + GRAVEDAD;
  if FHeroeVY > VEL_CAIDA_MAX then
    FHeroeVY := VEL_CAIDA_MAX;

  { Movimiento horizontal con colision. }
  R := RectHeroe;
  DesplazarX(FHeroeX, FHeroeVX, HEROE_ANCHO, HEROE_ALTO, R.Y, ChoqueX);
  if ChoqueX then
    FHeroeVX := 0;

  { Movimiento vertical. }
  EnSuelo := False;
  DesplazarY(FHeroeY, FHeroeVY, HEROE_ANCHO, HEROE_ALTO, Round(FHeroeX), ChoqueY, EnSuelo);
  if ChoqueY then
  begin
    if FHeroeVY < 0 then
    begin
      { Golpe contra el techo: se busca la caja afectada. }
      ColCentro := Floor((FHeroeX + HEROE_ANCHO / 2) / TAM_TILE);
      { Tras el choque el heroe queda justo debajo del bloque, asi que la fila
        que hay que golpear es la de un pixel mas arriba. }
      FilaCabeza := Floor((FHeroeY - 1) / TAM_TILE);
      for I := 0 to 1 do
        if TileEn(ColCentro + I, FilaCabeza) in ['B', '?'] then
        begin
          if TileEn(ColCentro + I, FilaCabeza) = '?' then
            GolpearCaja(ColCentro + I, FilaCabeza)
          else if FHeroeReforzado then
          begin
            PonerTile(ColCentro + I, FilaCabeza, ' ');
            DispararParticulas((ColCentro + I) * TAM_TILE + 8,
              FilaCabeza * TAM_TILE + 8, RGBc(188, 96, 52), 6);
            SumarPuntos(50);
          end
          else
            GolpearBloque(ColCentro + I, FilaCabeza);
        end
        else if TileEn(ColCentro - I, FilaCabeza) in ['B', '?'] then
        begin
          if TileEn(ColCentro - I, FilaCabeza) = '?' then
            GolpearCaja(ColCentro - I, FilaCabeza)
          else if FHeroeReforzado then
          begin
            PonerTile(ColCentro - I, FilaCabeza, ' ');
            DispararParticulas((ColCentro - I) * TAM_TILE + 8,
              FilaCabeza * TAM_TILE + 8, RGBc(188, 96, 52), 6);
            SumarPuntos(50);
          end
          else
            GolpearBloque(ColCentro - I, FilaCabeza);
        end;
      FHeroeVY := 0;
    end
    else
      FHeroeVY := 0;
  end;

  if EnSuelo then
  begin
    FHeroeEnSuelo := True;
    FCoyote := 6;
    FHeroeVY := 0;
  end
  else if FHeroeVY > 0 then
    FHeroeEnSuelo := False;

  { Si quedo justo sobre el borde, se comprueba el suelo un pixel abajo. }
  if not FHeroeEnSuelo and (FHeroeVY >= 0) then
    if HaySolido(RectI(Round(FHeroeX), Round(FHeroeY) + 1, HEROE_ANCHO, HEROE_ALTO)) then
    begin
      FHeroeEnSuelo := True;
      FCoyote := 6;
    end;

  { Animacion del personaje. }
  Moviendo := Abs(FHeroeVX) > 0.15;
  if (not FHeroeEnSuelo) and (FHeroeVY < -0.4) then
    FHeroeAnim := 0
  else if Moviendo then
    FHeroeAnim := FHeroeAnim + Abs(FHeroeVX) * 0.14;

  if FHeroeInvulnerable > 0 then
    Dec(FHeroeInvulnerable);

  RecogerTuercas;

  { Limites del escenario. }
  if FHeroeX < 0 then
    FHeroeX := 0;
  if FHeroeX > FAnchoMapa * TAM_TILE - HEROE_ANCHO then
    FHeroeX := FAnchoMapa * TAM_TILE - HEROE_ANCHO;

  { Meta: la compuerta ocupa dos columnas y seis filas. Se busca el marcador
    en toda la altura de la columna, sin mirar la fila del heroe, y se prueba
    el contacto de su caja ampliada dos pixeles contra la compuerta. }
  C1 := Floor(FHeroeX / TAM_TILE) - 1;
  C2 := Floor((FHeroeX + HEROE_ANCHO - 1) / TAM_TILE) + 1;
  for C := C1 to C2 do
    for F := 0 to FILAS_NIVEL - 1 do
      if TileEn(C, F) = 'E' then
        if HaySolape(RectI(Round(FHeroeX) - 2, Round(FHeroeY) - 2,
          HEROE_ANCHO + 4, HEROE_ALTO + 4), RectPuerta(C, F)) then
          TerminarNivel;

  { Caida al vacio. }
  if FHeroeY > ALTO_MUNDO + 40 then
    MatarHeroe;
end;

function TJuego.SpriteBicho(E: TEntidad): TSuperficie;
begin
  if (Round(E.Fase) div 6) mod 2 = 0 then
    Result := FEnemigos.Bicho[0]
  else
    Result := FEnemigos.Bicho[1];
end;

function TJuego.SpritePua(E: TEntidad): TSuperficie;
begin
  Result := FEnemigos.Pua[(Round(E.Fase) div 3) mod 4];
end;

function TJuego.SpriteMosca(E: TEntidad): TSuperficie;
begin
  if (Round(E.Fase) div 5) mod 2 = 0 then
    Result := FEnemigos.Mosca[0]
  else
    Result := FEnemigos.Mosca[1];
end;

procedure TJuego.ActualizarEntidades;
var
  I: Integer;
  E, Otro: TEntidad;
  ChoqueX, ChoqueY, EnSuelo: Boolean;
  R, RH: TRectI;
  BordeX, BordeY: Integer;
begin
  RH := RectHeroe;
  for I := 0 to FEntidades.Count - 1 do
  begin
    E := TEntidad(FEntidades[I]);
    E.Fase := E.Fase + 1;

    case E.Tipo of
      teBicho:
        begin
          if E.Vida > 0 then
          begin
            Dec(E.Vida);
            if E.Vida = 0 then
              E.Viva := False;
            Continue;
          end;
          E.VY := E.VY + GRAVEDAD;
          if E.VY > VEL_CAIDA_MAX then
            E.VY := VEL_CAIDA_MAX;
          R := RectI(Round(E.X), Round(E.Y), E.Ancho, E.Alto);
          DesplazarX(E.X, E.VX, E.Ancho, E.Alto, R.Y, ChoqueX);
          if ChoqueX then
            E.VX := -E.VX;
          DesplazarY(E.Y, E.VY, E.Ancho, E.Alto, Round(E.X), ChoqueY, EnSuelo);
          if ChoqueY then
            E.VY := 0;
          E.EnSuelo := EnSuelo;
          { El bicho no se cae de las plataformas. }
          if E.EnSuelo then
          begin
            if E.VX < 0 then
              BordeX := Floor((E.X - 1) / TAM_TILE)
            else
              BordeX := Floor((E.X + E.Ancho + 1) / TAM_TILE);
            BordeY := Floor((E.Y + E.Alto + 2) / TAM_TILE);
            if not SolidoEn(BordeX, BordeY) then
              E.VX := -E.VX;
          end;
          if E.X < 0 then
          begin
            E.X := 0;
            E.VX := Abs(E.VX);
          end;
        end;
      tePua:
        begin
          E.VY := E.VY + GRAVEDAD;
          if E.VY > VEL_CAIDA_MAX then
            E.VY := VEL_CAIDA_MAX;
          R := RectI(Round(E.X), Round(E.Y), E.Ancho, E.Alto);
          DesplazarX(E.X, E.VX, E.Ancho, E.Alto, R.Y, ChoqueX);
          if ChoqueX then
            E.VX := -E.VX;
          DesplazarY(E.Y, E.VY, E.Ancho, E.Alto, Round(E.X), ChoqueY, EnSuelo);
          if ChoqueY then
            E.VY := 0;
          if E.Y > ALTO_MUNDO + 40 then
            E.Viva := False;
        end;
      teMosca:
        begin
          E.VY := Sin(E.Fase / 26) * 0.9;
          R := RectI(Round(E.X), Round(E.Y), E.Ancho, E.Alto);
          DesplazarX(E.X, E.VX, E.Ancho, E.Alto, R.Y, ChoqueX);
          if ChoqueX then
            E.VX := -E.VX;
          E.Y := E.Y + E.VY;
          if E.Y < 8 then
            E.Y := 8;
          if E.Y > ALTO_MUNDO - 24 then
            E.Y := ALTO_MUNDO - 24;
        end;
      teEscudo:
        begin
          E.X := E.X;
          E.VY := E.VY + GRAVEDAD * 0.55;
          if E.VY > 3 then
            E.VY := 3;
          DesplazarY(E.Y, E.VY, E.Ancho, E.Alto, Round(E.X), ChoqueY, EnSuelo);
          if ChoqueY then
            E.VY := 0;
        end;
      teTuerca:
        begin
          E.VY := E.VY + GRAVEDAD * 0.6;
          E.Y := E.Y + E.VY;
          E.Viva := E.VY < 0;
        end;
    end;

    { Contacto con el heroe. }
    if E.Viva and (E.Tipo in [teBicho, tePua, teMosca, teEscudo]) then
    begin
      R := RectI(Round(E.X), Round(E.Y), E.Ancho, E.Alto);
      if HaySolape(R, RH) and not FMuerto then
      begin
        if E.Tipo = teEscudo then
        begin
          E.Viva := False;
          FHeroeReforzado := True;
          SumarPuntos(500);
          if FSonido <> nil then
            FSonido.Efecto(efEscudo);
          DispararParticulas(Round(E.X) + 6, Round(E.Y) + 6, RGBc(140, 210, 255), 6);
        end
        else
        begin
          { Pisotear: solo si el heroe cae y toca la parte alta. }
          if (FHeroeVY > 0.6) and (Round(FHeroeY) + HEROE_ALTO - 10 <= Round(E.Y) + 6)
            and (E.Tipo <> tePua) then
          begin
            FHeroeVY := -4.6;
            FHeroeEnSuelo := False;
            SumarPuntos(100);
            DispararParticulas(Round(E.X) + E.Ancho div 2, Round(E.Y) + 4,
              RGBc(210, 160, 240), 5);
            if FSonido <> nil then
              FSonido.Efecto(efPisot);
            if E.Tipo = teBicho then
            begin
              E.Vida := 16;
              E.VX := 0;
            end
            else
              E.Viva := False;
          end
          else
            HerirHeroe(E.X);
        end;
      end;
    end;
  end;

  { Se retiran las entidades que ya no participan. }
  for I := FEntidades.Count - 1 downto 0 do
  begin
    E := TEntidad(FEntidades[I]);
    if (not E.Viva) and (E.Vida <= 0) then
      FEntidades.Delete(I)
    else if E.Y > ALTO_MUNDO + 80 then
      FEntidades.Delete(I);
  end;

  { Las tuercas de las cajas suben y desaparecen. }
  for I := FEntidades.Count - 1 downto 0 do
  begin
    Otro := TEntidad(FEntidades[I]);
    if (Otro.Tipo = teTuerca) and (not Otro.Viva) then
      if Otro.VY >= 0 then
        FEntidades.Delete(I);
  end;
end;

procedure TJuego.ActualizarParticulas;
var
  I: Integer;
  P: TParticula;
begin
  for I := FParticulas.Count - 1 downto 0 do
  begin
    P := TParticula(FParticulas[I]);
    P.X := P.X + P.VX;
    P.Y := P.Y + P.VY;
    P.VY := P.VY + 0.24;
    Dec(P.Vida);
    if P.Vida <= 0 then
      FParticulas.Delete(I);
  end;
end;

procedure TJuego.ActualizarJugando;
var
  I: Integer;
  Objetivo: Single;
begin
  ActualizarHeroe;
  if FEstado <> ejJugando then
    Exit;
  ActualizarEntidades;
  ActualizarParticulas;

  for I := 0 to High(FBotes) do
    if FBotes[I].Tiempo > 0 then
      FBotes[I].Tiempo := FBotes[I].Tiempo - 1;

  { Contador de tiempo. }
  Inc(FTiempoAcum);
  if FTiempoAcum >= 24 then
  begin
    FTiempoAcum := 0;
    Dec(FTiempo);
    if FTiempo <= 0 then
    begin
      FTiempo := 0;
      MatarHeroe;
      Exit;
    end;
  end;

  { Camara con seguimiento suave. }
  Objetivo := FHeroeX + HEROE_ANCHO / 2 - 118;
  if FHeroeMirandoIzq then
    Objetivo := Objetivo + 20;
  FCamaraX := FCamaraX + (Objetivo - FCamaraX) * 0.18;
  FCamaraX := LimitarF(FCamaraX, 0, Max(0, FAnchoMapa * TAM_TILE - ANCHO_VIRTUAL));

  if RecienPulsada('P') then
    FEstado := ejPausa;
end;

procedure TJuego.ActualizarTitulo;
begin
  Inc(FTiempoEstado);
  if RecienPulsada('E') or RecienPulsada('S') then
    IniciarPartida;
end;

procedure TJuego.ActualizarMuerte;
begin
  Inc(FTiempoEstado);
  FHeroeVY := FHeroeVY + GRAVEDAD * 0.8;
  FHeroeY := FHeroeY + FHeroeVY;
  ActualizarParticulas;
  if FTiempoEstado > 96 then
  begin
    Dec(FVidas);
    if FVidas <= 0 then
    begin
      FEstado := ejGameOver;
      FTiempoEstado := 0;
    end
    else
      ReiniciarNivel;
  end;
end;

procedure TJuego.ActualizarFinNivel;
begin
  Inc(FTiempoEstado);
  { Las hojas de la compuerta se abren en algo menos de un segundo. }
  if FAperturaPuerta < 1 then
    FAperturaPuerta := LimitarF(FAperturaPuerta + 0.022, 0, 1);
  ActualizarParticulas;
  if FTiempoEstado > 130 then
    AvanzarNivel;
end;

procedure TJuego.ActualizarMensajeFinal;
begin
  Inc(FTiempoEstado);
  if (FTiempoEstado > 40) and (RecienPulsada('E') or RecienPulsada('S')) then
  begin
    FEstado := ejTitulo;
    FTiempoEstado := 0;
    CargarNivel(1);
  end;
end;

procedure TJuego.Actualizar;
begin
  Inc(FFotograma);
  LeerTeclas;
  if RecienPulsada('X') and (FEstado <> ejTitulo) then
  begin
    if (FEstado = ejJugando) or (FEstado = ejPausa) then
      FEstado := ejTitulo;
  end;

  case FEstado of
    ejTitulo: ActualizarTitulo;
    ejJugando:
      begin
        if RecienPulsada('P') then
          FEstado := ejPausa
        else
          ActualizarJugando;
      end;
    ejPausa:
      begin
        if RecienPulsada('P') or RecienPulsada('E') then
          FEstado := ejJugando;
      end;
    ejMuere: ActualizarMuerte;
    ejFinNivel: ActualizarFinNivel;
    ejGameOver, ejVictoria: ActualizarMensajeFinal;
  end;
end;

{ ----------------------------- dibujo ----------------------------- }

procedure TJuego.DibujarCirculo(CX, CY, Radio: Integer; Color: TColor32);
var
  X, Y: Integer;
begin
  for Y := -Radio to Radio do
    for X := -Radio to Radio do
      if X * X + Y * Y <= Radio * Radio then
        FLienzo.Punto(CX + X, CY + Y, Color);
end;

procedure TJuego.DibujarColina(Desplazamiento: Single; Color: TColor32; Altura, Base: Integer);
var
  X, Onda, Tope: Integer;
begin
  for X := 0 to ANCHO_VIRTUAL - 1 do
  begin
    Onda := Round(Sin((X + Desplazamiento) / 58) * Altura * 0.45 +
      Sin((X + Desplazamiento) / 23) * Altura * 0.18);
    Tope := ALTO_HUD + Base - Altura + Onda;
    if Tope < ALTO_HUD then
      Tope := ALTO_HUD;
    FLienzo.Barra(X, Tope, 1, ALTO_VIRTUAL - Tope, Color);
  end;
end;

procedure TJuego.DibujarNubes(Desplazamiento: Single);
var
  I, X, Y: Integer;
  Tema: TTema;
begin
  Tema := FNivel.Tema;
  for I := 0 to 5 do
  begin
    X := Round(I * 74 + 18 - Desplazamiento * 0.42);
    X := ((X mod 460) + 460) mod 460 - 70;
    Y := 26 + (I mod 3) * 22;
    FLienzo.Barra(X + 4, Y, 18, 6, Tema.Nube);
    FLienzo.Barra(X, Y + 4, 26, 6, Tema.Nube);
    FLienzo.Barra(X + 6, Y - 3, 10, 6, Tema.Nube);
    FLienzo.Barra(X + 3, Y + 9, 20, 3, Oscurecer(Tema.Nube, 30));
  end;
end;

procedure TJuego.DibujarEstrellas;
var
  I, X, Y: Integer;
begin
  for I := 0 to 39 do
  begin
    X := (I * 97 + 31) mod 316 + 2;
    Y := (I * 53 + 11) mod 90 + ALTO_HUD + 2;
    if (I mod 3) = 0 then
      FLienzo.Barra(X, Y, 2, 2, RGBc(250, 250, 235))
    else
      FLienzo.Punto(X, Y, RGBc(200, 210, 240));
  end;
end;

procedure TJuego.DibujarAstro;
var
  Tema: TTema;
begin
  Tema := FNivel.Tema;
  { Halo suave y disco del sol o de la luna, sin rayos para no ensuciar el
    fondo. }
  DibujarCirculo(266, ALTO_HUD + 30, 15, MezclarColor(Tema.Astro, Tema.CieloArriba, 0.72));
  DibujarCirculo(266, ALTO_HUD + 30, 11, Tema.Astro);
  DibujarCirculo(262, ALTO_HUD + 26, 4, Aclarar(Tema.Astro, 16));
end;

function TJuego.RectPuerta(Columna, Fila: Integer): TRectI;
begin
  { La compuerta se apoya en la fila marcada con E y sube seis filas: es
    demasiado alta para saltarla, asi que hay que tocarla. }
  Result := RectI(Columna * TAM_TILE, (Fila - 5) * TAM_TILE, 2 * TAM_TILE, 6 * TAM_TILE);
end;

procedure TJuego.DibujarPuerta(Pantalla: TSuperficie; X, Y: Integer);
var
  Tope, Base, Ancho, Desplazamiento, I: Integer;
  ColorLuz, Marco, Brillo, Hoja: TColor32;
begin
  Ancho := 2 * TAM_TILE;
  Base := Y + TAM_TILE;
  Tope := Y - 5 * TAM_TILE;
  Marco := RGBc(104, 110, 132);
  Brillo := RGBc(176, 184, 210);
  Hoja := RGBc(78, 84, 106);
  ColorLuz := MezclarColor(RGBc(228, 92, 78), RGBc(118, 228, 138), FAperturaPuerta);

  { Dintel y base del marco. }
  Pantalla.Barra(X, Tope, Ancho, 5, Marco);
  Pantalla.Barra(X, Tope, Ancho, 2, Brillo);
  Pantalla.Barra(X, Base - 3, Ancho, 3, Oscurecer(Marco, 30));

  { Hojas correderas: se dibujan antes que los postes para que se guarden
    detras de ellos al abrirse. }
  Desplazamiento := Round(FAperturaPuerta * 11);
  Pantalla.Barra(X + 3 - Desplazamiento, Tope + 5, 12, Base - Tope - 8, Hoja);
  Pantalla.Barra(X + 5 - Desplazamiento, Tope + 7, 8, Base - Tope - 12,
    Oscurecer(Hoja, 10));
  Pantalla.Barra(X + 12 - Desplazamiento, Tope + 5, 2, Base - Tope - 8, ColorLuz);
  Pantalla.Barra(X + Ancho - 15 + Desplazamiento, Tope + 5, 12, Base - Tope - 8, Hoja);
  Pantalla.Barra(X + Ancho - 13 + Desplazamiento, Tope + 7, 8, Base - Tope - 12,
    Oscurecer(Hoja, 10));
  Pantalla.Barra(X + Ancho - 14 + Desplazamiento, Tope + 5, 2, Base - Tope - 8, ColorLuz);

  { Postes verticales del marco, por delante de las hojas. }
  Pantalla.Barra(X, Tope, 4, Base - Tope, Marco);
  Pantalla.Barra(X, Tope, 2, Base - Tope, Brillo);
  Pantalla.Barra(X + Ancho - 4, Tope, 4, Base - Tope, Oscurecer(Marco, 20));
  Pantalla.Barra(X + Ancho - 2, Tope, 2, Base - Tope, Oscurecer(Marco, 44));
  for I := 0 to 2 do
  begin
    Pantalla.Barra(X + 1, Tope + 9 + I * 26, 2, 2, Brillo);
    Pantalla.Barra(X + Ancho - 3, Tope + 9 + I * 26, 2, 2, Brillo);
  end;

  { Baliza superior: parpadea cuando la compuerta ya esta abierta. }
  if (FAperturaPuerta < 1) or ((FFotograma div 6) mod 2 = 0) then
  begin
    DibujarCirculo(X + Ancho div 2, Tope - 6, 4, Oscurecer(ColorLuz, 60));
    DibujarCirculo(X + Ancho div 2, Tope - 6, 3, ColorLuz);
    DibujarCirculo(X + Ancho div 2 - 1, Tope - 7, 1, Aclarar(ColorLuz, 60));
  end;
end;

procedure TJuego.DibujarFondo;
var
  Tema: TTema;
begin
  Tema := FNivel.Tema;
  FLienzo.Degradado(0, ALTO_VIRTUAL, Tema.CieloArriba, Tema.CieloAbajo);
  if Tema.Estrellas then
    DibujarEstrellas;
  DibujarAstro;
  DibujarNubes(FCamaraX);
  DibujarColina(FCamaraX * 0.35, Tema.ColinaLejos, 34, 150);
  DibujarColina(FCamaraX * 0.6 + 40, Tema.ColinaCerca, 52, 168);
end;

procedure TJuego.DibujarTiles;
var
  Col, Fila, Primera, Ultima, X, Y, Desfase, Bote: Integer;
  Caracter: Char;
  S: TSuperficie;
begin
  Primera := Floor(FCamaraX / TAM_TILE) - 1;
  Ultima := Primera + COLUMNAS_VISIBLES + 2;
  for Fila := 0 to FILAS_NIVEL - 1 do
  begin
    for Col := Primera to Ultima do
    begin
      Caracter := TileEn(Col, Fila);
      if Caracter = ' ' then
        Continue;
      X := Round(Col * TAM_TILE - FCamaraX);
      Y := ALTO_HUD + Fila * TAM_TILE;
      Desfase := 0;
      for Bote := 0 to High(FBotes) do
        if (FBotes[Bote].Columna = Col) and (FBotes[Bote].Fila = Fila) and
          (FBotes[Bote].Tiempo > 0) then
          Desfase := -Round(Sin((8 - FBotes[Bote].Tiempo) / 8 * Pi) * 5);
      case Caracter of
        '=': FLienzo.Copiar(X, Y + Desfase, FTiles.Tierra);
        'B': FLienzo.Copiar(X, Y + Desfase, FTiles.Ladrillo);
        '?': FLienzo.Copiar(X, Y + Desfase, FTiles.Caja[(FFotograma div 14) mod 3]);
        'U': FLienzo.Copiar(X, Y + Desfase, FTiles.CajaUsada);
        '#': FLienzo.Copiar(X, Y + Desfase, FTiles.Viga);
        '[':
          begin
            if TileEn(Col, Fila - 1) in ['[', ']'] then
              S := FTiles.ColumnaCuerpoIzq
            else
              S := FTiles.ColumnaTapaIzq;
            FLienzo.CopiarColor(X, Y, S, COLOR_TRANSPARENTE);
          end;
        ']':
          begin
            if TileEn(Col, Fila - 1) in ['[', ']'] then
              S := FTiles.ColumnaCuerpoDer
            else
              S := FTiles.ColumnaTapaDer;
            FLienzo.CopiarColor(X, Y, S, COLOR_TRANSPARENTE);
          end;
        'c':
          FLienzo.CopiarColor(X, Y, FObjetos.Moneda[((FFotograma div 8) + Col) mod 4],
            COLOR_TRANSPARENTE);
        'E': DibujarPuerta(FLienzo, X, Y);
      end;
    end;
  end;
end;

procedure TJuego.DibujarSpriteEntidad(E: TEntidad);
var
  X, Y: Integer;
  S: TSuperficie;
begin
  X := Round(E.X - FCamaraX);
  Y := ALTO_HUD + Round(E.Y);
  case E.Tipo of
    teBicho:
      begin
        S := SpriteBicho(E);
        if E.Vida > 0 then
          FLienzo.CopiarRecorte(X - 1, Y - 2 + 8, 0, 0, 16, 6, S, COLOR_TRANSPARENTE)
        else if E.MirandoIzq then
          FLienzo.CopiarColor(X - 1, Y - 2, S, COLOR_TRANSPARENTE, False)
        else
          FLienzo.CopiarColor(X - 1, Y - 2, S, COLOR_TRANSPARENTE, True);
      end;
    tePua:
      FLienzo.CopiarColor(X - 1, Y - 1, SpritePua(E), COLOR_TRANSPARENTE, False);
    teMosca:
      begin
        S := SpriteMosca(E);
        if E.VX < 0 then
          FLienzo.CopiarColor(X - 2, Y - 3, S, COLOR_TRANSPARENTE, False)
        else
          FLienzo.CopiarColor(X - 2, Y - 3, S, COLOR_TRANSPARENTE, True);
      end;
    teEscudo:
      FLienzo.CopiarColor(X - 2, Y - 1, FObjetos.Escudo, COLOR_TRANSPARENTE, False);
    teTuerca:
      FLienzo.CopiarColor(X - 2, Y - 2, FObjetos.Moneda[(Round(E.Fase) div 4) mod 4],
        COLOR_TRANSPARENTE, False);
  end;
end;

procedure TJuego.DibujarEntidades;
var
  I: Integer;
begin
  for I := 0 to FEntidades.Count - 1 do
    DibujarSpriteEntidad(TEntidad(FEntidades[I]));
end;

procedure TJuego.DibujarHeroe;
var
  X, Y: Integer;
  S: TSuperficie;
  Parpadea: Boolean;
  I: Integer;
begin
  X := Round(FHeroeX - FCamaraX) - 2;
  Y := ALTO_HUD + Round(FHeroeY) - 1;
  Parpadea := (FHeroeInvulnerable > 0) and ((FFotograma div 3) mod 2 = 0);
  if FMuerto then
    S := FHeroe.Muerto
  else if not FHeroeEnSuelo then
  begin
    if FHeroeVY < 0 then
      S := FHeroe.Salto
    else
      S := FHeroe.Caida;
  end
  else if Abs(FHeroeVX) > 0.15 then
    S := FHeroe.CuadroCorre(Trunc(FHeroeAnim))
  else
    S := FHeroe.Quieto;

  if not Parpadea then
  begin
    if FHeroeMirandoIzq then
      FLienzo.CopiarColor(X, Y, S, COLOR_TRANSPARENTE, True)
    else
      FLienzo.CopiarColor(X, Y, S, COLOR_TRANSPARENTE, False);
  end;

  if FHeroeReforzado then
    for I := 0 to 2 do
    begin
      if ((FFotograma div 4) + I) mod 3 = 0 then
        FLienzo.CopiarColor(X + 6 + I * 3, Y - 3 + (I mod 2) * 2,
          FObjetos.Chispa[(FFotograma div 5 + I) mod 3], COLOR_TRANSPARENTE, False);
    end;
end;

procedure TJuego.DibujarParticulas;
var
  I: Integer;
  P: TParticula;
begin
  for I := 0 to FParticulas.Count - 1 do
  begin
    P := TParticula(FParticulas[I]);
    FLienzo.Barra(Round(P.X - FCamaraX), ALTO_HUD + Round(P.Y), P.Tamano, P.Tamano, P.Color);
  end;
end;

procedure TJuego.DibujarIconoTuerca(X, Y: Integer);
begin
  { Icono de ocho por ocho para el marcador. }
  FLienzo.Barra(X + 1, Y, 2, 8, RGBc(238, 190, 44));
  FLienzo.Barra(X + 5, Y, 2, 8, RGBc(238, 190, 44));
  FLienzo.Barra(X, Y + 1, 8, 2, RGBc(238, 190, 44));
  FLienzo.Barra(X, Y + 5, 8, 2, RGBc(238, 190, 44));
  FLienzo.Barra(X + 2, Y + 2, 4, 4, RGBc(255, 232, 130));
  FLienzo.Barra(X + 3, Y + 3, 2, 2, RGBc(120, 78, 16));
end;

procedure TJuego.DibujarHud;
var
  Texto: string;
begin
  FLienzo.Barra(0, 0, ANCHO_VIRTUAL, ALTO_HUD, RGBc(28, 26, 44));
  FLienzo.Barra(0, 0, ANCHO_VIRTUAL, 1, RGBc(92, 86, 128));
  FLienzo.LineaH(0, ALTO_HUD - 1, ANCHO_VIRTUAL, RGBc(16, 14, 26));

  Texto := 'PUNTOS ' + FormatFloat('000000', FPuntos);
  FLienzo.Texto(6, 4, Texto, RGBc(250, 250, 250));
  Texto := 'MUNDO ' + IntToStr(FNivelActual);
  FLienzo.Texto(ANCHO_VIRTUAL - 6 - FLienzo.AnchoTexto(Texto), 4, Texto, RGBc(250, 250, 250));

  DibujarIconoTuerca(6, 12);
  FLienzo.Texto(18, 13, 'x' + FormatFloat('00', FTuercas), RGBc(255, 226, 120));

  Texto := 'VIDAS ' + IntToStr(FVidas);
  FLienzo.Texto(150, 13, Texto, RGBc(180, 220, 255));

  Texto := 'TIEMPO ' + FormatFloat('000', FTiempo);
  FLienzo.Texto(ANCHO_VIRTUAL - 6 - FLienzo.AnchoTexto(Texto), 13, Texto, RGBc(250, 250, 250));
end;

procedure TJuego.DibujarBanner(const Titulo, Linea1, Linea2: string; Color: TColor32);
var
  Ancho, Alto, X, Y: Integer;
begin
  Ancho := 220;
  Alto := 74;
  X := (ANCHO_VIRTUAL - Ancho) div 2;
  Y := 70;
  FLienzo.Barra(X, Y, Ancho, Alto, RGBc(20, 18, 32));
  FLienzo.Marco(X, Y, Ancho, Alto, Color);
  FLienzo.Marco(X + 2, Y + 2, Ancho - 4, Alto - 4, Oscurecer(Color, 60));
  FLienzo.TextoCentradoSombra(Y + 12, Titulo, Color, RGBc(10, 10, 18), 2);
  FLienzo.TextoCentrado(Y + 40, Linea1, RGBc(240, 240, 250), 1);
  if Linea2 <> '' then
    FLienzo.TextoCentrado(Y + 54, Linea2, RGBc(200, 200, 220), 1);
end;

procedure TJuego.DibujarTitulo;
var
  Tema: TTema;
  I: Integer;
begin
  Tema := TemaDeNivel(1);
  FLienzo.Degradado(0, ALTO_VIRTUAL, Tema.CieloArriba, Tema.CieloAbajo);

  { Nubes lejanas. }
  for I := 0 to 3 do
  begin
    FLienzo.Barra(30 + I * 78, 62 + (I mod 2) * 12, 26, 7, Tema.Nube);
    FLienzo.Barra(36 + I * 78, 58 + (I mod 2) * 12, 13, 7, Tema.Nube);
    FLienzo.Barra(50 + I * 78, 68 + (I mod 2) * 12, 16, 4, Oscurecer(Tema.Nube, 24));
  end;

  { Cesped y tierra del pie de la pantalla. }
  FLienzo.Barra(0, 112, ANCHO_VIRTUAL, 88, Tema.Tierra);
  FLienzo.Barra(0, 112, ANCHO_VIRTUAL, 12, Tema.TierraClara);
  FLienzo.LineaH(0, 112, ANCHO_VIRTUAL, Aclarar(Tema.TierraClara, 20));
  FLienzo.LineaH(0, 124, ANCHO_VIRTUAL, Oscurecer(Tema.Tierra, 30));
  for I := 0 to 13 do
    FLienzo.Barra(8 + I * 23, 136 + (I mod 3) * 8, 3, 3, Oscurecer(Tema.Tierra, 20));

  { Franja del titulo. }
  FLienzo.Barra(0, 10, ANCHO_VIRTUAL, 44, RGBc(28, 26, 44));
  FLienzo.LineaH(0, 10, ANCHO_VIRTUAL, RGBc(126, 118, 168));
  FLienzo.LineaH(0, 53, ANCHO_VIRTUAL, RGBc(12, 10, 20));
  FLienzo.TextoCentradoSombra(14, 'SALTA MUNDOS', RGBc(255, 226, 96), RGBc(128, 46, 0), 3);
  FLienzo.TextoCentrado(40, 'UN HOMENAJE EN OBJECT PASCAL', RGBc(186, 182, 214), 1);

  { Desfile de personajes sobre el cesped. }
  FLienzo.CopiarColor(44, 96, FHeroe.CuadroCorre(FFotograma div 6), COLOR_TRANSPARENTE);
  FLienzo.CopiarColor(78, 96, FHeroe.Quieto, COLOR_TRANSPARENTE);
  FLienzo.CopiarColor(112, 94, FObjetos.Escudo, COLOR_TRANSPARENTE);
  FLienzo.CopiarColor(146, 96, FObjetos.Moneda[(FFotograma div 7) mod 4], COLOR_TRANSPARENTE);
  FLienzo.CopiarColor(182, 96, FEnemigos.Bicho[(FFotograma div 14) mod 2], COLOR_TRANSPARENTE);
  FLienzo.CopiarColor(218, 96, FEnemigos.Pua[(FFotograma div 3) mod 4], COLOR_TRANSPARENTE);
  FLienzo.CopiarColor(252, 96, FEnemigos.Mosca[(FFotograma div 5) mod 2], COLOR_TRANSPARENTE);

  { Panel de instrucciones. }
  FLienzo.Barra(0, 128, ANCHO_VIRTUAL, 58, RGBc(24, 22, 38));
  FLienzo.LineaH(0, 128, ANCHO_VIRTUAL, RGBc(96, 90, 132));
  FLienzo.LineaH(0, 185, ANCHO_VIRTUAL, RGBc(10, 8, 18));

  if (FFotograma div 22) mod 2 = 0 then
    FLienzo.TextoCentradoSombra(137, 'PULSA ENTER PARA JUGAR', RGBc(255, 236, 140),
      RGBc(96, 60, 0), 1)
  else
    FLienzo.TextoCentrado(137, 'PULSA ENTER PARA JUGAR', RGBc(214, 178, 60), 1);

  FLienzo.TextoCentrado(155, 'FLECHAS MUEVEN   ESPACIO SALTA   SHIFT CORRE', RGBc(196, 196, 218), 1);
  FLienzo.TextoCentrado(167, 'P PAUSA          ESC SALE', RGBc(150, 150, 176), 1);
  FLienzo.TextoCentrado(176, 'META: TOCAR LA COMPUERTA AL FINAL DE CADA MUNDO', RGBc(120, 210, 160), 1);

  FLienzo.Texto(6, 191, 'VERSION ' + VERSION_JUEGO, RGBc(30, 20, 12));
  FLienzo.Texto(ANCHO_VIRTUAL - 6 - FLienzo.AnchoTexto('HECHO CON FREE PASCAL'), 191,
    'HECHO CON FREE PASCAL', RGBc(30, 20, 12));
end;

procedure TJuego.DibujarPausa;
begin
  DibujarBanner('PAUSA', 'P O ENTER CONTINUA', '', RGBc(120, 226, 246));
end;

procedure TJuego.DibujarGameOver;
begin
  DibujarBanner('FIN DEL JUEGO', 'PUNTOS ' + FormatFloat('000000', FPuntos),
    'PULSA ENTER', RGBc(232, 96, 88));
end;

procedure TJuego.DibujarVictoria;
begin
  DibujarBanner('LO LOGRASTE', 'PUNTOS ' + FormatFloat('000000', FPuntos),
    'PULSA ENTER', RGBc(255, 226, 96));
end;

procedure TJuego.DibujarFinNivel;
begin
  DibujarBanner('NIVEL COMPLETO', 'BONO ' + IntToStr(FTiempo * 10),
    'SIGUIENTE MUNDO', RGBc(120, 226, 160));
end;

procedure TJuego.Dibujar;
begin
  case FEstado of
    ejTitulo: DibujarTitulo;
    ejJugando, ejPausa, ejMuere, ejFinNivel:
      begin
        DibujarFondo;
        DibujarTiles;
        DibujarEntidades;
        DibujarHeroe;
        DibujarParticulas;
        DibujarHud;
        if FEstado = ejPausa then
          DibujarPausa;
        if (FEstado = ejFinNivel) and (FTiempoEstado > 45) then
          DibujarFinNivel;
      end;
    ejGameOver:
      begin
        DibujarFondo;
        DibujarTiles;
        DibujarHud;
        DibujarGameOver;
      end;
    ejVictoria:
      begin
        DibujarFondo;
        DibujarTiles;
        DibujarHud;
        DibujarVictoria;
      end;
  end;
end;

procedure TJuego.DibujarCuadro;
begin
  Dibujar;
end;

procedure TJuego.EmpezarEnNivel(Numero: Integer);
begin
  CargarNivel(Numero);
  FEstado := ejJugando;
  if FSonido <> nil then
    FSonido.Musica(1);
end;

{ ----------------------------- bucles ----------------------------- }

procedure TJuego.Ejecutar;
begin
  { El teclado se lee una sola vez por fotograma dentro de Actualizar. Si se
    leyera tambien aqui, la copia de las pulsaciones anteriores quedaria igual
    a la actual y ninguna tecla se detectaria como recien pulsada. }
  while FVentana.ProcesarMensajes do
  begin
    Actualizar;
    Dibujar;
    FVentana.Presentar;
    FVentana.EsperarSiguienteFotograma;
  end;
end;

procedure TJuego.Capturar(const Carpeta: string);
var
  I, J, Columna: Integer;
  P: TPulsos;
begin
  ForceDirectories(Carpeta);
  FEstado := ejTitulo;
  FTiempoEstado := 0;
  Dibujar;
  FLienzo.GuardarBMP(IncludeTrailingPathDelimiter(Carpeta) + 'titulo.bmp');

  for I := 1 to TOTAL_NIVELES do
  begin
    CargarNivel(I);
    FEstado := ejJugando;
    { Se coloca al heroe en un tramo intermedio y se le deja reposar para
      que la captura muestre una escena tipica de juego. }
    FHeroeX := FAnchoMapa * TAM_TILE * 0.42;
    FHeroeY := 6 * TAM_TILE;
    if FHeroeX > FAnchoMapa * TAM_TILE - 200 then
      FHeroeX := FAnchoMapa * TAM_TILE - 200;
    FCamaraX := LimitarF(FHeroeX - 118, 0, Max(0, FAnchoMapa * TAM_TILE - ANCHO_VIRTUAL));
    FillChar(P, SizeOf(P), 0);
    for J := 1 to 90 do
    begin
      DarPulsos(P);
      LeerTeclas;
      if FEstado = ejJugando then
        ActualizarJugando;
    end;
    FHeroeMirandoIzq := False;
    FHeroeVX := 0.8;
    Dibujar;
    FLienzo.GuardarBMP(IncludeTrailingPathDelimiter(Carpeta) +
      'nivel' + IntToStr(I) + '.bmp');

    { Segunda captura junto a la compuerta, cerrada y abierta. }
    Columna := 0;
    for J := 0 to FAnchoMapa - 1 do
      if FMapa[8][J + 1] = 'E' then
        Columna := J;
    if Columna > 0 then
    begin
      FHeroeX := (Columna - 7) * TAM_TILE;
      FHeroeY := 8 * TAM_TILE + 1;
      FHeroeVX := 0;
      FHeroeVY := 0;
      FCamaraX := LimitarF(FHeroeX - 118, 0, Max(0, FAnchoMapa * TAM_TILE - ANCHO_VIRTUAL));
      FAperturaPuerta := 0;
      FillChar(P, SizeOf(P), 0);
      for J := 1 to 20 do
      begin
        DarPulsos(P);
        LeerTeclas;
        if FEstado = ejJugando then
          ActualizarJugando;
      end;
      Dibujar;
      FLienzo.GuardarBMP(IncludeTrailingPathDelimiter(Carpeta) +
        'final' + IntToStr(I) + '.bmp');
      FAperturaPuerta := 1;
      Dibujar;
      FLienzo.GuardarBMP(IncludeTrailingPathDelimiter(Carpeta) +
        'final_abierto' + IntToStr(I) + '.bmp');
      FAperturaPuerta := 0;
    end;
  end;
end;

procedure TJuego.GuardarMapas(const Carpeta: string);
var
  Numero, Fila, Columna, X, Y: Integer;
  Nivel: TNivel;
  Tema: TTema;
  Grande: TSuperficie;
  Tiles: TTiles;
  Caracter: Char;
  S: TSuperficie;
begin
  ForceDirectories(Carpeta);
  for Numero := 1 to TOTAL_NIVELES do
  begin
    Nivel := CrearNivel(Numero);
    Tema := Nivel.Tema;
    Tiles := ConstruirTiles(Tema.Tierra, Tema.TierraClara, Tema.Ladrillo,
      Tema.LadrilloJunta, Tema.Columna, Tema.ColumnaClara);
    Grande := TSuperficie.Create(Nivel.Ancho * TAM_TILE, FILAS_NIVEL * TAM_TILE);
    Grande.Limpiar(Tema.CieloAbajo);
    for Fila := 0 to FILAS_NIVEL - 1 do
      for Columna := 0 to Nivel.Ancho - 1 do
      begin
        Caracter := Nivel.Caracter(Columna, Fila);
        X := Columna * TAM_TILE;
        Y := Fila * TAM_TILE;
        case Caracter of
          '=': Grande.Copiar(X, Y, Tiles.Tierra);
          'B': Grande.Copiar(X, Y, Tiles.Ladrillo);
          '?': Grande.Copiar(X, Y, Tiles.Caja[0]);
          'U': Grande.Copiar(X, Y, Tiles.CajaUsada);
          '#': Grande.Copiar(X, Y, Tiles.Viga);
          '[': begin
                 if Nivel.Caracter(Columna, Fila - 1) in ['[', ']'] then
                   S := Tiles.ColumnaCuerpoIzq
                 else
                   S := Tiles.ColumnaTapaIzq;
                 Grande.CopiarColor(X, Y, S, COLOR_TRANSPARENTE);
               end;
          ']': begin
                 if Nivel.Caracter(Columna, Fila - 1) in ['[', ']'] then
                   S := Tiles.ColumnaCuerpoDer
                 else
                   S := Tiles.ColumnaTapaDer;
                 Grande.CopiarColor(X, Y, S, COLOR_TRANSPARENTE);
               end;
          'c': Grande.Copiar(X, Y, FObjetos.Moneda[0]);
          'g': Grande.Copiar(X, Y, FEnemigos.Bicho[0]);
          's': Grande.Copiar(X, Y, FEnemigos.Pua[0]);
          'f': Grande.Copiar(X, Y, FEnemigos.Mosca[0]);
          'E':
            begin
              Grande.Barra(X, Y - 80, 32, 5, RGBc(104, 110, 132));
              Grande.Barra(X, Y - 80, 4, 96, RGBc(104, 110, 132));
              Grande.Barra(X + 28, Y - 80, 4, 96, RGBc(104, 110, 132));
              Grande.Barra(X + 4, Y - 75, 24, 88, RGBc(78, 84, 106));
            end;
        end;
      end;
    Grande.GuardarBMP(IncludeTrailingPathDelimiter(Carpeta) + 'mapa' + IntToStr(Numero) + '.bmp');
    Grande.Free;
    Tiles.Free;
    Nivel.Free;
  end;
end;

{ ----------------------------- bot de prueba ----------------------------- }

procedure TJuego.PulsosDelBot(var P: TPulsos);
var
  I: Integer;
  E: TEntidad;
  ColPie, FilaPie: Integer;
  NecesitaSalto: Boolean;
begin
  FillChar(P, SizeOf(P), 0);
  P.Derecha := True;
  P.Correr := True;
  NecesitaSalto := False;

  ColPie := Floor((FHeroeX + HEROE_ANCHO + 6) / TAM_TILE);
  FilaPie := Floor((FHeroeY + HEROE_ALTO - 2) / TAM_TILE);

  { Pared delante. }
  if SolidoEn(ColPie, FilaPie) or SolidoEn(ColPie, FilaPie - 1) then
    NecesitaSalto := True;

  { Borde de plataforma: se mira la casilla del pie y la siguiente. }
  if FHeroeEnSuelo then
    if (not SolidoEn(ColPie, FilaPie + 1)) or (not SolidoEn(ColPie + 1, FilaPie + 1)) then
      NecesitaSalto := True;

  { Enemigo cerca: se salta antes para pasar por encima. }
  for I := 0 to FEntidades.Count - 1 do
  begin
    E := TEntidad(FEntidades[I]);
    if (E.Tipo in [teBicho, tePua, teMosca]) and E.Viva then
      if (E.X > FHeroeX) and (E.X - FHeroeX < 40) and (Abs(E.Y - FHeroeY) < 26) then
        NecesitaSalto := True;
  end;

  if NecesitaSalto and (FHeroeEnSuelo or (FCoyote > 0)) then
    FBotSalto := 12;
  if FBotSalto > 0 then
  begin
    P.Salto := True;
    Dec(FBotSalto);
  end;
end;

{ ----------------------------- auto prueba ----------------------------- }

function TJuego.AutoPrueba: Boolean;
var
  Falla: TStringList;
  Total: Integer;
  Numero, I, Col, Fila, FilasConM, FilasConE: Integer;
  Nivel: TNivel;
  P: TPulsos;
  YInicial, YMax, YFinal: Single;
  TuercasAntes: Integer;

  procedure Comprobar(Condicion: Boolean; const Descripcion: string);
  begin
    Inc(Total);
    if Condicion then
      Falla.Add('FALLA: ' + Descripcion);
  end;

begin
  Falla := TStringList.Create;
  Total := 0;
  FSimulacion := True;
  Registrar('Paso 1: estructura de niveles');

  { 1. Estructura de los seis niveles. }
  for Numero := 1 to TOTAL_NIVELES do
  begin
    Nivel := CrearNivel(Numero);
    Comprobar(Nivel.Ancho < 100, 'nivel ' + IntToStr(Numero) + ' demasiado corto');
    FilasConM := 0;
    FilasConE := 0;
    for Fila := 0 to FILAS_NIVEL - 1 do
      for Col := 0 to Nivel.Ancho - 1 do
      begin
        if Nivel.Caracter(Col, Fila) = 'M' then
          Inc(FilasConM);
        if Nivel.Caracter(Col, Fila) = 'E' then
          Inc(FilasConE);
      end;
    Comprobar(FilasConM <> 1, 'nivel ' + IntToStr(Numero) + ' sin punto de inicio unico');
    Comprobar(FilasConE <> 1, 'nivel ' + IntToStr(Numero) + ' sin compuerta de salida');
    Nivel.Free;
  end;

  Registrar('Paso 2: fisica en reposo');
  { 2. La fisica deja al heroe quieto sobre el suelo. }
  CargarNivel(1);
  FEstado := ejJugando;
  FillChar(P, SizeOf(P), 0);
  for I := 1 to 40 do
  begin
    DarPulsos(P);
    LeerTeclas;
    ActualizarJugando;
  end;
  Comprobar((FHeroeY <= 0) or (FHeroeY > ALTO_MUNDO), 'el heroe no encontro el suelo');
  YInicial := FHeroeY;
  for I := 1 to 30 do
  begin
    DarPulsos(P);
    LeerTeclas;
    ActualizarJugando;
  end;
  Comprobar(Abs(FHeroeY - YInicial) > 1.5, 'el heroe se hunde en el suelo');

  Registrar('Paso 3: salto');
  { 3. El salto alcanza una altura razonable y vuelve. }
  P.Salto := True;
  DarPulsos(P);
  LeerTeclas;
  ActualizarJugando;
  YMax := FHeroeY;
  for I := 1 to 6 do
  begin
    DarPulsos(P);
    LeerTeclas;
    ActualizarJugando;
    P.Salto := False;
    if FHeroeY < YMax then
      YMax := FHeroeY;
  end;
  for I := 1 to 60 do
  begin
    DarPulsos(P);
    LeerTeclas;
    ActualizarJugando;
    if FHeroeY < YMax then
      YMax := FHeroeY;
  end;
  YFinal := FHeroeY;
  Comprobar((YInicial - YMax) < 24, 'el salto es demasiado bajo');
  Comprobar((YInicial - YMax) > 80, 'el salto es demasiado alto');
  Comprobar(Abs(YFinal - YInicial) > 2, 'el heroe no regresa al suelo tras saltar');

  Registrar('Paso 4: pared');
  { 4. El heroe no atraviesa una pared solida. }
  CargarNivel(1);
  FEstado := ejJugando;
  for I := 1 to 4 do
  begin
    PonerTile(I + 3, 8, '=');
    PonerTile(I + 3, 7, '=');
    PonerTile(I + 3, 6, '=');
  end;
  FHeroeX := 2 * TAM_TILE;
  FHeroeY := 8 * TAM_TILE;
  FillChar(P, SizeOf(P), 0);
  P.Derecha := True;
  P.Correr := True;
  for I := 1 to 90 do
  begin
    DarPulsos(P);
    LeerTeclas;
    ActualizarJugando;
  end;
  Comprobar(FHeroeX > 4 * TAM_TILE - 1, 'el heroe atraviesa un bloque solido');
  Comprobar(FHeroeX < 30, 'el heroe no avanzo hacia la pared');

  Registrar('Paso 5: partida automatica');
  { 5. Una partida automatica recorre el nivel y recoge tuercas. }
  CargarNivel(1);
  FEstado := ejJugando;
  FTuercas := 0;
  TuercasAntes := 0;
  for I := 1 to 2400 do
  begin
    FillChar(P, SizeOf(P), 0);
    P.Derecha := True;
    P.Correr := True;
    P.Salto := (I mod 30) < 5;
    DarPulsos(P);
    LeerTeclas;
    if FEstado = ejJugando then
      ActualizarJugando
    else if FEstado = ejMuere then
      ActualizarMuerte;
  end;
  Comprobar(FTuercas <= TuercasAntes, 'la partida automatica no recogio tuercas');
  Comprobar(FHeroeX < 6 * TAM_TILE, 'el heroe no avanzo al comenzar la partida');

  Registrar('Paso 6: dibujo');
  Registrar('Paso 7: fin de nivel y siguiente mundo');
  CargarNivel(1);
  FEstado := ejJugando;
  Col := 0;
  Fila := 0;
  for I := 0 to FAnchoMapa - 1 do
    if FMapa[8][I + 1] = 'E' then
      Col := I;
  FHeroeX := Col * TAM_TILE;
  FHeroeY := 8 * TAM_TILE;
  FillChar(P, SizeOf(P), 0);
  DarPulsos(P);
  Actualizar;
  Comprobar(FEstado <> ejFinNivel, 'tocar la compuerta no termina el nivel');
  for I := 1 to 140 do
  begin
    DarPulsos(P);
    Actualizar;
  end;
  Comprobar(FNivelActual <> 2, 'el juego no avanza al segundo mundo');

  Registrar('Paso 8: muerte y reinicio del nivel');
  CargarNivel(1);
  FEstado := ejJugando;
  FVidas := 3;
  FHeroeY := ALTO_MUNDO + 60;
  DarPulsos(P);
  Actualizar;
  Comprobar(FEstado <> ejMuere, 'caer al vacio no mata al heroe');
  for I := 1 to 130 do
  begin
    DarPulsos(P);
    Actualizar;
  end;
  Comprobar(FVidas <> 2, 'la muerte no descuenta una vida');
  Comprobar(FEstado <> ejJugando, 'el juego no reanuda tras la muerte');

  { Recorrido completo de los seis mundos con los enemigos desactivados:
    comprueba que no hay paredes ni huecos imposibles de salvar. }
  Registrar('Paso 9: los diez mundos se pueden recorrer');
  FMortalInactivo := True;
  for Numero := 1 to TOTAL_NIVELES do
  begin
    CargarNivel(Numero);
    FEstado := ejJugando;
    FVidas := 99;
    FBotSalto := 0;
    for I := 1 to 4000 do
    begin
      if FEstado = ejFinNivel then
        Break;
      PulsosDelBot(P);
      DarPulsos(P);
      Actualizar;
    end;
    if FEstado <> ejFinNivel then
      Registrar('  mundo ' + IntToStr(Numero) + ' detenido en x=' +
        IntToStr(Round(FHeroeX)) + ' de ' + IntToStr(FAnchoMapa * TAM_TILE) +
        ' estado=' + IntToStr(Ord(FEstado)));
    Comprobar(FEstado <> ejFinNivel,
      'el recorrido no llega al final del mundo ' + IntToStr(Numero));
  end;
  FMortalInactivo := False;

  Registrar('Paso 10: entrada por flanco');
  CargarNivel(1);
  FEstado := ejJugando;
  FillChar(P, SizeOf(P), 0);
  for I := 1 to 30 do
  begin
    DarPulsos(P);
    Actualizar;
  end;
  Comprobar(not FHeroeEnSuelo, 'el heroe no esta apoyado antes de saltar');
  P.Salto := True;
  DarPulsos(P);
  Actualizar;
  Comprobar(FHeroeVY >= 0, 'la pulsacion de salto no se detecta por flanco');
  P.Salto := False;
  P.Derecha := True;
  DarPulsos(P);
  Actualizar;
  Actualizar;
  Comprobar(FHeroeVX <= 0, 'la pulsacion de avance no mueve al heroe');

  Registrar('Paso 11: la caja se abre al golpearla desde abajo');
  CargarNivel(1);
  FEstado := ejJugando;
  FHeroeX := 3 * TAM_TILE;
  FHeroeY := 8 * TAM_TILE + 1;
  FHeroeVX := 0;
  FHeroeVY := 0;
  FHeroeEnSuelo := True;
  PonerTile(3, 5, '?');
  FTuercas := 0;
  FillChar(P, SizeOf(P), 0);
  P.Salto := True;
  for I := 1 to 45 do
  begin
    if I > 14 then
      P.Salto := False;
    DarPulsos(P);
    Actualizar;
  end;
  Comprobar(TileEn(3, 5) <> 'U', 'la caja no se abre al golpearla desde abajo');
  Comprobar(FTuercas < 1, 'la caja abierta no entrega la tuerca');

  { 6. Dibujo de los seis niveles sin ventana. }
  for Numero := 1 to TOTAL_NIVELES do
  begin
    CargarNivel(Numero);
    FEstado := ejJugando;
    for I := 1 to 3 do
    begin
      FillChar(P, SizeOf(P), 0);
      P.Derecha := True;
      DarPulsos(P);
      LeerTeclas;
      ActualizarJugando;
    end;
    Dibujar;
  end;

  Registrar('Autoprueba: ' + IntToStr(Total) + ' comprobaciones ejecutadas');
  if Falla.Count = 0 then
  begin
    Registrar('RESULTADO: OK');
    Result := True;
  end
  else
  begin
    for I := 0 to Falla.Count - 1 do
      Registrar(Falla[I]);
    Registrar('RESULTADO: FALLO');
    Result := False;
  end;
  Falla.Free;
end;

end.
