<#
    .SYNOPSIS
        Assert that the user has elevated the PowerShell session.

    .DESCRIPTION
        Assert that the user has elevated the PowerShell session. The command will
        throw a statement-terminating error if the script is not run from an elevated
        session.

    .PARAMETER ErrorMessage
        The error message to assign to the exception.

    .EXAMPLE
        Assert-ElevatedUser

        Throws an exception if the user has not elevated the PowerShell session.

    .EXAMPLE
        Assert-ElevatedUser -ErrorMessage 'A custom error message to throw'

        Throws an exception if the user has not elevated the PowerShell session.

    .EXAMPLE
        `Assert-ElevatedUser -ErrorAction 'Stop'`

        This example stops the entire script if it is not run from an
        elevated PowerShell session.

    .OUTPUTS
        None.
#>
function Assert-ElevatedUser
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorMessage = $script:localizedData.ElevatedUser_UserNotElevated
    )

    $isElevated = $false

    if ($IsMacOS -or $IsLinux)
    {
        $isElevated = (id -u) -eq 0
    }
    else
    {
        [Security.Principal.WindowsPrincipal] $user = [Security.Principal.WindowsIdentity]::GetCurrent()

        $isElevated = $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }

    if (-not $isElevated)
    {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                $ErrorMessage,
                'UserNotElevated',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                'Command parameters'
            )
        )
    }
}
