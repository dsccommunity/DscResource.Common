BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
}

Describe 'Assert-BoundParameter' -Tag 'AssertBoundParameter' {
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
