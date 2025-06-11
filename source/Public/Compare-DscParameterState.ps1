<#
    .SYNOPSIS
        This method is used to compare current and desired values for any DSC resource.

    .DESCRIPTION
        This function compare the parameter status of DSC resource parameters against
        the current values present on the system, and return a hashtable with the metadata
        from the comparison.

        >[!NOTE]
        >The content of the function `Test-DscParameterState` has been extracted and now
        >`Test-DscParameterState` is just calling `Compare-DscParameterState`.
        >This function can be used in a DSC resource from the _Get_ function/method.

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

    .PARAMETER IncludeInDesiredState
        Indicates that result adds the properties in the desired state.
        By default, this command returns only the properties not in desired state.

    .PARAMETER IncludeValue
        Indicates that result contains the ActualValue and ExpectedValue properties.

    .OUTPUTS
        System.Object[]

    .NOTES
        Returns an array containing a PSCustomObject with metadata for each property
        that was evaluated.

        Metadata Name | Type | Description
        --- | --- | ---
        Property | `[System.String]` | The name of the property that was evaluated
        InDesiredState | `[System.Boolean]` | Returns `$true` if the expected and actual value was equal.
        ExpectedType | `[System.String]` | Return the type of desired object.
        ActualType | `[System.String]` | Return the type of current object.
        ExpectedValue | `[System.PsObject]` | Return the value of expected object.
        ActualValue | `[System.PsObject]` | Return the value of current object.

    .EXAMPLE
        $currentValues = @{
            String = 'This is a string'
            Int = 1
            Bool = $true
        }
        $desiredValues = @{
            String = 'This is a string'
            Int = 99
        }
        Compare-DscParameterState -CurrentValues $currentValues -DesiredValues $desiredValues

        The function Compare-DscParameterState compare the value of each hashtable based
        on the keys present in $desiredValues hashtable. The result indicates that Int
        property is not in the desired state.
        No information about Bool property, because it is not in $desiredValues hashtable.

    .EXAMPLE
        $currentValues = @{
            String = 'This is a string'
            Int = 1
            Bool = $true
        }
        $desiredValues = @{
            String = 'This is a string'
            Int = 99
            Bool = $false
        }
        $excludeProperties = @('Bool')
        Compare-DscParameterState `
            -CurrentValues $currentValues `
            -DesiredValues $desiredValues `
            -ExcludeProperties $ExcludeProperties

        The function Compare-DscParameterState compare the value of each hashtable based
        on the keys present in $desiredValues hashtable and without those in $excludeProperties.
        The result indicates that Int property is not in the desired state.
        No information about Bool property, because it is in $excludeProperties.

    .EXAMPLE
        $serviceParameters = @{
            Name     = $Name
        }
        $returnValue = Compare-DscParameterState `
            -CurrentValues (Get-Service @serviceParameters) `
            -DesiredValues $PSBoundParameters `
            -Properties @(
                'Name'
                'Status'
                'StartType'
            )

        This compares the values in the current state against the desires state.
        The command Get-Service is called using just the required parameters
        to get the values in the current state. The parameter 'Properties'
        is used to specify the properties 'Name','Status' and
        'StartType' for the comparison.

    .EXAMPLE
        Compare-DscParameterState -CurrentValues @{
            IsSingleInstance = 'Yes'
            NameServer = [Microsoft.Management.Infrastructure.CimInstance[]]@()
        } -DesiredValues @{
            NameServers = [Microsoft.Management.Infrastructure.CimInstance[]] @(
                New-CimInstance -ClassName 'MSFT_KeyValuePair' -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -Property @{
                    Key   = 'B.ROOT-SERVERS.NET.'
                    Value = '199.9.14.201'
                } -ClientOnly
            )
            IsSingleInstance = 'Yes'
            Verbose = $true
        } -TurnOffTypeChecking -ReverseCheck

        This example calls Compare-DscParameterState with the current state and
        the desired state and returns a hashtable array of all the properties
        that was evaluated not in desired state based on the properties pass in
        the parameter DesiredValues.
