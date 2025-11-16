# Script to create merged OnStep firmware binaries from Arduino IDE
# Usage: Copy the esptool command from Arduino IDE (with verbose upload ON)
#        then paste it when prompted or pass it via -CommandLine

param(
    [Parameter(Mandatory=$false)]
    [string]$CommandLine = '',
    
    [Parameter(Mandatory=$false)]
    [string]$Version = '',
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = '',
    
    [Parameter(Mandatory=$false)]
    [string]$ChipFamily = 'ESP32'
)

# Detect if launched by Explorer and install a global trap to keep window open on unexpected errors
try {
    $ppid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
    $pname = (Get-Process -Id $ppid -ErrorAction SilentlyContinue).ProcessName
    $script:LaunchedByExplorer = $pname -eq 'explorer'
} catch { $script:LaunchedByExplorer = $false }
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

# Ask interactively if not provided
function Get-EsptoolLineFromText {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $lines = $Text -split "(`r`n|`n|`r)"
    foreach ($ln in $lines) {
        $trim = $ln.Trim()
        if ($trim -match '(?i)esptool\.exe') { return $trim }
    }
    return ""
}

if ([string]::IsNullOrEmpty($CommandLine)) {
    Write-Host "=== OnStep Firmware Binary Maker ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Instructions:" -ForegroundColor Yellow
    Write-Host "1. Build in Arduino IDE with 'Verbose Output During Upload' enabled"
    Write-Host "2. Copy the single line that starts with the full path to esptool.exe" -ForegroundColor Yellow
    Write-Host "3. With that line in your clipboard, press Enter here (no pasting needed)" -ForegroundColor Yellow
    Write-Host ""
    for ($try=0; $try -lt 3 -and [string]::IsNullOrEmpty($CommandLine); $try++) {
        $null = Read-Host "Press Enter after copying the esptool.exe line to the clipboard"
        try {
            $clip = Get-Clipboard -Raw
        } catch {
            $clip = ""
        }
        $candidate = Get-EsptoolLineFromText -Text $clip
        if (-not [string]::IsNullOrEmpty($candidate)) {
            $CommandLine = $candidate
            break
        }
        # As a fallback allow manual single-line input
        if ($try -eq 2) {
            Write-Host ""
            Write-Host "Clipboard did not contain an 'esptool.exe' line." -ForegroundColor Yellow
            Write-Host "Please paste ONLY the single 'esptool.exe ...' line below and press Enter." -ForegroundColor Yellow
            $CommandLine = Read-Host "esptool.exe command"
        }
    }
}

if ([string]::IsNullOrEmpty($Version)) {
    $Version = Read-Host "Enter firmware version (e.g. 10.24c)"
}

if ([string]::IsNullOrEmpty($ProjectName)) {
    $ProjectName = Read-Host "Enter project name (e.g. FYSETC E4)"
}

# Auto-detect chip family from command
if ($CommandLine -match '--chip\s+(\w+)') {
    $detectedChip = $matches[1]
    if ($detectedChip -match 'esp32') {
        if ($CommandLine -match 'esp32s2') {
            $ChipFamily = 'ESP32-S2'
        } elseif ($CommandLine -match 'esp32s3') {
            $ChipFamily = 'ESP32-S3'
        } elseif ($CommandLine -match 'esp32c3') {
            $ChipFamily = 'ESP32-C3'
        } else {
            $ChipFamily = 'ESP32'
        }
    } elseif ($detectedChip -match 'esp8266') {
        $ChipFamily = 'ESP8266'
    }
    Write-Host "Detected chip: $ChipFamily" -ForegroundColor Green
}

# Sanitize project name and version for filenames
$filePrefix = $ProjectName -replace '[^\w]', '_'
if ($Version -notmatch '^[0-9A-Za-z._-]+$') {
    Write-Host "Note: normalizing version value. Use firmware version only (e.g. 10.24c), not tool output." -ForegroundColor Yellow
}
$Version = ($Version -replace '[^0-9A-Za-z._-]','_')
$fileName = "${filePrefix}_${Version}.bin"
$manifestFileName = "manifest_${filePrefix}_${Version}.json"

# Ensure folders exist
$firmwareDir = Join-Path $PSScriptRoot "firmware"
$manifestDir = Join-Path $PSScriptRoot "manifest"

if (-not (Test-Path $firmwareDir)) {
    New-Item -ItemType Directory -Path $firmwareDir -Force | Out-Null
    Write-Host "'firmware' folder created" -ForegroundColor Green
}

if (-not (Test-Path $manifestDir)) {
    New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
    Write-Host "'manifest' folder created" -ForegroundColor Green
}

# Extract flash params from command
$flashMode = 'dio'
$flashFreq = '80m'
$flashSize = '4MB'

if ($CommandLine -match '--flash_mode\s+(\w+)') {
    $flashMode = $matches[1]
}
if ($CommandLine -match '--flash_freq\s+(\w+)') {
    $flashFreq = $matches[1]
}
if ($CommandLine -match '--flash_size\s+(\w+)') {
    $flashSize = $matches[1]
}

