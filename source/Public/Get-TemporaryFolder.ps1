<#
    .SYNOPSIS
        Returns the path of the current user's temporary folder.

    .NOTES
        This is the same as doing the following
        - Windows: $env:TEMP
        - macOS: $env:TMPDIR
        - Linux: /tmp/
#>
function Get-TemporaryFolder
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    return [IO.Path]::GetTempPath().TrimEnd('\/')
}
