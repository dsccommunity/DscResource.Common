<#
    .SYNOPSIS
        Throws an error if there is a bound parameter that exists in both the
        mutually exclusive lists.

    .DESCRIPTION
        This command asserts passed parameters. It takes a hashtable, normally
        `$PSBoundParameters`. There are three parameter sets for this command.

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

        **AtLeastOne**

        Assert that at least one parameter from the specified list has been bound,
        and throws an exception if none are present.

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

       This parameter can also accept a hashtable of parameter names and their expected
       values. The assertion will only be performed if all the specified parameters in
       the BoundParameterList have the exact values specified in this hashtable.

    .PARAMETER AtLeastOneList
       An array of parameter names where at least one must be bound.

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

    .EXAMPLE
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -RequiredParameter @('PBStartPortRange', 'PBEndPortRange') -RequiredBehavior 'Any'

        Throws an exception if any of the two parameters are not present.

    .EXAMPLE
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -RequiredParameter @('PBStartPortRange', 'PBEndPortRange') -RequiredBehavior 'All'

        Throws an exception if all of the specified parameters are not present.

    .EXAMPLE
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -AtLeastOneList @('Severity', 'MessageId')

        Throws an exception if none of the parameters 'Severity' or 'MessageId' are specified.

    .EXAMPLE
        $assertBoundParameterParameters = @{
            BoundParameterList = $PSBoundParameters
            MutuallyExclusiveList1 = @(
                'Severity'
            )
            MutuallyExclusiveList2 = @(
                'MessageId'
            )
            IfParameterPresent = @{
                Ensure = 'Present'
            }
        }
        Assert-BoundParameter @assertBoundParameterParameters

        This example throws an exception if `$PSBoundParameters` contains both
        the parameters `Severity` and `MessageId` and the parameter `Ensure` has
        the value `Present`.

    .EXAMPLE
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -RequiredParameter @('Property2', 'Property3') -IfParameterPresent @{ Property1 = 'SpecificValue' }

        Throws an exception if the parameter 'Property1' has the value 'SpecificValue'
        and either of the required parameters are not specified.

    .EXAMPLE
        Assert-BoundParameter -BoundParameterList $PSBoundParameters -AtLeastOneList @('Severity', 'MessageId') -IfParameterPresent @{ Ensure = 'Present' }

        Throws an exception if the parameter 'Ensure' has the value 'Present' and
        none of the parameters 'Severity' or 'MessageId' are specified.
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
        [Parameter(ParameterSetName = 'MutuallyExclusiveParameters')]
        [Parameter(ParameterSetName = 'AtLeastOne')]
        [Alias('IfEqualParameterList')]
        [System.Object]
        $IfParameterPresent,

        [Parameter(ParameterSetName = 'AtLeastOne', Mandatory = $true)]
        [System.String[]]
        $AtLeastOneList
    )

    # Early return if IfParameterPresent conditions are not met
    if ($PSBoundParameters.ContainsKey('IfParameterPresent'))
    {
        if ($IfParameterPresent -is [System.Collections.Hashtable])
        {
            # Handle hashtable case (original IfEqualParameterList behavior)
            foreach ($parameterName in $IfParameterPresent.Keys)
            {
                if (-not $BoundParameterList.ContainsKey($parameterName) -or $BoundParameterList[$parameterName] -ne $IfParameterPresent[$parameterName])
                {
                    return
                }
            }
        }
        else
        {
            # Handle string array case (original IfParameterPresent behavior)
            $hasIfParameterPresent = $BoundParameterList.Keys.Where( { $_ -in $IfParameterPresent } )

            if (-not $hasIfParameterPresent)
            {
                return
            }
        }
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'MutuallyExclusiveParameters'
        {
            $itemFoundFromList1 = $BoundParameterList.Keys.Where({ $_ -in $MutuallyExclusiveList1 })
            $itemFoundFromList2 = $BoundParameterList.Keys.Where({ $_ -in $MutuallyExclusiveList2 })

            if ($itemFoundFromList1.Count -gt 0 -and $itemFoundFromList2.Count -gt 0)
            {
                $errorMessage = $script:localizedData.ParameterUsageWrong -f (
                    ($MutuallyExclusiveList1 -join "','"),
                    ($MutuallyExclusiveList2 -join "','")
                )

                New-ArgumentException -ArgumentName 'Parameters' -Message $errorMessage
            }

            break
        }

        'RequiredParameter'
        {
            $assertRequiredCommandParameterParams = @{
                BoundParameterList = $BoundParameterList
                RequiredParameter = $RequiredParameter
                RequiredBehavior = $RequiredBehavior
            }

            # Pass IfParameterPresent to Assert-RequiredCommandParameter for better error messages
            if ($PSBoundParameters.ContainsKey('IfParameterPresent'))
            {
                if ($IfParameterPresent -is [System.Collections.Hashtable])
                {
                    # For hashtable case, pass the keys as IfParameterPresent
                    $assertRequiredCommandParameterParams.IfParameterPresent = $IfParameterPresent.Keys
                }
                else
                {
                    # For string array case, pass as-is
                    $assertRequiredCommandParameterParams.IfParameterPresent = $IfParameterPresent
                }
            }

            Assert-RequiredCommandParameter @assertRequiredCommandParameterParams

            break
        }

        'AtLeastOne'
        {
            $boundParametersFromList = $BoundParameterList.Keys.Where({ $_ -in $AtLeastOneList })

            if ($boundParametersFromList.Count -eq 0)
            {
                $errorMessage = $script:localizedData.Assert_BoundParameter_AtLeastOneParameterMustBeSet -f ($AtLeastOneList -join "','")

                New-ArgumentException -ArgumentName 'Parameters' -Message $errorMessage
            }

            break
        }
    }
}
