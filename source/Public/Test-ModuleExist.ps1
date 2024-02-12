<#
    .SYNOPSIS
        Checks if a PowerShell module with a specified name is available in a
        `$env:PSModulePath`.

    .DESCRIPTION
        The Test-ModuleExist function checks if a PowerShell module with the specified
        name is available in a `$env:PSModulePath`. It can also filter the modules based on
        the scope or folder path. Additionally, it can filter the modules based on
        a specific version.

        See also `Assert-Module`.

    .PARAMETER Name
        The name of the module to check is available.

    .PARAMETER Scope
        The scope where the module should be available. This parameter is used to
        filter the modules based on the scope.

    .PARAMETER Path
        The path where the module should be available. This parameter is used to
        filter the modules based on the path. The specified path must match (fully
        or partially) one of the `$env:PSModulePath` paths.

    .PARAMETER Version
        The version of the module. This parameter is used to filter the modules
        based on a specific version.

    .EXAMPLE
        Test-ModuleExist -Name 'MyModule' -Scope 'CurrentUser'

        Checks if a module named 'MyModule' exists in the current user's module scope.

    .EXAMPLE
        Test-ModuleExist -Name 'MyModule' -Path 'C:\Modules'

        Checks if a module named 'MyModule' exists in the specified path.

    .EXAMPLE
        Test-ModuleExist -Name 'MyModule' -Path 'local/share/powershell/Module'

        Checks if a module named 'MyModule' exists in a `$env:PSModulePath` that
        matches the specified path. If for example 'MyModule' exist in the path
        `/home/username/.local/share/powershell/Module` it returns `$true`.


    .EXAMPLE
        Test-ModuleExist -Name 'MyModule' -Version '1.0.0'

        Checks if a module named 'MyModule' with version '1.0.0' exists.

    .OUTPUTS
        System.Boolean
#>

function Test-ModuleExist
{
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param
    (
        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Scope')]
        [Parameter(ParameterSetName = 'Path')]
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'Scope')]
        [ValidateSet('CurrentUser', 'AllUsers')]
        [System.String]
        $Scope,

        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [System.String]
        $Path,

        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Scope')]
        [Parameter(ParameterSetName = 'Path')]
        [ValidateScript({
            # From https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
            $_ -match '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'
        })]
        [System.String]
        $Version
    )

    $availableModules = @(Get-Module -Name $Name -ListAvailable)

    $modulePath = switch ($PSCmdlet.ParameterSetName)
    {
        'Scope'
        {
            Get-PSModulePath -Scope $Scope
        }

        'Path'
        {
            $Path
        }
    }

    if ($modulePath)
    {
        Write-Verbose -Message "Filtering modules by path '$modulePath'."

        $modulesToEvaluate = $availableModules |
            Where-Object -FilterScript {
                $_.Path -match [System.Text.RegularExpressions.Regex]::Escape($modulePath)
            }
    }
    else
    {
        $modulesToEvaluate = $availableModules
    }

    if ($modulesToEvaluate -and $PSBoundParameters.Version)
    {
        $moduleVersion, $modulePrerelease = $Version -split '-'

        Write-Verbose -Message "Filtering modules by version '$moduleVersion'."

        $modulesToEvaluate = $modulesToEvaluate |
            Where-Object -FilterScript {
                $_.Version -eq $moduleVersion
            }

        if ($modulesToEvaluate -and $modulePrerelease)
        {
            Write-Verbose -Message "Filtering modules by prerelease '$modulePrerelease'."

            $modulesToEvaluate = $modulesToEvaluate |
                Where-Object -FilterScript {
                    $_.PrivateData.PSData.Prerelease -eq $modulePrerelease
                }
        }
    }

    return ($modulesToEvaluate -and $modulesToEvaluate.Count -gt 0)
}
