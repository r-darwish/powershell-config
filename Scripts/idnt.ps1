class Package {
    [string]$Name
    [PackageManager]$Manager

    Package([string]$Name, [PackageManager]$Manager) {
        $this.Name = $Name
        $this.Manager = $Manager
    }
}

enum PackageManager {
    Brew
    BrewCask
    MacApplication
}

$packages = @()

if ($IsMacOS) {
    $packages += (brew leaves).ForEach{ [Package]::new($_, "Brew") }
    $packages += (brew list --cask).ForEach{ [Package]::new($_, "BrewCask") }
    $packages += (Get-ChildItem /Applications -Filter *.app -Directory ).ForEach{ [Package]::new($_.Name -replace ".app", "MacApplication") }
}

$toRemove = $packages | Out-ConsoleGridView -Title "Select packages to remove"

foreach ($pkg in $toRemove) {
    Write-Host Removing $pkg.Name

    switch ($pkg.Manager) {
        "Brew" { brew  rmtree $pkg.Name || Write-Error "Error removing $pkg.name" }
        "BrewCask" { brew cask uninstall $pkg.Name || Write-Error "Error removing $pkg.name" }
        "MacApplication" { Remove-Item -Recurse -Force (Join-Path /Applications ($pkg.Name + ".app")) || Write-Error "Error removing $pkg.name" }
        Default { Write-Error "Unhandled package manager $pkg.Manager" }
    }
}