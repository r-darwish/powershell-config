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

function New-WindowsSandbox {
    [CmdletBinding()]
    param (
        # Name of the box
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        # vGPU
        [Parameter()]
        [bool]
        $VGPU = $true,

        # Mapped Folders
        [Parameter()]
        [string[]]
        $Folders,

        # Launch
        [Parameter()]
        [switch]
        $Launch
    )

    # Set The Formatting
    $xmlsettings = New-Object System.Xml.XmlWriterSettings
    $xmlsettings.Indent = $true
    $xmlsettings.IndentChars = "    "
    $xmlsettings.OmitXmlDeclaration = $true
    $xmlsettings.ConformanceLevel = "Fragment"
    $filename = "$Name.wsb"

    # Set the File Name Create The Document
    $XmlWriter = [System.XML.XmlWriter]::Create($filename, $xmlsettings)



    # Start the Root Element
    $xmlWriter.WriteStartElement("Configuration")

    if ($VGPU) {
        $XmlWriter.WriteStartElement("vGPU")
        $XmlWriter.WriteString("Enable")
        $XmlWriter.WriteEndElement()
    }

    $XmlWriter.WriteStartElement("MappedFolders")
    for ($i = 0; $i -lt $Folders.Count; $i++) {
        $XmlWriter.WriteStartElement("MappedFolder")
        $split = $Folders[$i] -split '/'
        
        $absPath = Resolve-Path $split[0]
        $XmlWriter.WriteElementString("HostFolder", $absPath)

        if ($split[1]) {
            $XmlWriter.WriteElementString("SandboxFolder", $split[1])
        }

        $XmlWriter.WriteEndElement()
    }
    $XmlWriter.WriteEndElement()

    $xmlWriter.Flush()
    $xmlWriter.Close()

    if ($Launch) {
        & ./$filename
    }
}

function Test-Admin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}