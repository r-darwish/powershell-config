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