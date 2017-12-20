$PrintDriverInstallDefinition = [PSCustomObject][Ordered]@{
    ProviderName = "Brother"
    Version = "1.5.0.0"
    WindowsUpdateURL = "http://download.windowsupdate.com/msdownload/update/driver/drvs/2012/09/20501715_fe2de9f3194ab758a30d4736e7bfcee408f187dd.cab"
    INFFileName = "BROHLB1A.INF"
    DriverName = @"
Brother HL-6180DW series
"@ -split "`r`n"

},
#[PSCustomObject][Ordered]@{
#    ProviderName = "KYOCERA Document Solutions Inc."
#    Version = "6.0.2726.0"
#    WindowsUpdateURL = "http://download.windowsupdate.com/d/msdownload/update/driver/drvs/2016/03/200013427_1013740d1e5cc42a416b12d6e570122a8763d46e.cab"
#    INFFileName = "OEMSETUP.INF"
#},
[PSCustomObject][Ordered]@{
    ProviderName = "Zebra"
    Version = "5.1.7.6290"
    WindowsUpdateURL = "http://download.windowsupdate.com/c/msdownload/update/driver/drvs/2016/06/20857735_abfb8f058ce8dd7bbb70ec4a7df3947f81b204a8.cab"
    INFFileName = "ZBRN.inf"
    DriverName = @"
ZDesigner 110Xi4 203 dpi
ZDesigner 110Xi4 300 dpi
ZDesigner 110Xi4 600 dpi
ZDesigner LP 2844
ZDesigner ZM400 200 dpi (ZPL)
ZDesigner ZM400 300 dpi (ZPL)
"@ -split "`r`n"
},
[PSCustomObject][Ordered]@{
    ProviderName = "KYOCERA Document Solutions Inc."
    Version = "6.0.2726.0"
    WindowsUpdateURL = "http://download.windowsupdate.com/d/msdownload/update/driver/drvs/2013/11/20557306_dad42303dba3df7ee060e26fffd35cd483bf7844.cab"
    INFFileName = "OEMSETUP.INF"
    DriverName = @"
Kyocera FS-4300DN KX
"@ -split "`r`n"
}

$PrinterDefinition = [PSCustomObject][Ordered]@{
    DriverName = "Brother HL-6180DW series"
    Location = "Innovation Center"
    Name = "BlackCat"
}