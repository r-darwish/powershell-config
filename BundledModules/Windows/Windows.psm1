function Install-Chocolatey {
    Set-ExecutionPolicy Bypass; Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
}

function Install-Scoop {
    Invoke-Expression (New-Object net.webclient).downloadstring('https://get.scoop.sh')
}

function Install-Topgrade {
    $url = (Invoke-RestMethod "https://api.github.com/repos/r-darwish/topgrade/releases/latest" |
        Select-Object -expand assets |
        Where-Object { $_.name -like '*msvc*' } |
        Select-Object -expand browser_download_url);

    Invoke-WebRequest -Uri $url -OutFile topgrade.zip
    Expand-Archive -Path topgrade.zip
    Move-Item topgrade/topgrade.exe .
    Remove-Item topgrade.zip, topgrade
}
