$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $base 'juegos\freedoom'
$temporary = Join-Path $env:TEMP ('arcade-free-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $temporary | Out-Null
try {
  $zip = Join-Path $temporary 'repo.zip'
  Write-Host 'Descargando el juego libre desde GitHub...' -ForegroundColor Cyan
  Invoke-WebRequest -Uri 'https://github.com/danborden1/doom-web/archive/refs/heads/main.zip' -OutFile $zip -UseBasicParsing
  Expand-Archive -LiteralPath $zip -DestinationPath $temporary -Force
  $src = Join-Path $temporary 'doom-web-main'
  $required = @('index.html','freedoom1.wad','websockets-doom.js','websockets-doom.wasm','COPYING','FREEDOOM-COPYING.txt','FREEDOOM-CREDITS.txt')
  foreach($f in $required) { if(!(Test-Path (Join-Path $src $f))) { throw "Falta archivo esperado en origen: $f" } }
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  foreach($f in $required) { Copy-Item -LiteralPath (Join-Path $src $f) -Destination (Join-Path $dest $f) -Force }
  if(Test-Path (Join-Path $src 'default.cfg')) { Copy-Item -LiteralPath (Join-Path $src 'default.cfg') -Destination $dest -Force }
  $wad = Get-Item (Join-Path $dest 'freedoom1.wad')
  $wasm = Get-Item (Join-Path $dest 'websockets-doom.wasm')
  if($wad.Length -lt 10000000 -or $wasm.Length -lt 100000) { throw 'Descarga demasiado pequena; archivos incompletos.' }
  Write-Host "INSTALACION COMPLETA: Freedoom ($([math]::Round($wad.Length / 1MB,1)) MB de datos)." -ForegroundColor Green
  Write-Host 'Ahora ejecuta INICIAR_ARCADE.bat'
} catch { Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
finally { Remove-Item -LiteralPath $temporary -Recurse -Force -ErrorAction SilentlyContinue }
