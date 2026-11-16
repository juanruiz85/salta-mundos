program hoja;
{ Herramienta de desarrollo: arma una hoja de contactos con todos los
  sprites para revisar el dibujo sin abrir el juego. }
{$MODE DELPHI}{$H+}
uses
  SysUtils, GMCore, GMSuperficie, GMSprites;
var
  H: TSpritesHeroe;
  E: TSpritesEnemigos;
  O: TSpritesObjetos;
  T: TTiles;
  L: TSuperficie;
  X, Y, I: Integer;

  procedure Celda(Col, Fila: Integer; S: TSuperficie; const Nombre: string);
  var
    CX, CY: Integer;
  begin
    CX := 4 + Col * 44;
    CY := 4 + Fila * 58;
    L.Marco(CX, CY, 40, 40, RGBc(60, 60, 80));
    if S <> nil then
      L.Copiar(CX + (40 - S.Ancho) div 2, CY + (40 - S.Alto) div 2, S, False);
    L.Texto(CX, CY + 42, Nombre, RGBc(20, 20, 30), 1);
  end;

begin
  H := TSpritesHeroe.Create;
  E := TSpritesEnemigos.Create;
  O := TSpritesObjetos.Create;
  T := ConstruirTiles(RGBc(150, 100, 60), RGBc(96, 170, 72), RGBc(186, 96, 52),
    RGBc(96, 52, 30), RGBc(48, 152, 84), RGBc(140, 220, 140));
  L := TSuperficie.Create(452, 300);
  L.Limpiar(RGBc(226, 232, 240));
  Celda(0, 0, H.Quieto, 'QUIETO');
  Celda(1, 0, H.Corre[0], 'CORRE1');
  Celda(2, 0, H.Corre[1], 'CORRE2');
  Celda(3, 0, H.Corre[2], 'CORRE3');
  Celda(4, 0, H.Salto, 'SALTO');
  Celda(5, 0, H.Caida, 'CAIDA');
  Celda(6, 0, H.Muerto, 'MUERTO');
  Celda(7, 0, E.Bicho[0], 'BICHO1');
  Celda(8, 0, E.Bicho[1], 'BICHO2');
  Celda(9, 0, E.Pua[0], 'PUA1');
  Celda(0, 1, E.Pua[1], 'PUA2');
  Celda(1, 1, E.Mosca[0], 'MOSCA1');
  Celda(2, 1, E.Mosca[1], 'MOSCA2');
  Celda(3, 1, O.Moneda[0], 'TUERCA1');
  Celda(4, 1, O.Moneda[1], 'TUERCA2');
  Celda(5, 1, O.Moneda[2], 'TUERCA3');
  Celda(6, 1, O.Moneda[3], 'TUERCA4');
  Celda(7, 1, O.Escudo, 'ESCUDO');
  Celda(8, 1, O.Chispa[0], 'CHISPA');
  Celda(0, 2, T.Tierra, 'TIERRA');
  Celda(1, 2, T.Ladrillo, 'LADRILLO');
  Celda(2, 2, T.Caja[0], 'CAJA0');
  Celda(3, 2, T.Caja[1], 'CAJA1');
  Celda(4, 2, T.Caja[2], 'CAJA2');
  Celda(5, 2, T.CajaUsada, 'USADA');
  Celda(6, 2, T.TuboTapaIzq, 'TUBO T I');
  Celda(7, 2, T.TuboTapaDer, 'TUBO T D');
  Celda(8, 2, T.TuboCuerpoIzq, 'TUBO C I');
  Celda(9, 2, T.TuboCuerpoDer, 'TUBO C D');
  Celda(0, 3, T.Viga, 'VIGA');
  { Tira de suelo y tuberia para ver como encajan. }
  for I := 0 to 15 do
  begin
    L.Copiar(4 + I * 16, 244, T.Tierra, False);
    L.Copiar(4 + I * 16, 264, T.Ladrillo, False);
  end;
  L.Copiar(300, 214, T.TuboTapaIzq, False);
  L.Copiar(316, 214, T.TuboTapaDer, False);
  L.Copiar(300, 230, T.TuboCuerpoIzq, False);
  L.Copiar(316, 230, T.TuboCuerpoDer, False);
  L.GuardarBMP('build\hoja.bmp');
  L.Free;
  T.Free;
  H.Free;
  E.Free;
  O.Free;
  Writeln('hoja lista');
end.
