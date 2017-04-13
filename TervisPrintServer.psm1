function Invoke-PrintServerProvision {
    param (
        $EnvironmentName
    )
    Invoke-ClusterApplicationProvision -ClusterApplicationName PrintServer -EnvironmentName $EnvironmentName
    $Nodes = Get-TervisClusterApplicationNode -ClusterApplicationName Progistics -EnvironmentName $EnvironmentName
    $Nodes | Install-PrintServerDriversFromWindowsUpdate
    $Nodes | Add-PointAndPrintRegistryKeys
}

function Install-PrintServerDriversFromWindowsUpdate {
    param (
        [Parameter(ValueFromPipelineByPropertyName)]$ComputerName
    )
    Invoke-Command -ScriptBlock {
        $ZebraDriver = get-windowsdriver -Online | 
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
