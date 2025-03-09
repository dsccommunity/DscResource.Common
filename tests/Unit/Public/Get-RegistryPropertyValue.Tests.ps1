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

Describe 'Get-RegistryPropertyValue' -Tag 'GetRegistryPropertyValue' {
    BeforeAll {
        $mockWrongRegistryPath = 'HKLM:\SOFTWARE\AnyPath'
        $mockPropertyName = 'InstanceName'
        $mockPropertyValue = 'AnyValue'
    }

    Context 'When there are no property in the registry' {
        BeforeAll {
            Mock -CommandName Get-ItemPropertyValue -MockWith {
                return $null
            }
        }

        It 'Should return $null' {
            $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName
            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName Get-ItemPropertyValue -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the call to Get-ItemProperty throws an error (i.e. when the path does not exist)' -Skip:($IsLinux -or $IsMacOS) {
        Context 'When not passing ErrorAction parameter' {
            It 'Should throw an error' {
                $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName
                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When passing ErrorAction SilentlyContinue' {
            It 'Should throw an error' {
                $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName -ErrorAction 'SilentlyContinue'
                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When passing ErrorAction Ignore' {
            It 'Should throw an error' {
                $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName -ErrorAction 'Ignore'
                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When passing ErrorAction Continue' {
            It 'Should throw an error' {
                $result = Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName -ErrorAction 'Continue'
                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When passing ErrorAction Stop' {
            BeforeAll {
                Write-Verbose -Message 'Get-ItemPropertyValue is intentionally throwing an exception, because there was not a known way to mock it.' -Verbose
            }

            It 'Should throw an error' {
                { Get-RegistryPropertyValue -Path $mockWrongRegistryPath -Name $mockPropertyName -ErrorAction 'Stop' } | Should -Throw
            }
        }
    }

    Context 'When there are a property in the registry' {
        BeforeAll {
            $mockCorrectRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\RS'

            Mock -CommandName Get-ItemPropertyValue -MockWith {
                return $mockPropertyValue
            } -ParameterFilter {
                $Path -eq $mockCorrectRegistryPath `
                -and $Name -eq $mockPropertyName
            }
        }

        It 'Should return the correct value' {
            $result = Get-RegistryPropertyValue -Path $mockCorrectRegistryPath -Name $mockPropertyName
            $result | Should -Be $mockPropertyValue

            Should -Invoke -CommandName Get-ItemPropertyValue -Exactly -Times 1 -Scope It
        }
    }
}
