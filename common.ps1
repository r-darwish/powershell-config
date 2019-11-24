function Install-ModuleIfNeeded ($module)
{
    if (-Not (Get-Module -List -Name $module)) {
        Write-Output "Installing $module"
        Install-Module -Name $module -Scope CurrentUser -AllowClobber
    }
}
