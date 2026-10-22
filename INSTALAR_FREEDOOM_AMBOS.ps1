$ErrorActionPreference='Stop'
$root=Split-Path -Parent $MyInvocation.MyCommand.Path
$games=Join-Path $root 'juegos'
$tmp=Join-Path $env:TEMP ('arcade-freedoom-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
function Fetch([string]$url,[string]$out) {
  Write-Host "Descargando $url" -ForegroundColor Cyan
  Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -MaximumRedirection 8
  if (!(Test-Path $out) -or (Get-Item $out).Length -lt 1000) { throw "Descarga incompleta: $url" }
}
function Check-Wad([string]$path) {
  $bytes=[System.IO.File]::ReadAllBytes($path)
  if ($bytes.Length -lt 10000000) { throw "WAD demasiado pequeno: $path" }
  $sig=[System.Text.Encoding]::ASCII.GetString($bytes,0,4)
  if ($sig -ne 'IWAD') { throw "Cabecera WAD incorrecta: $path ($sig)" }
}
try {
  # Fuente del motor browser ya emparejado con Phase 1; datos de ambas fases oficiales.
  Fetch 'https://github.com/danborden1/doom-web/archive/refs/heads/main.zip' (Join-Path $tmp 'engine.zip')
  Fetch 'https://github.com/freedoom/freedoom/releases/download/v0.13.0/freedoom-0.13.0.zip' (Join-Path $tmp 'freedoom.zip')
  Expand-Archive -LiteralPath (Join-Path $tmp 'engine.zip') -DestinationPath (Join-Path $tmp 'engine')
  Expand-Archive -LiteralPath (Join-Path $tmp 'freedoom.zip') -DestinationPath (Join-Path $tmp 'data')
  $engine=Join-Path $tmp 'engine\doom-web-main'
  foreach($f in @('index.html','websockets-doom.js','websockets-doom.wasm','COPYING','FREEDOOM-COPYING.txt','FREEDOOM-CREDITS.txt')) {
     if (!(Test-Path (Join-Path $engine $f))) { throw "Motor incompleto: $f" }
  }
  $wads=@(Get-ChildItem (Join-Path $tmp 'data') -Filter 'freedoom*.wad' -File -Recurse)
  $w1=@($wads|Where-Object Name -eq 'freedoom1.wad'); $w2=@($wads|Where-Object Name -eq 'freedoom2.wad')
  if($w1.Count -ne 1 -or $w2.Count -ne 1) { throw 'El paquete oficial no contiene ambos WAD esperados.' }
  Check-Wad $w1[0].FullName; Check-Wad $w2[0].FullName
  $html=[IO.File]::ReadAllText((Join-Path $engine 'index.html'))
  if(!$html.Contains('freedoom1.wad')) { throw 'La pagina del motor cambio; revisar antes de instalar.' }
  foreach($phase in @(1,2)) {
    $stage=Join-Path $tmp "stage$phase";New-Item -ItemType Directory -Force -Path $stage | Out-Null
    foreach($f in @('index.html','websockets-doom.js','websockets-doom.wasm','COPYING','FREEDOOM-COPYING.txt','FREEDOOM-CREDITS.txt','default.cfg')) {
       if(Test-Path (Join-Path $engine $f)) {Copy-Item (Join-Path $engine $f) $stage}
    }
    if($phase -eq 1){$wad=$w1[0].FullName;$out='freedoom'}else{$wad=$w2[0].FullName;$out='freedoom2';$patched=$html.Replace('freedoom1.wad','freedoom2.wad');[IO.File]::WriteAllText((Join-Path $stage 'index.html'),$patched,(New-Object Text.UTF8Encoding($false)))}
    Copy-Item $wad (Join-Path $stage "freedoom$phase.wad")
    $target=Join-Path $games $out
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    Copy-Item (Join-Path $stage '*') $target -Force
    Write-Host "Phase $phase instalada: $target" -ForegroundColor Green
  }
  Write-Host 'Instalacion de ambas campanas terminada. Ejecuta INICIAR_ARCADE.bat.' -ForegroundColor Green
} catch {Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red; exit 1}
finally{Remove-Item $tmp -Force -Recurse -ErrorAction SilentlyContinue}
