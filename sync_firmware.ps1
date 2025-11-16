# Automatically generate manifests for each .bin in firmware/ then regenerate manifest_list.js
# Usage: .\sync_firmware.ps1

param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$firmwareDir = Join-Path $root 'firmware'
$manifestDir = Join-Path $root 'manifest'

if (-not (Test-Path $firmwareDir)) {
  New-Item -ItemType Directory -Force -Path $firmwareDir | Out-Null
}
if (-not (Test-Path $manifestDir)) {
  New-Item -ItemType Directory -Force -Path $manifestDir | Out-Null
}

function New-ManifestFromBin {
  param(
    [string]$BinPath
  )
  $binName = [System.IO.Path]::GetFileNameWithoutExtension($BinPath)  # ex: FYSETC_E4_10.24c
  # Version = après le dernier underscore
  $idx = $binName.LastIndexOf('_')
  if ($idx -le 0) {
    Write-Host ("Skipped (unexpected name): " + $binName) -ForegroundColor Yellow
    return
  }
  $projectSlug = $binName.Substring(0, $idx)       # ex: FYSETC_E4
  $version = $binName.Substring($idx + 1)          # ex: 10.24c
  $projectName = $projectSlug -replace '_',' '     # ex: FYSETC E4
  $manifestFile = Join-Path $manifestDir ("manifest_" + $binName + ".json")

  if (Test-Path $manifestFile) {
    Write-Host ("Manifest already exists: " + (Split-Path $manifestFile -Leaf)) -ForegroundColor DarkGray
    return
  }

  $content = @{
    name    = $projectName
    version = $version
    builds  = @(
      @{
        chipFamily = 'ESP32'
        parts = @(
          @{
            path = "firmware/$($binName).bin"
            offset = 0
          }
        )
      }
    )
  } | ConvertTo-Json -Depth 10

  Set-Content -Path $manifestFile -Value $content -Encoding UTF8
  Write-Host ("Created: " + (Split-Path $manifestFile -Leaf)) -ForegroundColor Green
}

Get-ChildItem -Path $firmwareDir -Filter *.bin -File | ForEach-Object {
  New-ManifestFromBin -BinPath $_.FullName
}

# Régénérer la liste des manifests pour l'UI
if (Test-Path (Join-Path $root 'list_manifests.ps1')) {
  Write-Host "Generating manifest_list.js ..." -ForegroundColor Cyan
  & (Join-Path $root 'list_manifests.ps1')
} else {
  Write-Host "list_manifests.ps1 not found, skipping." -ForegroundColor Yellow
}

Write-Host "Sync completed." -ForegroundColor Green

