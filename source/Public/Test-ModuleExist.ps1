<#
    .SYNOPSIS
        Checks if a PowerShell module with a specified name is available in a
        PSModulePath.

    .DESCRIPTION
        The Test-ModuleExist function checks if a PowerShell module with the specified
        name is available in a PSModulePath. It can also filter the modules based on
        the scope or folder path. Additionally, it can filter the modules based on
        a specific version.

        See also `Assert-Module`.

    .PARAMETER Name
        The name of the module to check if available.

    .PARAMETER Scope
        The scope where the module should be available. This parameter is used to
        filter the modules based on the scope.

    .PARAMETER Path
        The path where the module should be available. This parameter is used to
        filter the modules based on the path.

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
                Write-Debug -Message "Module: $($_.Name), ModulePath: $($_.Path), SpecifiedPath: $modulePath."

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
                Write-Debug -Message "Module: $($_.Name), ModuleVersion: $($_.Version), SpecifiedVersion: $moduleVersion."

                $_.Version -eq $moduleVersion
            }

        if ($modulesToEvaluate -and $modulePrerelease)
        {
            Write-Verbose -Message "Filtering modules by prerelease '$modulePrerelease'."

            $modulesToEvaluate = $modulesToEvaluate |
                Where-Object -FilterScript {
                    Write-Debug -Message "Module: $($_.Name), ModulePrerelease: $($_.PrivateData.PSData.Prerelease), SpecifiedPrerelease: $modulePrerelease."

                    $_.PrivateData.PSData.Prerelease -eq $modulePrerelease
                }
        }
    }

    return ($modulesToEvaluate -and $modulesToEvaluate.Count -gt 0)
}