# Extract esptool.exe path
$esptoolPath = ''
if ($CommandLine -match '([^\s]+esptool\.exe)') {
    $esptoolPath = $matches[1]
    Write-Host "Found esptool: $esptoolPath" -ForegroundColor Green
} else {
    Write-Host "ERROR: Could not find esptool.exe in the command" -ForegroundColor Red
    exit 1
}

# Extract all offsets and bin file paths
$argList = @()
$tempBinDir = Join-Path $PSScriptRoot "temp_binaries"
if (-not (Test-Path $tempBinDir)) {
    New-Item -ItemType Directory -Path $tempBinDir -Force | Out-Null
}

# Pattern to find pairs like: 0x1000 path\to\file.bin (path may be quoted)
$pairPattern = '0x[0-9A-Fa-f]+\s+("([^"]+)"|\S+)'
$pairs = [regex]::Matches($CommandLine, $pairPattern)
$missingFiles = @()

foreach ($p in $pairs) {
    $full = $p.Value
    if ($full -match '(0x[0-9A-Fa-f]+)\s+(.+)$') {
        $off = $matches[1]
        $originalPath = $matches[2].Trim('"')
        if ($originalPath -and ($originalPath -like '*.bin')) {
            # Check if original file exists
            if (-not (Test-Path $originalPath)) {
                $missingFiles += $originalPath
                continue
            }
            
            # Copy to temp folder to preserve it (Arduino IDE deletes temp folder after upload)
            $fileNameOnly = Split-Path $originalPath -Leaf
            $tempPath = Join-Path $tempBinDir $fileNameOnly
            Copy-Item -Path $originalPath -Destination $tempPath -Force
            Write-Host ("Copied: {0} -> {1}" -f $fileNameOnly, $tempPath) -ForegroundColor DarkGray
            
            # Use the copied file for merging
            $argList += @($off, $tempPath)
        }
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "ERROR: Some .bin files are missing (Arduino IDE may have deleted the temp folder):" -ForegroundColor Red
    foreach ($f in $missingFiles) {
        Write-Host ("  - {0}" -f $f) -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "SOLUTION: Run this script immediately after uploading in Arduino IDE," -ForegroundColor Yellow
    Write-Host "          while the temp build folder still exists." -ForegroundColor Yellow
    Write-Host "          Or rebuild in Arduino IDE and copy the command again." -ForegroundColor Yellow
    exit 1
}

if ($argList.Count -eq 0) {
    Write-Host "ERROR: No .bin files found in the command" -ForegroundColor Red
    exit 1
}

# Build and run merge_bin command using call operator (no string parsing issues)
$outputPath = Join-Path $PSScriptRoot $fileName
$argsList = @(
    '--chip', ($ChipFamily.ToLower()),
    'merge_bin',
    '-o', $outputPath,
    '--flash_mode', $flashMode,
    '--flash_freq', $flashFreq,
    '--flash_size', $flashSize
) + $argList

Write-Host ""
Write-Host "Starting esptool to merge binaries..." -ForegroundColor Cyan
Write-Host ("Command:`n  " + $esptoolPath + " " + ($argsList -join ' ')) -ForegroundColor DarkGray
Write-Host ""

try {
    & "$esptoolPath" @argsList
    if ($LASTEXITCODE -ne 0) {
        Write-Host ("ERROR: esptool exited with code {0}" -f $LASTEXITCODE) -ForegroundColor Red
        exit $LASTEXITCODE
    }
    if (Test-Path $outputPath) {
        Write-Host ("✓ Binary created: {0}" -f $fileName) -ForegroundColor Green
        $firmwarePath = Join-Path $firmwareDir $fileName
        Move-Item -Path $outputPath -Destination $firmwarePath -Force
        Write-Host ("✓ Moved to: firmware\{0}" -f $fileName) -ForegroundColor Green
    } else {
        Write-Host "ERROR: Binary file was not created" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host ("ERROR while executing esptool: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host "Tip: At the 'Enter firmware version' prompt, enter your firmware version only (e.g. 10.24c), not the 'esptool.py vX.Y.Z' line." -ForegroundColor Yellow
    exit 1
}

# Create manifest file
$manifestPath = Join-Path $manifestDir $manifestFileName
$manifestContent = @{
    name = $ProjectName
    version = $Version
    builds = @(
        @{
            chipFamily = $ChipFamily
            parts = @(
                @{
                    path = "firmware/$fileName"
                    offset = 0
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

Set-Content -Path $manifestPath -Value $manifestContent -Encoding UTF8
Write-Host "✓ Manifest created: manifest\$manifestFileName" -ForegroundColor Green

Write-Host ""
Write-Host "=== Done! ===" -ForegroundColor Green
Write-Host "Binary: firmware\$fileName" -ForegroundColor Cyan
Write-Host "Manifest: manifest\$manifestFileName" -ForegroundColor Cyan
Write-Host ""

# Keep window open if launched by double-click (Explorer)
try {
    $parent = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
    $parentName = (Get-Process -Id $parent -ErrorAction SilentlyContinue).ProcessName
    $launchedByExplorer = $parentName -eq 'explorer'
} catch { $launchedByExplorer = $false }
if ($launchedByExplorer) {
    Read-Host "Press Enter to close this window"
}