unit GMCodigos;
{ Codigos de nivel. Cada mundo tiene un codigo de cuatro caracteres que se
  muestra al terminar el mundo anterior y que se puede escribir en el menu
  para empezar directamente en el.

  El codigo se calcula con una mezcla sencilla a partir del numero de nivel,
  de modo que no se parece a una secuencia y no depende de guardar nada en
  disco. El alfabeto evita los caracteres que se confunden al leerlos
  (I, O, 0 y 1). }

{$MODE DELPHI}
{$H+}

interface

uses
  SysUtils,
  GMNiveles;

const
  LARGO_CODIGO = 4;
  ALFABETO_CODIGO = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function CodigoDeNivel(Numero: Integer): string;
function NivelDeCodigo(const Codigo: string): Integer;
function CodigoValido(const Codigo: string): Boolean;
procedure LimpiarCodigo(var Codigo: string);

implementation

function Mezclar(Valor: Cardinal): Cardinal;
begin
  { Mezcla tipo xorshift multiplicativa: suficiente para que los codigos no
    sigan el orden de los niveles. }
  Result := Valor;
  Result := Result xor (Result shr 13);
  Result := Result * 2654435761;
  Result := Result xor (Result shr 11);
  Result := Result * 2246822519;
  Result := Result xor (Result shr 15);
end;

function CodigoDeNivel(Numero: Integer): string;
var
  Valor: Cardinal;
  I: Integer;
begin
  Valor := Mezclar(Cardinal(Numero) * 7919 + 104729);
  Result := '';
  for I := 1 to LARGO_CODIGO do
  begin
    Result := Result + ALFABETO_CODIGO[(Valor mod Length(ALFABETO_CODIGO)) + 1];
    Valor := Valor div Length(ALFABETO_CODIGO);
    Valor := Mezclar(Valor + Cardinal(I));
  end;
end;

procedure LimpiarCodigo(var Codigo: string);
var
  I: Integer;
  Limpio: string;
begin
  Limpio := '';
  for I := 1 to Length(Codigo) do
    if Pos(UpCase(Codigo[I]), ALFABETO_CODIGO) > 0 then
      Limpio := Limpio + UpCase(Codigo[I]);
  Codigo := Copy(Limpio, 1, LARGO_CODIGO);
end;

function CodigoValido(const Codigo: string): Boolean;
var
  Limpio: string;
begin
  Limpio := Codigo;
  LimpiarCodigo(Limpio);
  Result := Length(Limpio) = LARGO_CODIGO;
end;

function NivelDeCodigo(const Codigo: string): Integer;
var
  Numero: Integer;
  Limpio: string;
begin
  Result := 0;
  Limpio := Codigo;
  LimpiarCodigo(Limpio);
  if Length(Limpio) <> LARGO_CODIGO then
    Exit;
  for Numero := 1 to TOTAL_NIVELES do
    if CodigoDeNivel(Numero) = Limpio then
    begin
      Result := Numero;
      Exit;
    end;
end;

end.
