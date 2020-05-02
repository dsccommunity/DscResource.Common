<#
    .SYNOPSIS
        Tests if an object has a property.

    .DESCRIPTION
        Tests if the specified object has the specified property and return
        $true or $false.

    .PARAMETER Object
        Specifies the object to test for the specified property.

    .PARAMETER PropertyName
        Specifies the property name to test for.

    .EXAMPLE
        Test-DscObjectHasProperty -Object 'AnyString' -PropertyName 'Length'
#>
function Test-DscObjectHasProperty
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Object,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PropertyName
    )

    if ($Object.PSObject.Properties.Name -contains $PropertyName)
    {
        return [System.Boolean] $Object.$PropertyName
    }

    return $false
}
