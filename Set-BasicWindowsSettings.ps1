param (
    # Set computer name
    # mswork-l, mswork-d
    # paul-mac, paul-pc
    [string]$setComputerName = "",

    # Set DisplayName for my account. Use only if you are not using a Microsoft Account
    [string]$setDisplayName = "",

    # Enable Custom Background on the Login / Lock Screen
    # Background file: C:\someDirectory\someImage.jpg
    # File Size Limit: 256Kb
    [string]$setLockScreenBackground = "",

    # Linux Distro
    # Select a distro url at: https://docs.microsoft.com/en-us/windows/wsl/install-manual#downloading-distros
    # Ex: https://aka.ms/wsl-debian-gnulinux
    [string]$setLinuxDistroUri = ""
)

Function Test-CommandExists ($command) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    Try {
        if (Get-Command $command) {
            return $true
        }
    }
    Catch {
        return $false
    }
    Finally {
        $ErrorActionPreference = $oldPreference
    }
}

Function Test-Elevated {
    # Check to see if we are currently running "as Administrator"
    if ((Test-CommandExists "Verify-Elevated") -and !(Verify-Elevated)) {
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess);

    exit
    }
    else {
        Write-Host -NoNewline "Can't verify if this is an Administrator shell. Only continue if it is..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

<# TODO: These can probaby be moved to a .reg file instead #>
Function Set-RegistryExplorer {
    ###############################################################################
    ### Explorer, Taskbar, and System Tray                                        #
    ###############################################################################
    Write-Host "Configuring Explorer, Taskbar, and System Tray..." -ForegroundColor "Yellow"

    # Ensure necessary registry paths
    if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Type Folder | Out-Null}
    if (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState")) {New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" -Type Folder | Out-Null}
    if (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Windows Search")) {New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Windows Search" -Type Folder | Out-Null}

    # Explorer: Show hidden files by default: Show Files: 1, Hide Files: 2
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1

    # Explorer: Show file extensions by default
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0

    # Taskbar: Disable Bing Search
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0 # For Windows 10

    # Enable Developer Mode
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" "AllowDevelopmentWithoutDevLicense" 1
}

<# TODO: These can probaby be moved to a .reg file instead #>
Function Set-RegistryAccessibility {
    ###############################################################################
    ### Accessibility and Ease of Use                                             #
    ###############################################################################
    Write-Host "Configuring Accessibility..." -ForegroundColor "Yellow"

    # Launch Screen Snipping when pressing the 'Print Screen' button
    Set-ItemProperty "HKCU:\Control Panel\Keyboard" "PrintScreenKeyForSnippingEnabled" 1

    # Automatic fill to space on Window Snap Enabled: 1, Disabled: 0
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "SnapFill" 1

    # Hide all windows when "shaking" one
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "DisallowShaking" 1

    # Disable showing what can be snapped next to a window
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "SnapAssist" 0

    # Disable automatic resize of adjacent windows on snap
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "JointResize" 0
}

Function Set-WindowsSettings {
    ###############################################################################
    ### Security and Identity                                                     #
    ###############################################################################
    Write-Host "Configuring System..." -ForegroundColor "Yellow"

    # Set Computer Name
    if ($setComputerName) {
        Write-Host "Setting Computer Name to '$setComputerName'..." -ForegroundColor "Yellow"

        (Get-WmiObject Win32_ComputerSystem).Rename($setComputerName) | Out-Null
    }

    # Set DisplayName for my account. Use only if you are not using a Microsoft Account
    if ($setDisplayName) {
        Write-Host "Setting Display Name to '$setDisplayName'..." -ForegroundColor "Yellow"

        $myIdentity=[System.Security.Principal.WindowsIdentity]::GetCurrent()
        $user = Get-WmiObject Win32_UserAccount | Where-Object {$_.Caption -eq $myIdentity.Name}
        $user.FullName = $setDisplayName
        $user.Put() | Out-Null
        Remove-Variable user
        Remove-Variable myIdentity
    }

    # Windows Subsystem for Linux
    if ($setLinuxDistroUri) {
        Write-Host "Installing Windows Subsystem for Linux with Distro from '$setLinuxDistroUri'..." -ForegroundColor "Yellow"

        Enable-WindowsOptionalFeature -Online -All -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null
        Invoke-WebRequest -Uri $setLinuxDistroUri -OutFile linuxDistro.appx -UseBasicParsing
        Add-AppxPackage .\linuxDistro.appx
        Remove-Item linuxDistro.appx
    }

    # Enable Custom Background on the Login / Lock Screen
    if ($setLockScreenBackground) {
        Write-Host "Setting Lock Screen Background to '$setLockScreenBackground'..." -ForegroundColor "Yellow"

        Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\Personalization" "LockScreenImage" $setLockScreenBackground
    }
}

Test-Elevated
Set-WindowsSettings
Set-RegistryExplorer
Set-RegistryAccessibility
Write-Output "Done! Note that some of these changes require a logout/restart to take effect."