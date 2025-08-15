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
        The function uses [System.Environment]::MachineName for the short computer name,
        which works consistently across all platforms where PowerShell runs.
        
        When the FullyQualifiedDomainName switch is used, the function attempts to
        retrieve the FQDN using [System.Net.Dns]::GetHostByName() which can resolve
        the full domain name when the system is properly configured with DNS.
        
        If DNS resolution fails or no domain is configured, the function will fall
        back to returning the short computer name even when FQDN is requested.
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

    if ($FullyQualifiedDomainName)
    {
        # Attempt to get FQDN using DNS resolution
        try
        {
            $fqdn = [System.Net.Dns]::GetHostByName($computerName).HostName
            if ($fqdn -and $fqdn -ne $computerName)
            {
                $computerName = $fqdn
            }
        }
        catch
        {
            # If DNS resolution fails, fall back to the short name
            # No action needed as $computerName already contains the short name
        }
    }

    return $computerName
}
