$modules = @("PSReadline", "PSColor", "Jump.Location", "PSCX", "VSSetup")
$windows_modules = @("PSWindowsUpdate")

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$admin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

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
    if ($admin) {
        Write-Host "* " -NoNewLine -ForegroundColor DarkRed
    }

    Write-Host ("$(get-location) ") -NoNewLine -ForegroundColor DarkBlue

    Write-Host ">" -NoNewLine -ForegroundColor DarkRed
    Write-Host ">" -NoNewLine -ForegroundColor DarkYellow
    Write-Host ">" -NoNewLine -ForegroundColor DarkGreen
    return " "
}

Import-Module PSColor
Import-Module Jump.Location

Set-Alias -Name z -Value j

Set-PSReadlineOption -EditMode Emacs
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineOption -TokenKind Parameter -ForegroundColor Blue
Set-PSReadlineOption -TokenKind Command -ForegroundColor Magenta
