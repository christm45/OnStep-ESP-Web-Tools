# Quick start: Flashing OnStep ESP firmware update Bogdan C.

# Quick start: Flashing OnStep ESP firmware

Installer powered by ESP Web Tools.

Sponsored by Gray Digital Arts and special thanks to Chad Gray https://graydigitalarts.com/ and his help to the community.

This guide walks you through flashing an ESP32/ESP8266 with the web installer and shows how to add your own binaries.

---

## 1) Prerequisites

- Windows with PowerShell 5.1+
- Google Chrome or Microsoft Edge (Web Serial support)
- USB cable for your ESP board (use a data cable, not charge‑only)
- Optional: CH340/CP210x driver if your board needs it

---

## 2) One‑click flashing (recommended)

1. If you already have a `.bin` file, copy it into the `firmware\` folder. Recommended name format: `Project_Version.bin` (example: `FYSETC_E4_10.24c.bin`).
2. Double‑click `start_webtool.bat`. Your browser will open `http://localhost:8000/index.html`.
3. In the page:
   - Select your project from “Select a project”.
   - Choose the firmware version (e.g., `10.24c (ESP32)`).
   - Click the blue `CONNECT` button.
   - Pick your device from the list (COM port). Close any Serial Monitor first.
   - For many ESP32 boards, hold the BOOT button when asked, then release after flashing starts.
4. Wait for the progress to reach 100%. The device will reboot with the new firmware.

If the project/version does not appear, run `sync_firmware.bat` once (see next section) and refresh the page.

---

## 3) Add a new .bin to the UI (no coding)

1. Copy your new `.bin` file into `firmware\` (use `Project_Version.bin` naming if possible).
2. Double‑click `sync_firmware.bat`.
   - This creates a matching manifest in `manifest\` and regenerates `manifest_list.js`.
3. Refresh the web page (or re‑open `start_webtool.bat`). Your new version will appear automatically.

---

## 4) Build your own .bin from Arduino IDE (optional)

If you have the OnStep project in Arduino IDE and want to create a merged `.bin`:

1. In Arduino IDE: File → Preferences → enable “Show verbose output during: upload”.
2. Upload your sketch once. Copy the full `esptool.exe` command from the IDE output.
3. Run the helper script and paste the command when asked:

```powershell
.\bin_maker.ps1
```

You will be prompted for:
- Firmware version (e.g., `10.24c`)
- Project name (e.g., `FYSETC E4`)

The script will:
- Detect the chip family (ESP32 / ESP32‑S2 / ESP32‑S3 / ESP32‑C3 / ESP8266)
- Merge all required pieces into a single `.bin` in `firmware\`
- Generate the corresponding manifest in `manifest\`

Alternative (no prompts):

```powershell
$command = 'C:\Path\to\esptool.exe --chip esp32 --port COM7 --baud 921600 --before default_reset --after hard_reset write_flash -e -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 C:\...\OnStepX.ino.bootloader.bin 0x8000 C:\...\OnStepX.ino.partitions.bin 0xe000 C:\...\boot_app0.bin 0x10000 C:\...\OnStepX.ino.bin'
.\bin_maker.ps1 -CommandLine $command -Version "10.24c" -ProjectName "FYSETC E4"
```

Finally, run:

```powershell
.\sync_firmware.ps1
```

Then open the UI via `start_webtool.bat` and flash as in step 2.

---

## 5) Troubleshooting

- No CONNECT button or it’s disabled:
  - Always open the page via `start_webtool.bat` (uses `http://localhost`, required by Web Serial).
  - Use Chrome or Edge; other browsers may not support Web Serial.
- No device in the list / connection fails:
  - Close Arduino Serial Monitor or any app using the COM port.
  - Try another USB cable/port; install the board’s USB driver (CH340/CP210x) if needed.
  - For ESP32, hold BOOT when prompted; press EN/RESET after flashing if it doesn’t auto‑reboot.
- New firmware doesn’t show up:
  - Make sure the `.bin` is in `firmware\`.
  - Run `sync_firmware.bat` to regenerate manifests and refresh the page.
- “Permission” prompt doesn’t appear:
  - Click the page, then `CONNECT` again; allow access to the serial device when prompted.

---

## 6) Useful commands (reference)

Interactive build from Arduino IDE command:

```powershell
.\bin_maker.ps1
```

Non‑interactive build:

```powershell
$command = 'C:\Path\to\esptool.exe --chip esp32 ... 0x10000 C:\...\OnStepX.ino.bin'
.\bin_maker.ps1 -CommandLine $command -Version "10.24c" -ProjectName "FYSETC E4"
```

Regenerate manifest list:

```powershell
.\sync_firmware.ps1
```

Start the local web installer (recommended):

```powershell
.\start_webtool.ps1
```
