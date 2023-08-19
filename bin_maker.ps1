# replace the content of the next three variables

$commandLine= '
C:\Users\cgray.GRAY\AppData\Local\Arduino15\packages\esp32\tools\esptool_py\3.1.0/esptool.exe --chip esp32 --port COM7 --baud 921600 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB 0xe000 C:\Users\cgray.GRAY\AppData\Local\Arduino15\packages\esp32\hardware\esp32\2.0.1/tools/partitions/boot_app0.bin 0x1000 C:\Users\CGRAY~1.GRA\AppData\Local\Temp\arduino_build_542949/OnStep.ino.bootloader.bin 0x10000 C:\Users\CGRAY~1.GRA\AppData\Local\Temp\arduino_build_542949/OnStep.ino.bin 0x8000 C:\Users\CGRAY~1.GRA\AppData\Local\Temp\arduino_build_542949/OnStep.ino.partitions.bin 

'

$ver = '10.16.b.5'
$projectName = 'GDA MaxESP4 OnStepX'


$filePrefix = $projectName.replace(' ','_')
$manifestFileName = 'manifest_' + $filePrefix + '_' + $ver + '.json'
$fileName = $filePrefix + '_' + $ver + '.bin'


$finalCommand = $commandLine.replace('--port COM7 --baud 921600 --before default_reset --after hard_reset write_flash -z','merge_bin -o firmware/' + $fileName)

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