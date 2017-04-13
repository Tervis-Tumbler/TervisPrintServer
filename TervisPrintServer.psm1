function Invoke-PrintServerProvision {
    param (
        $EnvironmentName
    )
    Invoke-ClusterApplicationProvision -ClusterApplicationName PrintServer -EnvironmentName $EnvironmentName
    $Nodes = Get-TervisClusterApplicationNode -ClusterApplicationName PrintServer -EnvironmentName $EnvironmentName
    $Nodes | Install-PrintServerDriversFromWindowsUpdate
    $Nodes | Add-PointAndPrintRegistryKeys
}

function Install-PrintServerDriversFromWindowsUpdate {
    param (
        [Parameter(ValueFromPipelineByPropertyName)]$ComputerName
    )
    Invoke-Command -ScriptBlock {
        $BrotherHL6180DWDriver = Get-WindowsDriver -Online | 
        where providername -eq Brother |
        where ClassName -eq Printer |
        where Version -eq 1.5.0.0
        if (-not $BrotherHL6180DWDriver) {
            Invoke-WebRequest http://download.windowsupdate.com/msdownload/update/driver/drvs/2012/09/20501715_fe2de9f3194ab758a30d4736e7bfcee408f187dd.cab -OutFile $env:TEMP\BrotherHL6180DWDriver.cab
            New-Item -Path $env:TEMP\BrotherHL6180DWDriver -ItemType Directory
            expand.exe -F:* $env:TEMP\BrotherHL6180DWDriver.cab $env:TEMP\BrotherHL6180DWDriver
            pnputil.exe -i -a $env:TEMP\BrotherHL6180DWDriver\BROHLB1A.INF
        }

        $KyoceraUniversalDriver = Get-WindowsDriver -Online | 
        where providername -eq Kyocera |
        where ClassName -eq Printer |
        where Version -eq 6.0.2726.0
        if (-not $KyoceraUniversalDriver) {
            Invoke-WebRequest http://download.windowsupdate.com/d/msdownload/update/driver/drvs/2013/11/20557306_dad42303dba3df7ee060e26fffd35cd483bf7844.cab -OutFile $env:TEMP\KyoceraUniversalDriver.cab
            New-Item -Path $env:TEMP\KyoceraUniversalDriver -ItemType Directory
            expand.exe -F:* $env:TEMP\KyoceraUniversalDriver.cab $env:TEMP\KyoceraUniversalDriver
            pnputil.exe -i -a $env:TEMP\KyoceraUniversalDriver\OEMSETUP.INF
        }

        $ZebraDriver = Get-WindowsDriver -Online | 
        where providername -eq zebra |
        where ClassName -eq Printer |
        where Version -eq 5.1.7.6290
        if (-not $ZebraDriver) {
            Invoke-WebRequest http://download.windowsupdate.com/c/msdownload/update/driver/drvs/2016/06/20857735_abfb8f058ce8dd7bbb70ec4a7df3947f81b204a8.cab -OutFile $env:TEMP\ZDesigner.cab
            New-Item -Path $env:TEMP\zdesigner -ItemType Directory
            expand.exe -F:* $env:TEMP\zdesigner.cab $env:TEMP\zdesigner
            pnputil.exe -i -a $env:TEMP\zdesigner\ZBRN.inf
        }
    } @PSBoundParameters
}

function Add-PointAndPrintRegistryKeys {
    param (
        [Parameter(ValueFromPipelineByPropertyName)]$ComputerName
    )
    begin {
        [string]$PointAndPrintRegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
        $PointAndPrintRegistryValue = "0"
    }
    process {
        $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
        $RegistryKey = $Registry.OpenSubKey('SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint')
        if (-NOT ($RegistryKey.VlaueCount -ge 3)) {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                New-Item -Path $Using:PointAndPrintRegistryPath
                New-ItemProperty -Path $Using:PointAndPrintRegistryPath -Name "Restricted" -Value $Using:PointAndPrintRegistryValue -PropertyType DWORD -Force
                New-ItemProperty -Path $Using:PointAndPrintRegistryPath -Name "InForest" -Value $Using:PointAndPrintRegistryValue -PropertyType DWORD -Force
                New-ItemProperty -Path $Using:PointAndPrintRegistryPath -Name "TrustedServers" -Value $Using:PointAndPrintRegistryValue -PropertyType DWORD -Force
            }
            $RegistryKey.Close()
            $Registry.Close()
        }
    }
    end {

        }
}
