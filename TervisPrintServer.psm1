$PrintDriverDefinition = [PSCustomObject][Ordered]@{
    ProviderName = "Brother"
    Version = "1.5.0.0"
    WindowsUpdateURL = "http://download.windowsupdate.com/msdownload/update/driver/drvs/2012/09/20501715_fe2de9f3194ab758a30d4736e7bfcee408f187dd.cab"
    INFFileName = "BROHLB1A.INF"
},
[PSCustomObject][Ordered]@{
    ProviderName = "Kyocera"
    Version = "6.0.2726.0"
    WindowsUpdateURL = "http://download.windowsupdate.com/d/msdownload/update/driver/drvs/2016/03/200013427_1013740d1e5cc42a416b12d6e570122a8763d46e.cab"
    INFFileName = "OEMSETUP.INF"
},
[PSCustomObject][Ordered]@{
    ProviderName = "Zebra"
    Version = "5.1.7.6290"
    WindowsUpdateURL = "http://download.windowsupdate.com/c/msdownload/update/driver/drvs/2016/06/20857735_abfb8f058ce8dd7bbb70ec4a7df3947f81b204a8.cab"
    INFFileName = "ZBRN.inf"
}

function Invoke-PrintServerProvision {
    param (
        $EnvironmentName
    )
    Invoke-ApplicationProvision -ApplicationName PrintServer -EnvironmentName $EnvironmentName
    $Nodes = Get-TervisApplicationNode -ApplicationName PrintServer -EnvironmentName $EnvironmentName
    $Nodes | Install-PrintServerDriversFromWindowsUpdate
    $Nodes | Add-PointAndPrintRegistryKeys
}

function Install-PrintServerDriversFromWindowsUpdate {
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$ComputerName,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$ProviderName,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$Version,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$WindowsUpdateURL,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$INFFileName
    )
    process {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $Driver = Get-WindowsDriver -Online | 
            where ProviderName -eq $Using:ProviderName |
            where ClassName -eq Printer |
            where Version -eq $Using:Version
            if (-not $Driver) {
                Invoke-WebRequest $Using:WindowsUpdateURL -OutFile $env:TEMP\Driver.cab
                New-Item -Path $env:TEMP\Driver -ItemType Directory
                expand.exe -F:* $env:TEMP\Driver.cab $env:TEMP\Driver
                pnputil.exe -i -a $env:TEMP\Driver\$Using:INFFileName
                Remove-Item -Path $env:TEMP\Driver -Recurse
            }
        }
    }
}

function Install-PrintServerDriversFromWindowsUpdate {
    param (
        [Parameter(ValueFromPipelineByPropertyName)]$ComputerName
    )
    $PrintDriverDefinition | 
    Where ProviderName -In Brother,Kyocera,Zebra |
    Install-PrintServerDriversFromWindowsUpdate
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
