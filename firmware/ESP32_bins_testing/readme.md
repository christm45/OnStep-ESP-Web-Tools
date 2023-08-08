Preparing your firmware
If you have ESP32 firmware and are using ESP-IDF framework v4 or later, you will need to create a merged version of your firmware before being able to use it with ESP Web Tools. If you use ESP8266 or ESP32 with ESP-IDF v3 or earlier, you can skip this section.

ESP32 firmware is split into 4 different files. When these files are installed using the command-line tool esptool, it will patch flash frequency, flash size and flash mode to match the target device. ESP Web Tools is not able to do this on the fly, so you will need to use esptool to create the single binary file and use that with ESP Web Tools.

Create a single binary using esptool with the following command:

esptool --chip esp32 merge_bin \
  -o merged-firmware.bin \
  --flash_mode dio \
  --flash_freq 40m \
  --flash_size 4MB \
  0x1000 bootloader.bin \
  0x8000 partitions.bin \
  0xe000 boot.bin \
  0x10000 your_app.bin
If your memory type is opi_opi or opi_qspi, set your flash mode to be dout. Else, if your flash mode is qio or qout, override your flash mode to be dio.



This is the compile data from the IDE.  You can see the 4 files... but i dont know where boot.bin is....


Serial port COM7
Connecting..........
Chip is ESP32-D0WD-V3 (revision 3)
Features: WiFi, BT, Dual Core, 240MHz, VRef calibration in efuse, Coding Scheme None
Crystal is 40MHz
MAC: 78:e3:6d:65:47:50
Uploading stub...
Running stub...
Stub running...
Changing baud rate to 921600
Changed.
Configuring flash size...
Flash will be erased from 0x00001000 to 0x00005fff...
Flash will be erased from 0x00008000 to 0x00008fff...
Flash will be erased from 0x0000e000 to 0x0000ffff...
Flash will be erased from 0x00010000 to 0x000f8fff...
Compressed 18880 bytes to 13017...

Writing at 0x00001000... (100 %)
Wrote 18880 bytes (13017 compressed) at 0x00001000 in 0.5 seconds (effective 284.0 kbit/s)...
Hash of data verified.

Compressed 3072 bytes to 146...
Writing at 0x00008000... (100 %)
Wrote 3072 bytes (146 compressed) at 0x00008000 in 0.1 seconds (effective 301.4 kbit/s)...
Hash of data verified.

Compressed 8192 bytes to 47...
Writing at 0x0000e000... (100 %)
Wrote 8192 bytes (47 compressed) at 0x0000e000 in 0.2 seconds (effective 419.5 kbit/s)...
Hash of data verified.

Compressed 953840 bytes to 575738...
Writing at 0x00010000... (2 %)
Writing at 0x00023cf5... (5 %)
Writing at 0x0002f775... (8 %)
Writing at 0x0003729a... (11 %)
Writing at 0x00043594... (13 %)
Writing at 0x00048b6b... (16 %)
Writing at 0x00050213... (19 %)
Writing at 0x000578d3... (22 %)
Writing at 0x0005db59... (25 %)
Writing at 0x0006395e... (27 %)
Writing at 0x00069132... (30 %)
Writing at 0x0006ea95... (33 %)
Writing at 0x00073ee7... (36 %)
Writing at 0x00079014... (38 %)
Writing at 0x0007e33a... (41 %)
Writing at 0x0008365f... (44 %)
Writing at 0x000889f0... (47 %)
Writing at 0x0008dd69... (50 %)
Writing at 0x00092fc6... (52 %)
Writing at 0x00098b65... (55 %)
Writing at 0x0009e2fa... (58 %)
Writing at 0x000a358f... (61 %)
Writing at 0x000a899a... (63 %)
Writing at 0x000adc3f... (66 %)
Writing at 0x000b3359... (69 %)
Writing at 0x000b8a69... (72 %)
Writing at 0x000be43d... (75 %)
Writing at 0x000c400f... (77 %)
Writing at 0x000c977d... (80 %)
Writing at 0x000d1e20... (83 %)
Writing at 0x000da1d8... (86 %)
Writing at 0x000df31c... (88 %)
Writing at 0x000e7aa7... (91 %)
Writing at 0x000ed181... (94 %)
Writing at 0x000f25e3... (97 %)
Writing at 0x000f8060... (100 %)
Wrote 953840 bytes (575738 compressed) at 0x00010000 in 9.0 seconds (effective 850.3 kbit/s)...
Hash of data verified.