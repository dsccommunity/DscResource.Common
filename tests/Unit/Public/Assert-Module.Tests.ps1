BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')
}

Describe 'Assert-Module' {
    Context 'When module is not installed' {
        BeforeAll {
            Mock -CommandName Get-Module
        }

        It 'Should throw the correct error' {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.RoleNotFound -f 'TestModule'
            }

            { Assert-Module -ModuleName 'TestModule' -Verbose } | `
                    Should -Throw -ExpectedMessage $mockErrorMessage
        }
    }

    Context 'When module is installed' {
        Context 'When module is already present in session' {
            BeforeAll {
                Mock -CommandName Import-Module
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                    }
                }
            }

            Context 'When asserting that module is available' {
                It 'Should not throw an error' {
                    { Assert-Module -ModuleName 'TestModule' } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When using ImportModule but module is already imported' {
                It 'Should not throw an error' {
                    { Assert-Module -ModuleName 'TestModule' -ImportModule } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Should -Invoke -CommandName Import-Module -Exactly -Times 0 -Scope Context
                }
            }

            Context 'When module should be forcibly imported' {
                It 'Should not throw an error' {
                    { Assert-Module -ModuleName 'TestModule' -ImportModule -Force } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Should -Invoke -CommandName Import-Module -ParameterFilter {
                        $Force -eq $true
                    } -Exactly -Times 1 -Scope Context
                }
            }
        }

        Context 'When module is not present in the session' {
            BeforeAll {
                Mock -CommandName Import-Module
                Mock -CommandName Get-Module -MockWith {
                    return $null
                } -ParameterFilter {
                    $ListAvailable -eq $false
                }

                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                    }
                } -ParameterFilter {
                    $ListAvailable -eq $true
                }
            }

            Context 'When module should be imported' {
                It 'Should not throw an error' {
                    { Assert-Module -ModuleName 'TestModule' -ImportModule } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Should -Invoke -CommandName Import-Module -Exactly -Times 1 -Scope Context
                }
            }
        }
    }
}
