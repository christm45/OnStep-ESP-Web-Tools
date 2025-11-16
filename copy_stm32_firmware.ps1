# Copy STM32 firmware .bin file from Arduino build temp folder to firmware/ directory
# Usage: .\copy_stm32_firmware.ps1

param(
    [Parameter(Mandatory=$false)]
    [string]$BinPath = '',
    
    [Parameter(Mandatory=$false)]
    [string]$Version = '',
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = 'MAXSTM3'
)

# Detect if launched by Explorer
$script:LaunchedByExplorer = $false
try {
    $ppid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
    $pname = (Get-Process -Id $ppid -ErrorAction SilentlyContinue).ProcessName
    $script:LaunchedByExplorer = $pname -eq 'explorer'
} catch {}
trap {
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    if ($script:LaunchedByExplorer) { Read-Host "Press Enter to close this window" }
    break
}

# If BinPath not provided, try to find it automatically
if ([string]::IsNullOrEmpty($BinPath)) {
    Write-Host "=== STM32 Firmware Copier ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Searching for OnStepX.ino.bin in Arduino temp folders..." -ForegroundColor Yellow
    
    # Search in Arduino temp directory
    $arduinoTempDir = "$env:LOCALAPPDATA\Temp"
    $foundBins = @()
    
    # Look for all OnStepX.ino.bin files in arduino_build_* folders
    Get-ChildItem -Path $arduinoTempDir -Filter "arduino_build_*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $binFile = Join-Path $_.FullName "OnStepX.ino.bin"
        if (Test-Path $binFile) {
            $foundBins += @{
                Path = $binFile
                LastWrite = (Get-Item $binFile).LastWriteTime
            }
        }
    }
    
    if ($foundBins.Count -gt 0) {
        # Sort by last write time (newest first)
        $foundBins = $foundBins | Sort-Object -Property LastWrite -Descending
        $BinPath = $foundBins[0].Path
        Write-Host ("Found .bin file: " + $BinPath) -ForegroundColor Green
        Write-Host ("Last modified: " + $foundBins[0].LastWrite.ToString()) -ForegroundColor DarkGray
        
        if ($foundBins.Count -gt 1) {
            Write-Host ("(Found " + $foundBins.Count + " .bin files, using the most recent)") -ForegroundColor DarkGray
        }
    } else {
        # Try reading from build log file
        $buildLogPath = Join-Path (Split-Path $PSScriptRoot -Parent) "STM32 MAXSTM3.txt"
        if (Test-Path $buildLogPath) {
            Write-Host "Checking build log file..." -ForegroundColor Yellow
            $content = Get-Content $buildLogPath -Raw -ErrorAction SilentlyContinue
            if ($content -match '([A-Z]:[^"]+OnStepX\.ino\.bin)') {
                $candidatePath = $matches[1]
                if (Test-Path $candidatePath) {
                    $BinPath = $candidatePath
                    Write-Host ("Found .bin path from log: " + $BinPath) -ForegroundColor Green
                }
            }
        }
    }
    
    # If still not found, ask user
    if ([string]::IsNullOrEmpty($BinPath)) {
        Write-Host ""
        Write-Host "Could not find OnStepX.ino.bin automatically." -ForegroundColor Yellow
        Write-Host "Please recompile in Arduino IDE, then run this script again." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Or enter the path manually:"
        Write-Host "Example: C:\Users\...\AppData\Local\Temp\arduino_build_XXXXX\OnStepX.ino.bin"
        Write-Host ""
        $BinPath = Read-Host "Bin file path (or press Enter to exit)"
        if ([string]::IsNullOrEmpty($BinPath)) {
            Write-Host "Exiting..." -ForegroundColor Yellow
            if ($script:LaunchedByExplorer) { Read-Host "Press Enter to close this window" }
            exit 0
        }
    }
}

if ([string]::IsNullOrEmpty($Version)) {
    $Version = Read-Host "Enter firmware version (e.g. 10.24c)"
}

# Normalize version
$Version = ($Version -replace '[^0-9A-Za-z._-]','_')

# Ensure firmware directory exists
$firmwareDir = Join-Path $PSScriptRoot "firmware"
if (-not (Test-Path $firmwareDir)) {
    New-Item -ItemType Directory -Path $firmwareDir -Force | Out-Null
    Write-Host "'firmware' folder created" -ForegroundColor Green
}

# Check if source file exists
if (-not (Test-Path $BinPath)) {
    Write-Host "ERROR: Source file not found: $BinPath" -ForegroundColor Red
    Write-Host "Make sure Arduino IDE has finished building and the temp folder still exists." -ForegroundColor Yellow
    if ($script:LaunchedByExplorer) { Read-Host "Press Enter to close this window" }
    exit 1
}

# Create destination filename
$filePrefix = $ProjectName -replace '[^\w]', '_'
$fileName = "${filePrefix}_${Version}.bin"
$destPath = Join-Path $firmwareDir $fileName

# Copy the file
Copy-Item -Path $BinPath -Destination $destPath -Force
Write-Host ("Copied: " + $fileName) -ForegroundColor Green
Write-Host ("  From: " + $BinPath) -ForegroundColor DarkGray
Write-Host ("  To:   " + $destPath) -ForegroundColor DarkGray

# Create manifest (for reference, though ESP Web Tools won't work with STM32)
$manifestDir = Join-Path $PSScriptRoot "manifest"
if (-not (Test-Path $manifestDir)) {
    New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
}

$manifestFileName = "manifest_${filePrefix}_${Version}.json"
$manifestPath = Join-Path $manifestDir $manifestFileName

$manifestContent = @{
    name = $ProjectName
    version = $Version
    builds = @(
        @{
            chipFamily = "STM32"
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
Write-Host ("Manifest created: manifest\" + $manifestFileName) -ForegroundColor Green

Write-Host ""
Write-Host "=== Done! ===" -ForegroundColor Green
Write-Host "Note: ESP Web Tools only works with ESP32/ESP8266." -ForegroundColor Yellow
Write-Host "STM32 firmware requires STM32CubeProgrammer or other STM32 tools to flash." -ForegroundColor Yellow
Write-Host ""

if ($script:LaunchedByExplorer) {
    Read-Host "Press Enter to close this window"
}

