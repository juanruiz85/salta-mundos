import io

p = 'src/GMJuego.pas'
s = io.open(p, encoding='utf-8').read()

viejo = """procedure TJuego.Ejecutar;
begin
  while FVentana.ProcesarMensajes do
  begin
    LeerTeclas;
    Actualizar;
    Dibujar;
    FVentana.Presentar;
    FVentana.EsperarSiguienteFotograma;
  end;
end;"""
nuevo = """procedure TJuego.Ejecutar;
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
end;"""
assert viejo in s, 'no se encontro Ejecutar'
s = s.replace(viejo, nuevo)

marca = "  { 6. Dibujo de los seis niveles sin ventana. }"
prueba = """  Registrar('Paso 7: entrada por flanco');
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

"""
assert marca in s, 'no se encontro la marca del paso 6'
s = s.replace(marca, prueba + marca, 1)
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('ok')
