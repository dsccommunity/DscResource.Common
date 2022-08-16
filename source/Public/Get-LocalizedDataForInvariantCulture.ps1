
<#
    .SYNOPSIS
        Gets language-specific data when the culture is invariant.
        This directly gets the data from the DefaultUICulture, but without calling
        "Import-LocalizedData" which throws when the pwsh session is configured to be
        of invariant culture (as in the Guest Config agent).

    .DESCRIPTION
        The Get-LocalizedDataForInvariantCulture grabs the data from a localized string data psd1,
        without calling Import-LocalizedData which errors when called in a session set to invariant
        culture in the pwsh config.

        Instead, this function reads and executes the content of a psd1 file in a
        constrained language mode that only allows basic ConvertFrom-stringData.

    .PARAMETER BaseDirectory
        Specifies the base directory where the .psd1 files are located. The default is
        the directory where the script is located. Import-LocalizedData searches for
        the .psd1 file for the script in a language-specific subdirectory of the base
        directory.

    .PARAMETER FileName
        Specifies the name of the data file (.psd1) to be imported. Enter a file name.
        You can specify a file name that does not include its .psd1 file name extension,
        or you can specify the file name including the .psd1 file name extension.

        The FileName parameter is required when Import-LocalizedData is not used in a
        script. Otherwise, the parameter is optional and the default value is the base
        name of the script. You can use this parameter to direct Import-LocalizedData
        to search for a different .psd1 file.

        For example, if the FileName is omitted and the script name is FindFiles.ps1,
        Import-LocalizedData searches for the FindFiles.psd1 data file.

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

        Import-LocalizedData begins the search in the directory where the script file
        is located (or the value of the BaseDirectory parameter). It then searches within
        the base directory for a subdirectory with the same name as the value of the
        $PsUICulture variable (or the value of the UICulture parameter), such as de-DE or
        ar-SA. Then, it searches in that subdirectory for a .psd1 file with the same name
        as the script (or the value of the FileName parameter).

        If Import-LocalizedData cannot find a subdirectory with the name of the UI culture,
        or the subdirectory does not contain a .psd1 file for the script, it searches for
        a .psd1 file for the script in a subdirectory with the name of the language code,
        such as de or ar. If it cannot find the subdirectory or .psd1 file, the command
        fails, the data is displayed in the default language in the script, and an error
        message is displayed explaining that the data could not be imported. To suppress
        the message and fail gracefully, use the ErrorAction common parameter with a value
        of SilentlyContinue.

        If Import-LocalizedData finds the subdirectory and the .psd1 file, it imports the
        hash table of user messages into the value of the BindingVariable parameter in the
        command. Then, when you display a message from the hash table in the variable, the
        localized message is displayed.

        For more information, see about_Script_Internationalization.

    .EXAMPLE
        $script:localizedData = Get-LocalizedDataForInvariantCulture -DefaultUICulture 'en-US'

        This is an example that can be used in DSC resources to import the
        localized strings.
#>
function Get-LocalizedDataForInvariantCulture
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BaseDirectory,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FileName,

        [Parameter()]
        [System.String[]]
        $SupportedCommand,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DefaultUICulture = 'en-US'
    )

    begin
    {
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
            $localizedFolder = Join-Path -Path $BaseDirectory -ChildPath $DefaultUICulture.ToString()
            $expression = Get-Content -Raw -Path (Join-Path -Path $localizedFolder -ChildPath $FileName)
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
