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

    .EXAMPLE
        Set-PSModulePath -Path '<Path 1>;<Path 2>'

        Sets the session environment variable `PSModulePath` to the specified path
        or paths (separated with semi-colons).

    .EXAMPLE
        Set-PSModulePath -Path '<Path 1>;<Path 2>' -Machine

        Sets the machine environment variable `PSModulePath` to the specified path
        or paths (separated with semi-colons).
#>
function Set-PSModulePath
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'ShouldProcess is not supported in DSC resources.'
    )]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Machine
    )

    if ($Machine.IsPresent)
    {
        [System.Environment]::SetEnvironmentVariable('PSModulePath', $Path, [System.EnvironmentVariableTarget]::Machine)
    }
    else
    {
        $env:PSModulePath = $Path
    }
}
