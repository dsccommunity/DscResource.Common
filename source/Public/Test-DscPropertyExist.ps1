<#
    .SYNOPSIS
        Tests whether the class-based resource has the specified property.

    .DESCRIPTION
        Tests whether the class-based resource has the specified property.

    .PARAMETER InputObject
        Specifies the object that should be tested for existens of the specified
        property.

    .PARAMETER Name
        Specifies the name of the property.

    .PARAMETER HasValue
        Specifies if the property should be evaluated to have a non-value. If
        the property exist but is assigned `$null` the command returns `$false`.

    .EXAMPLE
        Test-DscPropertyExist -InputObject $this -Name 'MyDscProperty'

        Returns $true or $false whether the property exist or not.

    .EXAMPLE
        Test-DscPropertyExist -InputObject $this -Name 'MyDscProperty' -HasValue

        Returns $true if the property exist and is assigned a non-null value, if not
        $false is returned.

    .OUTPUTS
        [System.Boolean]

    .NOTES
        This command only works with nullable data types, if using a non-nullable
        type make sure to make it nullable, e.g. [Nullable[System.Int32]].
#>
function Test-DscPropertyExist
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
        $HasValue
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
