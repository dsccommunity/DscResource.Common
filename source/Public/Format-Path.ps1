<#
    .SYNOPSIS
        Normalizes a file system path.

    .DESCRIPTION
        Normalizes a file system path to ensure proper formatting based on specified
        preferences. The function can add a backslash to drive letter paths and
        remove trailing backslashes from directory paths based on the parameters
        provided. It will recognize Windows drive paths and UNC paths and make sure
        they are formatted with backslashes, regardless of the operating system.
        Relative paths or absolute paths (that start with slash or backslash) will
        always be converted to use the system's directory separator.

        When no formatting parameters are specified, the function only normalizes
        directory separators (using backslashes for Windows paths and the system's
        directory separator for other paths) while preserving any trailing separators.

    .PARAMETER Path
        The file system path to normalize.

    .PARAMETER EnsureDriveLetterRoot
        When specified, adds a trailing backslash to paths that consist of only a
        drive letter (e.g., 'C:' becomes 'C:\'). This parameter takes precedence
        over NoTrailingDirectorySeparator for drive letter paths.

    .PARAMETER NoTrailingDirectorySeparator
        When specified, removes any trailing directory separator (backslash) from
        paths, including drive letters.

    .EXAMPLE
        Format-Path -Path 'C:/MyFolder/'

        Returns 'C:\MyFolder\'. Only normalizes directory separators when no formatting
        parameters are specified.

    .EXAMPLE
        Format-Path -Path 'C:' -EnsureDriveLetterRoot

        Returns 'C:\'

    .EXAMPLE
        Format-Path -Path 'C:\MyFolder\' -NoTrailingDirectorySeparator

        Returns 'C:\MyFolder'

    .EXAMPLE
        Format-Path -Path 'C:\MyFolder\' -EnsureDriveLetterRoot -NoTrailingDirectorySeparator

        Returns 'C:\MyFolder'

    .EXAMPLE
        Format-Path -Path 'C:' -EnsureDriveLetterRoot -NoTrailingDirectorySeparator

        Returns 'C:\'. The EnsureDriveLetterRoot parameter takes precedence over
        NoTrailingDirectorySeparator for drive letter paths.

    .EXAMPLE
        Format-Path -Path 'MyFolder/SubFolder\'

        Returns 'MyFolder\SubFolder\' on Windows or 'MyFolder/SubFolder/' on Linux/macOS.
        Relative paths are normalized to use the system's directory separator.

    .EXAMPLE
        Format-Path -Path '/var/log/' -NoTrailingDirectorySeparator

        Returns '/var/log' on Linux/macOS or '\var\log' on Windows.
        Unix-style absolute paths are normalized to use the system's directory separator.
#>
function Format-Path
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $EnsureDriveLetterRoot,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoTrailingDirectorySeparator
    )

    if ($Path -match '^(?:[a-zA-Z]:|\\\\)')
    {
        # Path starts with a Windows drive letter, normalize to backslashes.
        $normalizedPath = $Path -replace '/', '\'
    }
    else
    {
        $normalizedPath = $Path -replace '[\\|/]', [System.IO.Path]::DirectorySeparatorChar
    }

    # Remove trailing backslash if parameter is specified and path is not just a drive root.
    if ($NoTrailingDirectorySeparator)
    {
        $normalizedPath = $normalizedPath.TrimEnd('\/')
    }

    # Check if path is just a drive letter (e.g. 'C:').
    if ($EnsureDriveLetterRoot)
    {
        if ($normalizedPath -match '^[a-zA-Z]:$')
        {
            # Add a backslash to the drive letter path.
            $normalizedPath = $normalizedPath + '\'
        }
        elseif ($normalizedPath -match '^[a-zA-Z]:(?![\\]).')
        {
            # Insert missing backslash after drive letter if needed (e.g., 'C:temp' -> 'C:\temp').
            $normalizedPath = $normalizedPath -replace '^([a-zA-Z]:)', '$1\'
        }
    }

    Write-Debug -Message ($script:localizedData.Format_Path_NormalizedPath -f $Path, $normalizedPath)

    return $normalizedPath
}
