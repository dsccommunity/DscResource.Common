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

Describe 'Assert-RequiredCommandParameter' -Tag 'Private' {
    Context 'When RequiredBehavior is ''All''' {
        Context 'When required parameter is missing' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSet -f 'Parameter1'

                    $testParams = @{
                        BoundParameterList = @{}
                        RequiredParameter  = 'Parameter1'
                        RequiredBehavior   = 'All'
                    }

                    { Assert-RequiredCommandParameter @testParams } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }

        Context 'When the required parameter is present' {
            It 'Should not throw an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        BoundParameterList = @{
                            Parameter1 = 'Value1'
                        }
                        RequiredParameter  = 'Parameter1'
                        RequiredBehavior   = 'All'
                    }
                }

                { Assert-RequiredCommandParameter @testParams | Should -Not -Throw }
            }
        }

        Context 'When both required parameter and parameter in IfParameterPresent is not present' {
            It 'Should not throw an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        BoundParameterList = @{}
                        RequiredParameter  = 'Parameter1'
                        RequiredBehavior   = 'All'
                        IfParameterPresent = 'Parameter2'
                    }

                    { Assert-RequiredCommandParameter @testParams } | Should -Not -Throw
                }
            }
        }

        Context 'When the required parameter is not present and parameter in IfParameterPresent is present' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSetWhenParameterExist -f 'Parameter1', 'Parameter2'

                    $testParams = @{
                        BoundParameterList = @{
                            Parameter2 = 'Value2'
                        }
                        RequiredParameter  = 'Parameter1'
                        RequiredBehavior   = 'All'
                        IfParameterPresent = 'Parameter2'
                    }

                    { Assert-RequiredCommandParameter @testParams } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }

        Context 'When the parameters in IfParameterPresent is present and the required parameters are not present' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSetWhenParameterExist -f "Parameter3', 'Parameter4", "Parameter1', 'Parameter2"

                    $testParams = @{
                        BoundParameterList = @{
                            Parameter1 = 'Value1'
                            Parameter2 = 'Value2'
                        }
                        RequiredParameter  = @('Parameter3', 'Parameter4')
                        RequiredBehavior   = 'All'
                        IfParameterPresent = @('Parameter1', 'Parameter2')
                    }

                    { Assert-RequiredCommandParameter @testParams } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }

        Context 'When the parameters in IfParameterPresent is present and required parameters are present' {
            It 'Should not throw an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        BoundParameterList = @{
                            Parameter1 = 'Value1'
                            Parameter2 = 'Value2'
                        }
                        RequiredParameter  = @('Parameter1', 'Parameter2')
                        RequiredBehavior   = 'All'
                        IfParameterPresent = @('Parameter1', 'Parameter2')
                    }

                    { Assert-RequiredCommandParameter @testParams } | Should -Not -Throw
                }
            }
        }
    }

    Context 'When RequiredBehavior is ''Any''' {
        Context 'When required parameter is missing' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.RequiredCommandParameter_SpecificParametersAtLeastOneMustBeSet -f 'Parameter1'

                    $testParams = @{
                        BoundParameterList = @{}
                        RequiredParameter  = 'Parameter1'
                        RequiredBehavior   = 'Any'
                    }

                    { Assert-RequiredCommandParameter @testParams } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }

        Context 'When the required parameter is present' {
            It 'Should not throw an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        BoundParameterList = @{
                            Parameter1 = 'Value1'
                        }
                        RequiredParameter  = 'Parameter1'
                        RequiredBehavior   = 'Any'
                    }
                }

                { Assert-RequiredCommandParameter @testParams | Should -Not -Throw }
            }
        }

        Context 'When both required parameter and parameter in IfParameterPresent is not present' {
            It 'Should not throw an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        BoundParameterList = @{}
                        RequiredParameter  = 'Parameter1'
                        RequiredBehavior   = 'Any'
                        IfParameterPresent = 'Parameter2'
                    }

                    { Assert-RequiredCommandParameter @testParams } | Should -Not -Throw
                }
            }
        }

        Context 'When the required parameter is not present and parameter in IfParameterPresent is present' {
            It 'Should throw the correct error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $mockErrorMessage = $script:localizedData.RequiredCommandParameter_SpecificParametersAtLeastOneMustBeSetWhenParameterExist -f 'Parameter1', 'Parameter2'

                    $testParams = @{
                        BoundParameterList = @{
                            Parameter2 = 'Value2'
                        }
                        RequiredParameter  = 'Parameter1'
                        RequiredBehavior   = 'Any'
                        IfParameterPresent = 'Parameter2'
                    }

                    { Assert-RequiredCommandParameter @testParams } | Should -Throw -ExpectedMessage $mockErrorMessage
                }
            }
        }

        Context 'When the parameters in IfParameterPresent is present and one of the required parameters are present' {
            It 'Should not throw an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        BoundParameterList = @{
                            Parameter1 = 'Value1'
                            Parameter2 = 'Value2'
                        }
                        RequiredParameter  = @('Parameter1', 'Parameter2', 'Parameter3')
                        RequiredBehavior   = 'Any'
                        IfParameterPresent = @('Parameter1', 'Parameter2')
                    }

                    { Assert-RequiredCommandParameter @testParams } | Should -Not -Throw
                }
            }
        }
    }
}
