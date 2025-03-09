<#
    .SYNOPSIS
        Returns the value of the property specified in the Name parameter.

    .DESCRIPTION
        Returns the value of the property specified in the Name parameter at the
        location provided in the Path parameter.

    .PARAMETER Path
        Specifies the path where to look for the specified property name.

    .PARAMETER Name
        Specifies the name of the property to return the value for.

    .NOTES
        This function is similar to Get-ItemPropertyValue, but this command will
        honor the `-ErrorAction` parameter which Get-ItemPropertyValue does not.
        This command will return `$null` if the specified property name does not exist.
#>
function Get-RegistryPropertyValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $getItemPropertyValueResult = $null

    Write-Verbose -Message $PSBoundParameters.ContainsKey('ErrorAction') -Verbose
    Write-Verbose -Message $ErrorActionPreference -Verbose

    $getItemPropertyResult = Get-ItemProperty @PSBoundParameters -ErrorAction 'SilentlyContinue'

    if ($null -ne $getItemPropertyResult)
    {
        $getItemPropertyValueResult = $getItemPropertyResult.$Name
    }

    return $getItemPropertyValueResult
}
