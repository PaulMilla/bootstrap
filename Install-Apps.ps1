# Check to see if we are currently running "as Administrator"
if (!(Verify-Elevated)) {
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   $newProcess.Verb = "runas";
   [System.Diagnostics.Process]::Start($newProcess);

   exit
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
        Refresh-Environment
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

    ## browsers
    choco install GoogleChrome        --limit-output

    ## dev tools and frameworks
    choco install neovim              --limit-output
    choco install winmerge            --limit-output
    choco install conemu              --limit-output
    choco install vscode              --limit-output
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
    choco install alt-tab-terminator  --limit-output

    Refresh-Environment


    # NodeJS Setup
    nvm on
    $nodeLtsVersion = choco search nodejs-lts --limit-output | ConvertFrom-String -TemplateContent "{Name:package-name}\|{Version:1.11.1}" | Select-Object -ExpandProperty "Version"
    nvm install $nodeLtsVersion
    nvm use $nodeLtsVersion
    Remove-Variable nodeLtsVersion


    ## Node Packages
    Write-Host "Installing Node Packages..." -ForegroundColor "Yellow"
    if (which npm) {
        npm update npm
        npm install -g gulp
        npm install -g mocha
        npm install -g node-inspector
        npm install -g yo
    }


    # Ruby Setup
    gem pristine --all --env-shebang


    # Janus for vim
    ## https://github.com/carlhuda/janus
    ## This is a distribution of plug-ins and mappings for Vim, Gvim and MacVim.
    ## Some plugins include: CtrlP, NERDCommenter NERDTree, Syntastic, vim-multiple-cursors, etc.
    Write-Host "Installing Janus..." -ForegroundColor "Yellow"
    if ((which curl) -and (which vim) -and (which rake) -and (which bash)) {
        curl.exe -L https://bit.ly/janus-bootstrap | bash
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
    webpicmd /Install /AcceptEula /Products:"UrlRewrite2"
}

Install-Apps