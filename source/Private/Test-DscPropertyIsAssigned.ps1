<#
    .SYNOPSIS
        Tests whether the class-based resource property is assigned a non-null value.

    .DESCRIPTION
        Tests whether the class-based resource property is assigned a non-null value.

    .PARAMETER InputObject
        Specifies the object that contain the property.

    .PARAMETER Name
        Specifies the name of the property.

    .EXAMPLE
        Test-DscPropertyIsAssigned -InputObject $this -Name 'MyDscProperty'

        Returns $true or $false whether the property is assigned or not.

    .OUTPUTS
        [System.Boolean]

    .NOTES
        This command only works with nullable data types, if using a non-nullable
        type make sure to make it nullable, e.g. [nullable[System.Int32]].
#>
function Test-DscPropertyIsAssigned
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
        $Name
    )

    begin
    {
        $isAssigned = $false
    }

    process
    {
        $isAssigned = -not ($null -eq $InputObject.$Name)
    }

    end
    {
        return $isAssigned
    }
}
