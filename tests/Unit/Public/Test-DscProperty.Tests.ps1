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

Describe 'Test-DscProperty' -Tag 'Public' {
    Context 'When resource does not have an Ensure property' {
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
                $MyResourceProperty3

                [DscProperty(NotConfigurable)]
                [System.String]
                $MyResourceReadProperty
            }

            $script:mockResourceBaseInstance = [MyMockResource]::new()
        }

        It 'Should return the correct value' {
            $result = Test-DscProperty -Name 'Ensure' -InputObject $script:mockResourceBaseInstance

            $result | Should -BeFalse
        }
    }

    Context 'When resource have an Ensure property' {
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
                $Ensure

                [DscProperty(NotConfigurable)]
                [System.String]
                $MyResourceReadProperty
            }

            $script:mockResourceBaseInstance = [MyMockResource]::new()
        }

        It 'Should return the correct value' {
            $result = Test-DscProperty -Name 'Ensure' -InputObject $script:mockResourceBaseInstance

            $result | Should -BeTrue
        }
    }

    Context 'When resource have an Ensure property, but it is not a DSC property' {
        BeforeAll {
            class MyMockResource
            {
                [DscProperty(Key)]
                [System.String]
                $MyResourceKeyProperty1

                [DscProperty(Key)]
                [System.String]
                $MyResourceKeyProperty2

                [System.String]
                $Ensure

                [DscProperty(NotConfigurable)]
                [System.String]
                $MyResourceReadProperty
            }

            $script:mockResourceBaseInstance = [MyMockResource]::new()
        }

        It 'Should return the correct value' {
            $result = Test-DscProperty -Name 'Ensure' -InputObject $script:mockResourceBaseInstance

            $result | Should -BeFalse
        }
    }

    Context 'When using parameter HasValue' {
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
                $result = Test-DscProperty -Name 'MyProperty3' -HasValue -InputObject $script:mockResourceBaseInstance

                $result | Should -BeTrue
            }
        }

        Context 'When DSC property has a null value' {
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
                $result = Test-DscProperty -Name 'MyProperty3' -HasValue -InputObject $script:mockResourceBaseInstance

                $result | Should -BeFalse
            }
        }
    }

    Context 'When using parameter Attribute' {
        Context 'When DSC property has the expected attribute' {
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
                $result = Test-DscProperty -Name 'MyProperty3' -Attribute 'Optional' -InputObject $script:mockResourceBaseInstance

                $result | Should -BeTrue
            }
        }

        Context 'When DSC property has the wrong attribute' {
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
                $result = Test-DscProperty -Name 'MyProperty3' -Attribute 'Mandatory' -InputObject $script:mockResourceBaseInstance

                $result | Should -BeFalse
            }
        }
    }
}
