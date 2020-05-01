<#
    .SYNOPSIS
        Converts a hashtable into a CimInstance array.

    .DESCRIPTION
        This function is used to convert a hashtable into MSFT_KeyValuePair objects.
        These are stored as an CimInstance array. DSC cannot handle hashtables but
        CimInstances arrays storing MSFT_KeyValuePair.

    .PARAMETER Hashtable
        A hashtable with the values to convert.

    .OUTPUTS
        An object array with CimInstance objects.
#>
function ConvertTo-CimInstance
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Hashtable')]
        [System.Collections.Hashtable]
        $Hashtable
    )

    process
    {
        foreach ($item in $Hashtable.GetEnumerator())
        {
            New-CimInstance -ClassName 'MSFT_KeyValuePair' -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -Property @{
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
