<#
    .SYNOPSIS
        Tests if the current OS is a Nano server.
#>
function Test-IsNanoServer
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param ()

    $productDatacenterNanoServer = 143
    $productStandardNanoServer = 144

    $operatingSystemSKU = (Get-CimInstance -ClassName Win32_OperatingSystem).OperatingSystemSKU

    Write-Verbose -Message ($script:localizedData.TestIsNanoServerOperatingSystemSku -f $operatingSystemSKU)

    return ($operatingSystemSKU -in ($productDatacenterNanoServer, $productStandardNanoServer))
}
