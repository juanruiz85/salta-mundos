Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class Ventana {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
  [DllImport("user32.dll", CharSet = CharSet.Ansi)] public static extern int GetWindowTextA(IntPtr hWnd, StringBuilder texto, int maximo);
  public struct RECT { public int Left, Top, Right, Bottom; }
}
"@

$topmost = [IntPtr](-1)
$noActivar = 0x0010
$mostrar = 0x0040

# Se arranca el juego sin argumentos para revisar el menu inicial.
$proc = Start-Process -FilePath "dist\SaltaMundos.exe" -PassThru
Start-Sleep -Seconds 2
$proc.Refresh()
$handle = $proc.MainWindowHandle

$texto = New-Object System.Text.StringBuilder 260
[Ventana]::GetWindowTextA($handle, $texto, 260) | Out-Null
Write-Host ("Titulo real: [" + $texto.ToString() + "]")

$rect = New-Object Ventana+RECT
[Ventana]::GetWindowRect($handle, [ref]$rect) | Out-Null
$ancho = $rect.Right - $rect.Left
$alto = $rect.Bottom - $rect.Top
Write-Host "Ventana: $ancho x $alto"

[Ventana]::SetWindowPos($handle, $topmost, 0, 0, $ancho, $alto, $mostrar) | Out-Null
Start-Sleep -Milliseconds 1200

$bmp = New-Object System.Drawing.Bitmap $ancho, $alto
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen(0, 0, 0, 0, $bmp.Size)
$g.Dispose()
$bmp.Save((Join-Path (Get-Location) "build\menu-ventana.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Start-Sleep -Seconds 1
$proc.Refresh()
Write-Host ("Sigue vivo: " + (-not $proc.HasExited) + "  CPU=" + [math]::Round($proc.TotalProcessorTime.TotalSeconds, 2))
if (-not $proc.HasExited) { $proc.Kill() }
Write-Host "cerrado"
