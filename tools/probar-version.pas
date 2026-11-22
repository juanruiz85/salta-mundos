program probar_version;
{ Herramienta de desarrollo: comprueba la consulta de version en GitHub sin
  abrir el juego. }
{$MODE DELPHI}{$H+}
{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  GMCore,
  GMActualizacion;

var
  Comprobador: TComprobadorActualizaciones;
  I: Integer;
begin
  Comprobador := TComprobadorActualizaciones.Create;
  if ParamCount >= 1 then
    Comprobador.VersionLocal := ParamStr(1);
  Writeln('Version local: ', Comprobador.VersionLocal);
  try
    Comprobador.Consultar;
    for I := 1 to 40 do
    begin
      Sleep(500);
      if Comprobador.Estado <> acConsultando then
        Break;
    end;
    Writeln('Estado: ', Ord(Comprobador.Estado));
    Writeln('Etiqueta remota: [', Comprobador.Etiqueta, ']');
    Writeln('Texto: ', Comprobador.TextoEstado);
    Writeln('Hay version nueva: ', Comprobador.HayVersionNueva);
  finally
    Comprobador.Free;
  end;
end.
