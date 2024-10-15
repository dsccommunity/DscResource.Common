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

Describe 'Set-PSModulePath' {
    Context 'When using the parameter set TargetParameters' {
        Context 'When using FromTarget and ToTarget parameters' {
            BeforeAll {
                $originalPSModulePath = $env:PSModulePath

                Mock -CommandName Get-EnvironmentVariable -MockWith {
                    return '/tmp/path'
                }
            }

            AfterAll {
                $env:PSModulePath = $originalPSModulePath
            }

            It 'Should not throw an error and have set the correct value' {
                { Set-PSModulePath -FromTarget 'User' -ToTarget 'Session' } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-EnvironmentVariable -Exactly -Times 1 -Scope It

                [Environment]::GetEnvironmentVariable('PSModulePath') | Should -Be '/tmp/path'
            }

            It 'Should have returned the user PSModulePath to the original value' {
                { Set-PSModulePath -Path $originalPSModulePath } | Should -Not -Throw

                [Environment]::GetEnvironmentVariable('PSModulePath') | Should -Be $originalPSModulePath
            }
        }

        Context 'When using PassThru parameter' {
            BeforeAll {
                $originalPSModulePath = $env:PSModulePath
            }

            AfterEach {
                $env:PSModulePath = $originalPSModulePath
            }

            It 'Should not throw an error and return the correct value' {
                $result = Set-PSModulePath -Path 'C:\Module' -PassThru

                $result | Should -Be 'C:\Module'
            }

            It 'Should have set the session PSModulePath to the new value' {
                $env:PSModulePath | Should -Be $originalPSModulePath
            }
        }
    }
}
