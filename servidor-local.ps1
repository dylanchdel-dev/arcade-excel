$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8765/')
try { $listener.Start() } catch { Write-Host 'No se pudo iniciar puerto 8765. Cierra otros servidores y reintenta.'; exit 1 }
Write-Host 'Arcade activo: http://localhost:8765/ (Ctrl+C para detenerlo)' -ForegroundColor Green
Start-Process 'http://localhost:8765/'
$mimes = @{ '.html'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8'; '.wasm'='application/wasm'; '.wad'='application/octet-stream'; '.cfg'='text/plain'; '.txt'='text/plain'; '.css'='text/css'; '.png'='image/png' }
try {
 while ($listener.IsListening) {
  $ctx=$listener.GetContext(); $path=[uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
  if (!$path) {$path='index.html'}
  $file=[IO.Path]::GetFullPath((Join-Path $root $path))
  if(!$file.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -and $file -ne (Join-Path $root 'index.html')){ $ctx.Response.StatusCode=403; $ctx.Response.Close(); continue }
  if(!(Test-Path -LiteralPath $file -PathType Leaf)){ $ctx.Response.StatusCode=404; $ctx.Response.Close(); continue }
  $ext=[IO.Path]::GetExtension($file).ToLowerInvariant();$ctx.Response.ContentType= $(if($mimes.ContainsKey($ext)){$mimes[$ext]}else{'application/octet-stream'})
  $info=Get-Item -LiteralPath $file; $ctx.Response.ContentLength64=$info.Length
  if($ctx.Request.HttpMethod -ne 'HEAD') { $f=[IO.File]::OpenRead($file);try{$f.CopyTo($ctx.Response.OutputStream)}finally{$f.Dispose()} }
  $ctx.Response.OutputStream.Close()
 }
} finally { $listener.Stop(); $listener.Close() }
