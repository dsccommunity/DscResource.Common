BeforeAll {
    $script:moduleName = 'DscResource.Common'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

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
            MockParameterSetName = 'MutuallyExclusiveParameters'
            # cSpell: disable-next
            MockExpectedParameters = '-BoundParameterList <hashtable> -MutuallyExclusiveList1 <string[]> -MutuallyExclusiveList2 <string[]> [<CommonParameters>]'
        }
        @{
            MockParameterSetName = 'RequiredParameter'
            # cSpell: disable-next
            MockExpectedParameters = '-BoundParameterList <hashtable> -RequiredParameter <string[]> [-IfParameterPresent <string[]>] [<CommonParameters>]'
        }
    ) {
        InModuleScope -Parameters $_ -ScriptBlock {
            $result = (Get-Command -Name 'Assert-BoundParameter').ParameterSets |
                Where-Object -FilterScript {
                    $_.Name -eq $mockParameterSetName
                } |
                Select-Object -Property @(
                    @{
                        Name = 'ParameterSetName'
                        Expression = { $_.Name }
                    },
                    @{
                        Name = 'ParameterListAsString'
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
                        BoundParameterList = @{}
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
                        BoundParameterList = @{
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
                        BoundParameterList = @{
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
                        BoundParameterList = @{
                            param1 = 'value1'
                        }
                        MutuallyExclusiveList1 = @('param1')
                        MutuallyExclusiveList2 = @('param2')
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
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
                        BoundParameterList = @{
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
                        BoundParameterList = @{
                            param1 = 'value1'
                            param2 = 'value2'
                            param3 = 'value3'
                            param4 = 'value4'
                        }
                        MutuallyExclusiveList1 = @('param1','param2')
                        MutuallyExclusiveList2 = @('param3','param4')
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw -ExpectedMessage "$errorMessage*"
            }
        }
    }
}
