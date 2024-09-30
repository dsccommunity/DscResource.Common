<#
    .SYNOPSIS
        Converts a hashtable into a CimInstance array.

    .DESCRIPTION
        This function is used to convert a hashtable into MSFT_KeyValuePair objects.
        These are stored as an CimInstance array. DSC cannot handle hashtables but
        CimInstances arrays storing MSFT_KeyValuePair.

    .PARAMETER Hashtable
        A hashtable with the values to convert.

    .PARAMETER ClassName
        The ClassName of the CimInstance to create.

        Default value is to 'MSFT_KeyValuePair'.

    .PARAMETER Namespace
        The Namespace of the CimInstance to create.

        Default value is to 'root/microsoft/Windows/DesiredStateConfiguration'.

    .OUTPUTS
        System.Object[]

    .EXAMPLE
        ConvertTo-CimInstance -Hashtable @{
            String = 'a string'
            Bool   = $true
            Int    = 99
            Array  = 'a, b, c'
        }

        This example returns an CimInstance with the provided hashtable values.
#>
function ConvertTo-CimInstance
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Collections.Hashtable]
        $Hashtable,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ClassName = 'MSFT_KeyValuePair',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Namespace = 'root/microsoft/Windows/DesiredStateConfiguration'
    )

    process
    {
        foreach ($item in $Hashtable.GetEnumerator())
        {
            New-CimInstance -ClassName $ClassName -Namespace $Namespace -Property @{
                Key   = $item.Key
                Value = if ($item.Value -is [array])
                {
                    $item.Value -join ','
                }
                else
                {
                    $item.Value
                }
            } -ClientOnly
        }
    }
}
