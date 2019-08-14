$modules = @("PSReadline", "PSCX", "VSSetup", "ZLocation")
$windows_modules = @("PSWindowsUpdate")

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Set-Variable is_windows -option Constant -value (
    ($PSVersionTable.PSVersion.Major -lt 6) -Or
    ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
         [System.Runtime.InteropServices.OSPlatform]::Windows)))

if ($is_windows) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $admin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

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

Set-Alias -Name which -Value Get-Command
Set-Alias -Name sudo -Value Invoke-Elevated

$PSReadLineOptions = @{
    EditMode = "Emacs"
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
}

Set-PSReadLineOption @PSReadLineOptions
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
