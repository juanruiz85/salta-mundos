program SaltaMundos;
{ Salta Mundos: juego de plataformas por mundos, escrito en Object Pascal
  (modo Delphi) y compilado con Free Pascal para Windows.

  El programa dibuja todo a 320x200 sobre una superficie en memoria y luego
  estira la imagen a la ventana con un multiplo entero.

  Opciones de linea de comandos: ver EscribirAyuda en GMCore. }

{$MODE DELPHI}
{$H+}
{$IFNDEF CONSOLA}
  {$APPTYPE GUI}
{$ENDIF}

uses
  SysUtils,
  GMCore,
  GMSuperficie,
  GMVentana,
  GMSonido,
  GMJuego;

var
  Ventana: TVentana;
  Sonido: TSonido;
  Juego: TJuego;
  Opciones: TOpciones;
  Correcto: Boolean;

{ Deja constancia del arranque y de cualquier error en un archivo junto al
  ejecutable. Sirve para diagnosticar problemas sin consola asociada. }
procedure Registrar(const Linea: string);
var
  Archivo: TextFile;
  Ruta: string;
begin
  Ruta := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'salta-mundos.log';
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
    { Si no se puede escribir, el juego continua sin registro. }
  end;
  try
    Writeln(Linea);
    Flush(Output);
  except
  end;
end;

procedure Principal;
begin
  Opciones := LeerOpciones;
  if Opciones.Ayuda then
  begin
    EscribirAyuda;
    Halt(0);
  end;

  Registrar('Salta Mundos ' + VERSION_JUEGO + ' inicio');
  Sonido := TSonido.Create;
  try
    if Opciones.Silencio then
      Sonido.Silenciar;

    if Opciones.AutoPrueba or (Opciones.Capturar <> '') or (Opciones.Mapa <> '') then
    begin
      Juego := TJuego.Create(nil, Sonido);
      try
        Correcto := True;
        if Opciones.AutoPrueba then
          Correcto := Juego.AutoPrueba;
        if Opciones.Capturar <> '' then
          Juego.Capturar(Opciones.Capturar);
        if Opciones.Mapa <> '' then
          Juego.GuardarMapas(Opciones.Mapa);
      finally
        Juego.Free;
      end;
      if Correcto then
        Halt(0)
      else
        Halt(1);
    end;

    Sonido.Abrir;
    Ventana := TVentana.Create;
    try
      Ventana.Abrir('Salta Mundos ' + VERSION_JUEGO);
      Juego := TJuego.Create(Ventana, Sonido);
      try
        if Opciones.NivelInicial > 0 then
          Juego.EmpezarEnNivel(Opciones.NivelInicial);
        Juego.Ejecutar;
      finally
        Juego.Free;
      end;
    finally
      Ventana.Free;
    end;
  finally
    Sonido.Free;
  end;
end;

begin
  try
    Principal;
  except
    on E: Exception do
    begin
      Registrar('ERROR ' + E.ClassName + ': ' + E.Message);
      Halt(2);
    end;
  end;
end.
