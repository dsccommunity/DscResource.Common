<#
    .SYNOPSIS
        This command is used to test current and desired values for any DSC resource.

    .DESCRIPTION
        This function tests the parameter status of DSC resource parameters against
        the current values present on the system.

        This cmdlet was designed to be used in a DSC resource from only _Test_.
        The design pattern that uses the cmdlet `Test-DscParameterState` assumes that
        LCM is used which always calls _Test_ before _Set_, or that there never
        is a need to evaluate the state in _Set_.

    .PARAMETER CurrentValues
        A hashtable with the current values on the system, obtained by e.g.
        Get-TargetResource.

    .PARAMETER DesiredValues
        The hashtable of desired values. For example $PSBoundParameters with the
        desired values.

    .PARAMETER Properties
        This is a list of properties in the desired values list should be checked.
        If this is empty then all values in DesiredValues are checked.

    .PARAMETER ExcludeProperties
        This is a list of which properties in the desired values list should be checked.
        If this is empty then all values in DesiredValues are checked.

    .PARAMETER TurnOffTypeChecking
        Indicates that the type of the parameter should not be checked.

    .PARAMETER ReverseCheck
        Indicates that a reverse check should be done. The current and desired state
        are swapped for another test.

    .PARAMETER SortArrayValues
        If the sorting of array values does not matter, values are sorted internally
        before doing the comparison.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        $currentState = Get-TargetResource @PSBoundParameters
        $returnValue = Test-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters

        The function Get-TargetResource is called first using all bound parameters
        to get the values in the current state. The result is then compared to the
        desired state by calling `Test-DscParameterState`. The result is either
        `$true` or `$false`, `$false` if one or more properties are not in desired
        state.

    .EXAMPLE
        $getTargetResourceParameters = @{
            ServerName     = $ServerName
            InstanceName   = $InstanceName
            Name           = $Name
        }
        $returnValue = Test-DscParameterState `
            -CurrentValues (Get-TargetResource @getTargetResourceParameters) `
            -DesiredValues $PSBoundParameters `
            -ExcludeProperties @(
                'FailsafeOperator'
                'NotificationMethod'
            )

        This compares the values in the current state against the desires state.
        The function Get-TargetResource is called using just the required parameters
        to get the values in the current state. The parameter 'ExcludeProperties'
        is used to exclude the properties 'FailsafeOperator' and 'NotificationMethod'
        from the comparison. The result is either `$true` or `$false`, `$false` if
        one or more properties are not in desired state.

    .EXAMPLE
        $getTargetResourceParameters = @{
            ServerName     = $ServerName
            InstanceName   = $InstanceName
            Name           = $Name
        }
        $returnValue = Test-DscParameterState `
            -CurrentValues (Get-TargetResource @getTargetResourceParameters) `
            -DesiredValues $PSBoundParameters `
            -Properties ServerName, Name

        This compares the values in the current state against the desires state.
        The function Get-TargetResource is called using just the required parameters
        to get the values in the current state. The 'Properties' parameter  is used
        to to only compare the properties 'ServerName' and 'Name'.
#>
function Test-DscParameterState
{
    [CmdletBinding()]
    [OutputType([Bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $CurrentValues,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $DesiredValues,

        [Parameter()]
        [System.String[]]
        [Alias('ValuesToCheck')]
        $Properties,

        [Parameter()]
        [System.String[]]
        $ExcludeProperties,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $TurnOffTypeChecking,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ReverseCheck,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $SortArrayValues
    )

    $returnValue = $true

    $resultCompare = Compare-DscParameterState @PSBoundParameters

    if ($resultCompare.InDesiredState -contains $false)
    {
        $returnValue = $false
    }

    return $returnValue
}
