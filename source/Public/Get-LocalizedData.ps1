<#
.SYNOPSIS
Gets language-specific data into scripts and functions based on the UI culture
that is selected for the operating system.
Similar to Import-LocalizedData, with extra parameter 'DefaultUICulture'.

.DESCRIPTION
The Get-LocalizedData cmdlet dynamically retrieves strings from a subdirectory
whose name matches the UI language set for the current user of the operating system.
It is designed to enable scripts to display user messages in the UI language selected
by the current user.

Get-LocalizedData imports data from .psd1 files in language-specific subdirectories
of the script directory and saves them in a local variable that is specified in the
command. The cmdlet selects the subdirectory and file based on the value of the
$PSUICulture automatic variable. When you use the local variable in the script to
display a user message, the message appears in the user's UI language.

You can use the parameters of G-LocalizedData to specify an alternate UI culture,
path, and file name, to add supported commands, and to suppress the error message that
appears if the .psd1 files are not found.

The G-LocalizedData cmdlet supports the script internationalization
initiative that was introduced in Windows PowerShell 2.0. This initiative
aims to better serve users worldwide by making it easy for scripts to display
user messages in the UI language of the current user. For more information
about this and about the format of the .psd1 files, see about_Script_Internationalization.

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
.PARAMETER UICulture
Specifies an alternate UI culture. The default is the value of the $PsUICulture
automatic variable. Enter a UI culture in <language>-<region> format, such as
en-US, de-DE, or ar-SA.

The value of the UICulture parameter determines the language-specific subdirectory
(within the base directory) from which Import-LocalizedData gets the .psd1 file
for the script.

The cmdlet searches for a subdirectory with the same name as the value of the
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
#>
function Get-LocalizedData
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [Alias('Variable')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${BindingVariable},

        [Parameter(Position = 1, ParameterSetName = 'TargetedUICulture')]
        [string]
        ${UICulture},

        [Parameter()]
        [string]
        ${BaseDirectory},

        [Parameter()]
        [string]
        ${FileName},

        [Parameter()]
        [string[]]
        ${SupportedCommand},

        [Parameter(Position = 1, ParameterSetName = 'DefaultUICulture')]
        [string]
        ${DefaultUICulture}
    )

    begin
    {
        # Because Proxy Command changes the Invocation origin, we need to be explicit
        # when handing the pipeline back to original command
        if (!$PSBoundParameters.ContainsKey('FileName'))
        {
            if ($myInvocation.ScriptName)
            {
                $file = ([io.FileInfo]$myInvocation.ScriptName)
            }
            else
            {
                $file = [io.FileInfo]$myInvocation.MyCommand.Module.Path
            }
            $FileName = $file.BaseName
            $PSBoundParameters.add('FileName', $file.Name)
        }

        if ($PSBoundParameters.ContainsKey('BaseDirectory'))
        {
            $CallingScriptRoot = $BaseDirectory
        }
        else
        {
            $CallingScriptRoot = $myInvocation.PSScriptRoot
            $PSBoundParameters.add('BaseDirectory', $CallingScriptRoot)
        }

        if ($PSBoundParameters.ContainsKey('DefaultUICulture') -and !$PSBoundParameters.ContainsKey('UICulture'))
        {
            # We don't want the resolution to eventually return the ModuleManifest
            # So we run the same GetFilePath() logic than here:
            # https://github.com/PowerShell/PowerShell/blob/master/src/Microsoft.PowerShell.Commands.Utility/commands/utility/Import-LocalizedData.cs#L302-L333
            # and if we see it will return the wrong thing, set the UICulture to DefaultUI culture, and return the logic to Import-LocalizedData
            $currentCulture = Get-UICulture

            $fullFileName = $FileName + ".psd1"
            $LanguageFile = $null

            while ($null -ne $currentCulture -and $currentCulture.Name -and !$LanguageFile)
            {
                $filePath = [io.Path]::Combine($CallingScriptRoot, $CurrentCulture.Name, $fullFileName)
                if (Test-Path $filePath)
                {
                    Write-Debug "Found $filePath"
                    $LanguageFile = $filePath
                }
                else
                {
                    Write-Debug "File $filePath not found"
                }
                $currentCulture = $currentCulture.Parent
            }

            if (!$LanguageFile)
            {
                $PSBoundParameters.Add('UICulture', $DefaultUICulture)
            }
            $null = $PSBoundParameters.remove('DefaultUICulture')
        }

        try
        {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Import-LocalizedData', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch
        {
            throw
        }
    }

    process
    {
        try
        {
            $steppablePipeline.Process($_)
        }
        catch
        {
            throw
        }
    }

    end
    {
        if ($BindingVariable -and ($valueToBind = Get-Variable -Name $BindingVariable -ValueOnly -ErrorAction Ignore))
        {
            # Bringing the variable to the parent scope
            Set-Variable -Scope 1 -Name $BindingVariable -Force -ErrorAction SilentlyContinue -Value $valueToBind
        }
        try
        {
            $steppablePipeline.End()
        }
        catch
        {
            throw
        }
    }
}
