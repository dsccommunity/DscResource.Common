<#
    .SYNOPSIS
        Returns the computer name cross-plattform.

    .DESCRIPTION
        Returns the computer name cross-plattform. The variable `$env:COMPUTERNAME`
        does not exist cross-platform which hinders development and testing on
        macOS and Linux. Instead this command can be used to get the computer name
        cross-plattform.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-ComputerName

        Returns the computer name regardless of platform.
#>
function Get-ComputerName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    $computerName = $null

    if ($IsLinux -or $IsMacOs)
    {
        $computerName = hostname
    }
    else
    {
        <#
            We could run 'hostname' on Windows too, but $env:COMPUTERNAME
            is more widely used.
        #>
        $computerName = $env:COMPUTERNAME
    }

    return $computerName
}
