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

function Install-NvmWindows {
    <#
    .SYNOPSIS
        Installs NVM for Windows without requiring admin permissions.
    .DESCRIPTION
        Downloads the latest nvm-noinstall.zip from GitHub, extracts it to
        %LOCALAPPDATA%\nvm, configures settings.txt, and sets user environment
        variables (NVM_HOME, NVM_SYMLINK, PATH).
    #>
    [CmdletBinding()]
    param(
        [string]$InstallDir = "$env:LOCALAPPDATA\nvm",
        [string]$SymlinkDir = "$env:LOCALAPPDATA\nodejs"
    )

    # Get latest release version from GitHub API
    Write-Host "Fetching latest NVM for Windows release..." -ForegroundColor Yellow
    $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/coreybutler/nvm-windows/releases/latest"
    $version = $releaseInfo.tag_name
    $downloadUrl = "https://github.com/coreybutler/nvm-windows/releases/download/$version/nvm-noinstall.zip"

    Write-Host "Installing NVM for Windows $version to $InstallDir" -ForegroundColor Yellow

    # Create install directory
    if (!(Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    }

    # Download and extract
    $zipPath = "$InstallDir\nvm-noinstall.zip"
    Write-Host "Downloading $downloadUrl..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "Extracting to $InstallDir..."
    Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
    Remove-Item $zipPath

    # Create settings.txt with expanded paths
    $settingsContent = @"
root: $InstallDir
path: $SymlinkDir
"@
    Set-Content -Path "$InstallDir\settings.txt" -Value $settingsContent -Encoding ASCII
    Write-Host "Created settings.txt"

    # Set user environment variables (persist across sessions)
    [Environment]::SetEnvironmentVariable("NVM_HOME", $InstallDir, "User")
    [Environment]::SetEnvironmentVariable("NVM_SYMLINK", $SymlinkDir, "User")
    Write-Host "Set NVM_HOME=$InstallDir"
    Write-Host "Set NVM_SYMLINK=$SymlinkDir"

    # Add to user PATH if not already present
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathsToAdd = @($InstallDir, $SymlinkDir)
    $modified = $false

    foreach ($p in $pathsToAdd) {
        if ($userPath -notlike "*$p*") {
            $userPath = "$userPath;$p"
            $modified = $true
        }
    }

    if ($modified) {
        [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
        Write-Host "Added NVM directories to user PATH"
    }

    # Set for current session
    $env:NVM_HOME = $InstallDir
    $env:NVM_SYMLINK = $SymlinkDir
    $env:Path = "$env:Path;$InstallDir;$SymlinkDir"

    Write-Host "NVM for Windows installed successfully!" -ForegroundColor Green
    Write-Host "Run 'nvm install lts' then 'nvm use lts' to get started." -ForegroundColor Cyan
    Write-Host -ForegroundColor Yellow "Note: To use ``nvm use`` command without elevating, Windows settings need to have Developer Mode enabled to create symlinks."
}

function Install-PyEnvWindows {
    [CmdletBinding()]
    param(
        [string]$InstallDir = "$env:LOCALAPPDATA\pyenv"
    )

    Write-Host "Installing pyenv-win to $InstallDir" -ForegroundColor Yellow

    # Create install directory
    if (!(Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    }

    # Clone pyenv-win repository
    git clone https://github.com/pyenv-win/pyenv-win.git $InstallDir

    # Set user environment variables (persist across sessions)
    [Environment]::SetEnvironmentVariable("PYENV", $InstallDir, "User")
    [Environment]::SetEnvironmentVariable("PYENV_HOME", "$InstallDir\pyenv-win", "User")
    [Environment]::SetEnvironmentVariable("PYENV_ROOT", "$InstallDir\pyenv-win", "User")
    Write-Host "Set PYENV, PYENV_HOME, PYENV_ROOT environment variables"

    # Add to user PATH if not already present
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathsToAdd = @("$InstallDir\pyenv-win\bin", "$InstallDir\pyenv-win\shims")
    $modified = $false
    foreach ($p in $pathsToAdd) {
        if ($userPath -notlike "*$p*") {
            $userPath = "$userPath;$p"
            $modified = $true
        }
    }
    if ($modified) {
        [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
        Write-Host "Added pyenv-win directories to user PATH"
    }
    # Set for current session
    $env:PYENV = $InstallDir
    $env:PYENV_HOME = "$InstallDir\pyenv-win"
    $env:PYENV_ROOT = "$InstallDir\pyenv-win"
    $env:Path = "$env:Path;$InstallDir\pyenv-win\bin;$InstallDir\pyenv-win\shims"

    # Might need to run `pyenv update` to get latest versions
    # If that fails might need to apply the fix here: https://github.com/pyenv-win/pyenv-win/issues/715#issuecomment-3139835392
    # Replacing the broken pyenv-update.vbs file under the libexec folder
    Write-Host -ForegroundColor Yellow "To install a Python version, run 'pyenv install 3.14' and set it with 'pyenv global 3.14'"
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
    winget install Microsoft.PowerShell --scope user

    ## system and cli
    winget install Git.Git --scope user
    winget install cURL.cURL --scope user
    winget install Microsoft.NuGet --scope user
    winget install JanDeDobbeleer.OhMyPosh --scope user

    ## dev tools and frameworks
    winget install Microsoft.VisualStudioCode --scope user --override '/SILENT /mergetasks="!runcode,addcontextmenufiles,addcontextmenufolders"'
    winget install Microsoft.WinDbg --scope user
    #choco install python3             --limit-output
    #choco install ruby                --limit-output
    #choco install webpi               --limit-output #Helps install IIS

    ## better experience
    winget install Microsoft.PowerToys --scope user
    # winget install dotPDN.PaintDotNet --scope user
    # winget install File-New-Project.EarTrumpet --scope user
    winget install JAMSoftware.TreeSize.Free --scope user

    # Windows Subsystem for Linux
    if ($setLinuxDistroUri) {
        Enable-WindowsOptionalFeature -Online -All -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null
        Invoke-WebRequest -Uri $setLinuxDistroUri -OutFile linuxDistro.appx -UseBasicParsing
        Add-AppxPackage .\linuxDistro.appx
        Remove-Item linuxDistro.appx
    }

    ## fonts
    oh-my-posh font install SourceCodePro
    oh-my-posh font install Hack
    oh-my-posh font install FiraCode

    # These don't have a user scope option
    Install-NvmWindows
    # winget install 7zip.7zip
    # winget install Neovim.Neovim
    # winget install Maximus5.ConEmu
    # winget install Google.Chrome
    # winget install Lexikos.AutoHotkey
    Write-Host -ForegroundColor Yellow "The following apps were not available with user scope..."
    Write-Host "* 7-Zip"
    Write-Host "* Neovim"
    Write-Host "* ConEmu"
    Write-Host "* Google Chrome"
    Write-Host "* Chocolatey"

    Write-Host -ForegroundColor Yellow "To update Windows PowerShell use the *.msixbundle from: https://github.com/PowerShell/PowerShell/releases"

    RefreshEnv.cmd
}

Install-Apps