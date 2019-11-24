Set-Variable ProfileDirectory -Option Constant -Value (Split-Path $profile)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Set-Alias -Name which -Value Get-Command

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-Variable PSReadLineOptions -Scope Script -Option Constant -Value @{
    EditMode = "Emacs"
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    Colors = @{
        Default = "DarkGray"
        ContinuationPrompt = "DarkGray"
        Type = "DarkGray"
        Number = "DarkGray"
        Operator = "Yello"
        Command = "Magenta"
        Parameter = "Blue"
        Member = "DarkYellow"
    }
}
Set-PSReadLineOption @PSReadLineOptions
$Host.UI.RawUI.ForegroundColor = "black"

. "$ProfileDirectory/common.ps1"
@("PSReadline", "PSCX", "ZLocation", "Az") | ForEach-Object { Install-ModuleIfNeeded $_ }

if ($IsWindows) {
    . "$ProfileDirectory/windows.ps1"
} else {
    . "$ProfileDirectory/unix.ps1"
}


Invoke-Expression (&starship init powershell)
