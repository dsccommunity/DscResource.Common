<#
    .SYNOPSIS
        Returns the user name cross-plattform.

    .DESCRIPTION
        Returns the current user name cross-plattform. The variable `$env:USERNAME`
        does not exist cross-platform which hinders development and testing on
        macOS and Linux. Instead this command can be used to get the user name
        cross-plattform.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-UserName

        Returns the user name regardless of platform.
#>
function Get-UserName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    $userName = $null

    if ($IsLinux -or $IsMacOs)
    {
        $userName = $env:USER
    }
    else
    {
        $userName = $env:USERNAME
    }

    return $userName
}
