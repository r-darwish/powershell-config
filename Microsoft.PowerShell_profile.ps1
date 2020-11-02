Set-Variable ProfileDirectory -Option Constant -Value $PSScriptRoot
Set-Alias -Name which -Value Get-Command
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Install-NeededModules {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    @("PSReadline", "ZLocation", "posh-git", "Microsoft.PowerShell.ConsoleGuiTools").ForEach{ Install-Module $_ -Force }

    if (!$IsWindows) {
        Install-Module Microsoft.PowerShell.UnixCompleters
    }

    Install-Module -AllowClobber "Get-ChildItemColor"
}

Import-Module posh-git

Set-Variable VirtualEnvironmentDirectory -Option Constant -Value ($IsWindows ? "$env:APPDATA/venvs" : "~/.venvs")

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
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Name,
        
        [Parameter()]
        $Python = "python3")

    &$Python -m virtualenv (Join-Path $VirtualEnvironmentDirectory $Name)
    if ($LastExitCode -ne 0) {
        throw "Environment creation failed"
    }

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
Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Key Ctrl+Backspace -Function BackwardKillWord
function ocgv_history {
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    $selection = $history | Out-ConsoleGridView -Title "Select CommandLine from History" -OutputMode Single -Filter $line
    if ($selection) {
        [Microsoft.PowerShell.PSConsoleReadLine]::DeleteLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
        if ($selection.StartsWith($line)) {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selection.Length)
        }    
    }
}

$parameters = @{
    Key              = 'F7'
    BriefDescription = 'ShowMatchingHistoryOcgv'
    LongDescription  = 'Show Matching History using Out-ConsoleGridView'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example

        $history = Get-History | Sort-Object -Descending -Property Id -Unique | Select-Object CommandLine -ExpandProperty CommandLine 
        $history | ocgv_history
    }
}
Set-PSReadLineKeyHandler @parameters

$parameters = @{
    Key              = 'Shift-F7'
    BriefDescription = 'ShowMatchingGlobalHistoryOcgv'
    LongDescription  = 'Show Matching History for all PowerShell instances using Out-ConsoleGridView'
    ScriptBlock      = {
        param($key, $arg)   # The arguments are ignored in this example
        $history = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems().CommandLine 
        # reverse the items so most recent is on top
        [array]::Reverse($history) 
        $history | Select-Object -Unique | ocgv_history
    }
}
Set-PSReadLineKeyHandler @parameters


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

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
Invoke-Expression (&starship init powershell)
