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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Get-PSModulePath' {
    BeforeAll {
        Mock -CommandName Get-EnvironmentVariable -MockWith {
            return '/tmp/path'
        }
    }

    Context 'When getting the PSModulePath session environment variable' {
        It 'Should return the correct path' {
            Get-PSModulePath -FromTarget 'Session' | Should -Be '/tmp/path'

            Should -Invoke -CommandName Get-EnvironmentVariable -Exactly -Times 1 -Scope It
        }
    }

    Context 'When getting the PSModulePath user environment variable' {
        It 'Should return the correct path' {
            Get-PSModulePath -FromTarget 'User' | Should -Be '/tmp/path'

            Should -Invoke -CommandName Get-EnvironmentVariable -Exactly -Times 1 -Scope It
        }
    }

    Context 'When getting the PSModulePath machine environment variable' {
        It 'Should return the correct path' {
            Get-PSModulePath -FromTarget 'Machine' | Should -Be '/tmp/path'

            Should -Invoke -CommandName Get-EnvironmentVariable -Exactly -Times 1 -Scope It
        }
    }

    Context 'When getting the PSModulePath machine environment variable' {
        It 'Should return the correct unique path' {
            Get-PSModulePath -FromTarget 'Machine', 'User', 'Session' | Should -Be '/tmp/path'

            Should -Invoke -CommandName Get-EnvironmentVariable -Exactly -Times 3 -Scope It
        }
    }
}
