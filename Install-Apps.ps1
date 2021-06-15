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


function Install-Apps() {
    # Update Help for Modules
    Write-Host "Updating Help..." -ForegroundColor "Yellow"
    Update-Help -Force

    # Package Providers
    Write-Host "Installing Package Providers..." -ForegroundColor "Yellow"
    Get-PackageProvider NuGet -Force | Out-Null
    # Chocolatey Provider is not ready yet. Use normal Chocolatey
    #Get-PackageProvider Chocolatey -Force
    #Set-PackageSource -Name chocolatey -Trusted


    # Install PowerShell Modules
    Write-Host "Installing PowerShell Modules..." -ForegroundColor "Yellow"
    Install-Module PowershellGet -Scope CurrentUser -Force
    Install-Module PSWindowsUpdate -Scope CurrentUser -Force
    Install-Module PSReadLine -Scope CurrentUser -AllowPrerelease -Force
    Install-Module Posh-Git -Scope CurrentUser -Force
    Install-Module Oh-My-Posh -Scope CurrentUser -AllowPrerelease -Force


    # Chocolatey
    Write-Host "Installing Desktop Utilities..." -ForegroundColor "Yellow"
    if ($null -eq (which cinst)) {
        Invoke-Expression (new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')
        RefreshEnv.cmd
        choco feature enable -n=allowGlobalConfirmation
    }

    ## system and cli
    choco install powershell-core     --limit-output
    choco install curl                --limit-output
    choco install nuget.commandline   --limit-output
    choco install webpi               --limit-output
    choco install git.install         --limit-output -params '"/GitAndUnixToolsOnPath /NoShellIntegration"'
    choco install nvm.portable        --limit-output
    choco install python              --limit-output
    choco install explorerplusplus    --limit-output
    choco install ruby                --limit-output
    winget install 7zip.7zip

    ## fonts
    #choco install sourcecodepro       --limit-output
    choco install nerdfont-hack       --limit-output

    ## browsers
    choco install GoogleChrome        --limit-output

    ## dev tools and frameworks
    choco install neovim              --limit-output
    choco install winmerge            --limit-output
    choco install conemu              --limit-output
    choco install vscode              --limit-output
    choco install visualstudio2019enterprise --limit-output
    choco install paint.net           --limit-output
    WinGet install WinMerge.WinMerge
    WinGet install Microsoft.WinDbg
    choco install everything --params "/start-menu-shortcuts /run-on-system-startup" --limit-output
    choco install ueli                --limit-output
    choco install repoz               --limit-output

    ## better experience
    WinGet install powertoys
    WinGet install QL-Win.QuickLook
    WinGet install File-New-Project.EarTrumpet
    WinGet install NirSoft.ShellExView
    WinGet install AntibodySoftware.WizTree
    WinGet install Lexikos.AutoHotkey
    choco install freecommander-xe.install --limit-output
    # choco install alt-tab-terminator  --limit-output

    RefreshEnv.cmd


    # NodeJS Setup
    if (Test-CommandExists "nvm") {
        Write-Host "Installing NodeJS..." -ForegroundColor "Yellow"
        nvm on
        $nodeLtsVersion = choco search nodejs-lts --limit-output | ConvertFrom-String -TemplateContent "{Name:package-name}\|{Version:1.11.1}" | Select-Object -ExpandProperty "Version"
        nvm install $nodeLtsVersion
        nvm use $nodeLtsVersion
        Remove-Variable nodeLtsVersion

        Write-Host "Installing Node Packages..." -ForegroundColor "Yellow"
        npm update npm
        npm install -g gulp
        npm install -g mocha
        npm install -g node-inspector
        npm install -g yo
    }
    else {
        Write-Host -ForegroundColor Red "Couldn't setup NodeJS. Might need to restart PC before nvm is available"
    }


    # Ruby & Janus setup (Vim)
    if (Test-CommandExists "gem") {
        gem pristine --all --env-shebang
        
        # Janus for vim
        ## https://github.com/carlhuda/janus
        ## This is a distribution of plug-ins and mappings for Vim, Gvim and MacVim.
        ## Some plugins include: CtrlP, NERDCommenter NERDTree, Syntastic, vim-multiple-cursors, etc.
        if ((which curl) -and (which vim) -and (which rake) -and (which bash)) {
            Write-Host "Installing Janus..." -ForegroundColor "Yellow"
            curl.exe -L https://bit.ly/janus-bootstrap | bash
        }
    }
    else {
        Write-Host -ForegroundColor Red "Couldn't setup Ruby gem with Janus (vim plugins)" 
    }




    # Windows Features
    Write-Host "Installing Windows Features..." -ForegroundColor "Yellow"

    # IIS Base Configuration
    Enable-WindowsOptionalFeature -Online -All -FeatureName `
        "IIS-BasicAuthentication", `
        "IIS-DefaultDocument", `
        "IIS-DirectoryBrowsing", `
        "IIS-HttpCompressionDynamic", `
        "IIS-HttpCompressionStatic", `
        "IIS-HttpErrors", `
        "IIS-HttpLogging", `
        "IIS-ISAPIExtensions", `
        "IIS-ISAPIFilter", `
        "IIS-ManagementConsole", `
        "IIS-RequestFiltering", `
        "IIS-StaticContent", `
        "IIS-WebSockets", `
        "IIS-WindowsAuthentication" `
        -NoRestart | Out-Null

    # ASP.NET Base Configuration
    Enable-WindowsOptionalFeature -Online -All -FeatureName `
        "NetFx3", `
        "NetFx4-AdvSrvs", `
        "NetFx4Extended-ASPNET45", `
        "IIS-NetFxExtensibility", `
        "IIS-NetFxExtensibility45", `
        "IIS-ASPNET", `
        "IIS-ASPNET45" `
        -NoRestart | Out-Null

    # Web Platform Installer for remaining Windows features
    if (Test-CommandExists "wbpicmd") {
        webpicmd /Install /AcceptEula /Products:"UrlRewrite2"
    }
    else {
        Write-Host -ForegroundColor Red "Couldn't install UrlRewrite2"
    }
}

Install-Apps