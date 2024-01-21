<#
    .SYNOPSIS
        Compares the current and the desired value of a property.

    .DESCRIPTION
        This function is used to compare the current and the desired value of a
        property.

    .PARAMETER Values
        This is set to a hash table with the current value (the CurrentValue key)
        and desired value (the DesiredValue key).

    .EXAMPLE
        Test-DscPropertyState -Values @{
            CurrentValue = 'John'
            DesiredValue = 'Alice'
        }

    .EXAMPLE
        Test-DscPropertyState -Values @{
            CurrentValue = 1
            DesiredValue = 2
        }

    .NOTES
        This function is used by the command Compare-ResourcePropertyState.
#>
function Test-DscPropertyState
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Values
    )

    if ($null -eq $Values.CurrentValue -and $null -eq $Values.DesiredValue)
    {
        # Both values are $null so return $true
        $returnValue = $true
    }
    elseif ($null -eq $Values.CurrentValue -or $null -eq $Values.DesiredValue)
    {
        # Either CurrentValue or DesiredValue are $null so return $false
        $returnValue = $false
    }
    elseif (
        $Values.DesiredValue -is [Microsoft.Management.Infrastructure.CimInstance[]] `
        -or $Values.DesiredValue -is [System.Array] -and $Values.DesiredValue[0] -is [Microsoft.Management.Infrastructure.CimInstance]
    )
    {
        if (-not $Values.ContainsKey('KeyProperties'))
        {
            $errorMessage = $script:localizedData.KeyPropertiesMissing

            New-InvalidOperationException -Message $errorMessage
        }

        $propertyState = @()

        <#
            It is a collection of CIM instances, then recursively call
            Test-DscPropertyState for each CIM instance in the collection.
        #>
        foreach ($desiredCimInstance in $Values.DesiredValue)
        {
            $currentCimInstance = $Values.CurrentValue

            <#
                Use the CIM instance Key properties to filter out the current
                values if the exist.
            #>
            foreach ($keyProperty in $Values.KeyProperties)
            {
                $currentCimInstance = $currentCimInstance |
                    Where-Object -Property $keyProperty -EQ -Value $desiredCimInstance.$keyProperty
            }

            if ($currentCimInstance.Count -gt 1)
            {
                $errorMessage = $script:localizedData.TooManyCimInstances

                New-InvalidOperationException -Message $errorMessage
            }

            if ($currentCimInstance)
            {
                $keyCimInstanceProperties = $currentCimInstance.CimInstanceProperties |
                    Where-Object -FilterScript {
                        $_.Name -in $Values.KeyProperties
                    }

                <#
                    For each key property build a string representation of the
                    property name and its value.
                #>
                $keyPropertyValues = $keyCimInstanceProperties.ForEach({'{0}="{1}"' -f $_.Name, ($_.Value -join ',')})

                Write-Debug -Message (
                    $script:localizedData.TestingCimInstance -f @(
                        $currentCimInstance.CimClass.CimClassName,
                        ($keyPropertyValues -join ';')
                    )
                )
            }
            else
            {
                $keyCimInstanceProperties = $desiredCimInstance.CimInstanceProperties |
                    Where-Object -FilterScript {
                        $_.Name -in $Values.KeyProperties
                    }

                <#
                    For each key property build a string representation of the
                    property name and its value.
                #>
                $keyPropertyValues = $keyCimInstanceProperties.ForEach({'{0}="{1}"' -f $_.Name, ($_.Value -join ',')})

                Write-Debug -Message (
                    $script:localizedData.MissingCimInstance -f @(
                        $desiredCimInstance.CimClass.CimClassName,
                        ($keyPropertyValues -join ';')
                    )
                )
            }

            # Recursively call Test-DscPropertyState with the CimInstance to evaluate.
            $propertyState += Test-DscPropertyState -Values @{
                CurrentValue = $currentCimInstance
                DesiredValue = $desiredCimInstance
            }
        }

        # Return $false if one property is found to not be in desired state.
        $returnValue = -not ($false -in $propertyState)
    }
    elseif ($Values.DesiredValue -is [Microsoft.Management.Infrastructure.CimInstance])
    {
        $propertyState = @()

        <#
            It is a CIM instance, recursively call Test-DscPropertyState for each
            CIM instance property.
        #>
        $desiredCimInstanceProperties = $Values.DesiredValue.CimInstanceProperties |
            Select-Object -Property @('Name', 'Value')

        if ($desiredCimInstanceProperties)
        {
            foreach ($desiredCimInstanceProperty in $desiredCimInstanceProperties)
            {
                <#
                    Recursively call Test-DscPropertyState to evaluate each property
                    in the CimInstance.
                #>
                $propertyState += Test-DscPropertyState -Values @{
                    CurrentValue = $Values.CurrentValue.($desiredCimInstanceProperty.Name)
                    DesiredValue = $desiredCimInstanceProperty.Value
                }
            }
        }
        else
        {
            if ($Values.CurrentValue.CimInstanceProperties.Count -gt 0)
            {
                # Current value did not have any CIM properties, but desired state has.
                $propertyState += $false
            }
        }

        # Return $false if one property is found to not be in desired state.
        $returnValue = -not ($false -in $propertyState)
    }
    elseif ($Values.DesiredValue -is [System.Array] -or $Values.CurrentValue -is [System.Array])
    {
        $compareObjectParameters = @{
            ReferenceObject  = $Values.CurrentValue
            DifferenceObject = $Values.DesiredValue
        }

        $arrayCompare = Compare-Object @compareObjectParameters

        if ($null -ne $arrayCompare)
        {
            Write-Debug -Message $script:localizedData.ArrayDoesNotMatch

            $arrayCompare |
                ForEach-Object -Process {
                    if ($_.SideIndicator -eq '=>')
                    {
                        Write-Debug -Message (
                            $script:localizedData.ArrayValueIsAbsent -f $_.InputObject
                        )
                    }
                    else
                    {
                        Write-Debug -Message (
                            $script:localizedData.ArrayValueIsPresent -f $_.InputObject
                        )
                    }
                }

            $returnValue = $false
        }
        else
        {
            $returnValue = $true
        }
    }
    elseif ($Values.CurrentValue -ne $Values.DesiredValue)
    {
        $desiredType = $Values.DesiredValue.GetType()

        $returnValue = $false

        $supportedTypes = @(
            'String'
            'Int32'
            'UInt32'
            'Int16'
            'UInt16'
            'Single'
            'Boolean'
        )

        if ($desiredType.Name -notin $supportedTypes)
        {
            Write-Warning -Message ($script:localizedData.UnableToCompareType -f $desiredType.Name)
        }
        else
        {
            Write-Debug -Message (
                $script:localizedData.PropertyValueOfTypeDoesNotMatch `
                    -f $desiredType.Name, $Values.CurrentValue, $Values.DesiredValue
            )
        }
    }
    else
    {
        $returnValue = $true
    }

    return $returnValue
}
