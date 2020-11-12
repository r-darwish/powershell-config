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