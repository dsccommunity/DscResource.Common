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

Describe 'Test-DscObjectHasProperty' {
    Context 'When the object contains the expected property' {
        BeforeAll {
            # Use the Get-Verb cmdlet to just get a simple object fast
            InModuleScope -ScriptBlock {
                $script:testDscObject = (Get-Verb)[0]
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                { Test-DscObjectHasProperty -Object $script:testDscObject -PropertyName 'Verb' -Verbose } | Should -Not -Throw
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                $result = Test-DscObjectHasProperty -Object $script:testDscObject -PropertyName 'Verb' -Verbose

                $result | Should -BeTrue
            }
        }
    }

    Context 'When the object does not contain the expected property' {
        BeforeAll {
            # Use the Get-Verb cmdlet to just get a simple object fast
            InModuleScope -ScriptBlock {
                $script:testDscObject = (Get-Verb)[0]
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                { Test-DscObjectHasProperty -Object $script:testDscObject -PropertyName 'Missing' -Verbose } | Should -Not -Throw
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                $result = Test-DscObjectHasProperty -Object $script:testDscObject -PropertyName 'Missing' -Verbose

                $result | Should -BeFalse
            }
        }
    }
}
