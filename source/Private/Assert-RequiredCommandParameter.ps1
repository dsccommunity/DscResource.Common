<#
    .SYNOPSIS
        Assert that required parameters has been specified.

    .DESCRIPTION
        Assert that required parameters has been specified, and throws an exception if not.

    .PARAMETER BoundParameterList
       A hashtable containing the parameters to evaluate. Normally this is set to
       $PSBoundParameters.

    .PARAMETER RequiredParameter
       One or more parameter names that is required to have been specified.

    .PARAMETER RequiredBehavior
       Whether RequiredParameter requires all or at least one parameter to be present.

    .PARAMETER IfParameterPresent
       One or more parameter names that if specified will trigger the evaluation.
       If neither of the parameter names has been specified the evaluation of required
       parameters are not made.

    .EXAMPLE
        Assert-RequiredCommandParameter -BoundParameter $PSBoundParameters -RequiredParameter @('PBStartPortRange', 'PBEndPortRange')

        Throws an exception if either of the two parameters are not specified.

    .EXAMPLE
        Assert-RequiredCommandParameter -BoundParameter $PSBoundParameters -RequiredParameter @('PBStartPortRange', 'PBEndPortRange') -RequiredBehavior 'AtLeastOnce'

        Throws an exception if at least one of the two parameters are not specified.

    .EXAMPLE
        Assert-RequiredCommandParameter -BoundParameter $PSBoundParameters -RequiredParameter @('Property2', 'Property3') -IfParameterPresent @('Property1')

        Throws an exception if the parameter 'Property1' is specified and either of the required parameters are not.

    .OUTPUTS
        None.
#>
function Assert-RequiredCommandParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $BoundParameterList,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $RequiredParameter,

        [Parameter()]
        [BoundParameterBehavior]
        $RequiredBehavior,

        [Parameter()]
        [System.String[]]
        $IfParameterPresent
    )

    $evaluateRequiredParameter = $true

    if ($PSBoundParameters.ContainsKey('IfParameterPresent'))
    {
        $hasIfParameterPresent = $BoundParameterList.Keys.Where( { $_ -in $IfParameterPresent } )

        if (-not $hasIfParameterPresent)
        {
            $evaluateRequiredParameter = $false
        }
    }

    if ($evaluateRequiredParameter)
    {
        switch ($RequiredBehavior)
        {
            All
            {
                foreach ($parameter in $RequiredParameter)
                {
                    if ($parameter -notin $BoundParameterList.Keys)
                    {
                        $errorMessage = if ($PSBoundParameters.ContainsKey('IfParameterPresent'))
                        {

                            $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSetWhenParameterExist -f ($RequiredParameter -join ''', '''), ($IfParameterPresent -join ''', ''')
                        }
                        else
                        {
                            $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSet -f ($RequiredParameter -join ''', ''')
                        }

                        $PSCmdlet.ThrowTerminatingError(
                            [System.Management.Automation.ErrorRecord]::new(
                                $errorMessage,
                                'ARCP0001', # cspell: disable-line
                                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                                'Command parameters'
                            )
                        )
                    }
                }

                break
            }

            AtLeastOnce
            {
                # Get all assigned properties.
                $requiredProperty = $BoundParameterList.Keys.Where({ $_ -in $RequiredParameter })

                # Must include any of the properties.
                if ([System.String]::IsNullOrEmpty($requiredProperty))
                {
                    $errorMessage = if ($PSBoundParameters.ContainsKey('IfParameterPresent'))
                    {

                        $script:localizedData.RequiredCommandParameter_SpecificParametersAtLeastOneMustBeSetWhenParameterExist -f ($RequiredParameter -join ''', '''), ($IfParameterPresent -join ''', ''')
                    }
                    else
                    {
                        $script:localizedData.RequiredCommandParameter_SpecificParametersAtLeastOneMustBeSet -f ($RequiredParameter -join ''', ''')
                    }

                    $PSCmdlet.ThrowTerminatingError(
                        [System.Management.Automation.ErrorRecord]::new(
                            $errorMessage,
                            'ARCP0002', # cspell: disable-line
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            'Command parameters'
                        )
                    )
                }

                break
            }
        }

    }
}
