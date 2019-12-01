Set-Variable ProfileDirectory -Option Constant -Value (Split-Path $profile)
Set-Alias -Name which -Value Get-Command
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Install-NeededModules {
    @("PSReadline", "ZLocation", "PSFzf") | ForEach-Object { Install-Module $_ }
}

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-Variable PSReadLineOptions -Scope Script -Option Constant -Value @{
    EditMode = "Emacs"
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    Colors = @{
        Operator = "Yellow"
        Command = "Yellow"
        Parameter = "Blue"
        Member = "DarkYellow"
    }
}
Set-PSReadLineOption @PSReadLineOptions

Import-Module PSFzf -ArgumentList 'Ctrl+t','Ctrl+r'

if (Test-Path "Env:\PWD") {
    Remove-Item "Env:\PWD"
}

if ($IsWindows) {
    . "$ProfileDirectory/windows.ps1"
} else {
    . "$ProfileDirectory/unix.ps1"
}

Invoke-Expression (&starship init powershell)
