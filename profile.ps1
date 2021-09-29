using namespace Microsoft.PowerShell;

#region setup
Set-Variable ProfileDirectory -Option Constant -Value $PSScriptRoot
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function AddPath {
    param (
        # Parameter help description
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Current, 
    
        # New paths to add
        [Parameter(Mandatory, Position = 1)]
        [string[]]
        $New, 

        # Prepend paths instead of appending
        [Parameter()]
        [switch]
        $Prepend
    )

    $seperator = ($IsWindows ? ";" : ":")

    foreach ($p in $New) {
        $resolved = (Resolve-Path $p -ErrorAction SilentlyContinue)
        if (-not $resolved) {
            continue;
        }
        $resolved = $resolved.Path

        if (($Current -split $seperator) -inotcontains $resolved) {
            if ($Prepend) {
                $Current = $resolved + $seperator + $Current
            }
            else {
                $Current += $seperator + $resolved
            }
        }
    }

    $Current
}

$env:PSModulePath = AddPath $env:PSModulePath (Join-Path $ProfileDirectory "BundledModules")
$env:PATH = AddPath $env:PATH (Join-Path $ProfileDirectory "Scripts")
$env:EDITOR = "nvim"
Set-Alias -Name e -Value nvim

function Install-NeededModules {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    @("PSReadline", "ZLocation", "posh-git", "Microsoft.Powershell.ConsoleGuiTools").ForEach{ Install-Module $_ -Force }

    if (!$IsWindows) {
        Install-Module UnixCompleters
    }
}

#endregion
#region readline

Set-Variable PSReadLineOptions -Scope Script -Option Constant -Value @{
    EditMode                      = "Emacs"
    PredictionSource              = "History"
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
    Colors                        = @{
        Operator         = "Yellow"
        Command          = "Yellow"
        Parameter        = "Blue"
        Member           = "DarkYellow"
        Selection        = "$([char]0x1b)[36;7;238m"
        InlinePrediction = "$([char]0x1b)[36;7;238m"
    }
}
Set-PSReadLineOption @PSReadLineOptions
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Ctrl+f -Function ForwardWord
Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Key Ctrl+Backspace -Function BackwardKillWord
Set-PSReadLineKeyHandler -Key Alt+Backspace -Function BackwardKillWord
Set-PSReadLineKeyHandler -Key F1 -Function WhatIsKey
Set-PSReadLineKeyHandler -Key Ctrl+Shift+LeftArrow -Function SelectBackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+Shift+RightArrow -Function SelectForwardWord
Set-PSReadLineKeyHandler -Key Alt+j -BriefDescription AccestSuggestionAndExecute -LongDescription "Accept and execute the current suggestion" -ScriptBlock { 
    [PSConsoleReadLine]::AcceptSuggestion(); 
    [PSConsoleReadLine]::AcceptLine() 
}
Set-PSReadLineKeyHandler -Key Ctrl+UpArrow -BriefDescription GoBack -LongDescription "Go back one directory" -ScriptBlock { 
    Set-Location -
    [PSConsoleReadLine]::AcceptLine()
}

function AddPrefix {
    param([string]$prefix)

    $line = $null
    $cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($line.StartsWith($prefix)) {
        return
    }

    [PSConsoleReadLine]::SetCursorPosition(0)
    [PSConsoleReadLine]::Insert($prefix)
    [PSConsoleReadLine]::SetCursorPosition($cursor + $prefix.Length)
}

Set-PSReadLineKeyHandler -Key Alt+x -BriefDescription StoreInVariable -LongDescription "Add `$x = to the beginning of the line" -ScriptBlock { AddPrefix "`$x = " }
Set-PSReadLineKeyHandler -Key Alt+s -BriefDescription PrependSudo -LongDescription "Add sudo to the beginning of the line" -ScriptBlock { AddPrefix "sudo " }
Set-PSReadLineKeyHandler -Key Alt+w -BriefDescription WrapWithParenthesis -LongDescription "Wrap the command with parenthesis" -ScriptBlock { 
    $line = $null
    $cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [PSConsoleReadLine]::SetCursorPosition(0)
    [PSConsoleReadLine]::Insert("(")
    [PSConsoleReadLine]::SetCursorPosition($line.Length + 1)
    [PSConsoleReadLine]::Insert(")")
}

#endregion

if (Test-Path "Env:\PWD") {
    Remove-Item "Env:\PWD"
}

if (Test-Path "$ProfileDirectory/local.ps1" -PathType Leaf) {
    . "$ProfileDirectory/local.ps1"
}

if (-not $IsWindows) {
    . "$ProfileDirectory/unix.ps1"
}

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
Invoke-Expression (&starship init powershell)
