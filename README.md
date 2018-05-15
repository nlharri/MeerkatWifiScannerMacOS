# MeerkatWifiScannerMacOS
Wifi Scanner util for MacOS

This is a command line tool which lists the available access points with the following data:
- SSID
- Signal strength
- channel number

It was written in Objective-C and C++.
It uses the ncurses library, and the CoreWLAN library.
You need to add these two libraries to your XCode project:
- libncurses.5.4.tbd
- CoreWLAN.framework
