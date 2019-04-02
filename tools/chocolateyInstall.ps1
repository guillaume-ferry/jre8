﻿try {

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

    $scriptDir = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
  
    $packageName = 'jre8'
    # Modify these values -----------------------------------------------------
    # Find download URLs at http://www.java.com/en/download/manual.jsp
    $url = 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=235725_2787e4a523244c269598db4e85c51e0c'
    $checksum32 = 'DE27BD5A46F325E7F7874538F5CA7FBE77D25ABA9D1B3ED9B93E0A81E4EAFE35'
    $url64 = 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=235727_2787e4a523244c269598db4e85c51e0c'
    $checksum64 = '605D05442C1640530A8CA2938BAAFB785560AEFA88DC8CD0B43261EF3ECFA4BD'
    $oldVersion = '8.0.1810.13'
    $version = '8.0.1910.12'
    #--------------------------------------------------------------------------
    $homepath = $version -replace "(\d+\.\d+)\.(\d\d)(.*)", 'jre1.$1_$2'
    $updatenumber = $version -replace "\d+\.\d+\.(\d\d\d).*", '$1'
    $installerType = 'exe'
    $installArgs = "/s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0 $32dir"
    $installArgs64 = "/s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0 $64dir"
    $osBitness = Get-ProcessorBits
    $cachepath = "$env:temp\$packagename\$version"
  
  
    #This checks to see if current version is already installed
    Write-Output "Checking to see if local install is already up to date..."

    #This checks to see if current version is already installed
    Write-Output "Checking to see if local install is already up to date..."
    $checkreg = Get-UninstallRegistryKey -SoftwareName "Java 8 Update $updatenumber"

    # Checks if JRE 32/64-bit in the same version is already installed and if the user excluded 32-bit Java.
    # Otherwise it downloads and installs it.
    # This is to avoid unnecessary downloads and 1603 errors.
    if ($checkreg -ne $null) {
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
        if ($checkreg -ne $null) {
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
    $checkoldreg = Get-UninstallRegistryKey -SoftwareName "Java 8*"
    if ($checkoldreg -ne $null) {
        if ($checkoldreg -match 'Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall') {
            Write-Warning "Uninstalling JRE version $oldVersion 32bit"
            $item32 = $checkoldreg | Where-Object {$_.PSPath -like '*Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall*' -and $_.DisplayVersion -eq $oldVersion}
            if ($item32) {
                $32 = $item32.PSChildName
                Start-ChocolateyProcessAsAdmin "/qn /norestart /X$32" -exeToRun "msiexec.exe" -validExitCodes @(0, 1605, 3010)
            }
        }
        if ($checkoldreg -match 'Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall') {
            Write-Warning "Uninstalling JRE version $oldVersion $osBitness bit" #Formatted weird because this is used if run on a x86 install
            $item64 = $checkoldreg | Where-Object {$_.PSPath -like '*Software\Microsoft\Windows\CurrentVersion\Uninstall*' -and $_.DisplayVersion -eq $oldVersion}
            if ($item64) {
                $64 = $item64.PSChildName
                Start-ChocolateyProcessAsAdmin "/qn /norestart /X$64" -exeToRun "msiexec.exe" -validExitCodes @(0, 1605, 3010)
            }
        }
    }
} catch {
    #Write-ChocolateyFailure $packageName $($_.Exception.Message)
    throw
}
