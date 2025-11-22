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
        Write-Host "Can't verify if this is an Administrator shell. Only continue if it is..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

function Install-Apps {
    [CmdletBinding()]
    param (
        # Linux Distro
        # Select a distro url at: https://docs.microsoft.com/en-us/windows/wsl/install-manual#downloading-distros
        # Or empty for none. Ex: https://aka.ms/wsl-debian-gnulinux
        [Parameter()]
        [string]$setLinuxDistroUri = ""
    )
    # Install PowerShell
    ####################
    winget install Microsoft.PowerShell

    # Chocolatey
    Write-Host "Installing Desktop Utilities..." -ForegroundColor "Yellow"
    if (!(Test-CommandExists 'choco')) {
        Invoke-Expression (new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')
        RefreshEnv.cmd
        choco feature enable -n=allowGlobalConfirmation
    }

    ## fonts
    choco install sourcecodepro       --limit-output
    choco install nerdfont-hack       --limit-output
    choco install firacode            --limit-output

    ## system and cli
    winget install cURL.cURL
    winget install Git.Git
    winget install 7zip.7zip
    winget install Microsoft.NuGet
    winget install JanDeDobbeleer.OhMyPosh

    ## browsers
    # winget install Google.Chrome

    ## dev tools and frameworks
    winget install Neovim.Neovim
    winget install Microsoft.VisualStudioCode --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
    winget install Microsoft.WinDbg
    winget install Maximus5.ConEmu
    #winget install CoreyButler.NVMforWindows
    #choco install python3             --limit-output
    #choco install ruby                --limit-output
    #choco install webpi               --limit-output #Helps install IIS

    ## better experience
    winget install dotPDN.PaintDotNet
    winget install Microsoft.PowerToys
    WinGet install File-New-Project.EarTrumpet
    WinGet install Lexikos.AutoHotkey
    winget install JAMSoftware.TreeSize.Free

    # Windows Subsystem for Linux
    if ($setLinuxDistroUri) {
        Enable-WindowsOptionalFeature -Online -All -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null
        Invoke-WebRequest -Uri $setLinuxDistroUri -OutFile linuxDistro.appx -UseBasicParsing
        Add-AppxPackage .\linuxDistro.appx
        Remove-Item linuxDistro.appx
    }

    RefreshEnv.cmd
}

Test-Elevated
Install-Apps