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

Function Install-PSExtensions {
    # Update Help for Modules
    #########################
    Write-Host "Updating Help..." -ForegroundColor "Yellow"
    Update-Help -Force

    # https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    Write-Host "Ensuring latest PowerShell is installed..." -ForegroundColor "Yellow"
    winget install Microsoft.PowerShell

    # Install Package Providers
    ###########################
    Write-Host "Installing Package Providers..." -ForegroundColor "Yellow"
    if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -Force
    }

    # Get-PackageProvider NuGet -Force | Out-Null
    # Chocolatey Provider is not ready yet. Use normal Chocolatey
    #Get-PackageProvider Chocolatey -Force | Out-Null
    #Set-PackageSource -Name chocolatey -Trusted

    # Install PowerShell Modules
    ############################
    # If having 'Access to the cloud file is denied': https://github.com/PowerShell/PowerShellGet/issues/299
    Write-Host "Installing PowerShell Modules..." -ForegroundColor "Yellow"
    Install-Module PSWindowsUpdate -Scope CurrentUser -Force
    Install-Module PSReadLine -Scope CurrentUser -AllowPrerelease -Force
    Install-Module Posh-Git -Scope CurrentUser -Force
}

try {
    Test-Elevated
    Install-PSExtensions
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor "Red"
    Write-Host "If you're running PowerShell Core (7+), try running this script in Admin Windows PowerShell (5.1) instead." -ForegroundColor "Yellow"
    throw
}