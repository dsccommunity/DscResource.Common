<#
    .SYNOPSIS
        Asserts that the specified IP address is valid.

    .DESCRIPTION
        Checks the IP address so that it is valid and do not conflict with address
        family. If any problems are detected an exception will be thrown.

    .PARAMETER AddressFamily
        IP address family that the supplied Address should be in. Valid values are
        'IPv4' or 'IPv6'.

    .PARAMETER Address
        Specifies an IPv4 or IPv6 address.

    .EXAMPLE
        Assert-IPAddress -Address '127.0.0.1'

        This will assert that the supplied address is a valid IPv4 address.
        If it is not an exception will be thrown.

    .EXAMPLE
        Assert-IPAddress -Address 'fe80:ab04:30F5:002b::1'

        This will assert that the supplied address is a valid IPv6 address.
        If it is not an exception will be thrown.

    .EXAMPLE
        Assert-IPAddress -Address 'fe80:ab04:30F5:002b::1' -AddressFamily 'IPv6'

        This will assert that address is valid and that it matches the
        supplied address family. If the supplied address family does not match
        the address an exception will be thrown.
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
                        -Message ($script:localizedData.AddressIPv6MismatchError -f $Address, $AddressFamily) `
                        -ArgumentName 'AddressFamily'
                }
            }

            'IPv6'
            {
                if ($ipAddress.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetworkV6.ToString())
                {
                    New-InvalidArgumentException `
                        -Message ($script:localizedData.AddressIPv4MismatchError -f $Address, $AddressFamily) `
                        -ArgumentName 'AddressFamily'
                }
            }
        }
    }
}
