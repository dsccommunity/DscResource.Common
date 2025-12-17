<#
    .SYNOPSIS
        Returns the version information for a file.

    .DESCRIPTION
        Returns the version information for a file including the product version,
        file version, and other version-related metadata.

    .PARAMETER Path
        Specifies the file for which to return the version information.

    .EXAMPLE
        Get-FileVersion -Path 'E:\setup.exe'

        Returns the version information for the file setup.exe.

    .EXAMPLE
        Get-Item -Path 'E:\setup.exe' | Get-FileVersion

        Returns the version information for the file setup.exe using pipeline input.

    .EXAMPLE
        'E:\setup.exe' | Get-FileVersion

        Returns the version information for the file setup.exe using pipeline input.

    .INPUTS
        System.IO.FileInfo

        Accepts a file path via the pipeline.

    .INPUTS
        System.String

        Accepts a string path via the pipeline.

    .OUTPUTS
        System.Diagnostics.FileVersionInfo

        Returns the file version information.
#>
function Get-FileVersion
{
    [OutputType([System.Diagnostics.FileVersionInfo])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [System.IO.FileInfo]
        $Path
    )

    process
    {
        $file = Get-Item -Path $Path -ErrorAction 'Stop'

        if ($file.PSIsContainer)
        {
            $PSCmdlet.ThrowTerminatingError(
                (New-ErrorRecord -Exception ($script:localizedData.Get_FileVersion_PathIsNotFile -f $file.FullName) -ErrorId 'GFV0001' -ErrorCategory ([System.Management.Automation.ErrorCategory]::InvalidArgument) -TargetObject $file.FullName) # cSpell: disable-line
            )
        }

        $file.VersionInfo
    }
}
