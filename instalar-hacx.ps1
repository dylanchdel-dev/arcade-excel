$ErrorActionPreference='Stop'
$base=Split-Path -Parent $MyInvocation.MyCommand.Path
$phase1=Join-Path $base 'juegos\freedoom'
$target=Join-Path $base 'juegos\hacx'
$temp=Join-Path $env:TEMP ('arcade-hacx-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
  $needed=@('index.html','websockets-doom.js','websockets-doom.wasm')
  foreach($n in $needed){if(!(Test-Path (Join-Path $phase1 $n))){throw "Falta motor web $n; ejecuta INSTALAR_JUEGO_1.bat primero."}}
  $archive=Join-Path $temp 'hacx12.zip'
  Write-Host 'Descargando HacX 1.2 del sitio oficial de su autor...' -ForegroundColor Cyan
  Invoke-WebRequest -Uri 'https://drnostromo.com/hacx/files/hacx12.zip' -OutFile $archive -UseBasicParsing
  Expand-Archive -LiteralPath $archive -DestinationPath (Join-Path $temp 'extraido')
  $wads=@(Get-ChildItem -Path (Join-Path $temp 'extraido') -Recurse -File | Where-Object {$_.Name -ieq 'hacx.wad'})
  if($wads.Count -ne 1){throw 'El paquete oficial no contiene exactamente un HACX.WAD.'}
  # El IWAD 1.2 debe medir 19.321.722 bytes segun la base de hashes de Libretro.
  if($wads[0].Length -ne 19321722){throw "Tamano inesperado de HACX.WAD: $($wads[0].Length)"}
  $md5=(Get-FileHash -LiteralPath $wads[0].FullName -Algorithm MD5).Hash.ToLowerInvariant()
  if($md5 -ne '65ed74d522bdf6649c2831b13b9e02b4'){throw 'HACX.WAD no coincide con el hash oficial conocido.'}
  $stage=Join-Path $temp 'stage';New-Item -ItemType Directory -Path $stage | Out-Null
  foreach($n in $needed){Copy-Item -LiteralPath (Join-Path $phase1 $n) -Destination (Join-Path $stage $n)}
  foreach($n in @('COPYING','default.cfg')){if(Test-Path (Join-Path $phase1 $n)){Copy-Item -LiteralPath (Join-Path $phase1 $n) -Destination $stage}}
  Copy-Item -LiteralPath $wads[0].FullName -Destination (Join-Path $stage 'hacx.wad')
  $html=Join-Path $stage 'index.html';$content=[IO.File]::ReadAllText($html)
  if(!$content.Contains('freedoom1.wad')){throw 'El motor cambio y no se puede configurar automaticamente.'}
  $content=$content.Replace('freedoom1.wad','hacx.wad')
  [IO.File]::WriteAllText($html,$content,(New-Object Text.UTF8Encoding($false)))
  # La compatibilidad total de HacX con este motor WebAssembly no esta comprobada.
  New-Item -ItemType Directory -Force -Path $target | Out-Null
  Copy-Item -Path (Join-Path $stage '*') -Destination $target -Force
  Write-Host 'Archivos instalados; HacX pendiente de validacion en navegador.' -ForegroundColor Green
} catch { Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
finally{Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue}
