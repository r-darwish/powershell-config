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

    $gitArgs = @("branch", '--format=%(refname:short)')
    if ($Remotes) {
        $gitArgs += "-r"
    }
    git $gitArgs

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

function gco {
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
        $Tags
    )

    if (-not $Reference) {
        $Reference = Get-GitBranches -Remotes:$Remotes -Tags:$Tags | Out-ConsoleGridView -OutputMode Single -Title "Select a branch to checkout"
    }

    if ($Reference) {
        git checkout $Reference
    }
}

Register-ArgumentCompleter -CommandName gco -ParameterName Reference -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)
    Get-GitBranches -Remotes -Tags
}

function gituser {
    $email = "rodarwis@microsoft.com", "roey.ghost@gmail.com" | Out-ConsoleGridView -OutputMode Single -Title "Select a git user"
    git config user.email $email
}

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
        $Commit = "",
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
            if (-not $Commit) {
                $Commit = ((git branch "--format=%(upstream:short)") -split "\n")[0]
                if (-not $?) {
                    Write-Error "$abs`: Cannot find the upstream branch"
                    continue
                }
            }

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

function Get-Vagrant {
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