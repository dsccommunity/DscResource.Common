<#
    .SYNOPSIS
        Throws an error if there is a bound parameter that exists in both the
        mutually exclusive lists.

    .PARAMETER BoundParameterList
        The parameters that should be evaluated against the mutually exclusive
        lists MutuallyExclusiveList1 and MutuallyExclusiveList2. This parameter is
        normally set to the $PSBoundParameters variable.

    .PARAMETER MutuallyExclusiveList1
        An array of parameter names that are not allowed to be bound at the
        same time and those in MutuallyExclusiveList2.

    .PARAMETER MutuallyExclusiveList2
        An array of parameter names that are not allowed to be bound at the
        same time and those in MutuallyExclusiveList1.
#>
function Assert-BoundParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Hashtable]
        $BoundParameterList,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $MutuallyExclusiveList1,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $MutuallyExclusiveList2
    )

    $itemFoundFromList1 = $BoundParameterList.Keys.Where({ $_ -in $MutuallyExclusiveList1 })
    $itemFoundFromList2 = $BoundParameterList.Keys.Where({ $_ -in $MutuallyExclusiveList2 })

    if ($itemFoundFromList1.Count -gt 0 -and $itemFoundFromList2.Count -gt 0)
    {
        $errorMessage = `
            $script:localizedData.ParameterUsageWrong `
                -f ($MutuallyExclusiveList1 -join "','"), ($MutuallyExclusiveList2 -join "','")

        New-InvalidArgumentException -ArgumentName 'Parameters' -Message $errorMessage
    }
}
