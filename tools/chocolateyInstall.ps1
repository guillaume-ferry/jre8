try {

    $arguments = @{ }

    # Now we can use the $env:chocolateyPackageParameters inside the Chocolatey package
    $packageParameters = $env:chocolateyPackageParameters

    # Default value
    $exclude = $null

    # Now parse the packageParameters using good old regular expression
    if ($packageParameters) {
        $match_pattern = "\/(?<option>([a-zA-Z0-9]+)):(?<value>([`"'])?([a-zA-Z0-9- \(\)\s_\\:\.]+)([`"'])?)|\/(?<option>([a-zA-Z]+))"
        $option_name = 'option'
        $value_name = 'value'

        if ($packageParameters -match $match_pattern ) {
            $results = $packageParameters | Select-String $match_pattern -AllMatches
            $results.matches | ForEach-Object {
                $arguments.Add(
                    $_.Groups[$option_name].Value.Trim(),
                    $_.Groups[$value_name].Value.Trim())
            }
        } else {
            Throw "Package Parameters were found but were invalid (REGEX Failure)"
        }

        if ($arguments.ContainsKey("exclude")) {
            Write-Host "exclude Argument Found"
            $exclude = $arguments["exclude"]
        }

    } else {
        Write-Debug "No Package Parameters Passed in"
    }
  
    $packageName = 'jre8'
    # Modify these values -----------------------------------------------------
    # Find download URLs at http://www.java.com/en/download/manual.jsp
    $url = 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=236886_42970487e3af4f5aa5bca3f542482c60'
    $checksum32 = '2CAA55F2A9BFFB6BE596FB34F8CE14A554A60008B2764734B41A28AE15A21EA4'
    $url64 = 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=236888_42970487e3af4f5aa5bca3f542482c60'
    $checksum64 = 'A2FE774DD9A8B57B3C2F7FA1A4EEA64CCE06AE642348455F8B6D888A2D5422D0'
    $version = '8.0.2010.9'
    #--------------------------------------------------------------------------
    $updatenumber = $version -replace "\d+\.\d+\.(\d\d\d).*", '$1'
    $installerType = 'exe'
    $installArgs = "/s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0"
    
    $osBitness = Get-ProcessorBits
    $cachepath = "$env:TEMP\$env:chocolateyPackageName\$env:chocolateyPackageVersion"

    #This checks to see if current version is already installed
    Write-Output "Checking to see if local install is already up to date..."
    $checkreg = Get-UninstallRegistryKey -SoftwareName "Java 8 Update $updatenumber*"

    # Checks if JRE 32/64-bit in the same version is already installed and if the user excluded 32-bit Java.
    # Otherwise it downloads and installs it.
    # This is to avoid unnecessary downloads and 1603 errors.
    if ($null -ne $checkreg) {
        if ($checkreg -match 'Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall') {
            Write-Output "Java Runtime Environment $version (32-bit) is already installed. Skipping download and installation"
        }
    } elseif ($exclude -ne "32") {
        Write-Output "Downloading 32-bit installer"
        Get-ChocolateyWebFile -packageName $packageName -fileFullPath "$cachepath\JRE8x86.exe" -url $url -checksum $checksum32 -checksumType 'SHA256'
        Write-Output "Installing JRE $version 32-bit"
        Install-ChocolateyInstallPackage -packageName JRE8 -fileType $installerType -silentArgs $installArgs -file "$cachepath\JRE8x86.exe"
    } else {
        Write-Output "Java Runtime Environment $Version (32-bit) excluded for installation"
    }

    # Only check for the 64-bit version if the system is 64-bit
    if ($osBitness -eq 64) {
        if ($null -ne $checkreg) {
            if ($checkreg -match 'Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall') {
                Write-Output "Java Runtime Environment $version (64-bit) is already installed. Skipping download and installation"
            }
        } elseif ($exclude -ne "64") {
            Write-Output "Downloading 64-bit installer"
            Get-ChocolateyWebFile -packageName $packageName -fileFullPath "$cachepath\JRE8x64.exe" -url64 $url64 -checksum64 $checksum64 -checksumType 'SHA256'
            Write-Output "Installing JRE $version 64-bit"
            Install-ChocolateyInstallPackage -packageName JRE8 -fileType $installerType -silentArgs $installArgs -file64 "$cachepath\JRE8x64.exe"
        } else {
            Write-Output "Java Runtime Environment $Version (64-bit) excluded for installation"
        }
    }
  
    #Uninstalls the previous version of Java if either version exists
    Write-Output "Searching if the previous version exists..."
    $InstallerVersion = $version.Replace('.', '')

    [array]$checkoldreg = Get-UninstallRegistryKey -SoftwareName "Java 8*" | Where-Object {$_.DisplayVersion.Replace('.', '') -lt $InstallerVersion}
    if ($checkoldreg.Count -eq 0) {
        Write-Verbose 'No installed version. Nothing to do.'
    } elseif ($checkoldreg.count -ge 1) {
        $checkoldreg | ForEach-Object {
            Write-Warning "Uninstalling JRE previous : $($_.DisplayName)"
            $msiKey = $_.PSChildName
            Start-ChocolateyProcessAsAdmin "/qn /norestart /X$msiKey" -exeToRun "msiexec.exe" -validExitCodes @(0, 1605, 3010)
        }
    }
} catch {
    #Write-ChocolateyFailure $packageName $($_.Exception.Message)
    throw $_.Exception
}