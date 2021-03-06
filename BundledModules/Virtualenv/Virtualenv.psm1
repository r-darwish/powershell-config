$VirtualEnvironmentDirectory = ($IsWindows ? "$env:APPDATA\venvs" : "~/.venvs")


$VirtualenvCompleter = {
    param($commandName, $parameterName, $wordToComplete)
    Get-ChildItem $VirtualEnvironmentDirectory |
    Where-Object { $_.Name -like "$wordToComplete*" } |
    ForEach-Object { $_.Name }
}

function Enter-VirtualEnvironment {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory = $true, Position = 0)]
        $Name)

    $Subdir = if ($IsWindows) { "Scripts" } else { "bin" }
    . (Join-Path $VirtualEnvironmentDirectory $Name $Subdir "activate.ps1")
}

function New-VirtualEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Name,
        
        [Parameter()]
        [string]
        $Python = $IsWindows ? "python.exe" : "python3",

        [Parameter()]
        [string[]]
        $Requirements,

        [Parameter(Position = 1)]
        [string[]]
        $Package
    )

    &$Python -m virtualenv (Join-Path $VirtualEnvironmentDirectory $Name -ErrorAction Stop)

    if ($LastExitCode -ne 0) {
        throw "Environment creation failed"
    }

    Enter-VirtualEnvironment $Name
    
    foreach ($req in $Requirements) {
        $Package += "-r", $req
    }

    if ($Package) {
        $Package = @("install") + $Package
        Write-Debug "pip ${Package}"
        & pip $Package
    }
}

function Remove-VirtualEnvironment {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory = $true, Position = 0)]
        $Name)

    Remove-Item -Recurse -Force (Join-Path $VirtualEnvironmentDirectory $Name)
}

Register-ArgumentCompleter -CommandName Enter-VirtualEnvironment -ParameterName Name -ScriptBlock $VirtualenvCompleter
Register-ArgumentCompleter -CommandName Remove-VirtualEnvironment -ParameterName Name -ScriptBlock $VirtualenvCompleter

Set-Alias -Name venv -Value Enter-VirtualEnvironment
Set-Alias -Name mkvenv -Value New-VirtualEnvironment
Set-Alias -Name rmvenv -Value Remove-VirtualEnvironment

