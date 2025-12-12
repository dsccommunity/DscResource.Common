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

    .OUTPUTS
        `[System.Version]`

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

        $productVersionString = $fileVersionInfo.ProductVersion

        # Try to parse the product version string as a System.Version
        $parsedVersion = $null

        if (-not [System.Version]::TryParse($productVersionString, [ref] $parsedVersion))
        {
            $errorMessage = $script:localizedData.Get_FileProductVersion_InvalidVersionFormat -f $productVersionString, $Path

            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    $errorMessage,
                    'GFPV0002', # cSpell: disable-line
                    [System.Management.Automation.ErrorCategory]::InvalidData,
                    $Path
                )
            )
        }

        return $parsedVersion
    }
    catch
    {
        $errorMessage = $script:localizedData.Get_FileProductVersion_GetFileProductVersionError -f $Path, $_.Exception.Message

        Write-Error -Message $errorMessage -ErrorId 'GFPV0001' -Category 'ReadError' -TargetObject $Path -Exception $_.Exception

        return
    }
}
