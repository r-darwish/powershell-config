Set-Alias -Name sudo -Value Invoke-Elevated

Install-ModuleIfNeeded "VSSetup"

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
