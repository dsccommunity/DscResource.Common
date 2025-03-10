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

    .EXAMPLE
        Get-RegistryPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS' -Name 'RS'

        Returns the value of the property RS at the specified path.

    .EXAMPLE
        Get-RegistryPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS' -Name 'RS' -ErrorAction 'Stop'

        Returns the value of the property RS at the specified path, and throws an
        exception if either that path or the name does not exist.

    .EXAMPLE
        Get-RegistryPropertyValue -Path 'HKCU:\SOFTWARE\Microsoft\Wisp\Touch' -Name 'Friction' -ErrorAction 'SilentlyContinue'

        Returns the value of the property Friction at the specified path, and
        suppresses any errors that may occur if the path or the name does not exist.

    .NOTES
        This function is similar to Get-ItemPropertyValue, but this command will
        honor the `-ErrorAction` parameter which Get-ItemPropertyValue does not.
        This command will by default not throw an exception and instead return
        `$null` if the specified property name does not exist.
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

    $getRegistryPropertyValueResult = $null

    if (-not $PSBoundParameters.ContainsKey('ErrorAction'))
    {
        $ErrorActionPreference = 'SilentlyContinue'
    }

    $getItemPropertyResult = Get-ItemProperty -Path $Path -Name $Name -ErrorAction:$ErrorActionPreference

    if ($null -ne $getItemPropertyResult)
    {
        # If the property name is not found, Get-ItemProperty will return $null.
        $getRegistryPropertyValueResult = $getItemPropertyResult.$Name
    }

    return $getRegistryPropertyValueResult
}
