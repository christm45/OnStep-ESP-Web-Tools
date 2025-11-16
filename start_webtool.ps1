# Start a local server and open the flashing UI in the browser
# Usage: .\start_webtool.ps1 [-Port 8000]

param(
    [int]$Port = 8000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-Command {
    param([string]$Name)
    try {
        $null = Get-Command $Name -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Start-PythonServer {
    param([int]$Port)
    Write-Host "Starting Python server at http://localhost:$Port ..." -ForegroundColor Cyan
    Start-Process -WindowStyle Hidden -FilePath python -ArgumentList @('-m','http.server',"$Port") -WorkingDirectory $PSScriptRoot
}

function Start-NodeServer {
    param([int]$Port)
    Write-Host "Starting Node server (npx serve) at http://localhost:$Port ..." -ForegroundColor Cyan
    Start-Process -WindowStyle Hidden -FilePath npx -ArgumentList @('serve','-l',"$Port",".") -WorkingDirectory $PSScriptRoot
}

function Start-PowerShellServer {
    param([int]$Port)
    Write-Host "Starting built-in PowerShell server at http://localhost:$Port ..." -ForegroundColor Cyan
    $script = @'
Add-Type -AssemblyName System.Net.HttpListener
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:PORT/".Replace("PORT","' + $Port + '"))
$listener.Start()
Write-Host "Server ready."
try {
  while ($true) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response
    $path = $req.Url.AbsolutePath.TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($path)) { $path = 'index.html' }
    $localPath = [System.IO.Path]::GetFullPath((Join-Path "' + $PSScriptRoot.Replace('\','\\') + '" $path))
    if (-not $localPath.StartsWith("' + $PSScriptRoot.Replace('\','\\') + '")) {
      $res.StatusCode = 403; $res.Close(); continue
    }
    if (-not (Test-Path $localPath)) {
      $res.StatusCode = 404; $res.Close(); continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($localPath)
    $ext = [System.IO.Path]::GetExtension($localPath).ToLowerInvariant()
    $mime = switch ($ext) {
      '.html' { 'text/html; charset=UTF-8' }
      '.js'   { 'text/javascript; charset=UTF-8' }
      '.css'  { 'text/css; charset=UTF-8' }
      '.json' { 'application/json; charset=UTF-8' }
      '.png'  { 'image/png' }
      '.jpg'  { 'image/jpeg' }
      '.jpeg' { 'image/jpeg' }
      '.gif'  { 'image/gif' }
      '.svg'  { 'image/svg+xml' }
      '.bin'  { 'application/octet-stream' }
      default { 'application/octet-stream' }
    }
    $res.Headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    $res.ContentType = $mime
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.Close()
  }
} finally {
  $listener.Stop()
}
'@
    Start-Job -ScriptBlock ([ScriptBlock]::Create($script)) | Out-Null
}

# Choisir la meilleure option disponible
if (Test-Command python) {
    Start-PythonServer -Port $Port
} elseif (Test-Command npx) {
    Start-NodeServer -Port $Port
} else {
    Start-PowerShellServer -Port $Port
}

Start-Sleep -Seconds 1

# Ouvrir le navigateur par défaut
$url = "http://localhost:$Port/index.html"
Write-Host "Opening browser at $url" -ForegroundColor Green
Start-Process $url

Write-Host ""
Write-Host "Do not close this window while using the tool." -ForegroundColor Yellow
Write-Host "When finished, press Ctrl+C if the server is in the foreground." -ForegroundColor DarkGray

