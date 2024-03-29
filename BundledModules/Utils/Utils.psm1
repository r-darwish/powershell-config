function New-Container {
    [CmdletBinding()]
    param (
        # Image name
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Image,

        # Container name
        [Parameter(Position = 1)]
        [string]
        $Name = $null,

        # Shell
        [Parameter()]
        [string]
        $Shell = "bash"
    )
    
    $persistance = (-not $Name) ? "--rm" : "--name=$Name"
    $command = "run", "-it", $persistance, "-v", "$(Get-Location):/mnt", "-w", "/mnt", $Image, $Shell
    Write-Debug "Executing docker $command"
    & docker $command
    if ($LASTEXITCODE -ne 0) {
        throw "Docker failed"
    }
}

function kubectx {
    $ctx = kubectl config get-contexts -o name || throw "kubectl failed"
    $ctx = $ctx | Out-ConsoleGridView -OutputMode Single -Title "Select a context"
    if (-not $ctx) {
        throw "No context selected"
    }

    kubectl config use-context $ctx || throw "kubectl failed"

    $namespaces = (kubectl get namespaces -o name || throw "Kubectl failed" ).ForEach{ $_ -replace "namespace/" }
    $namespace = $namespaces | Out-ConsoleGridView -OutputMode Single -Title "Select a namespace in $ctx"
    kubectl config set-context --current --namespace=$namespace || throw "kubectl failed"
}

function Get-GitBranches {
    [CmdletBinding()]
    param (
        # Include Remotes
        [Parameter()]
        [switch]
        $Remotes,

        # Include tags
        [Parameter()]
        [switch]
        $Tags
    )

    git branch "--format=%(refname:short)"
    if ($Remotes) {
        git branch -r "--format=%(refname:short)"
    }

    if ($Tags) {
        git tag
    }
}

function fork {
    [CmdletBinding()]
    param (
        # Branch Name
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )
    
    $existing = Get-GitBranches -Remotes | Out-ConsoleGridView -OutputMode Single -Title "Select a branch to fork from"
    if ($existing) {
        git checkout -b $Name $existing --no-track
    }
}

function Set-GitBranch {
    [CmdletBinding()]
    param (
        # Reference to checkout
        [Parameter(Position = 0)]
        [string]
        $Reference,

        # Include Remotes
        [Parameter()]
        [switch]
        $Remotes,

        # Include tags
        [Parameter()]
        [switch]
        $Tags,

        # Force branch creation if it doesn't exist
        [Parameter()]
        [switch]
        $Force,

        # Create from specific branch
        [Parameter()]
        [string]
        $From
    )

    if (-not $Reference) {
        $Reference = Get-GitBranches -Remotes:$Remotes -Tags:$Tags | Out-ConsoleGridView -OutputMode Single -Title "Select a branch to checkout"
    }

    if ($Reference) {
        if ($From) {
            git checkout $From || throw "Unable to switch to the source branch"
        }

        $flags = @("checkout")
        if ($Force) {
            $flags += "-b"
        }
        $flags += $Reference

        git $flags
    }
}

New-Alias -Name gco -Value Set-GitBranch

Register-ArgumentCompleter -CommandName Set-GitBranch -ParameterName Reference -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)
    Get-GitBranches -Remotes -Tags
}

function Set-GitUser {
    $email = "roey.dror@wiz.io", "roey.ghost@gmail.com" | Out-ConsoleGridView -OutputMode Single -Title "Select a git user"
    git config user.email $email
}

New-Alias -Name gituser -Value Set-GitUser

function whatif {
    $newState = -not $WhatIfPreference
    $humanState = $newState ? "on" : "off"
    Write-Host "Turning $humanState global WhatIf mode"
    $global:WhatIfPreference = $newState
}

