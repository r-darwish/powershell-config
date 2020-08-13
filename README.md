# PowerShell Configuration

![Screenshot](screenshot.png)

A humble PowerShell configuration

# Installation

``` powershell
git clone https://github.com/r-darwish/powershell-config (Split-Path -parent $profile)
```

When you first run Powershell execute `Install-NeededModules` to install modules.

You should also install [Starship](https://starship.rs/) before using this configuration.

[Topgrade](https://github.com/r-darwish/topgrade) can keep this configuration up to date and will also run Windows Update using PSWindowsUpdate

# Modules

* [PSReadline](https://github.com/lzybkr/PSReadLine)
* [Jump.Location](https://github.com/tkellogg/Jump-Location) - Aliased to `z` in addition to `j`
* [ZLocation](https://github.com/vors/ZLocation)
* [PSFzf](https://github.com/kelleyma49/PSFzf)
* [Get-ChildItemColor](https://github.com/joonro/Get-ChildItemColor)

# Features

* Automatic installation of modules
* `Install-Chocolatey` - Install [Chocolatey](https://chocolatey.org/)
* `Install-Scoop` - Install [Scoop](https://scoop.sh/)
* `Get-Topgrade` - Download [Topgrade](https://github.com/r-darwish/topgrade) to the current
  directory

# Other helpful modules

These modules aren't installed by `Install-NeededModules`.

* Microsoft.PowerShell.GraphicalTools - For Out-GridView
* Az - Azure control
* VSSetup - Import Visual Studio build environment