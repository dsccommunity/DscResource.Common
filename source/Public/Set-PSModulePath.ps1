<#
    .SYNOPSIS
        Set environment variable PSModulePath in the current session or machine
        wide.

    .DESCRIPTION
        This is a command to set environment variable PSModulePath in current
        session or machine wide.

    .OUTPUTS
        None

    .PARAMETER Path
        A string with all the paths separated by semi-colons.

    .PARAMETER Machine
        If set the PSModulePath will be changed machine wide. If not set, only
        the current session will be changed.

    .PARAMETER FromTarget
        The target environment variable to copy the value from.

    .PARAMETER ToTarget
        The target environment variable to set the value to.

    .PARAMETER PassThru
        If specified, returns the set value.

    .EXAMPLE
        Set-PSModulePath -Path '<Path 1>;<Path 2>'

        Sets the session environment variable `PSModulePath` to the specified path
        or paths (separated with semi-colons).

    .EXAMPLE
        Set-PSModulePath -Path '<Path 1>;<Path 2>' -Machine

        Sets the machine environment variable `PSModulePath` to the specified path
        or paths (separated with semi-colons).

    .EXAMPLE
        Set-PSModulePath -FromTarget 'MAchine' -ToTarget 'User'

        Copies the value of the machine environment variable `PSModulePath` to the
        user environment variable `PSModulePath`.
#>
function Set-PSModulePath
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'ShouldProcess is not supported in DSC resources.'
    )]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'Default')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter(ParameterSetName = 'Default')]
        [System.Management.Automation.SwitchParameter]
        $Machine,

        [Parameter(Mandatory = $true, ParameterSetName = 'TargetParameters')]
        [ValidateSet('Session', 'User', 'Machine')]
        [System.String]
        $FromTarget,

        [Parameter(Mandatory = $true, ParameterSetName = 'TargetParameters')]
        [ValidateSet('Session', 'User', 'Machine')]
        [System.String]
        $ToTarget,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    if ($PSCmdlet.ParameterSetName -eq 'Default')
    {
        if ($Machine.IsPresent)
        {
            [System.Environment]::SetEnvironmentVariable('PSModulePath', $Path, [System.EnvironmentVariableTarget]::Machine)
        }
        else
        {
            $env:PSModulePath = $Path
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'TargetParameters')
    {
        $Path = Get-EnvironmentVariable -Name 'PSModulePath' -FromTarget $FromTarget

        switch ($ToTarget)
        {
            'Session'
            {
                [System.Environment]::SetEnvironmentVariable('PSModulePath', $Path)
            }

            default
            {
                [System.Environment]::SetEnvironmentVariable('PSModulePath', $Path, [System.EnvironmentVariableTarget]::$ToTarget)
            }
        }
    }

    if ($PassThru.IsPresent)
    {
        return $Path
    }
}
