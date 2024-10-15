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

        Context 'When module is not present in the session PS5' -Skip:($PSVersionTable.PSVersion.Major -gt 5) {
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

        Context 'When module is not present in the session PS6+' -Skip:($PSVersionTable.PSVersion.Major -lt 6) {
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
                    $ListAvailable -eq $true -and
                    $SkipEditionCheck -eq $true
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
