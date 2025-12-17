<#
    .SYNOPSIS
        Gets the product version of a file.

    .DESCRIPTION
        Gets the product version of a file and returns it as a System.Version object.
        This can be useful for checking the version of installed components or binaries.

    .PARAMETER Path
        The path to the file to get the product version from.

    .EXAMPLE
        Get-FileProductVersion -Path 'C:\Temp\setup.exe'

        Returns the product version of the file setup.exe as a System.Version object.

    .INPUTS
        None.

    .OUTPUTS
        `System.Version`

        Returns the product version as a System.Version object.
#>
function Get-FileProductVersion
{
    [CmdletBinding()]
    [OutputType([System.Version])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    try
    {
        $fileVersionInfo = Get-FileVersion -Path $Path -ErrorAction 'Stop'
    }
    catch
    {
        $errorMessage = $script:localizedData.Get_FileProductVersion_GetFileProductVersionError -f $Path, $_.Exception.Message
        $exception = New-Exception -Message $errorMessage -ErrorRecord $_

        $PSCmdlet.ThrowTerminatingError(
            (New-ErrorRecord -Exception $exception -ErrorId 'GFPV0001' -ErrorCategory ([System.Management.Automation.ErrorCategory]::ReadError) -TargetObject $Path) # cSpell: disable-line
        )
    }

    $productVersionString = $fileVersionInfo.ProductVersion

    $parsedVersion = $null
    if (-not [System.Version]::TryParse($productVersionString, [ref] $parsedVersion))
    {
        $errorMessage = $script:localizedData.Get_FileProductVersion_InvalidVersionFormat -f $productVersionString, $Path
        $exception = New-Exception -Message $errorMessage

        $PSCmdlet.ThrowTerminatingError(
            (New-ErrorRecord -Exception $exception -ErrorId 'GFPV0002' -ErrorCategory ([System.Management.Automation.ErrorCategory]::InvalidData) -TargetObject $Path) # cSpell: disable-line
        )
    }

    return $parsedVersion
}
