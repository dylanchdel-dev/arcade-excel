$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $root 'juegos\cave-story'
New-Item -Path $target -ItemType Directory -Force | Out-Null
$archive = Join-Path $target 'cave-story-original.zip'
$url = 'https://studiopixel.jp/binaries/dou_1006.zip'
Write-Host 'Descargando Cave Story original desde Studio Pixel...' -ForegroundColor Cyan
try {
  Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing -TimeoutSec 180
  Expand-Archive -Path $archive -DestinationPath $target -Force
  $exe = Get-ChildItem -Path $target -Recurse -File -Filter 'Doukutsu.exe' | Select-Object -First 1
  if (-not $exe) { throw 'El archivo Doukutsu.exe no fue encontrado en el paquete descargado.' }
  Write-Host "Juego disponible en $($exe.FullName)" -ForegroundColor Green
  Write-Host 'Inicia JUGAR_CAVE_STORY_PC.bat desde la raiz del USB.'
} catch { Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
