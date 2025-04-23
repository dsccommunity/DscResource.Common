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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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
Describe 'ConvertTo-CimInstance' -Skip:(-not ($IsWindows -or $PSEdition -eq 'Desktop')) {
    BeforeAll {
        $hashtable = @{
            k1 = 'v1'
            k2 = 100
            k3 = 1, 2, 3
        }
    }

    Context 'When parameters ''ClassName'' and ''Namespace'' are not supplied' {
        Context 'When the array contains the expected record count' {
            It 'Should not throw exception' {
                {
                    $script:result = [Microsoft.Management.Infrastructure.CimInstance[]] (
                        $hashtable | ConvertTo-CimInstance
                    )
                } | Should -Not -Throw
            }

            It 'Should record count should be correct' {
                $script:result.Count | Should -Be $hashtable.Count
            }

            It 'Should return result of type CimInstance[]' {
                $script:result.GetType().Name | Should -Be 'CimInstance[]'
            }

            It 'Should return value "k1" in the CimInstance array should be "v1"' {
                ($script:result | Where-Object Key -eq k1).Value | Should -Be 'v1'
            }

            It 'Should return value "k2" in the CimInstance array should be "100"' {
                ($script:result | Where-Object Key -eq k2).Value | Should -Be 100
            }

            It 'Should return value "k3" in the CimInstance array should be "1,2,3"' {
                ($script:result | Where-Object Key -eq k3).Value | Should -Be '1,2,3'
            }

            It 'Should be the correct ''ClassName''' {
                $script:result.CimSystemProperties.ClassName[0] | Should -Be 'MSFT_KeyValuePair'
            }

            It 'Should be the correct ''Namespace''' {
                $script:result.CimSystemProperties.Namespace[0] | Should -Be 'root/microsoft/Windows/DesiredStateConfiguration'
            }
        }
    }

    Context 'When parameters ''ClassName'' and ''Namespace'' are supplied' {
        Context 'When the array contains the expected record count' {
            It 'Should not throw exception' {
                $mockCimInstanceParams = @{
                    ClassName = 'MSFT_TaskNamedValue'
                    Namespace = 'Root/Microsoft/Windows/TaskScheduler'
                }

                {
                    $script:result = [Microsoft.Management.Infrastructure.CimInstance[]] (
                        $hashtable | ConvertTo-CimInstance @mockCimInstanceParams
                    )
                } | Should -Not -Throw
            }

            It 'Should record count should be correct' {
                $script:result.Count | Should -Be $hashtable.Count
            }

            It 'Should return result of type CimInstance[]' {
                $script:result.GetType().Name | Should -Be 'CimInstance[]'
            }

            It 'Should return value "k1" in the CimInstance array should be "v1"' {
                ($script:result | Where-Object Key -eq k1).Value | Should -Be 'v1'
            }

            It 'Should return value "k2" in the CimInstance array should be "100"' {
                ($script:result | Where-Object Key -eq k2).Value | Should -Be 100
            }

            It 'Should return value "k3" in the CimInstance array should be "1,2,3"' {
                ($script:result | Where-Object Key -eq k3).Value | Should -Be '1,2,3'
            }

            It 'Should be the correct ''ClassName''' {
                $script:result.CimSystemProperties.ClassName[0] | Should -Be 'MSFT_TaskNamedValue'
            }

            It 'Should be the correct ''Namespace''' {
                $script:result.CimSystemProperties.Namespace[0] | Should -Be 'Root/Microsoft/Windows/TaskScheduler'
            }
        }
    }
}
