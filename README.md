# Paul Milla's Bootstrap

## Sensible Windows defaults

When setting up a new Windows PC, you may want to set some Windows defaults and features, such as showing hidden files in Windows Explorer and installing IIS. This will also set your machine name and full user name, so you may want to modify this file before executing.

```posh
.\Set-BasicWindowsSettings.ps1
.\Set-WindowsSettings.ps1 # A much more expansive list of settings
```

## Install dependencies and packages

When setting up a new Windows box, you may want to install some common packages, utilities, and dependencies. These could include node.js packages via [NPM](https://www.npmjs.org), [Chocolatey](http://chocolatey.org/) packages, Windows Features and Tools via [Web Platform Installer](https://www.microsoft.com/web/downloads/platform.aspx), and Visual Studio Extensions from the [Visual Studio Gallery](http://visualstudiogallery.msdn.microsoft.com/).

```posh
.\Install-Apps.ps1
.\Install-PSExtensions.ps1 # A set of PS Packages and Modules
```

> The scripts will install Chocolatey, node.js, and WebPI if necessary.
> **Visual Studio Extensions**  
> Extensions will be installed into your most current version of Visual Studio. You can also install additional plugins at any time via `Install-VSExtension $url`. The Url can be found on the gallery; it's the extension's `Download` link url.

## Thanks to…

* @[Jay Harris](http://twitter.com/jayharris/) for his [Windows dotfiles](https://github.com/jayharris/dotfiles-windows), which this repositry is modeled after
* @[Mathias Bynens](http://mathiasbynens.be/) for his [OS X dotfiles](http://mths.be/dotfiles), which Jay Harris' repository is modeled after.