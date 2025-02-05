<#
    .SYNOPSIS
        Throws an error if there is a bound parameter that exists in both the
        mutually exclusive lists.

    .DESCRIPTION
        This command asserts passed parameters. It takes a hashtable, normally
        `$PSBoundParameters`. There are two parameter sets for this command.

        >There is no built in logic to validate against parameters sets for DSC
        >so this can be used instead to validate the parameters that were set in
        >the configuration.

        **MutuallyExclusiveParameters**

        This parameter set takes two mutually exclusive lists of parameters.
        If any of the parameters in the first list are specified, none of the
        parameters in the second list can be specified.

        **RequiredParameter**

        Assert that required parameters has been specified, and throws an exception
        if not. Optionally it can be specified that parameters are only required
        if a specific parameter has been passed.

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

    .PARAMETER RequiredBehavior
       Whether RequiredParameter requires all or at least one parameter to be present.

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

        Throws an exception if the parameter 'Property1' is specified and either
        of the required parameters are not.
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
        [BoundParameterBehavior]
        $RequiredBehavior = [BoundParameterBehavior]::All,

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
