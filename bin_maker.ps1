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

# Ask interactively if not provided
if ([string]::IsNullOrEmpty($CommandLine)) {
    Write-Host "=== OnStep Firmware Binary Maker ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Instructions:" -ForegroundColor Yellow
    Write-Host "1. Build in Arduino IDE with 'Verbose Output During Upload' enabled"
    Write-Host "2. Copy the full esptool command from the IDE output"
    Write-Host "3. Paste it below"
    Write-Host ""
    $CommandLine = Read-Host "Paste the full esptool command"
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

# Sanitize project name for filenames
$filePrefix = $ProjectName -replace '[^\w]', '_'
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
$binParts = @()
# Pattern to find offset + file path (supports quoted paths with spaces)
$offsetPattern = '0x[0-9a-fA-F]+\s+([^\s"]+|"[^"]+")'
$allMatches = [regex]::Matches($CommandLine, $offsetPattern)

foreach ($match in $allMatches) {
    $fullMatch = $match.Value
    if ($fullMatch -match '(0x[0-9a-fA-F]+)\s+(.+)') {
        $localOffset = $matches[1]
        $localBinPath = $matches[2].Trim('"')
        # Ensure it's a .bin file
        if ($localBinPath -match '\.bin$') {
            $binParts += "$localOffset `"$localBinPath`""
        }
    }
}

if ($binParts.Count -eq 0) {
    Write-Host "ERROR: No .bin files found in the command" -ForegroundColor Red
    exit 1
}

# Build merge_bin command
$outputPath = Join-Path $PSScriptRoot $fileName
$mergeCommand = "`"$esptoolPath`" --chip $($ChipFamily.ToLower()) merge_bin -o `"$outputPath`" --flash_mode $flashMode --flash_freq $flashFreq --flash_size $flashSize $($binParts -join ' ')"

Write-Host ""
Write-Host "Executing merge_bin command..." -ForegroundColor Cyan
Write-Host $mergeCommand -ForegroundColor Gray
Write-Host ""

try {
    Invoke-Expression $mergeCommand
    
    if (Test-Path $outputPath) {
        Write-Host "✓ Binary created: $fileName" -ForegroundColor Green
        
        # Move file to firmware folder
        $firmwarePath = Join-Path $firmwareDir $fileName
        Move-Item -Path $outputPath -Destination $firmwarePath -Force
        Write-Host "✓ Moved to: firmware\$fileName" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Binary file was not created" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR while executing: $_" -ForegroundColor Red
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