function Reset-GitDirectory {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
    param(
        # Commit
        [Parameter(Position = 0)]
        [string]
        $Commit = "HEAD",
        # Directories
        [SupportsWildcards()]
        [Parameter(Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $Path = @(".")
    )
    
    foreach ($p in (Get-Item $Path)) {
        $abs = Resolve-Path $p
        if (-not $?) {
            continue
        }
        Write-Verbose $abs

        Push-Location $p
        try {
            if ($?) {
                if ($PSCmdlet.ShouldProcess($abs, "Reset to $Commit")) {
                    git reset $Commit --hard
                }
            }
        }
        finally {
            Pop-Location
        }
    }
}

New-Alias grs Reset-GitDirectory

function Get-VagrantBox {
    [CmdletBinding()]
    param ()
    
    vagrant global-status --machine-readable 
    | ConvertFrom-Csv -WarningAction SilentlyContinue 
    | Where-Object metadata -EQ machine-home 
    | Select-Object -Property @{Name = "Name"; Expression = { Split-Path $_."machine-count" -Leaf } }, @{Name = "Path"; Expression = { $_."machine-count" } }
}

function Enter-Vagrant {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )
        
    $machine = Get-Vagrant | Where-Object Name -EQ $Name
    if (-not $machine) { throw "No vagrant machine named $Name" }
    
    Push-Location $machine.Path

    $isHyperv = Test-Path .\.vagrant\machines\default\hyperv
    
    $activate = {
        param($isHyperv)

        $status = vagrant status --machine-readable | ConvertFrom-Csv -Header timestamp, target, type, data | Where-Object type -EQ state-human-short | Select-Object -ExpandProperty data
        if (-not $status) { throw "Vagrant failed" }
    
        $off = $status -like "*off"
        if ($off) {
            vagrant up || throw "Error turning on the machine"
        }

        vagrant ssh

        if ($off) {
            vagrant halt
        }
    }

    if ($isHyperv -and (-not (Test-Admin))) {
        Write-Debug "Hyper-V machine. Using sudo"
        sudo pwsh -Command $activate -args $isHyperv
    }
    else {
        & $activate
    }

    Pop-Location
}

function dark {
    if ($IsMacOS) {
        osascript -e 'tell app \"System Events\" to tell appearance preferences to set dark mode to not dark mode'
    }
    elseif ($IsWindows) {
        $value = (Get-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize).SystemUsesLightTheme -bxor 1
        [Void](New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value $value -Type Dword -Force)
        [Void](New-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value $value -Type Dword -Force)
    }
}

function Send-WOL {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$mac,
        [string]$ip = "255.255.255.255",
        [int]$port = 9
    )
    $broadcast = [Net.IPAddress]::Parse($ip)
 
    $mac = (($mac.replace(":", "")).replace("-", "")).replace(".", "")
    $target = 0, 2, 4, 6, 8, 10 | ForEach-Object { [convert]::ToByte($mac.substring($_, 2), 16) }
    $packet = (, [byte]255 * 6) + ($target * 16)
 
    $UDPclient = New-Object System.Net.Sockets.UdpClient
    $UDPclient.Connect($broadcast, $port)
    [void]$UDPclient.Send($packet, 102)
}

function Remove-KnownHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int[]]$Line
    )
    begin {
        $hosts = Get-Content ~/.ssh/known_hosts || throw "Error reading the host file"
        $newHosts = ""
    }
    
    process {
        for ($i = 0; $i -lt $hosts.Count; $i++) {
            $currentLine = $i + 1
            if ($currentLine -in $Line) {
                Write-Verbose "Dropping $($hosts[$i])"
                continue
            }

            $newHosts += $hosts[$i] + "`n"
        }
    }
    
    end {
        $newHosts > ~/.ssh/known_hosts
    }
}

function which {
    param (
        [Parameter(Mandatory)]
        [string]$Command
    )
    
    $cmd = Get-Command $Command
    $cmd.Source
}

function New-CompressedPDF {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$InputFile,

        [Parameter(Position = 1)]
        [string]$OutputFile
    )
    
    begin {
        if (-not $OutputFile) {
            $OutputFile = $InputFile -replace ".pdf", "-c"
        }

        $command = $IsWindows ? (Get-Item 'C:\Program Files\gs\*\bin\gswin64c.exe').FullName : "gs"
        $params = @("-sDEVICE=pdfwrite", "-dCompatibilityLevel=1.4", "-dPDFSETTINGS=/ebook", "-dNOPAUSE", "-dBATCH", "-dColorImageResolution=150", "-sOutputFile=$OutputFile.pdf", $InputFile)
    }
    
    process {
        Write-Verbose "Compressing $InputFile to $OutputFile"
        & $command $params
    }
    
    end {
        
    }
}

function BuildGo {
    $binaryName = (Split-Path . -Leaf)
    $outputDir = "out"
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory
    }
    Push-Location $outputDir

    $buildConfigurations = @(
        ("linux", "amd64"), 
        ("linux", "arm64"), 
        ("windows", "amd64"), 
        ("darwin", "amd64"),
        ("darwin", "arm64")
    )
    foreach ($config in $buildConfigurations) {
        $env:GOOS = $os = $config[0]
        $env:GOARCH = $arch = $config[1]

        $bin = $binaryName
        if ($env:GOOS -eq "windows") {
            $bin += ".exe"
        }

        Write-Host "Building $os $arch"
        go build ..
        if (-not $?) {
            continue
        }

        Compress-Archive -Path $bin -DestinationPath "$binaryName-$os-$arch.zip"
    }

    Pop-Location

}
function bi {
    <#
    .SYNOPSIS
        Brew install
    #>
    param (
        # Install a cask
        [switch]
        $Cask,

        # Rest of the args
        [Parameter(Position = 0, ValueFromRemainingArguments = $true, Mandatory = $true)]
        $Args
    )

    $cmd = @("install")
    if ($Cask) {
        $cmd += "--cask"
    }

    $cmd += $Args

    & brew @cmd
}