$ModulePath = (Get-Module -ListAvailable TervisPrintServer).ModuleBase
. $ModulePath\Definition.ps1


function Invoke-PrintServerProvision {
    param (
        $EnvironmentName
    )
    Invoke-ApplicationProvision -ApplicationName PrintServer -EnvironmentName $EnvironmentName
    $Nodes = Get-TervisApplicationNode -ApplicationName PrintServer -EnvironmentName $EnvironmentName
    $Nodes | Install-PrintServerDriversFromWindowsUpdateAll
    $Nodes | Add-PointAndPrintRegistryKeys
    $Nodes | Set-AllPrinterDriversToPackaged
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

function Install-PrintServerDriversFromWindowsUpdateAll {
    param (
        [Parameter(ValueFromPipelineByPropertyName)]$ComputerName
    )
    process {
        $PrintDriverInstallDefinition |
        Where ProviderName -In Brother,"KYOCERA Document Solutions Inc.",Zebra |
        Install-PrintServerDriversFromWindowsUpdate -ComputerName $ComputerName
    }
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

function Get-PrintServerPrinterDefinitionPSCustomObjectStanza {
    $Printers = Get-TervisPrinter
    
    $PrinterPSCustomObjects = $Printers |
    Select-object -Property Name,Vendor,Model,ServicedBy,DPI,LabelWidth,LabelLength,MediaType,DriverName,Location
    $PrinterPSCustomObjects | ConvertTo-PSCustomObjectStanza

    $PrinterPSCustomObjects | 
    Where-Object Vendor -eq "Kyocera" |
    ConvertTo-PSCustomObjectStanza
}

function Install-TervisPrinters {
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$ComputerName
    )
    process {
        Add-PrinterDriver -Name "ZDesigner 110Xi4 203 dpi" -ComputerName $ComputerName

        if (-not (Test-WCSPrintersInstalled @PSBoundParameters)) {
            Get-WCSEquipment -EnvironmentName $EnvironmentName -PrintEngineOrientationRelativeToLabel $PrintEngineOrientationRelativeToLabel |
            Add-LocalWCSPrinter -ComputerName $ComputerName
        }

        if (-not (Test-WCSPrintersInstalled @PSBoundParameters)) {
            Throw "Couldn't install some printers or ports. To identify the missing  run Test-WCSPrintersInstalled -Verbose -ComputerName $ComputerName -PrintEngineOrientationRelativeToLabel $PrintEngineOrientationRelativeToLabel -EnvironmentName $EnvironmentName"
        }
    }
}

function Update-TervisPrinters {
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$ComputerName,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$EnvironmentName,
        [Parameter(Mandatory)][ValidateSet("Top","Bottom")]$PrintEngineOrientationRelativeToLabel
    )
    process {
        Get-WCSEquipment -EnvironmentName $EnvironmentName -PrintEngineOrientationRelativeToLabel $PrintEngineOrientationRelativeToLabel |
        Add-LocalWCSPrinter -ComputerName $ComputerName -Force
    }
}

function Test-TervisPrintersInstalled {
    [CMDLetBinding()]
    param (
        [Parameter(Mandatory)]$ComputerName,
        [Parameter(Mandatory)]$EnvironmentName,
        [Parameter(Mandatory)][ValidateSet("Top","Bottom")]$PrintEngineOrientationRelativeToLabel
    )
    $Equipment = Get-WCSEquipment -EnvironmentName $EnvironmentName -PrintEngineOrientationRelativeToLabel $PrintEngineOrientationRelativeToLabel
    $PrinterPorts = Get-PrinterPort -ComputerName $ComputerName
    $Printers = Get-Printer -ComputerName $ComputerName

    $MissingPorts = Compare-Object -ReferenceObject ($Equipment.HostID | sort -Unique) -DifferenceObject $PrinterPorts.Name | 
    where SideIndicator -EQ "<="
    $MissingPorts | Write-VerboseAdvanced -Verbose:($VerbosePreference -ne "SilentlyContinue")

    $MissingPrinters = Compare-Object -ReferenceObject $Equipment.ID -DifferenceObject $Printers.Name | 
    where SideIndicator -EQ "<="
    $MissingPrinters | Write-VerboseAdvanced -Verbose:($VerbosePreference -ne "SilentlyContinue")

    -not $MissingPorts -and -not $MissingPrinters
}

