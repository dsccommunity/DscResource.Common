<#
    .SYNOPSIS
        Gets language-specific data when the culture is invariant.
        This directly gets the data from the DefaultUICulture, but without calling
        "Import-LocalizedData" which throws when the pwsh session is configured to be
        of invariant culture (as in the Guest Config agent).

    .DESCRIPTION
        The Get-LocalizedDataForInvariantCulture grabs the data from a localized string data psd1 file,
        without calling Import-LocalizedData which errors when called in a powershell session with the
        Globalization-Invariant mode enabled
        (https://docs.microsoft.com/en-us/dotnet/core/compatibility/globalization/6.0/culture-creation-invariant-mode).

        Instead, this function reads and executes the content of a psd1 file in a
        constrained language mode that only allows basic ConvertFrom-stringData.

    .PARAMETER BaseDirectory
        Specifies the base directory where the .psd1 files are located. The default is
        the directory where the script is located. Import-LocalizedData searches for
        the .psd1 file for the script in a language-specific subdirectory of the base
        directory.

    .PARAMETER FileName
        Specifies the base name of the data file (.psd1) to be imported. Enter a file name.
        You can specify a file name that does not include its .psd1 file name extension,
        or you can specify the file name including the .psd1 file name extension.

        The FileName parameter is required when Get-LocalizedDataForInvariantCulture is not used in a
        script. Otherwise, the parameter is optional and the default value is the base
        name of the calling script. You can use this parameter to directly search for a
        specific .psd1 file.

        For example, if the FileName is omitted and the script name is FindFiles.ps1,
        Get-LocalizedDataForInvariantCulture searches for the FindFiles.psd1 or
        FindFiles.strings.psd1 data file.

    .PARAMETER SupportedCommand
        Specifies cmdlets and functions that generate only data.

        Use this parameter to include cmdlets and functions that you have written or
        tested. For more information, see about_Script_Internationalization.

    .PARAMETER DefaultUICulture
        Specifies which UICulture to default to if current UI culture or its parents
        culture don't have matching data file.

        For example, if you have a data file in 'en-US' but not in 'en' or 'en-GB' and
        your current culture is 'en-GB', you can default back to 'en-US'.

    .NOTES
        The Get-LocalizedDataForInvariantCulture should only be used when we want to avoid
        using Import-LocalizedData, such as when doing so will fail because the powershell session
        is in Globalization-Invariant mode:
        https://docs.microsoft.com/en-us/dotnet/core/compatibility/globalization/6.0/culture-creation-invariant-mode

        Before using Get-LocalizedDataForInvariantCulture, localize your user messages to the desired
        default locale (UI culture, usually en-US) in a hash table of key/value pairs, and save the
        hash table in a file with the same name as the script or module with a .psd1 file name extension.
        Create a directory under the module base or script's parent directory for each supported UI culture,
        and then save the .psd1 file for each UI culture in the directory with the UI culture name.

        For example, localize your user messages for the de-DE locale and format them in
        a hash table. Save the hash table in a <ScriptName>.psd1 file. Then create a de-DE
        subdirectory under the script directory, and save the de-DE <ScriptName>.psd1
        file in the de-DE subdirectory. Repeat this method for each locale that you support.

        Import-LocalizedData performs a structured search for the localized user
        messages for a script.

        Get-LocalizedDataForInvariantCulture only search in the BaseDirectory specified.
        It then searches within the base directory for a subdirectory with the same name
        as the value of the $DefaultUICulture variable (specified or default to en-US),
        such as de-DE or ar-SA.
        Then, it searches in that subdirectory for a .psd1 file with the same name
        as provided FileName such as FileName.psd1 or FileName.strings.psd1.

    .EXAMPLE
        Get-LocalizedDataForInvariantCulture -BaseDirectory .\source\ -FileName DscResource.Common -DefaultUICulture en-US

        This is an example, usually it is only used by Get-LocalizedData in DSC resources to import the
        localized strings when the Culture is Invariant (id 127).
#>
function Get-LocalizedDataForInvariantCulture
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BaseDirectory,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $FileName,

        [Parameter()]
        [System.String]
        [ValidateNotNull()]
        $DefaultUICulture = 'en-US'
    )

    begin
    {
        if ($FileName -match '\.psm1$|\.ps1$|\.psd1$')
        {
            Write-Debug -Message 'Found an extension to the file name to search. Stripping...'
            $FileName = $FileName -replace '\.psm1$|\.ps1$|\.psd1$'
        }

        [string] $languageFile = ''
        $localizedFolder = Join-Path -Path $BaseDirectory -ChildPath $DefaultUICulture
        [string[]] $localizedFileNamesToTry = @(
            ('{0}.psd1' -f $FileName)
            ('{0}.strings.psd1' -f $FileName)
        )

        foreach ($localizedFileName in $localizedFileNamesToTry)
        {
            $filePath = [System.IO.Path]::Combine($localizedFolder, $localizedFileName)
            if (Test-Path -Path $filePath)
            {
                Write-Debug -Message "Found '$filePath'."
                $languageFile = $filePath
                # Exit loop as we found the first filename.
                break
            }
            else
            {
                Write-Debug -Message "File '$filePath' not found."
            }
        }

        if ([string]::IsNullOrEmpty($languageFile))
        {
            throw ('File ''{0}'' not found in ''{1}''.' -f ($localizedFileNamesToTry -join ','),$localizedFolder)
        }
        else
        {
            Write-Debug -Message ('Getting file {0}' -f $languageFile)
        }

        $constrainedState = [System.Management.Automation.Runspaces.InitialSessionState]::Create()

        if (!$IsCoreCLR)
        {
            $constrainedState.ApartmentState = [System.Threading.ApartmentState]::STA
        }

        $constrainedState.LanguageMode = [System.Management.Automation.PSLanguageMode]::ConstrainedLanguage
        $constrainedState.DisableFormatUpdates = $true

        $sspe = New-Object System.Management.Automation.Runspaces.SessionStateProviderEntry 'Environment',([Microsoft.PowerShell.Commands.EnvironmentProvider]),$null
        $constrainedState.Providers.Add($sspe)

        $sspe = New-Object System.Management.Automation.Runspaces.SessionStateProviderEntry 'FileSystem',([Microsoft.PowerShell.Commands.FileSystemProvider]),$null
        $constrainedState.Providers.Add($sspe)

        $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Get-Content',([Microsoft.PowerShell.Commands.GetContentCommand]),$null
        $constrainedState.Commands.Add($ssce)

        $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Get-Date',([Microsoft.PowerShell.Commands.GetDateCommand]),$null
        $constrainedState.Commands.Add($ssce)

        $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Get-ChildItem',([Microsoft.PowerShell.Commands.GetChildItemCommand]),$null
        $constrainedState.Commands.Add($ssce)

        $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Get-Item',([Microsoft.PowerShell.Commands.GetItemCommand]),$null
        $constrainedState.Commands.Add($ssce)

        $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Test-Path',([Microsoft.PowerShell.Commands.TestPathCommand]),$null
        $constrainedState.Commands.Add($ssce)

        $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'Out-String',([Microsoft.PowerShell.Commands.OutStringCommand]),$null
        $constrainedState.Commands.Add($ssce)

        $ssce = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'ConvertFrom-StringData',([Microsoft.PowerShell.Commands.ConvertFromStringDataCommand]),$null
        $constrainedState.Commands.Add($ssce)

        # $scopedItemOptions = [System.Management.Automation.ScopedItemOptions]::AllScope

        # Create new runspace with the above defined entries. Then open and set its working dir to $destinationAbsolutePath
        # so all condition attribute expressions can use a relative path to refer to file paths e.g.
        # condition="Test-Path src\${PLASTER_PARAM_ModuleName}.psm1"
        $constrainedRunspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($constrainedState)
        $constrainedRunspace.Open()
        $destinationAbsolutePath = (Get-Item -Path $BaseDirectory -ErrorAction Stop).FullName
        $null = $constrainedRunspace.SessionStateProxy.Path.SetLocation($destinationAbsolutePath)
    }

    process
    {
        try
        {
            $powershell = [PowerShell]::Create()
            $powershell.Runspace = $constrainedRunspace
            $expression = Get-Content -Raw -Path $languageFile
            try
            {
                $null = $powershell.AddScript($expression)
                $powershell.Invoke()
            }
            catch
            {
                throw $_
            }

            # Check for non-terminating errors.
            if ($powershell.Streams.Error.Count -gt 0)
            {
                $powershell.Streams.Error.ForEach({
                    Write-Error $_
                })
            }
        }
        finally
        {
            if ($powershell)
            {
                $powershell.Dispose()
            }
        }
    }

    end
    {
        $constrainedRunspace.Dispose()
    }
}
