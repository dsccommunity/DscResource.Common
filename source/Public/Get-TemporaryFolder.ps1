<#
    .SYNOPSIS
        Returns the path of the current user's temporary folder.

    .DESCRIPTION
        Returns the path of the current user's temporary folder.

    .OUTPUTS
        System.String

    .NOTES
        This is the same as doing the following
        - Windows: $env:TEMP
        - macOS: $env:TMPDIR
        - Linux: /tmp/

        Examples of what the command returns:

        - Windows: C:\Users\username\AppData\Local\Temp\
        - macOS: /var/folders/6x/thq2xce46bc84lr66fih2p5h0000gn/T/
        - Linux: /tmp/

    .EXAMPLE
        Get-TemporaryFolder

        Returns the current user temporary folder on the current operating system.
#>
function Get-TemporaryFolder
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    return [IO.Path]::GetTempPath()
}
