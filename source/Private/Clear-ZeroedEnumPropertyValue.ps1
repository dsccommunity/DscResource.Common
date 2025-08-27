<#
    .SYNOPSIS
        Removes any properties from a hashable which have values that are
        type [System.Enum] and have an [System.Int32] value of 0.

    .DESCRIPTION
        Removes any properties from a hashable which have values that are
        type [System.Enum] and have an [System.Int32] value of 0.

    .PARAMETER InputObject
        The hashtable to be checked.

    .EXAMPLE
        Clear-ZeroedEnumPropertyValue -InputObject $ht

    .OUTPUTS
        [System.Collections.Hashtable]
#>

function Clear-ZeroedEnumPropertyValue
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Collections.Hashtable]
        $InputObject
    )

    begin
    {
        $result = @{}
    }

    process
    {

        foreach ($property in $InputObject.Keys)
        {
            $value = $InputObject.$property
            if ($value -is [System.Enum] -and [System.Int32]$value.value__ -eq 0)
            {
                continue
            }

            $result.$property = $value
        }

    }

    end
    {
        return $result
    }
}
