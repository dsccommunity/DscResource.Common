
<#
    .SYNOPSIS
        Returns the environment variable PSModulePath from the specified target.

    .DESCRIPTION
        Returns the environment variable PSModulePath from the specified target.
        If more than one target are provided only the unique paths will be
        concatenated and returned.

    .PARAMETER FromTarget
        Specifies the target to get the PSModulePath from.

    .EXAMPLE
        Get-PSModulePath -FromTarget 'Session'

        Returns the paths from the Session target.

    .EXAMPLE
        Get-PSModulePath -FromTarget 'Session', 'User', 'Machine'

        Returns the unique paths from the all targets.

    .OUTPUTS
        [System.String]

        If there are no paths to return the command will return an empty string.
#>
function Get-PSModulePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Session', 'User', 'Machine')]
        [System.String[]]
        $FromTarget
    )

    $modulePathSession = $null
    $modulePathUser = $null
    $modulePathMachine = $null

    <#
        Get the environment variables from required targets. The value returned
        is cast to System.String to convert $null values to empty string.
    #>
    switch ($FromTarget)
    {
        'Session'
        {
            $modulePathSession = Get-EnvironmentVariable -Name 'PSModulePath'
        }

        'User'
        {
            $modulePathUser = Get-EnvironmentVariable -Name 'PSModulePath' -FromTarget 'User'
        }

        'Machine'
        {
            $modulePathMachine = Get-EnvironmentVariable -Name 'PSModulePath' -FromTarget 'Machine'
        }
    }

    $modulePath = $modulePathSession, $modulePathUser, $modulePathMachine -join ';'

    $modulePathArray = $modulePath -split ';' |
        Where-Object -FilterScript {
            -not [System.String]::IsNullOrEmpty($_)
        } |
        Sort-Object -Unique

    $modulePath = $modulePathArray -join ';'

    return $modulePath
}
