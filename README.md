# OnStep-ESP-Web-Tools

Web tool to build and flash OnStep firmware for ESP32/ESP8266 from Arduino IDE.

## Description

This project allows you to:
- Automatically create merged firmware binaries from Arduino IDE/OnStep builds
- Generate the manifests required by ESP Web Tools
- Flash firmware directly from a web browser

## Usage

### Step 1: Build in Arduino IDE

1. Open your OnStep project in Arduino IDE
2. Go to File > Preferences
3. Enable "Show verbose output during: upload"
4. Build and upload to your ESP32/ESP8266
5. Copy the full `esptool.exe` command from the IDE output

Example:
```
C:\Users\...\AppData\Local\Arduino15\packages\esp32\tools\esptool_py\4.5.1/esptool.exe --chip esp32 --port COM7 --baud 921600 --before default_reset --after hard_reset write_flash -e -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 C:\Users\...\AppData\Local\Temp\arduino_build_972360/OnStepX.ino.bootloader.bin 0x8000 C:\Users\...\AppData\Local\Temp\arduino_build_972360/OnStepX.ino.partitions.bin 0xe000 C:\Users\...\AppData\Local\Arduino15\packages\esp32\hardware\esp32\2.0.17/tools/partitions/boot_app0.bin 0x10000 C:\Users\...\AppData\Local\Temp\arduino_build_972360/OnStepX.ino.bin
```

### Step 2: Create merged firmware

Run the PowerShell script `bin_maker.ps1`:

```powershell
.\bin_maker.ps1
```

The script will:
1. Ask you to paste the full esptool command
2. Ask for the firmware version (e.g. `10.24c`)
3. Ask for the project name (e.g. `FYSETC E4`)
4. Auto-detect the MCU type (ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP8266)
5. Create the merged binary in `firmware/`
6. Create the manifest file in `manifest/`

Alternative (non-interactive):
```powershell
.\bin_maker.ps1 -CommandLine "votre commande esptool" -Version "10.24c" -ProjectName "FYSETC E4"
```

### Step 3: Regenerate manifest list (optional)

If you created multiple firmwares, generate a list automatically:

```powershell
.\list_manifests.ps1
```

This creates `manifest_list.js`, which `index.html` uses automatically.

### Step 4: Use the web interface

1. Recommended: double-click `start_webtool.bat` (or run `.\start_webtool.ps1`) to launch a local server and open `http://localhost:8000/index.html`.
   - The launcher uses Python if present, else `npx serve`, else a built-in PowerShell server.
   - The CONNECT button requires a secure context (localhost/HTTPS) and a Web Serial capable browser (Chrome/Edge).
2. Manual: serve `index.html` via a local server (e.g. `python -m http.server 8000` then open `http://localhost:8000/index.html`).
3. Select your project
4. Choose the firmware version
5. Click **CONNECT** to connect to your device
6. Follow on-screen instructions to flash

### Add a new firmware (.bin) on another machine

- Drop your `.bin` into `firmware/` (recommended naming: `Project_Version.bin`, e.g. `FYSETC_E4_10.24c.bin`).
- Run `sync_firmware.bat` (or `.\sync_firmware.ps1`) to auto-create the manifest and regenerate the list used by the UI.

- Launch `start_webtool.bat` and flash from the interface.

## Repository structure

```
OnStep-ESP-Web-Tools/
├── bin_maker.ps1          # Build merged binaries
├── list_manifests.ps1     # Build manifest list for the UI
├── start_webtool.ps1/.bat # Local server launcher
├── sync_firmware.ps1/.bat # Auto-create manifests from .bin files
├── index.html             # Main web UI
├── firmware/              # .bin files
├── manifest/              # Manifest JSON files
└── js/                    # ESP Web Tools libs
```

## Features

### `bin_maker.ps1`

- Auto-detect MCU (ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP8266)
- Extract flash params (mode, freq, size)
- Create `firmware/` and `manifest/` if missing
- Move output to correct folders
- Generate manifest JSON
- Support paths with spaces
- Clear error messages

### `index.html`

- Dynamic manifest discovery
- Group by project
- Sort versions (newest first)
- Show MCU type per version
- Responsive and dark mode support

## Manifest JSON format

```json
{
  "name": "Project Name",
  "version": "10.24c",
  "builds": [
    {
      "chipFamily": "ESP32",
      "parts": [
        {
          "path": "firmware/ProjectName_10.24c.bin",
          "offset": 0
        }
      ]
    }
  ]
}
```

## Requirements

- Windows with PowerShell 5.1 or newer
- Arduino IDE with ESP32/ESP8266 cores installed
- Modern browser with Web Serial API (Chrome, Edge)

## Resources

- [ESP Web Tools](https://esphome.github.io/esp-web-tools/)
- [OnStep Wiki](https://onstep.groups.io/g/main/wiki/)
- [Arduino ESP32](https://github.com/espressif/arduino-esp32)

---

Note: This project is a prototype. For more information on OnStep, visit `https://onstep.groups.io/g/main/wiki/`.

