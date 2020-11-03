Set-Variable ProfileDirectory -Option Constant -Value $PSScriptRoot
Set-Alias -Name which -Value Get-Command
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

function Install-NeededModules {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    @("PSReadline", "ZLocation", "posh-git", "Microsoft.PowerShell.ConsoleGuiTools").ForEach{ Install-Module $_ -Force }

    if (!$IsWindows) {
        Install-Module Microsoft.PowerShell.UnixCompleters
    }

    Install-Module -AllowClobber "Get-ChildItemColor"
}

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

if (-not $IsWindows) {
    . "$ProfileDirectory/unix.ps1"
}

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
Invoke-Expression (&starship init powershell)
