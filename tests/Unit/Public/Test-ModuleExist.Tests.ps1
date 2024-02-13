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

Describe 'Test-ModuleExist' {
    Context 'When checking if a module exists on the machine' {
        Context 'When module is unavailable' {
            BeforeAll {
                Mock -CommandName Get-Module -ParameterFilter { $ListAvailable -eq $true }
            }

            It 'Should return $false' {
                Test-ModuleExist -Name 'TestModule' -Verbose | Should -BeFalse
            }
        }

        Context 'When module is available' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                    }
                } -ParameterFilter { $ListAvailable -eq $true }
            }

            It 'Should return $true' {
                Test-ModuleExist -Name 'TestModule' -Verbose | Should -BeTrue
            }
        }
    }

    Context 'When checking if a module with a specific version exists on the machine' {
        Context 'When module is unavailable' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                        Version = '1.0.0'
                    }
                } -ParameterFilter { $ListAvailable -eq $true }
            }

            It 'Should return $false' {
                Test-ModuleExist -Name 'TestModule' -Version '1.1.1' -Verbose | Should -BeFalse
            }
        }

        Context 'When module is available' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                        Version = '1.1.1'
                    }
                } -ParameterFilter { $ListAvailable -eq $true }
            }

            It 'Should return $true' {
                Test-ModuleExist -Name 'TestModule' -Version '1.1.1' -Verbose | Should -BeTrue
            }
        }
    }

    Context 'When checking if a module with a specific preview version exists on the machine' {
        Context 'When module is unavailable' {
            Context 'When the module exists but has a different prerelease string' {
                BeforeAll {
                    Mock -CommandName Get-Module -MockWith {
                        return @{
                            Name = 'TestModule'
                            Version = '1.1.1'
                            PrivateData = @{
                                PSData = @{
                                    Prerelease = 'alpha'
                                }
                            }
                        }
                    } -ParameterFilter { $ListAvailable -eq $true }
                }

                It 'Should return $false' {
                    Test-ModuleExist -Name 'TestModule' -Version '1.1.1-preview1' -Verbose | Should -BeFalse
                }
            }

            Context 'When the module exists but has an empty prerelease string' {
                BeforeAll {
                    Mock -CommandName Get-Module -MockWith {
                        return @{
                            Name = 'TestModule'
                            Version = '1.1.1'
                            PrivateData = @{
                                PSData = @{
                                    Prerelease = ''
                                }
                            }
                        }
                    } -ParameterFilter { $ListAvailable -eq $true }
                }

                It 'Should return $false' {
                    Test-ModuleExist -Name 'TestModule' -Version '1.1.1-preview1' -Verbose | Should -BeFalse
                }
            }

            Context 'When the module exists with no prerelease string' {
                BeforeAll {
                    Mock -CommandName Get-Module -MockWith {
                        return @{
                            Name = 'TestModule'
                            Version = '1.1.1'
                        }
                    } -ParameterFilter { $ListAvailable -eq $true }
                }

                It 'Should return $false' {
                    Test-ModuleExist -Name 'TestModule' -Version '1.1.1-preview1' -Verbose | Should -BeFalse
                }
            }
        }

        Context 'When module is available' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                        Version = '1.1.1'
                        PrivateData = @{
                            PSData = @{
                                Prerelease = 'preview1'
                            }
                        }
                    }
                } -ParameterFilter { $ListAvailable -eq $true }
            }

            It 'Should return $true' {
                Test-ModuleExist -Name 'TestModule' -Version '1.1.1-preview1' -Verbose | Should -BeTrue
            }
        }
    }

    Context 'When checking if a module with a specific path exists' {
        Context 'When module is unavailable' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                        # Use the last path in the PSModulePath to simulate a module that is not available in a specified.
                        Path = ($env:PSModulePath -split [System.IO.Path]::PathSeparator)[-1]
                    }
                } -ParameterFilter { $ListAvailable -eq $true }
            }

            It 'Should return $false' {
                Test-ModuleExist -Name 'TestModule' -Path $TestDrive -Verbose | Should -BeFalse
            }
        }

        Context 'When module is available' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                        Path = Join-Path -Path $TestDrive -ChildPath 'TestModule'
                    }
                } -ParameterFilter { $ListAvailable -eq $true }
            }

            It 'Should return $true' {
                Test-ModuleExist -Name 'TestModule' -Path $TestDrive -Verbose | Should -BeTrue
            }
        }
    }

    Context 'When checking if a module in Scope CurrentUser exists' {
        Context 'When module is unavailable' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                        Path = Join-Path -Path $TestDrive -ChildPath 'TestModule'
                    }
                } -ParameterFilter { $ListAvailable -eq $true }
            }

            It 'Should return $false' {
                Test-ModuleExist -Name 'TestModule' -Scope 'CurrentUser' -Verbose | Should -BeFalse
            }
        }

        Context 'When module is available' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                        Path = (Get-PSModulePath -Scope 'CurrentUser')
                    }
                } -ParameterFilter { $ListAvailable -eq $true }
            }

            It 'Should return $true' {
                Test-ModuleExist -Name 'TestModule' -Scope 'CurrentUser' -Verbose | Should -BeTrue
            }
        }
    }

    Context 'When checking if a module in Scope AllUsers exists' {
        Context 'When module is unavailable' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                        Path = Join-Path -Path $TestDrive -ChildPath 'TestModule'
                    }
                } -ParameterFilter { $ListAvailable -eq $true }
            }

            It 'Should return $false' {
                Test-ModuleExist -Name 'TestModule' -Scope 'AllUsers' -Verbose | Should -BeFalse
            }
        }

        Context 'When module is available' {
            BeforeAll {
                Mock -CommandName Get-Module -MockWith {
                    return @{
                        Name = 'TestModule'
                        Path = (Get-PSModulePath -Scope 'AllUsers')
                    }
                } -ParameterFilter { $ListAvailable -eq $true }
            }

            It 'Should return $true' {
                Test-ModuleExist -Name 'TestModule' -Scope 'AllUsers' -Verbose | Should -BeTrue
            }
        }
    }
}
