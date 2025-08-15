<#
    .SYNOPSIS
        Returns the computer name cross-plattform.

    .DESCRIPTION
        Returns the computer name cross-plattform. The variable `$env:COMPUTERNAME`
        does not exist cross-platform which hinders development and testing on
        macOS and Linux. Instead this command can be used to get the computer name
        cross-plattform.

    .PARAMETER FullyQualifiedDomainName
        Returns the fully qualified domain name (FQDN) instead of just the computer name.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-ComputerName

        Returns the computer name regardless of platform.

    .EXAMPLE
        Get-ComputerName -FullyQualifiedDomainName

        Returns the fully qualified domain name regardless of platform.

    .NOTES
        The function uses [System.Environment]::MachineName which works consistently
        across all platforms where PowerShell runs. When used without the
        FullyQualifiedDomainName switch, it returns only the short computer name
        by splitting on the first dot to ensure consistent behavior regardless
        of how the system hostname is configured.

        For the FullyQualifiedDomainName to return accurate information cross-platform,
        the system must be properly configured with the correct domain information.
        On some systems, [System.Environment]::MachineName may only return the
        short name even when requesting the FQDN if the system is not domain-joined
        or properly configured with DNS domain information.
#>
function Get-ComputerName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $FullyQualifiedDomainName
    )

    $computerName = [System.Environment]::MachineName

    if (-not $FullyQualifiedDomainName)
    {
        # Return only the short computer name by splitting on the first dot
        $computerName = ($computerName -split '\.')[0]
    }

    return $computerName
}
