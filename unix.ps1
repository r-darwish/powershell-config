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

$env:PATH += ":/usr/local/bin"
