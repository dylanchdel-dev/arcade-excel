$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$phase1 = Join-Path $base 'juegos\freedoom'
$dest = Join-Path $base 'juegos\freedoom2'
$temp = Join-Path $env:TEMP ('arcade-phase2-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $temp | Out-Null
try {
  $engineFiles = @('index.html', 'websockets-doom.js', 'websockets-doom.wasm', 'COPYING')
  foreach ($f in $engineFiles) { if (!(Test-Path -LiteralPath (Join-Path $phase1 $f))) { throw "Primero ejecuta INSTALAR_JUEGO_1.bat: falta $f" } }
  $zip = Join-Path $temp 'freedoom.zip'
  Write-Host 'Descargando Freedoom Phase 2 v0.13.0 desde la publicacion oficial...' -ForegroundColor Cyan
  Invoke-WebRequest -Uri 'https://github.com/freedoom/freedoom/releases/download/v0.13.0/freedoom-0.13.0.zip' -OutFile $zip -UseBasicParsing
  Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $temp 'extraido') -Force
  $wadFiles = @(Get-ChildItem -LiteralPath (Join-Path $temp 'extraido') -Filter 'freedoom2.wad' -Recurse -File)
  if ($wadFiles.Count -ne 1) { throw 'No se encontro exactamente un freedoom2.wad en el paquete oficial.' }
  if ($wadFiles[0].Length -lt 10000000) { throw 'El archivo freedoom2.wad es inesperadamente pequeno.' }
  $staging = Join-Path $temp 'staging'; New-Item -ItemType Directory -Force -Path $staging | Out-Null
  foreach ($f in $engineFiles) { Copy-Item -LiteralPath (Join-Path $phase1 $f) -Destination (Join-Path $staging $f) }
  foreach ($f in @('FREEDOOM-COPYING.txt','FREEDOOM-CREDITS.txt','default.cfg')) { if (Test-Path (Join-Path $phase1 $f)) { Copy-Item -LiteralPath (Join-Path $phase1 $f) -Destination (Join-Path $staging $f) } }
  Copy-Item -LiteralPath $wadFiles[0].FullName -Destination (Join-Path $staging 'freedoom2.wad')
  $htmlFile = Join-Path $staging 'index.html'
  $content = [IO.File]::ReadAllText($htmlFile)
  if (-not $content.Contains('freedoom1.wad')) { throw 'El motor web cambio: no se puede configurar Phase 2 de forma segura.' }
  $content = $content.Replace('freedoom1.wad', 'freedoom2.wad')
  [IO.File]::WriteAllText($htmlFile,$content, (New-Object Text.UTF8Encoding($false)))
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Copy-Item -Path (Join-Path $staging '*') -Destination $dest -Force
  Write-Host 'Phase 2 descargado y configurado. Inicia INICIAR_ARCADE.bat y pulsa JUGAR PHASE 2.' -ForegroundColor Green
  Write-Host 'Nota: esta configuracion necesita ser probada en tu navegador Windows.' -ForegroundColor Yellow
} catch { Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
finally { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
