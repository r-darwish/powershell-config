class Package {
    [string]$Name
    [PackageManager]$Manager
    $Object

    Package([string]$Name, [PackageManager]$Manager) {
        $this.Name = $Name
        $this.Manager = $Manager
    }

    Package([string]$Name, [PackageManager]$Manager, $Object) {
        $this.Name = $Name
        $this.Manager = $Manager
        $this.Object = $Object
    }
}

enum PackageManager {
    Brew
    BrewCask
    MacApplication
    Chocolatey
    Scoop
    Win32App
    Appx
}

$packages = @()

function exists {
    param ($Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

if ($IsMacOS) {
    $packages += (brew leaves).ForEach{ [Package]::new($_, "Brew") }
    $packages += (brew list --cask).ForEach{ [Package]::new($_, "BrewCask") }
    $packages += (Get-ChildItem /Applications -Filter *.app -Directory ).ForEach{ [Package]::new($_.Name -replace ".app", "MacApplication") }
}
elseif ($IsWindows) {
    if (-not (Test-Admin)) {
        throw "This script show run as an administrator"
    }

    if (exists chocolatey) {
        $packages += (chocolatey list -localonly --idonly --limitoutput).ForEach{ [Package]::new($_, "Chocolatey") }
    }
    if (exists sccop) {
        $packages += (scoop list 6>&1 | Where-Object { $_.MessageData.Message.StartsWith("  ") }).ForEach{ 
            [Package]::new($_.MessageData.Message.Trim(), "Scoop") 
        }
    }
    $packages += (Get-CimInstance -ClassName Win32_Product | Sort-Object -Property Name).ForEach{ [Package]::new($_.Name, "Win32App", $_) }
    $packages += (Get-AppxPackage -AllUsers | Sort-Object -Property Name).ForEach{ [Package]::new($_.Name, "Appx", $_) }
}

$toRemove = $packages | Out-ConsoleGridView -Title "Select packages to remove"

foreach ($pkg in $toRemove) {
    Write-Host Removing $pkg.Name

    switch ($pkg.Manager) {
        "Brew" { brew  rmtree $pkg.Name || Write-Error "Error removing $pkg.name" }
        "BrewCask" { brew cask uninstall $pkg.Name || Write-Error "Error removing $pkg.name" }
        "MacApplication" { Remove-Item -Recurse -Force (Join-Path /Applications ($pkg.Name + ".app")) || Write-Error "Error removing $pkg.name" }
        "Chocolatey" { choco uninstall $pkg.name || Write-Error "Error removing $pkg.name" }
        "Scoop" { scoop uninstall $pkg.name || Write-Error "Error removing $pkg.name" }
        "Win32App" { $pkg.Object | Invoke-CimMethod -MethodName Uninstall }
        "Appx" { $pkg.Object | Remove-AppxPackage -AllUsers }
        Default { Write-Error "Unhandled package manager $pkg.Manager" }
    }
}