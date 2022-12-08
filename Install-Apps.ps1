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


function Install-Apps {
    [CmdletBinding()]
    param (
        # Linux Distro
        # Select a distro url at: https://docs.microsoft.com/en-us/windows/wsl/install-manual#downloading-distros
        # Or empty for none
        [Parameter()]
        [string]$setLinuxDistroUri = "https://aka.ms/wsl-debian-gnulinux"
    )
    # https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    # Update Help for Modules
    Write-Host "Updating Help..." -ForegroundColor "Yellow"
    #Update-Help -Force

    # Package Providers
    Write-Host "Installing Package Providers..." -ForegroundColor "Yellow"
    Get-PackageProvider NuGet -Force | Out-Null
    # Chocolatey Provider is not ready yet. Use normal Chocolatey
    #Get-PackageProvider Chocolatey -Force
    #Set-PackageSource -Name chocolatey -Trusted


    # Install PowerShell Modules
    # If having 'Access to the cloud file is denied': https://github.com/PowerShell/PowerShellGet/issues/300
    Write-Host "Installing PowerShell Modules..." -ForegroundColor "Yellow"
    Install-Module PowershellGet -Scope CurrentUser -Force -MinimumVersion 3.0.11-beta -AllowPrerelease
    Install-Module PSWindowsUpdate -Scope CurrentUser -Force
    Install-Module PSReadLine -Scope CurrentUser -AllowPrerelease -Force
    Install-Module Posh-Git -Scope CurrentUser -Force
    #Install-Module Oh-My-Posh -Scope CurrentUser -AllowPrerelease -Force


    # Chocolatey
    Write-Host "Installing Desktop Utilities..." -ForegroundColor "Yellow"
    if (!(Test-CommandExists 'choco')) {
        Invoke-Expression (new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')
        RefreshEnv.cmd
        choco feature enable -n=allowGlobalConfirmation
    }

    ## system and cli
    choco install powershell-core     --limit-output
    choco install curl                --limit-output
    choco install python3             --limit-output
    choco install explorerplusplus    --limit-output
    choco install freecommander-xe.install --limit-output
    winget install Git.Git
    winget install 7zip.7zip
    winget install Microsoft.NuGet
    winget install CoreyButler.NVMforWindows

    #choco install ruby                --limit-output
    #choco install webpi               --limit-output #Helps install IIS


    ## fonts
    choco install sourcecodepro       --limit-output
    choco install nerdfont-hack       --limit-output

    ## browsers
    winget install Google.Chrome

    ## dev tools and frameworks
    winget install Neovim.Neovim
    winget install Maximus5.ConEmu
    winget install Microsoft.VisualStudioCode
    winget install OliverSchwendener.ueli
    choco install paint.net           --limit-output

    #winget install WinMerge.WinMerge
    #winget install Microsoft.WinDbg
    #choco install repoz               --limit-output

    ## better experience
    winget install Microsoft.PowerToys --source winget
    WinGet install QL-Win.QuickLook
    WinGet install File-New-Project.EarTrumpet
    WinGet install NirSoft.ShellExView
    WinGet install Lexikos.AutoHotkey

    #WinGet install AntibodySoftware.WizTree
    #choco install alt-tab-terminator  --limit-output

    # Windows Subsystem for Linux
    if ($setLinuxDistroUri) {
        Enable-WindowsOptionalFeature -Online -All -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null
        Invoke-WebRequest -Uri $setLinuxDistroUri -OutFile linuxDistro.appx -UseBasicParsing
        Add-AppxPackage .\linuxDistro.appx
        Remove-Item linuxDistro.appx
    }

    RefreshEnv.cmd
}

Install-Apps