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

Describe 'Assert-BoundParameter' -Tag 'AssertBoundParameter' {
    It 'Should have the correct parameters in parameter set <MockParameterSetName>' -ForEach @(
        @{
            MockParameterSetName   = 'MutuallyExclusiveParameters'
            # cSpell: disable-next
            MockExpectedParameters = '-BoundParameterList <hashtable> -MutuallyExclusiveList1 <string[]> -MutuallyExclusiveList2 <string[]> [-IfParameterPresent <object>] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'RequiredParameter'
            # cSpell: disable-next
            MockExpectedParameters = '-BoundParameterList <hashtable> -RequiredParameter <string[]> [-RequiredBehavior <BoundParameterBehavior>] [-IfParameterPresent <object>] [<CommonParameters>]'
        }
        @{
            MockParameterSetName   = 'AtLeastOne'
            # cSpell: disable-next
            MockExpectedParameters = '-BoundParameterList <hashtable> -AtLeastOneList <string[]> [-IfParameterPresent <object>] [<CommonParameters>]'
        }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            $result = (Get-Command -Name 'Assert-BoundParameter').ParameterSets |
                Where-Object -FilterScript {
                    $_.Name -eq $mockParameterSetName
                } |
                    Select-Object -Property @(
                        @{
                            Name       = 'ParameterSetName'
                            Expression = { $_.Name }
                        },
                        @{
                            Name       = 'ParameterListAsString'
                            Expression = { $_.ToString() }
                        }
                    )

            $result.ParameterSetName | Should -Be $MockParameterSetName
            $result.ParameterListAsString | Should -Be $MockExpectedParameters
        }
    }

    Context 'When the assert is successful' {
        Context 'When there are no bound parameters' {
            It 'Should not throw an error' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{}
                        MutuallyExclusiveList1 = @('a')
                        MutuallyExclusiveList2 = @('b')
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }
        }

        Context 'When there are one bound parameters' {
            It 'Should not throw an error' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{
                            param1 = 'value1'
                        }
                        MutuallyExclusiveList1 = @('a')
                        MutuallyExclusiveList2 = @('b')
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }
        }

        Context 'When there are two bound parameters' {
            It 'Should not throw an error' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{
                            param1 = 'value1'
                            param2 = 'value2'
                        }
                        MutuallyExclusiveList1 = @('a', 'b')
                        MutuallyExclusiveList2 = @('c', 'd')
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }
        }

        Context 'When there are only one parameter matching a value in an exclusive list' {
            It 'Should not throw an error' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{
                            param1 = 'value1'
                        }
                        MutuallyExclusiveList1 = @('param1')
                        MutuallyExclusiveList2 = @('param2')
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }
        }

        Context 'When the required parameter is present' {
            BeforeAll {
                Mock -CommandName Assert-RequiredCommandParameter -ParameterFilter {
                    $RequiredBehavior -eq 'All'
                }
            }

            It 'Should pass the correct value for ''RequiredBehavior''' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        BoundParameterList = @{
                            Parameter1 = 'Value1'
                        }

                        RequiredParameter  = 'Parameter1'
                    }

                    { Assert-BoundParameter @testParams } | Should -Not -Throw
                }

                Should -Invoke -CommandName Assert-RequiredCommandParameter -ParameterFilter {
                    $RequiredBehavior -eq 'All'
                } -Exactly -Times 1 -Scope It
            }

            It 'Should not throw an error' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $testParams = @{
                        BoundParameterList = @{
                            Parameter1 = 'Value1'
                        }

                        RequiredParameter  = 'Parameter1'
                    }

                    { Assert-BoundParameter @testParams } | Should -Not -Throw
                }
            }
        }

        Context 'When using the AtLeastOne parameter set' {
            Context 'When at least one parameter from the list is bound' {
                It 'Should not throw an error' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                Severity = 'Warning'
                                OtherParam = 'value'
                            }
                            AtLeastOneList = @('Severity', 'MessageId')
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }

            Context 'When multiple parameters from the list are bound' {
                It 'Should not throw an error' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                Severity = 'Warning'
                                MessageId = '12345'
                                OtherParam = 'value'
                            }
                            AtLeastOneList = @('Severity', 'MessageId')
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }
        }
    }

    Context 'When the assert fails' {
        Context 'When using parameters that are mutually exclusive' {
            It 'Should throw an error' {
                $errorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.ParameterUsageWrong
                }

                $errorMessage = $errorMessage -f 'param1', 'param2'

                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{
                            param1 = 'value1'
                            param2 = 'value1'
                        }
                        MutuallyExclusiveList1 = @('param1')
                        MutuallyExclusiveList2 = @('param2')
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw -ExpectedMessage "$errorMessage*"
            }
        }

        Context 'When using several parameters that are mutually exclusive' {
            It 'Should throw an error' {
                $errorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.ParameterUsageWrong
                }

                $errorMessage = $errorMessage -f "param1','param2", "param3','param4"

                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{
                            param1 = 'value1'
                            param2 = 'value2'
                            param3 = 'value3'
                            param4 = 'value4'
                        }
                        MutuallyExclusiveList1 = @('param1', 'param2')
                        MutuallyExclusiveList2 = @('param3', 'param4')
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw -ExpectedMessage "$errorMessage*"
            }
        }

        Context 'When using the AtLeastOne parameter set and none of the required parameters are bound' {
            It 'Should throw an error' {
                $errorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.Assert_BoundParameter_AtLeastOneParameterMustBeSet
                }

                $errorMessage = $errorMessage -f "Severity','MessageId"

                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            OtherParam = 'value'
                        }
                        AtLeastOneList = @('Severity', 'MessageId')
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw -ExpectedMessage "$errorMessage*"
            }
        }

        Context 'When the required parameter is not present' {
            BeforeAll {
                Mock -CommandName Assert-RequiredCommandParameter -MockWith {
                    throw 'Mocked error'
                }
            }

            It 'Should not throw an error' {
                InModuleScope -ScriptBlock {
                    { Assert-BoundParameter -BoundParameterList @{} -RequiredParameter 'Parameter1' } |
                        Should -Throw -ExpectedMessage '*Mocked error*'
                }
            }
        }
    }

    Context 'When using IfEqualParameterList parameter' {
        Context 'When using MutuallyExclusiveParameters parameter set' {
            Context 'When the IfEqualParameterList condition is met' {
                It 'Should throw an error when mutually exclusive parameters are both present' {
                    $errorMessage = InModuleScope -ScriptBlock {
                        $script:localizedData.ParameterUsageWrong
                    }

                    $errorMessage = $errorMessage -f "Severity", "MessageId"

                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                Severity = 'High'
                                MessageId = '12345'
                                Ensure = 'Present'
                            }
                            MutuallyExclusiveList1 = @('Severity')
                            MutuallyExclusiveList2 = @('MessageId')
                            IfEqualParameterList = @{
                                Ensure = 'Present'
                            }
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Throw -ExpectedMessage "$errorMessage*"
                }

                It 'Should not throw an error when mutually exclusive parameters are not both present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                Severity = 'High'
                                Ensure = 'Present'
                            }
                            MutuallyExclusiveList1 = @('Severity')
                            MutuallyExclusiveList2 = @('MessageId')
                            IfEqualParameterList = @{
                                Ensure = 'Present'
                            }
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }

            Context 'When the IfEqualParameterList condition is not met' {
                It 'Should not throw an error even when mutually exclusive parameters are both present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                Severity = 'High'
                                MessageId = '12345'
                                Ensure = 'Absent'
                            }
                            MutuallyExclusiveList1 = @('Severity')
                            MutuallyExclusiveList2 = @('MessageId')
                            IfEqualParameterList = @{
                                Ensure = 'Present'
                            }
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }

                It 'Should not throw an error when the parameter in IfEqualParameterList is not present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                Severity = 'High'
                                MessageId = '12345'
                            }
                            MutuallyExclusiveList1 = @('Severity')
                            MutuallyExclusiveList2 = @('MessageId')
                            IfEqualParameterList = @{
                                Ensure = 'Present'
                            }
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }

            Context 'When multiple conditions in IfEqualParameterList must match' {
                It 'Should throw an error when all conditions are met and mutually exclusive parameters are present' {
                    $errorMessage = InModuleScope -ScriptBlock {
                        $script:localizedData.ParameterUsageWrong
                    }

                    $errorMessage = $errorMessage -f "Severity", "MessageId"

                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                Severity = 'High'
                                MessageId = '12345'
                                Ensure = 'Present'
                                Type = 'Server'
                            }
                            MutuallyExclusiveList1 = @('Severity')
                            MutuallyExclusiveList2 = @('MessageId')
                            IfEqualParameterList = @{
                                Ensure = 'Present'
                                Type = 'Server'
                            }
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Throw -ExpectedMessage "$errorMessage*"
                }

                It 'Should not throw an error when only some conditions are met' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                Severity = 'High'
                                MessageId = '12345'
                                Ensure = 'Present'
                                Type = 'Client'
                            }
                            MutuallyExclusiveList1 = @('Severity')
                            MutuallyExclusiveList2 = @('MessageId')
                            IfEqualParameterList = @{
                                Ensure = 'Present'
                                Type = 'Server'
                            }
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }
        }

        Context 'When using RequiredParameter parameter set' {
            BeforeAll {
                Mock -CommandName Assert-RequiredCommandParameter
            }

            Context 'When the IfEqualParameterList condition is met' {
                It 'Should call Assert-RequiredCommandParameter when condition is met' {
                    InModuleScope -ScriptBlock {
                        $testParams = @{
                            BoundParameterList = @{
                                Property1 = 'SpecificValue'
                                Property2 = 'Value2'
                            }
                            RequiredParameter = @('Property2', 'Property3')
                            IfEqualParameterList = @{
                                Property1 = 'SpecificValue'
                            }
                        }

                        Assert-BoundParameter @testParams
                    }

                    Should -Invoke -CommandName Assert-RequiredCommandParameter -Exactly -Times 1 -Scope It
                }
            }

            Context 'When the IfEqualParameterList condition is not met' {
                It 'Should not call Assert-RequiredCommandParameter when condition is not met' {
                    InModuleScope -ScriptBlock {
                        $testParams = @{
                            BoundParameterList = @{
                                Property1 = 'DifferentValue'
                                Property2 = 'Value2'
                            }
                            RequiredParameter = @('Property2', 'Property3')
                            IfEqualParameterList = @{
                                Property1 = 'SpecificValue'
                            }
                        }

                        Assert-BoundParameter @testParams
                    }

                    Should -Invoke -CommandName Assert-RequiredCommandParameter -Exactly -Times 0 -Scope It
                }
            }
        }

        Context 'When using AtLeastOne parameter set' {
            Context 'When the IfEqualParameterList condition is met' {
                It 'Should throw an error when none of the required parameters are present' {
                    $errorMessage = InModuleScope -ScriptBlock {
                        $script:localizedData.Assert_BoundParameter_AtLeastOneParameterMustBeSet
                    }

                    $errorMessage = $errorMessage -f "Severity','MessageId"

                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                Ensure = 'Present'
                                OtherParam = 'value'
                            }
                            AtLeastOneList = @('Severity', 'MessageId')
                            IfEqualParameterList = @{
                                Ensure = 'Present'
                            }
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Throw -ExpectedMessage "$errorMessage*"
                }

                It 'Should not throw an error when at least one required parameter is present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                Severity = 'High'
                                Ensure = 'Present'
                            }
                            AtLeastOneList = @('Severity', 'MessageId')
                            IfEqualParameterList = @{
                                Ensure = 'Present'
                            }
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }

            Context 'When the IfEqualParameterList condition is not met' {
                It 'Should not throw an error even when none of the required parameters are present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                Ensure = 'Absent'
                                OtherParam = 'value'
                            }
                            AtLeastOneList = @('Severity', 'MessageId')
                            IfEqualParameterList = @{
                                Ensure = 'Present'
                            }
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }

                It 'Should not throw an error when the parameter in IfEqualParameterList is not present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList = @{
                                OtherParam = 'value'
                            }
                            AtLeastOneList = @('Severity', 'MessageId')
                            IfEqualParameterList = @{
                                Ensure = 'Present'
                            }
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }
        }
    }
}
