
<#
    .SYNOPSIS
        Returns the value from an environment variable from a specified target.

    .DESCRIPTION
        Returns the value from an environment variable from a specified target.

    .PARAMETER FromTarget
        Specifies the target to get the value from. Defaults to 'Session'.

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
