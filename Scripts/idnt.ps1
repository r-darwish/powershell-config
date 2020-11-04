class Package {
    [string]$Name
    [PackageManager]$Manager
}

enum PackageManager {
    Brew
    BrewCask
}

$packages = @()

if ($IsMacOS) {
    $packages += (brew leaves).ForEach{ 
        $pkg = [Package]::new()
        $pkg.Manager = [PackageManager]::Brew
        $pkg.Name = $_
        $pkg
    }

    $packages += (brew list --cask).ForEach{ 
        $pkg = [Package]::new()
        $pkg.Manager = [PackageManager]::BrewCask
        $pkg.Name = $_
        $pkg
    }
}

$toRemove = $packages | Out-ConsoleGridView -Title "Select packages to remove"

foreach ($pkg in $toRemove) {
    Write-Host Removing $pkg.Name

    switch ($pkg.Manager) {
        "Brew" { brew  rmtree $pkg.Name || Write-Error "Error removing $pkg.name" }
        "BrewCask" { brew cask uninstall $pkg.Name || Write-Error "Error removing $pkg.name" }
        Default { Write-Error "Unhandled package manager $pkg.Manager" }
    }
}