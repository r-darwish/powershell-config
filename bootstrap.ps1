if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing chocolatey"
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    choco feature enable -n allowGlobalConfirmation
}
function InstallChocoDependency {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string[]]
        $Dependency
    )

    foreach ($dependency in $Dependency) {
        Write-Host "Installing $dependency via Chocolatey"
        choco install $dependency
    }
}

InstallChocoDependency @("powershell-core", "microsoft-windows-terminal", "starship", "git")
git clone https://github.com/r-darwish/powershell-config (& 'C:\Program Files\PowerShell\7\pwsh.exe' -c 'Split-Path -parent $profile')
&'C:\Program Files\PowerShell\7\pwsh.exe' -c "Install-NeededModules"