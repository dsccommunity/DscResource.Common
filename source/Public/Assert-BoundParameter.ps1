<#
    .SYNOPSIS
        Throws an error if there is a bound parameter that exists in both the
        mutually exclusive lists.

    .DESCRIPTION
        Throws an error if there is a bound parameter that exists in both the
        mutually exclusive lists.

    .PARAMETER BoundParameterList
        The parameters that should be evaluated against the mutually exclusive
        lists MutuallyExclusiveList1 and MutuallyExclusiveList2. This parameter is
        normally set to the $PSBoundParameters variable.

    .PARAMETER MutuallyExclusiveList1
        An array of parameter names that are not allowed to be bound at the
        same time as those in MutuallyExclusiveList2.

    .PARAMETER MutuallyExclusiveList2
        An array of parameter names that are not allowed to be bound at the
        same time as those in MutuallyExclusiveList1.

    .PARAMETER RequiredParameter
       One or more parameter names that is required to have been specified.

    .PARAMETER IfParameterPresent
       One or more parameter names that if specified will trigger the evaluation.
       If neither of the parameter names has been specified the evaluation of required
       parameters are not made.

    .EXAMPLE
        $assertBoundParameterParameters = @{
            BoundParameterList = $PSBoundParameters
            MutuallyExclusiveList1 = @(
                'Parameter1'
            )
            MutuallyExclusiveList2 = @(
                'Parameter2'
            )
        }

        Assert-BoundParameter @assertBoundParameterParameters

        This example throws an exception if `$PSBoundParameters` contains both
        the parameters `Parameter1` and `Parameter2`.

    .EXAMPLE
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -RequiredParameter @('PBStartPortRange', 'PBEndPortRange')

        Throws an exception if either of the two parameters are not specified.

    .EXAMPLE
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -RequiredParameter @('Property2', 'Property3') -IfParameterPresent @('Property1')

        Throws an exception if the parameter 'Property1' is specified and either of the required parameters are not.
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

        [Parameter(ParameterSetName = 'MutuallyExclusiveParameters', Mandatory = $true)]
        [System.String[]]
        $MutuallyExclusiveList1,

        [Parameter(ParameterSetName = 'MutuallyExclusiveParameters', Mandatory = $true)]
        [System.String[]]
        $MutuallyExclusiveList2,

        [Parameter(ParameterSetName = 'RequiredParameter', Mandatory = $true)]
        [System.String[]]
        $RequiredParameter,

        [Parameter(ParameterSetName = 'RequiredParameter')]
        [System.String[]]
        $IfParameterPresent
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'MutuallyExclusiveParameters'
        {
            $itemFoundFromList1 = $BoundParameterList.Keys.Where({ $_ -in $MutuallyExclusiveList1 })
            $itemFoundFromList2 = $BoundParameterList.Keys.Where({ $_ -in $MutuallyExclusiveList2 })

            if ($itemFoundFromList1.Count -gt 0 -and $itemFoundFromList2.Count -gt 0)
            {
                $errorMessage = `
                    $script:localizedData.ParameterUsageWrong `
                        -f ($MutuallyExclusiveList1 -join "','"), ($MutuallyExclusiveList2 -join "','")

                New-InvalidArgumentException -ArgumentName 'Parameters' -Message $errorMessage
            }

            break
        }

        'RequiredParameter'
        {
            Assert-RequiredCommandParameter @PSBoundParameters

            break
        }
    }
}
