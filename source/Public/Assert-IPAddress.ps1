<#
    .SYNOPSIS
    Check the Address details are valid and do not conflict with Address family.
    If any problems are detected an exception will be thrown.

    .PARAMETER AddressFamily
    IP address family.

    .PARAMETER Address
    IP Address
#>
function Assert-IPAddress
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateSet('IPv4', 'IPv6')]
        [System.String]
        $AddressFamily,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Address
    )

    [System.Net.IPAddress] $ipAddress = $null
    if (-not ([System.Net.IPAddress]::TryParse($Address, [ref] $ipAddress)))
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.AddressFormatError -f $Address) `
            -ArgumentName 'Address'
    }

    if ($AddressFamily)
    {
        switch ($AddressFamily)
        {
            'IPv4'
            {
                if ($ipAddress.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork.ToString())
                {
                    New-InvalidArgumentException `
                        -Message ($script:localizedData.AddressIPv4MismatchError -f $Address, $AddressFamily) `
                        -ArgumentName 'AddressFamily'
                }
            }
            'IPv6'
            {
                if ($ipAddress.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetworkV6.ToString())
                {
                    New-InvalidArgumentException `
                        -Message ($script:localizedData.AddressIPv6MismatchError -f $Address, $AddressFamily) `
                        -ArgumentName 'AddressFamily'
                }
            }
        }
    }
}
