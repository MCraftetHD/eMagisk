This is a heavely modified version of Atsu's Fork of Pokemod's eMagisk which only works for Cosmog ATVs 
Ill maintain this as long as it is needed and/or as long as ill Map.

Installs and configures everything needed for the ATV to run Cosmog smoothly

---------------

## Installation

1. Download the latest release (check tags)
2. adb push the magisk module into the device (or wget/curl)
3. `magisk --install-module magiskmodule.zip`
4. `reboot`


------------------

#Install via CMD (Windows)

1. Install adb for Windows
2. Connect your devices via adb `adb connect 192.168.178.101`
3. adb push the zip onto the devices `for %i in (101 102 103 104 105) do adb -s 192.168.178.%i push C:\Path\to\eMagisk.zip /sdcard/download`
       (Change the IPs to your devices local IP)
4. `for %i in (101 102 103 104 105) do adb -s 192.168.178.%i shell su -c magisk --install-module /sdcard/download/eMagisk_vJp2.zip`
5. `for %i in (101 102 103 104 105) do adb -s 192.168.178.%i reboot`
