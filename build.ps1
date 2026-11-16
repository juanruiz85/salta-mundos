<#
.SYNOPSIS
    Compila Salta Mundos con Free Pascal en modo Delphi.

.DESCRIPTION
    Busca el compilador de Free Pascal para Win64, compila el programa y deja
    el ejecutable en la carpeta de salida. Si no se indica otra cosa, usa la
    carpeta build para los archivos intermedios y dist para el binario final.

.EXAMPLE
    ./build.ps1
    ./build.ps1 -OutDir dist -Fpc C:\fpc322\bin\i386-win32\ppcrossx64.exe
#>
[CmdletBinding()]
param(
    [string] $OutDir = 'dist',
    [string] $ObjDir = 'build',
    [string] $Fpc = '',
    [switch] $SinOptimizar
)

$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot
Set-Location $raiz

function Buscar-Compilador {
    param([string] $RutaIndicada)

    $candidatos = New-Object System.Collections.Generic.List[string]
    if ($RutaIndicada) { $candidatos.Add($RutaIndicada) }
    if ($env:FPC) { $candidatos.Add($env:FPC) }
    $candidatos.Add('C:\fpc322\bin\i386-win32\ppcrossx64.exe')
    $candidatos.Add('C:\FPC\3.2.2\bin\i386-win32\ppcrossx64.exe')
    $candidatos.Add('C:\FPC\bin\i386-win32\ppcrossx64.exe')
    $candidatos.Add('C:\Lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe')

    $enPath = Get-Command ppcrossx64.exe -ErrorAction SilentlyContinue
    if ($enPath) { $candidatos.Add($enPath.Source) }
    $fpcPath = Get-Command fpc.exe -ErrorAction SilentlyContinue
    if ($fpcPath) {
        $carpeta = Split-Path $fpcPath.Source -Parent
        $candidatos.Add((Join-Path $carpeta 'ppcrossx64.exe'))
    }

    foreach ($c in $candidatos) {
        if ($c -and (Test-Path $c)) { return (Resolve-Path $c).Path }
    }
    throw 'No se encontro Free Pascal. Instale Free Pascal 3.2.2 o indique la ruta con -Fpc.'
}

$compilador = Buscar-Compilador -RutaIndicada $Fpc
Write-Host "Compilador: $compilador"

$salida = Join-Path $raiz $OutDir
$objetos = Join-Path $raiz $ObjDir
$unidades = Join-Path $objetos 'units'
New-Item -ItemType Directory -Force -Path $salida, $unidades | Out-Null

$argumentos = @(
    '-Mdelphi'
    '-Sh'
    '-vw'
    "-Fu$(Join-Path $raiz 'src')"
    "-FE$salida"
    "-FU$unidades"
)
if (-not $SinOptimizar) {
    $argumentos += '-O2'
    $argumentos += '-Xs'
}

$fuente = Join-Path $raiz 'src\SaltaMundos.dpr'
Write-Host "Compilando $fuente"
& $compilador @argumentos $fuente
if ($LASTEXITCODE -ne 0) {
    throw "La compilacion fallo con codigo $LASTEXITCODE"
}

$exe = Join-Path $salida 'SaltaMundos.exe'
if (-not (Test-Path $exe)) {
    throw "No se genero el ejecutable en $exe"
}
$tamano = [math]::Round((Get-Item $exe).Length / 1KB, 0)
Write-Host "Listo: $exe ($tamano KB)"
