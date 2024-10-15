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

# macOS and Linux does not support CimInstance.
Describe 'ConvertTo-HashTable' -Skip:(-not ($IsWindows -or $PSEdition -eq 'Desktop')) {
    BeforeAll {
        [Microsoft.Management.Infrastructure.CimInstance[]] $cimInstances = ConvertTo-CimInstance -Hashtable @{
            k1 = 'v1'
            k2 = 100
            k3 = 1, 2, 3
        }
    }

    Context 'When the array contains the expected record count' {
        It 'Should not throw exception' {
            { $script:result = $cimInstances | ConvertTo-HashTable } | Should -Not -Throw
        }

        It "Should return record count of $($cimInstances.Count)" {
            $script:result.Count | Should -Be $cimInstances.Count
        }

        It 'Should return result of type [System.Collections.Hashtable]' {
            $script:result | Should -BeOfType [System.Collections.Hashtable]
        }

        It 'Should return value "k1" in the hashtable should be "v1"' {
            $script:result.k1 | Should -Be 'v1'
        }

        It 'Should return value "k2" in the hashtable should be "100"' {
            $script:result.k2 | Should -Be 100
        }

        It 'Should return value "k3" in the hashtable should be "1,2,3"' {
            $script:result.k3 | Should -Be '1,2,3'
        }
    }
}
