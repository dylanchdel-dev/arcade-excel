$ErrorActionPreference='Stop'
$base=Split-Path -Parent $MyInvocation.MyCommand.Path
$motor=Join-Path $base 'juegos\freedoom'
$target=Join-Path $base 'juegos\chexquest3'
$wad=Join-Path $base 'ARCHIVOS_PROPIOS\CHEX3.WAD'
if (!(Test-Path $wad)) { Write-Host 'Falta ARCHIVOS_PROPIOS\CHEX3.WAD. Obtenlo de la descarga oficial https://www.chexquest3.com/downloads/ (version compatible; no todos los formatos funcionan con este motor).' -ForegroundColor Yellow; exit 1 }
$required=@('index.html','websockets-doom.js','websockets-doom.wasm')
foreach($n in $required){if(!(Test-Path (Join-Path $motor $n))){Write-Host "Falta $n del motor base: ejecuta INSTALAR_JUEGO_1.bat." -ForegroundColor Red;exit 1}}
New-Item -ItemType Directory -Force -Path $target | Out-Null
foreach($n in $required){Copy-Item -LiteralPath (Join-Path $motor $n) -Destination (Join-Path $target $n) -Force}
Copy-Item -LiteralPath $wad -Destination (Join-Path $target 'chex3.wad') -Force
$page=Join-Path $target 'index.html'
$content=[IO.File]::ReadAllText($page)
if (!$content.Contains('freedoom1.wad')) { Write-Host 'Motor no compatible con la sustitucion automatica de WAD. No se puede garantizar soporte Chex3.' -ForegroundColor Red; exit 1 }
$content=$content.Replace('freedoom1.wad','chex3.wad')
[IO.File]::WriteAllText($page,$content,(New-Object Text.UTF8Encoding($false)))
Write-Host 'Preparacion experimental terminada. El motor web podria no admitir Chex Quest 3; verificar despues.' -ForegroundColor Yellow
