<#
    .SYNOPSIS
        Compare current and desired property values for any DSC resource and return
        a hashtable with the metadata from the comparison.

    .DESCRIPTION
        This function is used to compare current and desired property values for any
        DSC resource, and return a hashtable with the metadata from the comparison.

        This introduces another design pattern that is used to evaluate current and
        desired state in a DSC resource. This command is meant to be used in a DSC
        resource from both _Test_ and _Set_. The evaluation is made in _Set_
        to make sure to only change the properties that are not in the desired state.
        Properties that are in the desired state should not be changed again. This
        design pattern also handles when the command `Invoke-DscResource` is called
        with the method `Set`, which with this design pattern will evaluate the
        properties correctly.

        >[!NOTE]
        >This design pattern is not widely used in the DSC resource modules in the
        >DSC Community, the only known use is in SqlServerDsc. This design pattern
        >can be viewed as deprecated, and should be replaced with the design pattern
        >that uses the command [`Compare-DscParameterState`](Compare-DscParameterState).

        See the other design patterns that uses the command [`Compare-DscParameterState`](Compare-DscParameterState)
        or [`Test-DscParameterState`](Test-DscParameterState).

    .PARAMETER CurrentValues
        The current values that should be compared to to desired values. Normally
        the values returned from Get-TargetResource.

    .PARAMETER DesiredValues
        The values set in the configuration and is provided in the call to the
        functions *-TargetResource, and that will be compared against current
        values. Normally set to $PSBoundParameters.

    .PARAMETER Properties
        An array of property names, from the keys provided in DesiredValues, that
        will be compared. If this parameter is left out, all the keys in the
        DesiredValues will be compared.

    .PARAMETER IgnoreProperties
        An array of property names, from the keys provided in DesiredValues, that
        will be ignored in the comparison. If this parameter is left out, all the
        keys in the DesiredValues will be compared.

    .PARAMETER CimInstanceKeyProperties
        A hashtable containing a key for each property that contain a collection
        of CimInstances and the value is an array of strings of the CimInstance
        key properties.
        @{
            Permission = @('State')
        }

    .OUTPUTS
        System.Collections.Hashtable[]

    .NOTES
        Returns an array containing a hashtable with metadata for each property
        that was evaluated.

        Metadata Name | Type | Description
        --- | --- | ---
        ParameterName | `[System.String]` | The name of the property that was evaluated
        Expected | The type of the property | The desired value for the property
        Actual | The type of the property | The actual current value for the property
        InDesiredState | `[System.Boolean]` | Returns `$true` if the expected and actual value was equal.

    .EXAMPLE
        $compareTargetResourceStateParameters = @{
            CurrentValues = (Get-TargetResource $PSBoundParameters)
            DesiredValues = $PSBoundParameters
        }
        $propertyState = Compare-ResourcePropertyState @compareTargetResourceStateParameters
        $propertiesNotInDesiredState = $propertyState.Where({ -not $_.InDesiredState })

        This example calls Compare-ResourcePropertyState with the current state
        and the desired state and returns a hashtable array of all the properties
        that was evaluated based on the properties pass in the parameter DesiredValues.
        Finally it sets a parameter `$propertiesNotInDesiredState` that contain
        an array with all properties not in desired state.

    .EXAMPLE
        $compareTargetResourceStateParameters = @{
            CurrentValues = (Get-TargetResource $PSBoundParameters)
            DesiredValues = $PSBoundParameters
            Properties    = @(
                'Property1'
            )
        }
        $propertyState = Compare-ResourcePropertyState @compareTargetResourceStateParameters
        $false -in $propertyState.InDesiredState

        This example calls Compare-ResourcePropertyState with the current state
        and the desired state and returns a hashtable array with just the property
        `Property1` as that was the only property that was to be evaluated.
        Finally it checks if `$false` is present in the array property `InDesiredState`.

    .EXAMPLE
        $compareTargetResourceStateParameters = @{
            CurrentValues    = (Get-TargetResource $PSBoundParameters)
            DesiredValues    = $PSBoundParameters
            IgnoreProperties = @(
                'Property1'
            )
        }
        $propertyState = Compare-ResourcePropertyState @compareTargetResourceStateParameters

        This example calls Compare-ResourcePropertyState with the current state
        and the desired state and returns a hashtable array of all the properties
        except the property `Property1`.

    .EXAMPLE
        $compareTargetResourceStateParameters = @{
            CurrentValues    = (Get-TargetResource $PSBoundParameters)
            DesiredValues    = $PSBoundParameters
            CimInstanceKeyProperties = @{
                ResourceProperty1 = @(
                    'CimProperty1'
                )
            }
        }
        $propertyState = Compare-ResourcePropertyState @compareTargetResourceStateParameters

        This example calls Compare-ResourcePropertyState with the current state
        and the desired state and have a property `ResourceProperty1` who's value
        is an  array of embedded CIM instances. The key property for the CIM instances
        are `CimProperty1`. The CIM instance key property `CimProperty1` is used
        to get the unique CIM instance object to compare against from both the current
        state and the desired state.
