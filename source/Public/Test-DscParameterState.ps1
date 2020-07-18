<#
    .SYNOPSIS
        This method is used to compare current and desired values for any DSC resource.

    .DESCRIPTION
        This function tests the parameter status of DSC resource parameters against
        the current values present on the system.

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

    .EXAMPLE
        $currentState = Get-TargetResource @PSBoundParameters

        $returnValue = Test-DscParameterState -CurrentValues $currentState -DesiredValues $PSBoundParameters

        The function Get-TargetResource is called first using all bound parameters
        to get the values in the current state. The result is then compared to the
        desired state by calling `Test-DscParameterState`.

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
        is used to exclude the properties 'FailsafeOperator' and
        'NotificationMethod' from the comparison.

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

    if ($CurrentValues -is [Microsoft.Management.Infrastructure.CimInstance] -or
        $CurrentValues -is [Microsoft.Management.Infrastructure.CimInstance[]])
    {
        $CurrentValues = ConvertTo-HashTable -CimInstance $CurrentValues
    }

    if ($DesiredValues -is [Microsoft.Management.Infrastructure.CimInstance] -or
        $DesiredValues -is [Microsoft.Management.Infrastructure.CimInstance[]])
    {
        $DesiredValues = ConvertTo-HashTable -CimInstance $DesiredValues
    }

    $types = 'System.Management.Automation.PSBoundParametersDictionary', 'System.Collections.Hashtable', 'Microsoft.Management.Infrastructure.CimInstance'

    if ($DesiredValues.GetType().FullName -notin $types)
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.InvalidDesiredValuesError -f $DesiredValues.GetType().FullName) `
            -ArgumentName 'DesiredValues'
    }

    if ($CurrentValues.GetType().FullName -notin $types)
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.InvalidCurrentValuesError -f $CurrentValues.GetType().FullName) `
            -ArgumentName 'CurrentValues'
    }

    if ($DesiredValues -is [Microsoft.Management.Infrastructure.CimInstance] -and -not $Properties)
    {
        New-InvalidArgumentException `
            -Message $script:localizedData.InvalidPropertiesError `
            -ArgumentName Properties
    }

    $desiredValuesClean = Remove-CommonParameter -Hashtable $DesiredValues

    if (-not $Properties)
    {
        $keyList = $desiredValuesClean.Keys
    }
    else
    {
        $keyList = $Properties
    }
    if ($ExcludeProperties)
    {
        $keyList = $keyList | Where-Object -FilterScript { $_ -notin $ExcludeProperties }
    }

    foreach ($key in $keyList)
    {
        $desiredValue = $desiredValuesClean.$key
        $currentValue = $CurrentValues.$key

        if ($desiredValue -is [Microsoft.Management.Infrastructure.CimInstance] -or
            $desiredValue -is [Microsoft.Management.Infrastructure.CimInstance[]])
        {
            $desiredValue = ConvertTo-HashTable -CimInstance $desiredValue
        }
        if ($currentValue -is [Microsoft.Management.Infrastructure.CimInstance] -or
            $currentValue -is [Microsoft.Management.Infrastructure.CimInstance[]])
        {
            $currentValue = ConvertTo-HashTable -CimInstance $currentValue
        }

        if ($desiredValue)
        {
            $desiredType = $desiredValue.GetType()
        }
        else
        {
            $desiredType = @{
                Name = 'Unknown'
            }
        }

        if ($currentValue)
        {
            $currentType = $currentValue.GetType()
        }
        else
        {
            $currentType = @{
                Name = 'Unknown'
            }
        }

        if ($currentType.Name -ne 'Unknown' -and $desiredType.Name -eq 'PSCredential')
        {
            # This is a credential object. Compare only the user name
            if ($currentType.Name -eq 'PSCredential' -and $currentValue.UserName -eq $desiredValue.UserName)
            {
                Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
                $returnValue = $false
            }

            # Assume the string is our username when the matching desired value is actually a credential
            if ($currentType.Name -eq 'string' -and $currentValue -eq $desiredValue.UserName)
            {
                Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
                $returnValue = $false
            }
        }

        if (-not $TurnOffTypeChecking)
        {
            if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
                $desiredType.FullName -ne $currentType.FullName)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchTypeMismatchMessage -f $key, $currentType.FullName, $desiredType.FullName)
                $returnValue = $false
                continue
            }
        }

        if ($currentValue -eq $desiredValue -and -not $desiredType.IsArray)
        {
            Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
            continue
        }

        if ($desiredValuesClean.GetType().Name -in 'HashTable', 'PSBoundParametersDictionary')
        {
            $checkDesiredValue = $desiredValuesClean.ContainsKey($key)
        }
        else
        {
            $checkDesiredValue = Test-DscObjectHasProperty -Object $desiredValuesClean -PropertyName $key
        }

        if (-not $checkDesiredValue)
        {
            Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
            continue
        }

        if ($desiredType.IsArray)
        {
            Write-Verbose -Message ($script:localizedData.TestDscParameterCompareMessage -f $key, $desiredType.FullName)

            if (-not $currentValue -and -not $desiredValue)
            {
                Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, 'empty array', 'empty array')
                continue
            }
            elseif (-not $currentValue)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
                $returnValue = $false
                continue
            }
            elseif ($currentValue.Count -ne $desiredValue.Count)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueDifferentCountMessage -f $desiredType.FullName, $key, $currentValue.Count, $desiredValue.Count)
                $returnValue = $false
                continue
            }
            else
            {
                $desiredArrayValues = $desiredValue
                $currentArrayValues = $currentValue

                if ($SortArrayValues)
                {
                    $desiredArrayValues = @($desiredArrayValues | Sort-Object)
                    $currentArrayValues = @($currentArrayValues | Sort-Object)
                }

                for ($i = 0; $i -lt $desiredArrayValues.Count; $i++)
                {
                    if ($desiredArrayValues[$i])
                    {
                        $desiredType = $desiredArrayValues[$i].GetType()
                    }
                    else
                    {
                        $desiredType = @{
                            Name = 'Unknown'
                        }
                    }

                    if ($currentArrayValues[$i])
                    {
                        $currentType = $currentArrayValues[$i].GetType()
                    }
                    else
                    {
                        $currentType = @{
                            Name = 'Unknown'
                        }
                    }

                    if (-not $TurnOffTypeChecking)
                    {
                        if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
                            $desiredType.FullName -ne $currentType.FullName)
                        {
                            Write-Verbose -Message ($script:localizedData.NoMatchElementTypeMismatchMessage -f $key, $i, $currentType.FullName, $desiredType.FullName)
                            $returnValue = $false
                            continue
                        }
                    }

                    #Convert a scriptblock into a string as scriptblocks are not comparable
                    $wasCurrentArrayValuesConverted = $false
                    if ($currentArrayValues[$i] -is [scriptblock])
                    {
                        $currentArrayValues[$i] = if ($desiredArrayValues[$i] -is [string])
                        {
                            $currentArrayValues[$i] = $currentArrayValues[$i].Invoke()
                        }
                        else
                        {
                            $currentArrayValues[$i].ToString()
                        }
                        $wasCurrentArrayValuesConverted = $true
                    }
                    if ($desiredArrayValues[$i] -is [scriptblock])
                    {
                        $desiredArrayValues[$i] = if ($currentArrayValues[$i] -is [string] -and -not $wasCurrentArrayValuesConverted)
                        {
                            $desiredArrayValues[$i].Invoke()
                        }
                        else
                        {
                            $desiredArrayValues[$i].ToString()
                        }
                    }

                    if ($desiredType -eq [System.Collections.Hashtable] -and $currentType -eq [System.Collections.Hashtable])
                    {
                        $param = $PSBoundParameters
                        $param.CurrentValues = $currentArrayValues[$i]
                        $param.DesiredValues = $desiredArrayValues[$i]

                        if ($returnValue)
                        {
                            $returnValue = Test-DscParameterState @param
                        }
                        else
                        {
                            Test-DscParameterState @param | Out-Null
                        }
                        continue
                    }

                    if ($desiredArrayValues[$i] -ne $currentArrayValues[$i])
                    {
                        Write-Verbose -Message ($script:localizedData.NoMatchElementValueMismatchMessage -f $i, $desiredType.FullName, $key, $currentArrayValues[$i], $desiredArrayValues[$i])
                        $returnValue = $false
                        continue
                    }
                    else
                    {
                        Write-Verbose -Message ($script:localizedData.MatchElementValueMessage -f $i, $desiredType.FullName, $key, $currentArrayValues[$i], $desiredArrayValues[$i])
                        continue
                    }
                }

            }
        }
        elseif ($desiredType -eq [System.Collections.Hashtable] -and $currentType -eq [System.Collections.Hashtable])
        {
            $param = $PSBoundParameters
            $param.CurrentValues = $currentValue
            $param.DesiredValues = $desiredValue

            if ($returnValue)
            {
                $returnValue = Test-DscParameterState @param
            }
            else
            {
                Test-DscParameterState @param | Out-Null
            }
            continue
        }
        else
        {
            #Convert a scriptblock into a string as scriptblocks are not comparable
            $wasCurrentValue = $false
            if ($currentValue -is [scriptblock])
            {
                $currentValue = if ($desiredValue -is [string])
                {
                    $currentValue = $currentValue.Invoke()
                }
                else
                {
                    $currentValue.ToString()
                }
                $wasCurrentValue = $true
            }
            if ($desiredValue -is [scriptblock])
            {
                $desiredValue = if ($currentValue -is [string] -and -not $wasCurrentValue)
                {
                    $desiredValue.Invoke()
                }
                else
                {
                    $desiredValue.ToString()
                }
            }

            if ($desiredValue -ne $currentValue)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
                $returnValue = $false
            }
        }
    }

    if ($ReverseCheck)
    {
        Write-Verbose -Message $script:localizedData.StartingReverseCheck
        $reverseCheckParameters = $PSBoundParameters
        $reverseCheckParameters.CurrentValues = $DesiredValues
        $reverseCheckParameters.DesiredValues = $CurrentValues
        $null = $reverseCheckParameters.Remove('ReverseCheck')

        if ($returnValue)
        {
            $returnValue = Test-DscParameterState @reverseCheckParameters
        }
        else
        {
            $null = Test-DscParameterState @reverseCheckParameters
        }
    }

    Write-Verbose -Message ($script:localizedData.TestDscParameterResultMessage -f $returnValue)
    return $returnValue
}
