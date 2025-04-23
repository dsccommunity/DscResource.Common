[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:moduleName = 'DscResource.Common'

    # Make sure there are not other modules imported that will conflict with mocks.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe 'Get-FileProductVersion' {
    Context 'When the file exists and has a product version' {
        BeforeAll {
            Mock -CommandName Get-Item -MockWith {
                return [PSCustomObject] @{
                    Exists      = $true
                    VersionInfo = [PSCustomObject] @{
                        ProductVersion = '15.0.2000.5'
                    }
                }
            }
        }

        It 'Should return the correct product version as a System.Version object' {
            $result = Get-FileProductVersion -Path (Join-Path -Path $TestDrive -ChildPath 'testfile.dll')
            $result | Should -BeOfType [System.Version]
            $result.Major | Should -Be 15
            $result.Minor | Should -Be 0
            $result.Build | Should -Be 2000
            $result.Revision | Should -Be 5
        }
    }

    Context 'When Get-Item throws an exception' {
        BeforeAll {
            Mock -CommandName Get-Item -MockWith {
                throw 'Mock exception message'
            }
        }

        It 'Should throw the correct error' {
            $mockFilePath = Join-Path -Path $TestDrive -ChildPath 'testfile.dll'

            $mockGetFileProductVersionErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Get_FileProductVersion_GetFileProductVersionError
            }

            {
                Get-FileProductVersion -Path $mockFilePath -ErrorAction 'Stop'
            } | Should -Throw ($mockGetFileProductVersionErrorMessage -f $mockFilePath, 'Mock exception message')
        }
    }
}
