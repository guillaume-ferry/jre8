Write-Debug "Starting $($MyInvocation.MyCommand.Definition)"

$packageName = "JRE8"
$version = '8.0.2010.9'
$InstallerVersion = $version.Replace('.', '')
[array]$checkreg = Get-UninstallRegistryKey -SoftwareName "Java 8*" | Where-Object {$_.DisplayVersion.Replace('.', '') -eq $InstallerVersion}
<#
Exit Codes:
    0: Java installed successfully.
    1605: Java is not installed.
    3010: A reboot is required to finish the install.
#>

if ($checkreg.Count -eq 0) {
    Write-Verbose 'No installed version. Nothing to do.'
} elseif ($checkreg.count -ge 1) {
    $checkreg | ForEach-Object {
        Write-Warning "Uninstalling JRE : $($_.DisplayName)"
        $msiKey = $_.PSChildName
        Start-ChocolateyProcessAsAdmin "/qn /norestart /X$msiKey" -exeToRun "msiexec.exe" -validExitCodes @(0, 1605, 3010)
    }
}

Write-Warning "$packageName may require a reboot to complete the uninstallation."
