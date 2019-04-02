Write-Debug ("Starting " + $MyInvocation.MyCommand.Definition)

$scriptDir = $(Split-Path -parent $MyInvocation.MyCommand.Definition)


[string]$packageName = "JRE8"
$version = '8.0.1910.12'
#$thisJreInstalledHash = thisJreInstalled($version)
$checkreg = Get-UninstallRegistryKey -SoftwareName "Java 8*"
$osBitness = Get-ProcessorBits
<#
Exit Codes:
    0: Java installed successfully.
    1605: Java is not installed.
    3010: A reboot is required to finish the install.
#>

if ($checkreg -ne $null) {
    if ($checkreg -match 'Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall') {
        Write-Warning "Uninstalling JRE version $Version 32bit"
        $item32 = $checkreg | Where-Object {$_.PSPath -like '*Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall*'}
        $32 = $item32.PSChildName
        Start-ChocolateyProcessAsAdmin "/qn /norestart /X$32" -exeToRun "msiexec.exe" -validExitCodes @(0, 1605, 3010)
    }
    if ($checkreg -match 'Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall') {
        Write-Warning "Uninstalling JRE version $Version $osBitness bit" #Formatted weird for x86 windows installs
        $item64 = $checkreg | Where-Object {$_.PSPath -like '*Software\Microsoft\Windows\CurrentVersion\Uninstall*'}
        $64 = $item64.PSChildName
        Start-ChocolateyProcessAsAdmin "/qn /norestart /X$64" -exeToRun "msiexec.exe" -validExitCodes @(0, 1605, 3010)
    }
}

Write-Warning "$packageName may require a reboot to complete the uninstallation."
