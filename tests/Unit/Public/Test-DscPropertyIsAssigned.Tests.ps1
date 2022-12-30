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

    Import-Module -Name $script:moduleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Test-DscPropertyIsAssigned' -Tag 'Public' {
    Context 'When DSC property has a non-null value' {
        BeforeAll {
            class MyMockResource
            {
                [DscProperty(Key)]
                [System.String]
                $MyResourceKeyProperty1

                [DscProperty(Key)]
                [System.String]
                $MyResourceKeyProperty2

                [DscProperty()]
                [System.String]
                $MyProperty3

                [DscProperty(NotConfigurable)]
                [System.String]
                $MyResourceReadProperty
            }

            $script:mockResourceBaseInstance = [MyMockResource] @{
                MyProperty3 = 'AnyValue'
            }
        }

        It 'Should return the correct value' {
            $result = Test-DscPropertyIsAssigned -Name 'MyProperty3' -InputObject $script:mockResourceBaseInstance

            $result | Should -BeTrue
        }
    }


    Context 'When DSC property has a non-null value' {
        BeforeAll {
            class MyMockResource
            {
                [DscProperty(Key)]
                [System.String]
                $MyResourceKeyProperty1

                [DscProperty(Key)]
                [System.String]
                $MyResourceKeyProperty2

                [DscProperty()]
                [System.String]
                $MyProperty3

                [DscProperty(NotConfigurable)]
                [System.String]
                $MyResourceReadProperty
            }

            $script:mockResourceBaseInstance = [MyMockResource] @{}
        }

        It 'Should return the correct value' {
            $result = Test-DscPropertyIsAssigned -Name 'MyProperty3' -InputObject $script:mockResourceBaseInstance

            $result | Should -BeFalse
        }
    }
}
