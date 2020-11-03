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