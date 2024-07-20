<#
    .SYNOPSIS
        Returns the individual scope path or the environment variable PSModulePath
        from one or more of the specified targets.

    .DESCRIPTION
        Returns the individual scope path or the environment variable PSModulePath
        from one or more of the specified targets.

        If more than one target is provided in the parameter FromTarget the return
        value will contain the concatenation of all unique paths from the targets.
        If there are no paths to return the command will return an empty string.

    .PARAMETER FromTarget
        Specifies the environment target to get the PSModulePath from.

    .PARAMETER Scope
        Specifies the scope to get the individual module path of.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-PSModulePath

        Returns the module path to the CurrentUser scope.

    .EXAMPLE
        Get-PSModulePath -Scope 'CurrentUser'

        Returns the module path to the CurrentUser scope.

    .EXAMPLE
        Get-PSModulePath -Scope 'AllUsers'

        Returns the module path to the AllUsers scope.

    .EXAMPLE
        Get-PSModulePath -Scope 'Builtin'

        Returns the module path to the Builtin scope. This is the module path
        containing the modules that ship with PowerShell.

    .EXAMPLE
        Get-PSModulePath -FromTarget 'Session'

        Returns the paths from the Session target.

    .EXAMPLE
        Get-PSModulePath -FromTarget 'Session', 'User', 'Machine'

        Returns the unique paths from the all targets.

    .OUTPUTS
        [System.String]

        If there are no paths to return the command will return an empty string.
#>
function Get-PSModulePath
{
    [CmdletBinding(DefaultParameterSetName = 'Scope')]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'FromTarget')]
        [ValidateSet('Session', 'User', 'Machine')]
        [System.String[]]
        $FromTarget,

        [Parameter(ParameterSetName = 'Scope')]
        [ValidateSet('CurrentUser', 'AllUsers', 'Builtin')]
        [System.String]
        $Scope = 'CurrentUser'
    )

    if ($PSCmdlet.ParameterSetName -eq 'FromTarget')
    {
        $modulePathSession = $modulePathUser = $modulePathMachine = $null

        <#
            Get the environment variables from required targets. The value returned
            is cast to System.String to convert $null values to empty string.
        #>
        switch ($FromTarget)
        {
            'Session'
            {
                $modulePathSession = Get-EnvironmentVariable -Name 'PSModulePath' -FromTarget 'Session'

                continue
            }

            'User'
            {
                $modulePathUser = Get-EnvironmentVariable -Name 'PSModulePath' -FromTarget 'User'

                continue
            }

            'Machine'
            {
                $modulePathMachine = Get-EnvironmentVariable -Name 'PSModulePath' -FromTarget 'Machine'

                continue
            }
        }

        $modulePath = $modulePathSession, $modulePathUser, $modulePathMachine -join [System.IO.Path]::PathSeparator

        $modulePathArray = $modulePath -split [System.IO.Path]::PathSeparator |
            Where-Object -FilterScript {
                -not [System.String]::IsNullOrEmpty($_)
            } |
            Sort-Object -Unique

        $modulePath = $modulePathArray -join [System.IO.Path]::PathSeparator
    }

    if ($PSCmdlet.ParameterSetName -eq 'Scope')
    {
        switch ($Scope)
        {
            'CurrentUser'
            {
                $modulePath = if ($IsLinux -or $IsMacOS)
                {
                    # Must be correct case on case-sensitive file systems.
                    Join-Path -Path $HOME -ChildPath '.local/share/powershell/Modules'
                }
                else
                {
                    $documentsFolder = [Environment]::GetFolderPath('MyDocuments')

                    # When the $documentsFolder is null or empty string the folder does not exist.
                    if ([System.String]::IsNullOrEmpty($documentsFolder))
                    {
                        $PSCmdlet.ThrowTerminatingError(
                            [System.Management.Automation.ErrorRecord]::new(
                                ($script:localizedData.PSModulePath_MissingMyDocumentsPath -f (Get-UserName)),
                                'MissingMyDocumentsPath',
                                [System.Management.Automation.ErrorCategory]::ResourceUnavailable,
                                (Get-UserName)
                            )
                        )
                    }

                    if ($IsCoreCLR)
                    {
                        Join-Path -Path $documentsFolder -ChildPath 'PowerShell/Modules'
                    }
                    else
                    {
                        Join-Path -Path $documentsFolder -ChildPath 'WindowsPowerShell/Modules'
                    }
                }

                break
            }

            'AllUsers'
            {
                $modulePath = if ($IsLinux -or $IsMacOS)
                {
                    '/usr/local/share/powershell/Modules'
                }
                else
                {
                    Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell/Modules'
                }

                break
            }

            'BuiltIn'
            {
                # cSPell: ignore PSHOME
                $modulePath = Join-Path -Path $PSHOME -ChildPath 'Modules'

                break
            }
        }
    }

    return $modulePath
}
