BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
}

Describe 'Assert-Module' {
    BeforeAll {
        $testModuleName = 'TestModule'
    }

    Context 'When module is not installed' {
        BeforeAll {
            Mock -CommandName Get-Module
        }

        It 'Should throw the correct error' {
            { Assert-Module -ModuleName $testModuleName -Verbose } | `
                    Should -Throw ($script:localizedData.RoleNotFound -f $testModuleName)
        }
    }

    Context 'When module is installed' {
        Context 'When module is already present in session' {
            BeforeAll {
                Mock -CommandName Import-Module
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = $testModuleName
                    }
                }
            }

            Context 'When asserting that module is available' {
                It 'Should not throw an error' {
                    { Assert-Module -ModuleName $testModuleName } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Should -Invoke -CommandName Import-Module -Exactly -Times 0
                }
            }

            Context 'When using ImportModule but module is already imported' {
                It 'Should not throw an error' {
                    { Assert-Module -ModuleName $testModuleName -ImportModule } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Should -Invoke -CommandName Import-Module -Exactly -Times 0
                }
            }

            Context 'When module should be forcibly imported' {
                It 'Should not throw an error' {
                    { Assert-Module -ModuleName $testModuleName -ImportModule -Force } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Should -Invoke -CommandName Import-Module -ParameterFilter {
                        $Force -eq $true
                    } -Exactly -Times 1
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
                        Name = $testModuleName
                    }
                } -ParameterFilter {
                    $ListAvailable -eq $true
                }
            }

            Context 'When module should be imported' {
                It 'Should not throw an error' {
                    { Assert-Module -ModuleName $testModuleName -ImportModule } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Should -Invoke -CommandName Import-Module -Exactly -Times 1
                }
            }
        }
    }
}