#>
function Compare-DscParameterState
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
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
        $SortArrayValues,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IncludeInDesiredState,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $IncludeValue
    )

    $returnValue = @()
    #region ConvertCIm to Hashtable
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
    #endregion Endofconverion
    #region CheckType of object
    $types = 'System.Management.Automation.PSBoundParametersDictionary',
        'System.Collections.Hashtable',
        'Microsoft.Management.Infrastructure.CimInstance',
        'System.Collections.Specialized.OrderedDictionary'

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
    #endregion checktype
    #region check if CimInstance and not have properties in parameters invoke exception
    if ($DesiredValues -is [Microsoft.Management.Infrastructure.CimInstance] -and -not $Properties)
    {
        New-InvalidArgumentException `
            -Message $script:localizedData.InvalidPropertiesError `
            -ArgumentName Properties
    }
    #endregion check cim and properties
    #Clean value if there are a common parameters provide from Test/Get-TargetResource parameter
    $desiredValuesClean = Remove-CommonParameter -Hashtable $DesiredValues
    #region generate keyList based on $Properties and $excludeProperties value
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
    #endregion
    #region enumerate of each key in list
    foreach ($key in $keyList)
    {
        #generate default value
        $InDesiredStateTable = [ordered]@{
            Property        = $key
            InDesiredState  = $true
        }
        $returnValue += $InDesiredStateTable
        #get value of each key
        $desiredValue = $desiredValuesClean.$key
        $currentValue = $CurrentValues.$key

        #Check if IncludeValue parameter is used.
        if ($IncludeValue)
        {
            $InDesiredStateTable['ExpectedValue']   = $desiredValue
            $InDesiredStateTable['ActualValue']     = $currentValue
        }

        #region convert to hashtable if value of key is CimInstance
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
        #endregion converttohashtable
        #region gettype of value to check if they are the same.
        if ($null -ne $desiredValue)
        {
            $desiredType = $desiredValue.GetType()
        }
        else
        {
            $desiredType = @{
                Name = 'Unknown'
            }
        }

        $InDesiredStateTable['ExpectedType'] = $desiredType

        if ($null -ne $currentValue)
        {
            $currentType = $currentValue.GetType()
        }
        else
        {
            $currentType = @{
                Name = 'Unknown'
            }
        }

        $InDesiredStateTable['ActualType'] = $currentType

        #endregion
        #region check if the desiredtype if a credential object. Only if the current type isn't unknown.
        if ($currentType.Name -ne 'Unknown' -and $desiredType.Name -eq 'PSCredential')
        {
            # This is a credential object. Compare only the user name
            if ($currentType.Name -eq 'PSCredential' -and $currentValue.UserName -eq $desiredValue.UserName)
            {
                Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
                continue # pass to the next key
            }
            elseif ($currentType.Name -ne 'string')
            {
                Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
                $InDesiredStateTable.InDesiredState = $false
            }

            # Assume the string is our username when the matching desired value is actually a credential
            if ($currentType.Name -eq 'string' -and $currentValue -eq $desiredValue.UserName)
            {
                Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
                continue # pass to the next key
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
                $InDesiredStateTable.InDesiredState = $false
            }
        }
        #endregion test credential
        #region Test type of object. And if they're not InDesiredState, generate en exception
        if (-not $TurnOffTypeChecking)
        {
            if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
                $desiredType.FullName -ne $currentType.FullName)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchTypeMismatchMessage -f $key, $currentType.FullName, $desiredType.FullName)
                $InDesiredStateTable.InDesiredState = $false
                continue # pass to the next key
            }
            elseif ($desiredType.Name -eq 'Unknown' -and $desiredType.Name -ne $currentType.Name)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchTypeMismatchMessage -f $key, $currentType.Name, $desiredType.Name)
                $InDesiredStateTable.InDesiredState = $false
                continue # pass to the next key
            }
        }
        #endregion TestType
        #region Check if the value of Current and desired state is the same but only if they are not an array
        if ($currentValue -eq $desiredValue -and -not $desiredType.IsArray)
        {
            Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
            continue # pass to the next key
        }
        #endregion check same value
        #region Check if the DesiredValuesClean has the key and if it doesn't have, it's not necessary to check his value
        if ($desiredValuesClean.GetType().Name -in 'HashTable', 'PSBoundParametersDictionary', 'OrderedDictionary')
        {
            $checkDesiredValue = $desiredValuesClean.ContainsKey($key)
        }
        else
        {
            $checkDesiredValue = Test-DscObjectHasProperty -Object $desiredValuesClean -PropertyName $key
        }
        # if there no key, don't need to check
        if (-not $checkDesiredValue)
        {
            Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
            continue # pass to the next key
        }
        #endregion
        #region Check if desired type is array, if no Hashtable and current type hashtable to
        if ($desiredType.IsArray -or $desiredType.ImplementedInterfaces -contains [System.Collections.IList])
        {
            Write-Verbose -Message ($script:localizedData.TestDscParameterCompareMessage -f $key, $desiredType.FullName)
            # Check if the currentValues and desiredValue are empty array.
            if (-not $currentValue -and -not $desiredValue)
            {
                Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, 'empty array', 'empty array')
                continue
            }
            elseif (-not $currentValue)
            {
                #If only currentvalue is empty, the configuration isn't compliant.
                Write-Verbose -Message ($script:localizedData.NoMatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
                $InDesiredStateTable.InDesiredState = $false
                continue
            }
            elseif ($currentValue.Count -ne $desiredValue.Count)
            {
                #If there is a difference between the number of objects in arrays, this isn't compliant.
                Write-Verbose -Message ($script:localizedData.NoMatchValueDifferentCountMessage -f $desiredType.FullName, $key, $currentValue.Count, $desiredValue.Count)
                $InDesiredStateTable.InDesiredState = $false
                continue
            }
            else
            {
                $desiredArrayValues = $desiredValue
                $currentArrayValues = $currentValue
                # if the sortArrayValues parameter is using, sort value of array
                if ($SortArrayValues)
                {
                    $desiredArrayValues = @($desiredArrayValues | Sort-Object)
                    $currentArrayValues = @($currentArrayValues | Sort-Object)
                }
                <#
                    for all object in collection, check their type.ConvertoString if they are script block.

                #>
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
                            $InDesiredStateTable.InDesiredState = $false
                            continue
                        }
                    }

                    <#
                        Convert a scriptblock into a string as scriptblocks are not comparable
                        if currentvalue is scriptblock and if desired value is string,
                        we invoke the result of script block. Ifno, we convert to string.
                        if Desired value
                    #>

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

                    if (($desiredType -eq [System.Collections.Hashtable] -or $desiredType -eq [System.Collections.Specialized.OrderedDictionary]) -and ($currentType -eq [System.Collections.Hashtable]-or $currentType -eq [System.Collections.Specialized.OrderedDictionary]))
                    {
                        $param = @{} + $PSBoundParameters
                        $param.CurrentValues = $currentArrayValues[$i]
                        $param.DesiredValues = $desiredArrayValues[$i]

                        'IncludeInDesiredState','IncludeValue','Properties','ReverseCheck' | ForEach-Object {
                            if ($param.ContainsKey($_))
                            {
                                $null = $param.Remove($_)
                            }
                        }

                        if ($InDesiredStateTable.InDesiredState)
                        {
                            $InDesiredStateTable.InDesiredState = Test-DscParameterState @param
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
                        $InDesiredStateTable.InDesiredState = $false
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
        elseif (($desiredType -eq [System.Collections.Hashtable] -or $desiredType -eq [System.Collections.Specialized.OrderedDictionary]) -and ($currentType -eq [System.Collections.Hashtable]-or $currentType -eq [System.Collections.Specialized.OrderedDictionary]))
        {
            $param = @{} + $PSBoundParameters
            $param.CurrentValues = $currentValue
            $param.DesiredValues = $desiredValue

            'IncludeInDesiredState','IncludeValue','Properties','ReverseCheck' | ForEach-Object {
                if ($param.ContainsKey($_))
                {
                    $null = $param.Remove($_)
                }
            }

            if ($InDesiredStateTable.InDesiredState)
            {
                <#
                    if desiredvalue is an empty hashtable and not currentvalue, it's not necessery to compare them, it's not compliant.
                    See issue 65 https://github.com/dsccommunity/DscResource.Common/issues/65
                #>
                if ($desiredValue.Keys.Count -eq 0 -and $currentValue.Keys.Count -ne 0)
                {
                    Write-Verbose -Message ($script:localizedData.NoMatchKeyMessage -f $desiredType.FullName, $key, $($currentValue.Keys -join ', '))
                    $InDesiredStateTable.InDesiredState = $false
                }
                else{
                    $InDesiredStateTable.InDesiredState = Test-DscParameterState @param
                }
            }
            else
            {
                $null = Test-DscParameterState @param
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
                $InDesiredStateTable.InDesiredState = $false
            }
        }
        #endregion check type
    }
    #endregion end of enumeration
    if ($ReverseCheck)
    {
        Write-Verbose -Message $script:localizedData.StartingReverseCheck
        $reverseCheckParameters = @{} + $PSBoundParameters
        $reverseCheckParameters['CurrentValues'] = $DesiredValues
        $reverseCheckParameters['DesiredValues'] = $CurrentValues
        $reverseCheckParameters['Properties'] = $keyList + $CurrentValues.Keys | Select-Object -Unique
        if ($ExcludeProperties)
        {
            $reverseCheckParameters['Properties'] = $reverseCheckParameters['Properties'] | Where-Object -FilterScript { $_ -notin $ExcludeProperties }
        }

        $null = $reverseCheckParameters.Remove('ReverseCheck')

        if ($returnValue)
        {
            $returnValue = Compare-DscParameterState @reverseCheckParameters
        }
        else
        {
            $null = Compare-DscParameterState @reverseCheckParameters
        }
    }

    # Remove in desired state value if IncludeDesirateState parameter is not use
    if (-not $IncludeInDesiredState)
    {
        [array]$returnValue = $returnValue.where({$_.InDesiredState -eq $false})
    }

    #change verbose message
    if ($IncludeInDesiredState.IsPresent)
    {
        $returnValue.ForEach({
            if ($_.InDesiredState)
            {
                $localizedString = $script:localizedData.PropertyInDesiredStateMessage
            }
            else
            {
                $localizedString = $script:localizedData.PropertyNotInDesiredStateMessage
            }

            Write-Verbose -Message ($localizedString -f $_.Property)
        })
    }
    <#
        If Compare-DscParameterState is used in precedent step, don't need to convert it
        We use .foreach() method as we are sure that $returnValue is an array.
    #>
    [Array]$returnValue = @(
        $returnValue.foreach(
            {
                if ($_ -is [System.Collections.Hashtable])
                {
                    [pscustomobject]$_
                }
                else
                {
                    $_
                }
            }
        )
    )

    return $returnValue
}
