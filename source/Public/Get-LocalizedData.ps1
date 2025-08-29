<#
    .SYNOPSIS
        Gets language-specific data into scripts and functions based on the UI culture
        that is specified or that is selected for the operating system.

    .DESCRIPTION
        The Get-LocalizedData command dynamically retrieves strings from a subdirectory
        whose name matches the UI language set for the current user of the operating system.
        It is designed to enable scripts to display user messages in the UI language selected
        by the current user.

        Optionally the `Get-LocalizedData` saves the hash table in the variable
        that is specified by the value of the `BindingVariable` parameter.

        Get-LocalizedData imports data from .psd1 files in language-specific subdirectories
        of the script directory and saves them in a local variable that is specified in the
        command. The command selects the subdirectory and file based on the value of the
        $PSUICulture automatic variable. When you use the local variable in the script to
        display a user message, the message appears in the user's UI language.

        You can use the parameters of G-LocalizedData to specify an alternate UI culture,
        path, and file name, to add supported commands, and to suppress the error message that
        appears if the .psd1 files are not found.

        The G-LocalizedData command supports the script internationalization
        initiative that was introduced in Windows PowerShell 2.0. This initiative
        aims to better serve users worldwide by making it easy for scripts to display
        user messages in the UI language of the current user. For more information
        about this and about the format of the .psd1 files, see about_Script_Internationalization.

        ```mermaid
        graph LR

        Argument{Parameter set?} -->|"Only UICulture
        (DefaultUICulture = en-US)"| UseUIC
        Argument -->|"Only DefaultUICulture"| GetUIC[[Get OS Culture]]
        GetUIC --> LCID127{"Is LCID = 127?<br>(in variant culture)"}
        Argument -->|"Both UICulture and
        DefaultUICulture"| UseUIC
        UseUIC[Use UICulture] --> LCID127
        LCID127 -->|"No"| SetUIC[[Set UICulture]]
        LCID127 -->|"Yes"| UseDC[Use default culture]
        UseDC --> SetUIC
        SetUIC --> SearchFile[[Find UICulture<br>localization file]]
        SearchFile --> FileExist
        FileExist{localization<br>file exist?} -->|"No"| ParentCulture{Parent culture<br>exist?}
        ParentCulture -->|"Yes"| UseParentC[Use parent culture]
        UseParentC --> SetUIC
        ParentCulture -->|"No"| EvalDefaultC{Evaluate<br>default>br>culture?}
        EvalDefaultC -->|"Yes"| UseDC
        EvalDefaultC -->|"No"| EvalStillLCID127{Still invariant?}
        FileExist -->|"Yes"| EvalStillLCID127
        EvalStillLCID127 -->|"Yes, Use Get-LocalizedDataForInvariantCulture"| GetFile[[Get localization strings]]
        EvalStillLCID127 -->|"No, Use Import-LocalizedData"| GetFile
        ```

    .PARAMETER BindingVariable
        Specifies the variable into which the text strings are imported. Enter a variable
        name without a dollar sign ($).

        In Windows PowerShell 2.0, this parameter is required. In Windows PowerShell 3.0,
        this parameter is optional. If you omit this parameter, Import-LocalizedData
        returns a hash table of the text strings. The hash table is passed down the pipeline
        or displayed at the command line.

        When using Import-LocalizedData to replace default text strings specified in the
        DATA section of a script, assign the DATA section to a variable and enter the name
        of the DATA section variable in the value of the BindingVariable parameter. Then,
        when Import-LocalizedData saves the imported content in the BindingVariable, the
        imported data will replace the default text strings. If you are not specifying
        default text strings, you can select any variable name.

        If the BindingVariable parameter is not specified, Import-LocalizedData returns
        a hashtable of the text strings. The hash table is passed down the pipeline or
        displayed at the command line.

    .PARAMETER UICulture
        Specifies an alternate UI culture. The default is the value of the $PsUICulture
        automatic variable. Enter a UI culture in <language>-<region> format, such as
        en-US, de-DE, or ar-SA.

        The value of the UICulture parameter determines the language-specific subdirectory
        (within the base directory) from which Import-LocalizedData gets the .psd1 file
        for the script.

        The command searches for a subdirectory with the same name as the value of the
        UICulture parameter or the $PsUICulture automatic variable, such as de-DE or
        ar-SA. If it cannot find the directory, or the directory does not contain a .psd1
        file for the script, it searches for a subdirectory with the name of the language
        code, such as de or ar. If it cannot find the subdirectory or .psd1 file, the
        command fails and the data is displayed in the default language specified in the
        script.

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
        Before using Import-LocalizedData, localize your user messages. Format the messages
        for each locale (UI culture) in a hash table of key/value pairs, and save the
        hash table in a file with the same name as the script and a .psd1 file name extension.
        Create a directory under the script directory for each supported UI culture, and
        then save the .psd1 file for each UI culture in the directory with the UI
        culture name.

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

        This command should preferably be used at the top of each resource PowerShell
        module script file (.psm1).

        It will automatically look for a file in the folder for the current UI
        culture, or default to the UI culture folder 'en-US'.

        The localized strings file can be named either `<ScriptFileName>.psd1`,
        e.g. `DSC_MyResource.psd1`, or suffixed with `strings`, e.g.
        `DSC_MyResource.strings.psd1`.

        Read more about localization in the section [Localization](https://dsccommunity.org/styleguidelines/localization/)
        in the DSC Community style guideline.

    .OUTPUTS
        System.Collections.Hashtable

    .EXAMPLE
        $script:localizedData = Get-LocalizedData

        Imports the localized strings for the current OS UI culture. If the localized
        folder does not exist then the localized strings for the default UI culture
        'en-US' is returned.

    .EXAMPLE
        $script:localizedData = Get-LocalizedData -DefaultUICulture 'de-DE'

        Imports the localized strings for the current OS UI culture. If the localized
        folder does not exist then the localized strings for the default UI culture
        'de-DE' is returned.

    .EXAMPLE
        $script:localizedData = Get-LocalizedData -UICulture 'de-DE'

        Imports the localized strings for UI culture 'de-DE'. If the localized folder
        does not exist then the localized strings for the default UI culture 'en-US'
        is returned.

        $script:localizedData = Get-LocalizedData -UICulture 'de-DE' -DefaultUICulture 'en-GB'

        Imports the localized strings for UI culture 'de-DE'. If the localized folder
        does not exist then the localized strings for the default UI culture
        'en-GB' is returned.
#>
function Get-LocalizedData
{
    [CmdletBinding(DefaultParameterSetName = 'DefaultUICulture')]
    param
    (
        [Parameter(Position = 0)]
        [Alias('Variable')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $BindingVariable,

        [Parameter(Position = 1)]
        [System.String]
        $UICulture,

        [Parameter()]
        [System.String]
        $BaseDirectory,

        [Parameter()]
        [System.String]
        $FileName,

        [Parameter()]
        [System.String[]]
        $SupportedCommand,

        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DefaultUICulture = 'en-US'
    )

    if ($PSBoundParameters.ContainsKey('FileName'))
    {
        Write-Debug -Message ('Looking for provided file with base name: ''{0}''.' -f $FileName)
    }
    else
    {
        if ($myInvocation.ScriptName)
        {
            $file = [System.IO.FileInfo] $myInvocation.ScriptName
        }
        else
        {
            $file = [System.IO.FileInfo] $myInvocation.MyCommand.Module.Path
        }

        $FileName = $file.BaseName

        $null = $PSBoundParameters.Add('FileName', $file.Name)

        Write-Debug -Message ('Looking for resolved file with base name: ''{0}''.' -f $FileName)
    }

    if ($PSBoundParameters.ContainsKey('BaseDirectory'))
    {
        $callingScriptRoot = $BaseDirectory
    }
    else
    {
        $callingScriptRoot = $MyInvocation.PSScriptRoot

        $null = $PSBoundParameters.Add('BaseDirectory', $callingScriptRoot)
    }

    # If UICulture wasn't specified use the OS configured one, otherwise use the one specified.
    if (-not $PSBoundParameters.ContainsKey('UICulture'))
    {
        $currentCulture = Get-UICulture

        Write-Debug -Message ("Using OS configured culture:`n{0}" -f ($currentCulture | Out-String))

        $PSBoundParameters['UICulture'] = $currentCulture.Name
    }
    else
    {
        $currentCulture = [System.Globalization.CultureInfo]::GetCultureInfo($UICulture)

        Write-Debug -Message ("Using specified culture:`n{0}" -f ($currentCulture | Out-String))
    }

    <#
        If the LCID is 127 (invariant) then use default UI culture anyway.
        If we can't create the CultureInfo object, it's probably because the
        Globalization-invariant mode is enabled for the DotNet runtime (breaking change in .Net)
        See more information in issue https://github.com/dsccommunity/DscResource.Common/issues/11.
        https://docs.microsoft.com/en-us/dotnet/core/compatibility/globalization/6.0/culture-creation-invariant-mode
    #>

    $evaluateDefaultCulture = $true

    if ($currentCulture.LCID -eq 127) # cSpell: ignore LCID
    {
        try
        {
            # Current culture is invariant, let's directly evaluate the DefaultUICulture
            $currentCulture = [System.Globalization.CultureInfo]::GetCultureInfo($DefaultUICulture)

            Write-Debug -Message ("Invariant culture. Using default culture instead:`n{0}" -f ($currentCulture | Out-String))

            # No need to evaluate the DefaultUICulture later, as we'll start with this (in the while loop below)
            $evaluateDefaultCulture = $false
        }
        catch
        {
            # The code will now skip to the InvokeCommand part and execute the Get-LocalizedDataForInvariantCulture
            # function instead of Import-LocalizedData.

            Write-Debug -Message 'The Globalization-Invariant mode is enabled, only the Invariant Culture is allowed.'
        }

        Write-Debug -Message ('Setting parameter UICulture to ''{0}''.' -f $DefaultUICulture)

        $PSBoundParameters['UICulture'] = $DefaultUICulture
    }

    [System.String] $languageFile = ''

    [System.String[]] $localizedFileNamesToTry = @(
        ('{0}.strings.psd1' -f $FileName)
        ('{0}.psd1' -f $FileName)
    )

    while (-not [System.String]::IsNullOrEmpty($currentCulture.Name) -and [System.String]::IsNullOrEmpty($languageFile))
    {
        Write-Debug -Message ('Looking for Localized data file using the current culture ''{0}''.' -f $currentCulture.Name)

        foreach ($localizedFileName in $localizedFileNamesToTry)
        {
            $filePath = [System.IO.Path]::Combine($callingScriptRoot, $CurrentCulture.Name, $localizedFileName)

            if (Test-Path -Path $filePath)
            {
                Write-Debug -Message "Found '$filePath'."

                $languageFile = $filePath

                # Set the filename to the file we found.
                $PSBoundParameters['FileName'] = $localizedFileName

                # Exit loop if as we found the first filename.
                break
            }
            else
            {
                Write-Debug -Message "File '$filePath' not found."
            }
        }

        # If the file wasn't found one, try parent culture or the default culture.
        if ([System.String]::IsNullOrEmpty($languageFile))
        {
            # Evaluate the parent culture if there is a valid one (not invariant culture).
            if ($currentCulture.Parent -and [System.String] $currentCulture.Parent.Name)
            {
                $currentCulture = $currentCulture.Parent

                Write-Debug -Message ('Setting parameter UICulture to ''{0}''.' -f $currentCulture.Name)

                $PSBoundParameters['UICulture'] = $currentCulture.Name

                Write-Debug -Message ("Did not find matching file for current culture, testing parent culture:`n{0}" -f ($currentCulture | Out-String))
            }
            else
            {
                # If we haven't evaluated the default culture yet, do it now.
                if ($evaluateDefaultCulture)
                {
                    $evaluateDefaultCulture = $false

                    <#
                        Evaluating the default UI culture (which defaults to 'en-US').
                        If the default UI culture cannot be resolved, we'll revert
                        to the current culture because then most likely the invariant
                        mode is enabled for the DotNet runtime.
                    #>
                    try
                    {
                        $currentCulture = [System.Globalization.CultureInfo]::GetCultureInfo($DefaultUICulture)

                        Write-Debug -Message ("Did not find matching file for current or parent culture, testing default culture:`n{0}" -f ($currentCulture | Out-String))
                    }
                    catch
                    {
                        # Set the OS culture to revert to invariant culture (LCID 127).
                        $currentCulture = Get-UICulture

                        Write-Debug -Message ("Unable to create the [CultureInfo] object for default culture '{0}', most likely due to invariant mode being enabled. Reverting to current (invariant) culture:`n{1}" -f $DefaultUICulture, ($currentCulture | Out-String))

                        <#
                            Already tried every possible way. Exit the while loop and hand over to
                            Import-LocalizedData or Get-LocalizedDataForInvariantCultureMode
                        #>
                        break
                    }

                    Write-Debug -Message ('Setting parameter UICulture to ''{0}''.' -f $DefaultUICulture)

                    $PSBoundParameters['UICulture'] = $DefaultUICulture
                }
                else
                {
                    Write-Debug -Message 'Already evaluated everything we could, continue and let the command called next throw an exception.'

                    break
                }
            }
        }
    }

    if ($currentCulture.LCID -eq 127)
    {
        $getLocalizedDataForInvariantCultureParameters = Get-Command -Name 'Get-LocalizedDataForInvariantCulture' -ErrorAction 'Stop'

        $PSBoundParameters.Keys.ForEach({
                if ($_ -notin $getLocalizedDataForInvariantCultureParameters.Parameters.Keys)
                {
                    $null = $PSBoundParameters.Remove($_)
                }
            })

        Write-Debug ('Because culture is invariant, calling Get-LocalizedDataForInvariantCulture using parameters: {0}' -f ($PSBoundParameters | Out-String))

        # This works around issue with Import-LocalizedData when pwsh configured as invariant.
        $localizedData = Get-LocalizedDataForInvariantCulture @PSBoundParameters
    }
    else
    {
        Write-Debug ('Calling Microsoft.PowerShell.Utility\Import-LocalizedData using parameters: {0}' -f ($PSBoundParameters | Out-String))

        # Removes the parameter DefaultUICulture so that isn't used when calling Import-LocalizedData.
        $null = $PSBoundParameters.Remove('DefaultUICulture')

        $localizedData = Microsoft.PowerShell.Utility\Import-LocalizedData @PSBoundParameters
    }

    if ($PSBoundParameters.ContainsKey('BindingVariable'))
    {
        # The command we called returned the localized data in the binding variable.
        $boundLocalizedData = Get-Variable -Name $BindingVariable -ValueOnly -ErrorAction 'Ignore'

        if ($boundLocalizedData)
        {
            Write-Debug -Message ('Binding variable ''{0}'' to localized data.' -f $BindingVariable)

            # Bringing the variable to the parent scope
            Set-Variable -Scope 1 -Name $BindingVariable -Force -ErrorAction 'SilentlyContinue' -Value $boundLocalizedData
        }
    }
    else
    {
        Write-Debug -Message 'Returning localized data.'

        return $localizedData
    }
}
