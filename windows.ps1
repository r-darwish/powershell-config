function Install-Chocolatey {
    Set-ExecutionPolicy Bypass; Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
}

function Install-Scoop {
    Invoke-Expression (new-object net.webclient).downloadstring('https://get.scoop.sh')
}

function Get-Topgrade {
    $url = (Invoke-WebRequest "https://api.github.com/repos/r-darwish/topgrade/releases/latest" |
        ConvertFrom-Json |
        Select-Object -expand assets |
        Where-Object { $_.name -like '*msvc*' } |
        Select-Object -expand browser_download_url);

    Invoke-WebRequest -Uri $url -OutFile topgrade.zip
    Expand-Archive -Path topgrade.zip
    Remove-Item topgrade.zip
}
