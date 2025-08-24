# replace the content of the next three variables

$commandLine= '
C:\Users\Bogdan\AppData\Local\Arduino15\packages\esp32\tools\esptool_py\4.5.1/esptool.exe --chip esp32 merge_bin -o merged-firmware.bin --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 C:\Users\Bogdan\AppData\Local\Temp\arduino_build_972360/OnStepX.ino.bootloader.bin 0x8000 C:\Users\Bogdan\AppData\Local\Temp\arduino_build_972360/OnStepX.ino.partitions.bin 0xe000 C:\Users\Bogdan\AppData\Local\Arduino15\packages\esp32\hardware\esp32\2.0.17/tools/partitions/boot_app0.bin 0x10000 C:\Users\Bogdan\AppData\Local\Temp\arduino_build_972360/OnStepX.ino.bin 
 

'

$ver = '10.18.c.6'
$projectName = 'FYSETC E4'


$filePrefix = $projectName.replace(' ','_')
$manifestFileName = 'manifest_' + $filePrefix + '_' + $ver + '.json'
$fileName = $filePrefix + '_' + $ver + '.bin'


$finalCommand = $commandLine.replace('--port COM7 --baud 921600 --before default_reset --after hard_reset write_flash -z','merge_bin -o ' + $fileName)

$finalCommand | Invoke-Expression

New-Item $manifestFileName -Force

$manifestContent = '{
  "name": "' + $projectName + '",
  "version": "' + $ver +'",
  "builds": [
    {
      "chipFamily": "ESP32",
      "parts": [{ "path": "firmware/' + $fileName + '", "offset": 0 }]
    }
  ]
}'

Set-Content $manifestFileName $manifestContent