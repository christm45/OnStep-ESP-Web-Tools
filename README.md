# OnStep-ESP-Web-Tools


To make the binaries for the ESP32 you need to run a Compile with upload to your ESP32 MCU in the Arduino IDE.

In the IDE preferences turn on "Verbose Output During Upload".

When the binaries are created you will see a command in the IDE like this:

```
C:\Users\cgray.GRAY\AppData\Local\Arduino15\packages\esp32\tools\esptool_py\4.2.1/esptool.exe --chip esp32 --port COM7 --baud 921600 --before default_reset --after hard_reset write_flash -e -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 C:\Users\CGRAY~1.GRA\AppData\Local\Temp\arduino_build_358479/OnStepX.ino.bootloader.bin 0x8000 C:\Users\CGRAY~1.GRA\AppData\Local\Temp\arduino_build_358479/OnStepX.ino.partitions.bin 0xe000 C:\Users\cgray.GRAY\AppData\Local\Arduino15\packages\esp32\hardware\esp32\2.0.6/tools/partitions/boot_app0.bin 0x10000 C:\Users\CGRAY~1.GRA\AppData\Local\Temp\arduino_build_358479/OnStepX.ino.bin
```

You need to replace the section 
```
--port COM7 --baud 921600 --before default_reset --after hard_reset write_flash -e -z
```

With this to merge the binaries into one
```
merge_bin -o merged-firmware.bin 
```

The merged binary named merged-firmware.bin will be created in the folder you ran the command from.

THis is the binary you need to use.

I made a powershell script to help automate the creation of the bin and manifest files.
bin_maker.ps1

