$modules = @("PSReadline", "PSCX", "ZLocation")
$windows_modules = @("VSSetup")

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Set-Variable is_windows -option Constant -value (
    ($PSVersionTable.PSVersion.Major -lt 6) -Or
    ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
         [System.Runtime.InteropServices.OSPlatform]::Windows)))

function Install-ModuleIfNeeded ($module)
{
    if (-Not (Get-Module -List -Name $module)) {
        Write-Output "Installing $module"
        Install-Module -Name $module -Scope CurrentUser -AllowClobber
    }
}

function Install-Chocolatey
{
    Set-ExecutionPolicy Bypass; iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
}

function Install-Scoop
{
    iex (new-object net.webclient).downloadstring('https://get.scoop.sh')
}

function Download-Topgrade
{
    $url = (Invoke-WebRequest "https://api.github.com/repos/r-darwish/topgrade/releases/latest" |
            ConvertFrom-Json |
            Select -expand assets |
            Where-Object {$_.name -like '*msvc*'} |
            Select -expand browser_download_url);

    Invoke-WebRequest -Uri $url -OutFile topgrade.zip
    Expand-Archive -Path topgrade.zip
    Remove-Item topgrade.zip
}

if ($is_windows) {
    foreach ($module in $windows_modules) {
        Install-ModuleIfNeeded $module
    }

	function Add-WUServices {
		Add-WUServiceManager 7971f918-a847-4430-9279-4a52d1efe18d
	}
}

foreach ($module in $modules) {
    Install-ModuleIfNeeded $module
}

Invoke-Expression (&starship init powershell)

Set-Alias -Name which -Value Get-Command
Set-Alias -Name sudo -Value Invoke-Elevated

$Host.UI.RawUI.ForegroundColor = "black"
$PSReadLineOptions = @{
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
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
