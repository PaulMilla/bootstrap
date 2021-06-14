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
    [string]$setLinuxDistroUri = "https://aka.ms/wsl-debian-gnulinux"
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

<# TODO: These can probaby be moved to a .reg file instead #>
function Set-Registry() {
    ###############################################################################
    ### Privacy                                                                   #
    ###############################################################################
    Write-Host "Configuring Privacy..." -ForegroundColor "Yellow"

    # General: Don't let apps use advertising ID for experiences across apps: Allow: 1, Disallow: 0
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Type Folder | Out-Null}
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
    Remove-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Id" -ErrorAction SilentlyContinue

    # General: Disable Application launch tracking: Enable: 1, Disable: 0
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start-TrackProgs" 0

    # General: Disable SmartScreen Filter: Enable: 1, Disable: 0
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" "EnableWebContentEvaluation" 0

    # General: Disable key logging & transmission to Microsoft: Enable: 1, Disable: 0
    # Disabled when Telemetry is set to Basic
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Input")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Input" -Type Folder | Out-Null}
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Input\TIPC")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Input\TIPC" -Type Folder | Out-Null}
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Input\TIPC" "Enabled" 0

    # General: Opt-out from websites from accessing language list: Opt-in: 0, Opt-out 1
    Set-ItemProperty "HKCU:\Control Panel\International\User Profile" "HttpAcceptLanguageOptOut" 1

    # General: Disable SmartGlass: Enable: 1, Disable: 0
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SmartGlass" "UserAuthPolicy" 0

    # General: Disable SmartGlass over BlueTooth: Enable: 1, Disable: 0
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\SmartGlass" "BluetoothPolicy" 0

    # General: Disable suggested content in settings app: Enable: 1, Disable: 0
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338393Enabled" 0
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338394Enabled" 0
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338396Enabled" 0

    # Camera: Don't let apps use camera: Allow, Deny
    # Build 1709
    # Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{E5323777-F976-4f5b-9B55-B94699C46E44}" "Value" "Deny"
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" "Value" "Deny"

    # Microphone: Don't let apps use microphone: Allow, Deny
    # Build 1709
    #Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{2EEF81BE-33FA-4800-9670-1CD474972C3F}" "Value" "Deny"
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" "Value" "Deny"

    # Notifications: Don't let apps access notifications: Allow, Deny
    # Build 1511
    #Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{21157C1F-2651-4CC1-90CA-1F28B02263F6}" "Value" "Deny"
    # Build 1607, 1709
    #if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{52079E78-A92B-413F-B213-E8FE35712E72}")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{52079E78-A92B-413F-B213-E8FE35712E72}" -Type Folder | Out-Null}
    #Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{52079E78-A92B-413F-B213-E8FE35712E72}" "Value" "Deny"
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userNotificationListener" "Value" "Deny"

    # Speech, Inking, & Typing: Stop "Getting to know me"
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Type Folder | Out-Null}
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\InputPersonalization" "RestrictImplicitTextCollection" 1
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 1
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Type Folder | Out-Null}
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" 0
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" "AcceptedPrivacyPolicy" 0
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" "HasAccepted" 0

    # Account Info: Don't let apps access name, picture, and other account info: Allow, Deny
    # Build 1709
    #if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{C1D23ACC-752B-43E5-8448-8D0E519CD6D6}")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{C1D23ACC-752B-43E5-8448-8D0E519CD6D6}" -Type Folder | Out-Null}
    #Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{C1D23ACC-752B-43E5-8448-8D0E519CD6D6}" "Value" "Deny"
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userAccountInformation" "Value" "Deny"

    # Contacts: Don't let apps access contacts: Allow, Deny
    # Build 1709
    #if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{7D7E8402-7C54-4821-A34E-AEEFD62DED93}")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{7D7E8402-7C54-4821-A34E-AEEFD62DED93}" -Type Folder | Out-Null}
    #Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{7D7E8402-7C54-4821-A34E-AEEFD62DED93}" "Value" "Deny"
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts" "Value" "Deny"

    # Calendar: Don't let apps access calendar: Allow, Deny
    # Build 1709
    #if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{D89823BA-7180-4B81-B50C-7E471E6121A3}")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{D89823BA-7180-4B81-B50C-7E471E6121A3}" -Type Folder | Out-Null}
    #Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{D89823BA-7180-4B81-B50C-7E471E6121A3}" "Value" "Deny"
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appointments" "Value" "Deny"

    # Call History: Don't let apps make phone calls: Allow, Deny
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCall" "Value" "Deny"

    # Call History: Don't let apps access call history: Allow, Deny
    # Build 1709
    #if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{8BC668CF-7728-45BD-93F8-CF2B3B41D7AB}")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{8BC668CF-7728-45BD-93F8-CF2B3B41D7AB}" -Type Folder | Out-Null}
    #Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{8BC668CF-7728-45BD-93F8-CF2B3B41D7AB}" "Value" "Deny"
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\phoneCallHistory" "Value" "Deny"

    # Diagnostics: Don't let apps access diagnostics of other apps: Allow, Deny
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics" "Value" "Deny"

    # Documents: Don't let apps access documents: Allow, Deny
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\documentsLibrary" "Value" "Deny"

    # Email: Don't let apps read and send email: Allow, Deny
    # Build 1709
    #if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{9231CB4C-BF57-4AF3-8C55-FDA7BFCC04C5}")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{9231CB4C-BF57-4AF3-8C55-FDA7BFCC04C5}" -Type Folder | Out-Null}
    #Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{9231CB4C-BF57-4AF3-8C55-FDA7BFCC04C5}" "Value" "Deny"
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\email" "Value" "Deny"

    # File System: Don't let apps access the file system: Allow, Deny
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\broadFileSystemAccess" "Value" "Deny"

    # Location: Don't let apps access the location: Allow, Deny
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny"

    # Messaging: Don't let apps read or send messages (text or MMS): Allow, Deny
    # Build 1709
    #if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{992AFA70-6F47-4148-B3E9-3003349C1548}")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{992AFA70-6F47-4148-B3E9-3003349C1548}" -Type Folder | Out-Null}
    #Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{992AFA70-6F47-4148-B3E9-3003349C1548}" "Value" "Deny"
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\chat" "Value" "Deny"

    # Pictures: Don't let apps access pictures: Allow, Deny
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\picturesLibrary" "Value" "Deny"

    # Radios: Don't let apps control radios (like Bluetooth): Allow, Deny
    # Build 1709
    #if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{A8804298-2D5F-42E3-9531-9C8C39EB29CE}")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{A8804298-2D5F-42E3-9531-9C8C39EB29CE}" -Type Folder | Out-Null}
    #Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\{A8804298-2D5F-42E3-9531-9C8C39EB29CE}" "Value" "Deny"
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios" "Value" "Deny"

    # Tasks: Don't let apps access the tasks: Allow, Deny
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userDataTasks" "Value" "Deny"

    # Other Devices: Don't let apps share and sync with non-explicitly-paired wireless devices over uPnP: Allow, Deny
    # Build 1709
    #if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled" -Type Folder | Out-Null}
    #Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\LooselyCoupled" "Value" "Deny"
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync" "Value" "Deny"

    # Videos: Don't let apps access videos: Allow, Deny
    # Build 1903
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\videosLibrary" "Value" "Deny"

    # Feedback: Windows should never ask for my feedback
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf" -Type Folder | Out-Null}
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules")) {New-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Type Folder | Out-Null}
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" "NumberOfSIUFInPeriod" 0

    # Feedback: Telemetry: Send Diagnostic and usage data: Basic: 1, Enhanced: 2, Full: 3
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 1

    # Start Menu: Disable suggested content: Enable: 1, Disable: 0
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338388Enabled" 0

    ###############################################################################
    ### Devices and Startup                                                       #
    ###############################################################################
    Write-Host "Configuring Devices and Startup..." -ForegroundColor "Yellow"

    # Sound: Disable Startup Sound
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStartupSound" 1
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" "DisableStartupSound" 1

    # SSD: Disable SuperFetch
    Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnableSuperfetch" 0

    # Network: Disable WiFi Sense
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" "AutoConnectAllowedOEM" 0

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

    # Explorer: Show path in title bar
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" "FullPath" 1

    # Explorer: Avoid creating Thumbs.db files on network volumes
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "DisableThumbnailsOnNetworkFolders" 1

    # Taskbar: Enable small icons
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarSmallIcons" 1

    # Taskbar: Don't show Windows Store Apps on Taskbar
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "StoreAppsOnTaskbar" 0

    # Taskbar: Disable Bing Search
    # Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\ConnectedSearch" "ConnectedSearchUseWeb" 0 # For Windows 8.1
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0 # For Windows 10

    # Taskbar: Disable Cortana
    Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0

    # SysTray: Action Center, Network, and Volume icons
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "HideSCAHealth" 1  # Hide Action Center
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "HideSCANetwork" 0 # Show Network
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "HideSCAVolume" 0  # Show Volume
    #Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "HideSCAPower" 1  # Hide Power

    # Taskbar: Show colors on Taskbar, Start, and SysTray: Disabled: 0, Taskbar, Start, & SysTray: 1, Taskbar Only: 2
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "ColorPrevalence" 1

    # Titlebar: Disable theme colors on titlebar
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\DWM" "ColorPrevalence" 0

    # Recycle Bin: Disable Delete Confirmation Dialog
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "ConfirmFileDelete" 0

    # Sync Settings: Disable automatically syncing settings with other Windows 10 devices
    # Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Personalization" "Enabled" 0 # Theme
    # Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials" "Enabled" 0     # Passwords
    # Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" "Enabled" 0        # Language
    # Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Accessibility" "Enabled" 0   # Accessibility / Ease of Access
    # Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Windows" "Enabled" 0         # Other Windows Settings
    #Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\BrowserSettings" "Enabled" 0 # Internet Explorer (Removed in 1903)

    ###############################################################################
    ### Default Windows Applications                                              #
    ###############################################################################
    
    # Prevent "Suggested Applications" from returning
    if (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\CloudContent")) {New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\CloudContent" -Type Folder | Out-Null}
    Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1

    ###############################################################################
    ### Accessibility and Ease of Use                                             #
    ###############################################################################
    Write-Host "Configuring Accessibility..." -ForegroundColor "Yellow"

    # Turn Off Windows Narrator
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Narrator.exe")) {New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Narrator.exe" -Type Folder | Out-Null}
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Narrator.exe" "Debugger" "%1"

    # Launch Screen Snipping when pressing the 'Print Screen' button
    Set-ItemProperty "HKCU:\Control Panel\Keyboard" "PrintScreenKeyForSnippingEnabled" 1

    # "Window Snap" Automatic Window Arrangement Enabled: 1, Disabled: 0
    Set-ItemProperty "HKCU:\Control Panel\Desktop" "WindowArrangementActive" 1

    # Automatic fill to space on Window Snap Enabled: 1, Disabled: 0
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "SnapFill" 1

    # Hide all windows when "shaking" one
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "DisallowShaking" 1

    # Disable showing what can be snapped next to a window
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "SnapAssist" 0

    # Disable automatic resize of adjacent windows on snap
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "JointResize" 0

    # Disable auto-correct
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\TabletTip\1.7" "EnableAutocorrection" 0

    ###############################################################################
    ### Windows Update & Application Updates                                      #
    ###############################################################################
    Write-Host "Configuring Windows Update..." -ForegroundColor "Yellow"

    # Ensure Windows Update registry paths
    if (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate")) {New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Type Folder | Out-Null}
    if (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU")) {New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -Type Folder | Out-Null}

    # Enable Automatic Updates
    Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoUpdate" 0

    # Disable automatic reboot after install
    Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" "NoAutoRebootWithLoggedOnUsers" 1
    Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoRebootWithLoggedOnUsers" 1

    # Configure to Auto-Download but not Install: NotConfigured: 0, Disabled: 1, NotifyBeforeDownload: 2, NotifyBeforeInstall: 3, ScheduledInstall: 4
    Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUOptions" 3

    # Include Recommended Updates
    Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" "IncludeRecommendedUpdates" 1

    # Delivery Optimization: Download from 0: Http Only [Disable], 1: Peering on LAN, 2: Peering on AD / Domain, 3: Peering on Internet, 99: No peering, 100: Bypass & use BITS
    #Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" "DODownloadMode" 0
    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization")) {New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Type Folder | Out-Null}
    if (!(Test-Path "HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Windows\DeliveryOptimization")) {New-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Windows\DeliveryOptimization" -Type Folder | Out-Null}
    Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0
    Set-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0

    ###############################################################################
    ### Internet Explorer                                                         #
    ###############################################################################
    Write-Host "Configuring Internet Explorer..." -ForegroundColor "Yellow"

    # Set home page to `about:blank` for faster loading
    Set-ItemProperty "HKCU:\Software\Microsoft\Internet Explorer\Main" "Start Page" "about:blank"

    # Disable 'Default Browser' check: "yes" or "no"
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Internet Explorer\Main" "Check_Associations" "no"

    # Disable Password Caching [Disable Remember Password]
    Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" "DisablePasswordCaching" 1

    ###############################################################################
    ### Disk Cleanup (CleanMgr.exe)                                               #
    ###############################################################################
    Write-Host "Configuring Disk Cleanup..." -ForegroundColor "Yellow"

    # Cleanup Files by Group: 0=Disabled, 2=Enabled
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache"                                  "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files"                     "StateFlags6174" 2   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files"                         "StateFlags6174" 2   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Offline Pages Files"                          "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files"                             "StateFlags6174" 2   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations"                       "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin"                                  "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\RetailDemo Offline Content"                   "StateFlags6174" 2   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup"                         "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files"                              "StateFlags6174" 2   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files"               "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files"                  "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files"                              "StateFlags6174" 2   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files"                        "StateFlags6174" 2   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache"                              "StateFlags6174" 2   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup"                               "StateFlags6174" 2   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files"                      "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions"                           "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender"                             "StateFlags6174" 2   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Archive Files"        "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Queue Files"          "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Archive Files" "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Queue Files"   "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Temp Files"           "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files"               "StateFlags6174" 0   -ErrorAction SilentlyContinue
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files"                    "StateFlags6174" 0   -ErrorAction SilentlyContinue
}

function Set-WindowsSettings() {
    ###############################################################################
    ### Security and Identity                                                     #
    ###############################################################################
    Write-Host "Configuring System..." -ForegroundColor "Yellow"

    # Set Computer Name
    if ($setComputerName) {
        (Get-WmiObject Win32_ComputerSystem).Rename($setComputerName) | Out-Null
    }

    # Set DisplayName for my account. Use only if you are not using a Microsoft Account
    if ($setDisplayName) {
        $myIdentity=[System.Security.Principal.WindowsIdentity]::GetCurrent()
        $user = Get-WmiObject Win32_UserAccount | Where-Object {$_.Caption -eq $myIdentity.Name}
        $user.FullName = $setDisplayName
        $user.Put() | Out-Null
        Remove-Variable user
        Remove-Variable myIdentity
    }

    # Enable Developer Mode
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" "AllowDevelopmentWithoutDevLicense" 1

    # Windows Subsystem for Linux
    if ($setLinuxDistroUri) {
        Enable-WindowsOptionalFeature -Online -All -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue | Out-Null
        Invoke-WebRequest -Uri $setLinuxDistroUri -OutFile linuxDistro.appx -UseBasicParsing
        Add-AppxPackage .\linuxDistro.appx
        Remove-Item linuxDistro.appx
    }

    ###############################################################################
    ### Lock Screen                                                               #
    ###############################################################################

    # Enable Custom Background on the Login / Lock Screen
    if ($setLockScreenBackground) {
        Set-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\Personalization" "LockScreenImage" $setLockScreenBackground
    }

    ###############################################################################
    ### Power                                                                     #
    ###############################################################################
    Write-Host "Configuring Power..." -ForegroundColor "Yellow"
    
    # Power: Disable Hibernation
    powercfg /hibernate off

    # Power: Set standby delay to 24 hours
    powercfg /change /standby-timeout-ac 1440

    ###############################################################################
    ### Default Windows Applications                                              #
    ###############################################################################
    Write-Host "Configuring Default Windows Applications..." -ForegroundColor "Yellow"

    # Uninstall 3D Builder
    Get-AppxPackage "Microsoft.3DBuilder" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.3DBuilder" | Remove-AppxProvisionedPackage -Online

    # Uninstall Alarms and Clock
    Get-AppxPackage "Microsoft.WindowsAlarms" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.WindowsAlarms" | Remove-AppxProvisionedPackage -Online

    # Uninstall Autodesk Sketchbook
    Get-AppxPackage "*.AutodeskSketchBook" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "*.AutodeskSketchBook" | Remove-AppxProvisionedPackage -Online

    # Uninstall Bing Finance
    Get-AppxPackage "Microsoft.BingFinance" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.BingFinance" | Remove-AppxProvisionedPackage -Online

    # Uninstall Bing News
    Get-AppxPackage "Microsoft.BingNews" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.BingNews" | Remove-AppxProvisionedPackage -Online

    # Uninstall Bing Sports
    Get-AppxPackage "Microsoft.BingSports" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.BingSports" | Remove-AppxProvisionedPackage -Online

    # Uninstall Bing Weather
    Get-AppxPackage "Microsoft.BingWeather" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.BingWeather" | Remove-AppxProvisionedPackage -Online

    # Uninstall Bubble Witch 3 Saga
    Get-AppxPackage "king.com.BubbleWitch3Saga" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "king.com.BubbleWitch3Saga" | Remove-AppxProvisionedPackage -Online

    # Uninstall Calendar and Mail
    Get-AppxPackage "Microsoft.WindowsCommunicationsApps" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.WindowsCommunicationsApps" | Remove-AppxProvisionedPackage -Online

    # Uninstall Candy Crush Soda Saga
    Get-AppxPackage "king.com.CandyCrushSodaSaga" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "king.com.CandyCrushSodaSaga" | Remove-AppxProvisionedPackage -Online

    # Uninstall Disney Magic Kingdoms
    Get-AppxPackage "*.DisneyMagicKingdoms" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "*.DisneyMagicKingdoms" | Remove-AppxProvisionedPackage -Online

    # Uninstall Dolby
    Get-AppxPackage "DolbyLaboratories.DolbyAccess" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "DolbyLaboratories.DolbyAccess" | Remove-AppxProvisionedPackage -Online

    # Uninstall Facebook
    Get-AppxPackage "*.Facebook" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "*.Facebook" | Remove-AppxProvisionedPackage -Online

    # Uninstall Get Office, and it's "Get Office365" notifications
    Get-AppxPackage "Microsoft.MicrosoftOfficeHub" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.MicrosoftOfficeHub" | Remove-AppxProvisionedPackage -Online

    # Uninstall Get Started
    Get-AppxPackage "Microsoft.GetStarted" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.GetStarted" | Remove-AppxProvisionedPackage -Online

    # Uninstall Maps
    Get-AppxPackage "Microsoft.WindowsMaps" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.WindowsMaps" | Remove-AppxProvisionedPackage -Online

    # Uninstall March of Empires
    Get-AppxPackage "*.MarchofEmpires" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "*.MarchofEmpires" | Remove-AppxProvisionedPackage -Online

    # Uninstall Messaging
    Get-AppxPackage "Microsoft.Messaging" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.Messaging" | Remove-AppxProvisionedPackage -Online

    # Uninstall Mobile Plans
    Get-AppxPackage "Microsoft.OneConnect" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.OneConnect" | Remove-AppxProvisionedPackage -Online

    # Uninstall OneNote
    Get-AppxPackage "Microsoft.Office.OneNote" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.Office.OneNote" | Remove-AppxProvisionedPackage -Online

    # Uninstall Paint
    Get-AppxPackage "Microsoft.MSPaint" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.MSPaint" | Remove-AppxProvisionedPackage -Online

    # Uninstall People
    Get-AppxPackage "Microsoft.People" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.People" | Remove-AppxProvisionedPackage -Online

    # Uninstall Photos
    Get-AppxPackage "Microsoft.Windows.Photos" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.Windows.Photos" | Remove-AppxProvisionedPackage -Online

    # Uninstall Print3D
    Get-AppxPackage "Microsoft.Print3D" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.Print3D" | Remove-AppxProvisionedPackage -Online

    # Uninstall Skype
    Get-AppxPackage "Microsoft.SkypeApp" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.SkypeApp" | Remove-AppxProvisionedPackage -Online

    # Uninstall SlingTV
    Get-AppxPackage "*.SlingTV" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "*.SlingTV" | Remove-AppxProvisionedPackage -Online

    # Uninstall Solitaire
    Get-AppxPackage "Microsoft.MicrosoftSolitaireCollection" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.MicrosoftSolitaireCollection" | Remove-AppxProvisionedPackage -Online

    # Uninstall Spotify
    Get-AppxPackage "SpotifyAB.SpotifyMusic" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "SpotifyAB.SpotifyMusic" | Remove-AppxProvisionedPackage -Online

    # Uninstall StickyNotes
    Get-AppxPackage "Microsoft.MicrosoftStickyNotes" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.MicrosoftStickyNotes" | Remove-AppxProvisionedPackage -Online

    # Uninstall Sway
    Get-AppxPackage "Microsoft.Office.Sway" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.Office.Sway" | Remove-AppxProvisionedPackage -Online

    # Uninstall Twitter
    Get-AppxPackage "*.Twitter" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "*.Twitter" | Remove-AppxProvisionedPackage -Online

    # Uninstall Voice Recorder
    Get-AppxPackage "Microsoft.WindowsSoundRecorder" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.WindowsSoundRecorder" | Remove-AppxProvisionedPackage -Online

    # Uninstall Windows Phone Companion
    Get-AppxPackage "Microsoft.WindowsPhone" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.WindowsPhone" | Remove-AppxProvisionedPackage -Online

    # Uninstall XBox
    Get-AppxPackage "Microsoft.XboxApp" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.XboxApp" | Remove-AppxProvisionedPackage -Online

    # Uninstall Zune Music (Groove)
    Get-AppxPackage "Microsoft.ZuneMusic" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.ZuneMusic" | Remove-AppxProvisionedPackage -Online

    # Uninstall Zune Video
    Get-AppxPackage "Microsoft.ZuneVideo" -AllUsers | Remove-AppxPackage
    Get-AppXProvisionedPackage -Online | Where-Object DisplayNam -like "Microsoft.ZuneVideo" | Remove-AppxProvisionedPackage -Online

    # Uninstall Windows Media Player
    Disable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -NoRestart -WarningAction SilentlyContinue | Out-Null

    ###############################################################################
    ### Windows Defender and Microsoft Update                                     #
    ###############################################################################
    Write-Host "Configuring Windows Defender..." -ForegroundColor "Yellow"

    # Disable Cloud-Based Protection: Enabled Advanced: 2, Enabled Basic: 1, Disabled: 0
    Set-MpPreference -MAPSReporting 0

    # Disable automatic sample submission: Prompt: 0, Auto Send Safe: 1, Never: 2, Auto Send All: 3
    Set-MpPreference -SubmitSamplesConsent 2

    # Opt-In to Microsoft Update
    $MU = New-Object -ComObject Microsoft.Update.ServiceManager -Strict
    $MU.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"") | Out-Null
    Remove-Variable MU

    ###############################################################################
    ### PowerShell Console                                                        #
    ###############################################################################
    Write-Host "Configuring Console..." -ForegroundColor "Yellow"

    # Make 'Source Code Pro' an available Console font
    Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont' 000 'Source Code Pro'

    function Set-ConsoleSettings($registryPath) {
        if (!(Test-Path $registryPath)) {
            New-Item -path $registryPath -ItemType Folder | Out-Null
        }

        # Dimensions of window, in characters: 8-byte; 4b height, 4b width. Max: 0x7FFF7FFF (32767h x 32767w)
        Set-ItemProperty $registryPath "WindowSize"           0x002D0078 # 45h x 120w
        # Dimensions of screen buffer in memory, in characters: 8-byte; 4b height, 4b width. Max: 0x7FFF7FFF (32767h x 32767w)
        Set-ItemProperty $registryPath "ScreenBufferSize"     0x0BB80078 # 3000h x 120w
        # Percentage of Character Space for Cursor: 25: Small, 50: Medium, 100: Large
        Set-ItemProperty $registryPath "CursorSize"           100
        # Name of display font
        Set-ItemProperty $registryPath "FaceName"             "Source Code Pro"
        # Font Family: Raster: 0, TrueType: 54
        Set-ItemProperty $registryPath "FontFamily"           54
        # Dimensions of font character in pixels, not Points: 8-byte; 4b height, 4b width. 0: Auto
        Set-ItemProperty $registryPath "FontSize"             0x00110000 # 17px height x auto width
        # Boldness of font: Raster=(Normal: 0, Bold: 1), TrueType=(100-900, Normal: 400)
        Set-ItemProperty $registryPath "FontWeight"           400
        # Number of commands in history buffer
        Set-ItemProperty $registryPath "HistoryBufferSize"    50
        # Discard duplicate commands
        Set-ItemProperty $registryPath "HistoryNoDup"         1
        # Typing Mode: Overtype: 0, Insert: 1
        Set-ItemProperty $registryPath "InsertMode"           1
        # Enable Copy/Paste using Mouse
        Set-ItemProperty $registryPath "QuickEdit"            1
        # Background and Foreground Colors for Window: 2-byte; 1b background, 1b foreground; Color: 0-F
        Set-ItemProperty $registryPath "ScreenColors"         0x0F
        # Background and Foreground Colors for Popup Window: 2-byte; 1b background, 1b foreground; Color: 0-F
        Set-ItemProperty $registryPath "PopupColors"          0xF0
        # Adjust opacity between 30% and 100%: 0x4C to 0xFF -or- 76 to 255
        Set-ItemProperty $registryPath "WindowAlpha"          0xF2

        # The 16 colors in the Console color well (Persisted values are in BGR).
        # Theme: Jellybeans
        Set-ItemProperty $registryPath "ColorTable00"         $(Convert-ConsoleColor "#151515") # Black (0)
        Set-ItemProperty $registryPath "ColorTable01"         $(Convert-ConsoleColor "#8197bf") # DarkBlue (1)
        Set-ItemProperty $registryPath "ColorTable02"         $(Convert-ConsoleColor "#437019") # DarkGreen (2)
        Set-ItemProperty $registryPath "ColorTable03"         $(Convert-ConsoleColor "#556779") # DarkCyan (3)
        Set-ItemProperty $registryPath "ColorTable04"         $(Convert-ConsoleColor "#902020") # DarkRed (4)
        Set-ItemProperty $registryPath "ColorTable05"         $(Convert-ConsoleColor "#540063") # DarkMagenta (5)
        Set-ItemProperty $registryPath "ColorTable06"         $(Convert-ConsoleColor "#dad085") # DarkYellow (6)
        Set-ItemProperty $registryPath "ColorTable07"         $(Convert-ConsoleColor "#888888") # Gray (7)
        Set-ItemProperty $registryPath "ColorTable08"         $(Convert-ConsoleColor "#606060") # DarkGray (8)
        Set-ItemProperty $registryPath "ColorTable09"         $(Convert-ConsoleColor "#7697d6") # Blue (9)
        Set-ItemProperty $registryPath "ColorTable10"         $(Convert-ConsoleColor "#99ad6a") # Green (A)
        Set-ItemProperty $registryPath "ColorTable11"         $(Convert-ConsoleColor "#c6b6ee") # Cyan (B)
        Set-ItemProperty $registryPath "ColorTable12"         $(Convert-ConsoleColor "#cf6a4c") # Red (C)
        Set-ItemProperty $registryPath "ColorTable13"         $(Convert-ConsoleColor "#f0a0c0") # Magenta (D)
        Set-ItemProperty $registryPath "ColorTable14"         $(Convert-ConsoleColor "#fad07a") # Yellow (E)
        Set-ItemProperty $registryPath "ColorTable15"         $(Convert-ConsoleColor "#e8e8d3") # White (F)
    }

    @(`
    "HKCU:\Console\%SystemRoot%_System32_bash.exe",`
    "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe",`
    "HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe",`
    "HKCU:\Console\Windows PowerShell (x86)",`
    "HKCU:\Console\Windows PowerShell",`
    "HKCU:\Console"`
    ) | ForEach-Object { Set-ConsoleSettings $_ }

    # Customizing PoSh syntax
    # Theme: Jellybeans
    Set-PSReadlineOption -Colors @{
        "Default"   = "#e8e8d3"
        "Comment"   = "#888888"
        "Keyword"   = "#8197bf"
        "String"    = "#99ad6a"
        "Operator"  = "#c6b6ee"
        "Variable"  = "#c6b6ee"
        "Command"   = "#8197bf"
        "Parameter" = "#e8e8d3"
        "Type"      = "#fad07a"
        "Number"    = "#cf6a4c"
        "Member"    = "#fad07a"
        "Emphasis"  = "#f0a0c0"
        "Error"     = "#902020"
    }

    # Remove property overrides from PowerShell and Bash shortcuts
    Reset-AllPowerShellShortcuts
    Reset-AllBashShortcuts

    Write-Output "Done. Note that some of these changes require a logout/restart to take effect."
}

Set-WindowsSettings