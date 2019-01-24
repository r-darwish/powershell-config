$modules = @("PSReadline", "PSColor")
$windows_modules = @("PSWindowsUpdate")

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

function prompt
{
    Write-Host ($(get-location)) -nonewline
    Write-Host " >" -nonewline  -ForegroundColor Red
    Write-Host ">" -nonewline  -ForegroundColor Yellow
    Write-Host ">" -nonewline  -ForegroundColor Green
    return " "
}

Import-Module PSColor

Set-PSReadlineOption -EditMode Emacs
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineOption -TokenKind Parameter -ForegroundColor Blue
Set-PSReadlineOption -TokenKind Command -ForegroundColor Magenta
