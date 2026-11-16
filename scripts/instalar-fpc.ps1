<#
.SYNOPSIS
    Instala Free Pascal 3.2.2 para Win64 en un runner de Windows.

.DESCRIPTION
    Descarga el instalador oficial desde SourceForge y lo ejecuta en modo
    silencioso. Si el compilador ya esta presente no hace nada. Se usa tanto
    en la maquina de desarrollo como en el flujo de GitHub Actions.
#>
[CmdletBinding()]
param(
    [string] $Destino = 'C:\fpc322'
)

$ErrorActionPreference = 'Stop'

$compilador = Join-Path $Destino 'bin\i386-win32\ppcrossx64.exe'
if (Test-Path $compilador) {
    Write-Host "Free Pascal ya esta instalado en $Destino"
    exit 0
}

$temporales = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }
$instalador = Join-Path $temporales 'fpc-3.2.2-win.exe'

$urls = @(
    'https://downloads.sourceforge.net/project/freepascal/Win32/3.2.2/fpc-3.2.2.win32.and.win64.exe'
    'https://sourceforge.net/projects/freepascal/files/Win32/3.2.2/fpc-3.2.2.win32.and.win64.exe/download'
)

$descargado = $false
foreach ($url in $urls) {
    try {
        Write-Host "Descargando $url"
        & curl.exe -L --fail --retry 3 --retry-delay 5 --max-time 900 -o $instalador $url
        if ((Test-Path $instalador) -and ((Get-Item $instalador).Length -gt 50MB)) {
            $descargado = $true
            break
        }
    }
    catch {
        Write-Warning "No se pudo descargar desde $url"
    }
}
if (-not $descargado) {
    throw 'No se pudo descargar el instalador de Free Pascal.'
}

Write-Host 'Instalando Free Pascal en modo silencioso'
$proceso = Start-Process -FilePath $instalador -ArgumentList @(
    '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/NOICONS', "/DIR=$Destino"
) -Wait -PassThru
Write-Host "Instalador termino con codigo $($proceso.ExitCode)"

if (-not (Test-Path $compilador)) {
    $alternativas = @(
        'C:\fpc322\bin\i386-win32\ppcrossx64.exe'
        'C:\FPC\3.2.2\bin\i386-win32\ppcrossx64.exe'
        'C:\Program Files\FPC\3.2.2\bin\i386-win32\ppcrossx64.exe'
    )
    foreach ($alternativa in $alternativas) {
        if (Test-Path $alternativa) {
            Write-Host "Compilador encontrado en $alternativa"
            exit 0
        }
    }
    throw 'La instalacion de Free Pascal no dejo el compilador en la ruta esperada.'
}
Write-Host "Free Pascal instalado en $Destino"
