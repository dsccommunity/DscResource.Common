<#
    .SYNOPSIS
        Tests whether the class-based resource has the specified property.

    .DESCRIPTION
        Tests whether the class-based resource has the specified property, and
        can optionally tests if the property has a certain attribute or whether
        it is assigned a non-null value.

    .PARAMETER InputObject
        Specifies the object that should be tested for existens of the specified
        property.

    .PARAMETER Name
        Specifies the name of the property.

    .PARAMETER HasValue
        Specifies if the property should be evaluated to have a non-value. If
        the property exist but is assigned `$null` the command returns `$false`.

    .PARAMETER Attribute
        Specifies if the property should be evaluated to have a specific attribute.
        If the property exist but is not the specific attribute the command returns
        `$false`.

    .OUTPUTS
        [System.Boolean]

    .EXAMPLE
        Test-DscProperty -InputObject $this -Name 'MyDscProperty'

        Returns `$true` or `$false` whether the property exist or not.

    .EXAMPLE
        $this | Test-DscProperty -Name 'MyDscProperty'

        Returns `$true` or `$false` whether the property exist or not.

    .EXAMPLE
        Test-DscProperty -InputObject $this -Name 'MyDscProperty' -HasValue

        Returns `$true` if the property exist and is assigned a non-null value,
        if not `$false` is returned.

    .EXAMPLE
        Test-DscProperty -InputObject $this -Name 'MyDscProperty' -Attribute 'Optional'

        Returns `$true` if the property exist and is an optional property.

    .EXAMPLE
        Test-DscProperty -InputObject $this -Name 'MyDscProperty' -Attribute 'Optional' -HasValue

        Returns `$true` if the property exist, is an optional property, and is
        assigned a non-null value.

    .OUTPUTS
        [System.Boolean]

    .NOTES
        This command only works with nullable data types, if using a non-nullable
        type make sure to make it nullable, e.g. [Nullable[System.Int32]].
#>
function Test-DscProperty
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $HasValue,

        [Parameter()]
        [ValidateSet('Key', 'Mandatory', 'NotConfigurable', 'Optional')]
        [System.String[]]
        $Attribute
    )

    begin
    {
        $hasProperty = $false
    }

    process
    {
        $isDscProperty = (Get-DscProperty @PSBoundParameters).ContainsKey($Name)

        if ($isDscProperty)
        {
            $hasProperty = $true
        }
    }

    end
    {
        return $hasProperty
    }
}
