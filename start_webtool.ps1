# Start a local server and open the flashing UI in the browser
# Usage: .\start_webtool.ps1 [-Port 8000]

param(
    [int]$Port = 8000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Detect if launched by Explorer; keep window open on early errors too
$script:LaunchedByExplorer = $false
try {
    $ppid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
    $pname = (Get-Process -Id $ppid -ErrorAction SilentlyContinue).ProcessName
    $script:LaunchedByExplorer = $pname -eq 'explorer'
} catch {}
function Test-ExplorerLaunch {
    param([int]$StartPid = $PID)
    try {
        $current = Get-CimInstance Win32_Process -Filter "ProcessId=$StartPid"
        for ($i=0; $i -lt 5 -and $null -ne $current; $i++) {
            $name = $current.Name
            if ($name -eq 'explorer.exe') { return $true }
            if ($current.ParentProcessId -le 0) { break }
            $current = Get-CimInstance Win32_Process -Filter "ProcessId=$($current.ParentProcessId)"
        }
    } catch {}
    return $false
}
$script:LaunchedByExplorer = $script:LaunchedByExplorer -or (Test-ExplorerLaunch -StartPid $PID)
trap {
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    if ($script:LaunchedByExplorer) { Read-Host "Press Enter to close this window" }
    break
}

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
    $proc = Start-Process -PassThru -WindowStyle Hidden -FilePath python -ArgumentList @('-m','http.server',"$Port") -WorkingDirectory $PSScriptRoot
    return $proc
}

function Start-NodeServer {
    param([int]$Port)
    Write-Host "Starting Node server (npx serve) at http://localhost:$Port ..." -ForegroundColor Cyan
    $proc = Start-Process -PassThru -WindowStyle Hidden -FilePath npx -ArgumentList @('serve','-l',"$Port",".") -WorkingDirectory $PSScriptRoot
    return $proc
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
    $job = Start-Job -ScriptBlock ([ScriptBlock]::Create($script))
    return $job
}

# Choose best available option and keep a handle
$serverProc = $null
$serverJob = $null
if (Test-Command python) {
    $serverProc = Start-PythonServer -Port $Port
} elseif (Test-Command npx) {
    $serverProc = Start-NodeServer -Port $Port
} else {
    $serverJob = Start-PowerShellServer -Port $Port
}

Start-Sleep -Seconds 1

# Ouvrir le navigateur par défaut
$url = "http://localhost:$Port/index.html"
Write-Host "Opening browser at $url" -ForegroundColor Green
Start-Process $url

Write-Host ""
Write-Host "Server is running on http://localhost:$Port" -ForegroundColor Yellow
Write-Host "Press Enter to stop the server and close this window..." -ForegroundColor DarkGray
Read-Host | Out-Null

# Stop server when user is done
try {
    if ($serverProc -ne $null) {
        Stop-Process -Id $serverProc.Id -Force -ErrorAction SilentlyContinue
    }
    if ($serverJob -ne $null) {
        Stop-Job -Job $serverJob -Force -ErrorAction SilentlyContinue
        Remove-Job -Job $serverJob -Force -ErrorAction SilentlyContinue
    }
} catch {}

