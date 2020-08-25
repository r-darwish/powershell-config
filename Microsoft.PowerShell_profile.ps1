Set-Variable ProfileDirectory -Option Constant -Value (Split-Path $profile)
Set-Alias -Name which -Value Get-Command
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Install-NeededModules {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    @("PSReadline", "ZLocation") | ForEach-Object { Install-Module $_ -Force }

    if (!$IsWindows) {
        Install-Module Microsoft.PowerShell.UnixCompleters
    }

    Install-Module -AllowClobber "Get-ChildItemColor"
}

Import-Module posh-git

Set-Variable VirtualEnvironmentDirectory -Option Constant -Value "~/.venvs"

$script:VirtualenvCompleter = {
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
        [string]
        [Parameter(Mandatory = $true, Position = 0)]
        $Name)

    python3 -m virtualenv (Join-Path $VirtualEnvironmentDirectory $Name)
    Enter-VirtualEnvironment $Name
}

function Remove-VirtualEnvironment {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Mandatory = $true, Position = 0)]
        $Name)

    Remove-Item -Recurse -Force (Join-Path $VirtualEnvironmentDirectory $Name)
}

Register-ArgumentCompleter -CommandName Enter-VirtualEnvironment -ParameterName Name -ScriptBlock $script:VirtualenvCompleter
Register-ArgumentCompleter -CommandName Remove-VirtualEnvironment -ParameterName Name -ScriptBlock $script:VirtualenvCompleter

Set-Alias -Name venv -Value Enter-VirtualEnvironment
Set-Alias -Name mkvenv -Value New-VirtualEnvironment
Set-Alias -Name rmvenv -Value Remove-VirtualEnvironment

Set-Variable PSReadLineOptions -Scope Script -Option Constant -Value @{
    EditMode                      = "Emacs"
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    Colors                        = @{
        Operator  = "Yellow"
        Command   = "Yellow"
        Parameter = "Blue"
        Member    = "DarkYellow"
        Selection = "`e[1;37;1;40m"
    }
}
Set-PSReadLineOption @PSReadLineOptions
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Ctrl+f -Function CharacterSearch
Set-PSReadLineKeyHandler -Key Ctrl+b -Function CharacterSearchBackward

If (-Not (Test-Path Variable:PSise)) {
    Set-Alias ls Get-ChildItemColor -Option AllScope
}

if (Test-Path "Env:\PWD") {
    Remove-Item "Env:\PWD"
}

if (Test-Path "$ProfileDirectory/local.ps1" -PathType Leaf) {
    . "$ProfileDirectory/local.ps1"
}

if ($IsWindows) {
    . "$ProfileDirectory/windows.ps1"
}
else {
    . "$ProfileDirectory/unix.ps1"
}

Invoke-Expression (&starship init powershell)
