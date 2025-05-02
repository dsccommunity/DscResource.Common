<#
    .SYNOPSIS
        Returns DSC resource properties that is part of a class-based DSC resource.

    .DESCRIPTION
        Returns DSC resource properties that is part of a class-based DSC resource.
        The properties can be filtered using name, attribute, or if it has been
        assigned a non-null value.

    .PARAMETER InputObject
        The object that contain one or more key properties.

    .PARAMETER Name
        Specifies one or more property names to return. If left out all properties
        are returned.

    .PARAMETER ExcludeName
        Specifies one or more property names to exclude.

    .PARAMETER Attribute
        Specifies one or more property attributes to return. If left out all property
        types are returned.

    .PARAMETER HasValue
        Specifies to return only properties that has been assigned a non-null value.
        If left out all properties are returned regardless if there is a value
        assigned or not.

    .PARAMETER IgnoreZeroEnumValue
        Specifies to return only Enum properties that has been assigned a non zero value.

    .OUTPUTS
        System.Collections.Hashtable

    .EXAMPLE
        Get-DscProperty -InputObject $this

        Returns all DSC resource properties of the DSC resource.

    .EXAMPLE
        $this | Get-DscProperty

        Returns all DSC resource properties of the DSC resource.

    .EXAMPLE
        Get-DscProperty -InputObject $this -Name @('MyProperty1', 'MyProperty2')

        Returns the DSC resource properties with the specified names.

    .EXAMPLE
        Get-DscProperty -InputObject $this -Attribute @('Mandatory', 'Optional')

        Returns the DSC resource properties that has the specified attributes.

    .EXAMPLE
        Get-DscProperty -InputObject $this -Attribute @('Optional') -HasValue

        Returns the DSC resource properties that has the specified attributes and
        has a non-null value assigned.

    .EXAMPLE
        Get-DscProperty -InputObject $this -Attribute @('Optional') -HasValue -IgnoreZeroEnumValue

        Returns the DSC resource properties that has the specified attributes and
        has a non-null value assigned, and any Enum properties that has a non-zero value.

    .OUTPUTS
        [System.Collections.Hashtable]

    .NOTES
        This command only works with nullable data types, if using a non-nullable
        type make sure to make it nullable, e.g. [Nullable[System.Int32]].
#>
function Get-DscProperty
{
    [CmdletBinding(DefaultParameterSetName = 'BaseSet')]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'BaseSet')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'IgnoreZeroEnumValue')]
        [PSObject]
        $InputObject,

        [Parameter(ParameterSetName = 'BaseSet')]
        [Parameter(ParameterSetName = 'IgnoreZeroEnumValue')]
        [System.String[]]
        $Name,

        [Parameter(ParameterSetName = 'BaseSet')]
        [Parameter(ParameterSetName = 'IgnoreZeroEnumValue')]
        [System.String[]]
        $ExcludeName,

        [Parameter(ParameterSetName = 'BaseSet')]
        [Parameter(ParameterSetName = 'IgnoreZeroEnumValue')]
        [ValidateSet('Key', 'Mandatory', 'NotConfigurable', 'Optional')]
        [Alias('Type')]
        [System.String[]]
        $Attribute,

        [Parameter(ParameterSetName = 'BaseSet')]
        [Parameter(ParameterSetName = 'IgnoreZeroEnumValue', Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $HasValue,

        [Parameter(ParameterSetName = 'IgnoreZeroEnumValue')]
        [System.Management.Automation.SwitchParameter]
        $IgnoreZeroEnumValue
    )

    process
    {
        $property = $InputObject.PSObject.Properties.Name |
            Where-Object -FilterScript {
                <#
                    Return all properties if $Name is not assigned, or if assigned
                    just those properties.
                #>
                (-not $Name -or $_ -in $Name) -and

                <#
                    Return all properties if $ExcludeName is not assigned. Skip
                    property if it is included in $ExcludeName.
                #>
                (-not $ExcludeName -or ($_ -notin $ExcludeName)) -and

                # Only return the property if it is a DSC property.
                $InputObject.GetType().GetMember($_).CustomAttributes.Where(
                    {
                        $_.AttributeType.Name -eq 'DscPropertyAttribute'
                    }
                )
            }

        if (-not [System.String]::IsNullOrEmpty($property))
        {
            if ($PSBoundParameters.ContainsKey('Attribute'))
            {
                $propertiesOfAttribute = @()

                $propertiesOfAttribute += $property | Where-Object -FilterScript {
                    $InputObject.GetType().GetMember($_).CustomAttributes.Where(
                        {
                            <#
                                To simplify the code, ignoring that this will compare
                                MemberNAme against type 'Optional' which does not exist.
                            #>
                            $_.NamedArguments.MemberName -in $Attribute
                        }
                    ).NamedArguments.TypedValue.Value -eq $true
                }

                # Include all optional parameter if it was requested.
                if ($Attribute -contains 'Optional')
                {
                    $propertiesOfAttribute += $property | Where-Object -FilterScript {
                        $InputObject.GetType().GetMember($_).CustomAttributes.Where(
                            {
                                $_.NamedArguments.MemberName -notin @('Key', 'Mandatory', 'NotConfigurable')
                            }
                        )
                    }
                }

                $property = $propertiesOfAttribute
            }
        }

        # Return a hashtable containing each key property and its value.
        $getPropertyResult = @{}

        foreach ($currentProperty in $property)
        {
            if ($HasValue.IsPresent)
            {
                $isAssigned = Test-DscPropertyIsAssigned -Name $currentProperty -InputObject $InputObject

                if (-not $isAssigned)
                {
                    continue
                }
            }

            $getPropertyResult.$currentProperty = $InputObject.$currentProperty
        }

        if ($IgnoreZeroEnumValue.IsPresent)
        {
            $getPropertyResult = $getPropertyResult | Clear-ZeroedEnumPropertyValue
        }

        return $getPropertyResult
    }
}
