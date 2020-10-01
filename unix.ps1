Function Enter-TmuxSession {
    [CmdletBinding()]
    param(
        [string]
        [Parameter(Position = 0)]
        $Session = "main"
    )

    tmux new-session -A -s $Session
}

Set-Alias -Name t -Value Enter-TmuxSession

$env:PATH += ":/usr/local/bin:$home/.local/bin"

if (Test-Path -Path "~/.cargo/bin") {
    $env:PATH += ":~/.cargo/bin"
}

function exec {
    Start-Process $args[0] $args[1..$args.Length] -Wait
}

Import-Module Microsoft.PowerShell.UnixCompleters