#>
function Compare-ResourcePropertyState
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseSyntacticallyCorrectExamples', '', Justification = 'Because the rule does not yet support parsing the code when a parameter type is not available. The ScriptAnalyzer rule UseSyntacticallyCorrectExamples will always error in the editor due to https://github.com/indented-automation/Indented.ScriptAnalyzerRules/issues/8.')]
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $CurrentValues,

        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $DesiredValues,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Properties,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $IgnoreProperties,

        [Parameter()]
        [ValidateNotNull()]
        [System.Collections.Hashtable]
        $CimInstanceKeyProperties = @{}
    )

    if ($PSBoundParameters.ContainsKey('Properties'))
    {
        # Filter out the parameters (keys) not specified in Properties
        $desiredValuesToRemove = $DesiredValues.Keys |
            Where-Object -FilterScript {
                $_ -notin $Properties
            }

        $desiredValuesToRemove |
            ForEach-Object -Process {
                $DesiredValues.Remove($_)
            }
    }
    else
    {
        <#
            Remove any common parameters that might be part of DesiredValues,
            if it $PSBoundParameters was used to pass the desired values.
        #>
        $commonParametersToRemove = $DesiredValues.Keys |
            Where-Object -FilterScript {
                $_ -in [System.Management.Automation.PSCmdlet]::CommonParameters `
                    -or $_ -in [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
            }

        $commonParametersToRemove |
            ForEach-Object -Process {
                $DesiredValues.Remove($_)
            }
    }

    # Remove any properties that should be ignored.
    if ($PSBoundParameters.ContainsKey('IgnoreProperties'))
    {
        $IgnoreProperties |
            ForEach-Object -Process {
                if ($DesiredValues.ContainsKey($_))
                {
                    $DesiredValues.Remove($_)
                }
            }
    }

    $compareTargetResourceStateReturnValue = [System.Collections.ArrayList]::new()

    foreach ($parameterName in $DesiredValues.Keys)
    {
        Write-Debug -Message ($script:localizedData.EvaluatePropertyState -f $parameterName)

        $parameterState = @{
            ParameterName = $parameterName
            Expected      = $DesiredValues.$parameterName
            Actual        = $CurrentValues.$parameterName
        }

        # Check if the parameter is in compliance.
        $isPropertyInDesiredState = Test-DscPropertyState -Values @{
            CurrentValue = $CurrentValues.$parameterName
            DesiredValue = $DesiredValues.$parameterName
            KeyProperties = $CimInstanceKeyProperties.$parameterName
        }

        if ($isPropertyInDesiredState)
        {
            Write-Verbose -Message ($script:localizedData.PropertyInDesiredState -f $parameterName)

            $parameterState['InDesiredState'] = $true
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.PropertyNotInDesiredState -f $parameterName)

            $parameterState['InDesiredState'] = $false
        }

        $compareTargetResourceStateReturnValue += $parameterState
    }

    return $compareTargetResourceStateReturnValue
}
