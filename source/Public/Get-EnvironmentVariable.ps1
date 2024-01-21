<#
    .SYNOPSIS
        Returns the value from an environment variable from a specified target.

    .DESCRIPTION
        Returns the value from an environment variable from a specified target.
        This command returns `$null` if the environment variable does not exist.

    .PARAMETER Name
        Specifies the environment variable name.

    .PARAMETER FromTarget
        Specifies the target to return the value from. Defaults to 'Session'.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-EnvironmentVariable -Name 'PSModulePath'

        Returns the value for the environment variable PSModulePath.

    .EXAMPLE
        Get-EnvironmentVariable -Name 'PSModulePath' -FromTarget 'Machine'

        Returns the value for the environment variable PSModulePath from the
        Machine target.

    .OUTPUTS
        [System.String]
#>
function Get-EnvironmentVariable
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Session', 'User', 'Machine')]
        [System.String]
        $FromTarget = 'Session'
    )

    switch ($FromTarget)
    {
        'Session'
        {
            $value = [System.Environment]::GetEnvironmentVariable($Name)
        }

        'User'
        {
            $value = [System.Environment]::GetEnvironmentVariable($Name, 'User')
        }

        'Machine'
        {
            $value = [System.Environment]::GetEnvironmentVariable($Name, 'Machine')
        }
    }

    return $value
}
