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

Describe 'Get-PSModulePath' {
    Context 'When using parameter FromTarget' {
        Context 'When returning unique path' {
            BeforeAll {
                Mock -CommandName Get-EnvironmentVariable -MockWith {
                    return '/tmp/path'
                }
            }

            Context 'When getting the PSModulePath session environment variable' {
                It 'Should return the correct path' {
                    Get-PSModulePath -FromTarget 'Session' | Should -Be '/tmp/path'

                    Should -Invoke -CommandName Get-EnvironmentVariable -Exactly -Times 1 -Scope It
                }
            }

            Context 'When getting the PSModulePath user environment variable' {
                It 'Should return the correct path' {
                    Get-PSModulePath -FromTarget 'User' | Should -Be '/tmp/path'

                    Should -Invoke -CommandName Get-EnvironmentVariable -Exactly -Times 1 -Scope It
                }
            }

            Context 'When getting the PSModulePath machine environment variable' {
                It 'Should return the correct path' {
                    Get-PSModulePath -FromTarget 'Machine' | Should -Be '/tmp/path'

                    Should -Invoke -CommandName Get-EnvironmentVariable -Exactly -Times 1 -Scope It
                }
            }

            Context 'When getting the PSModulePath machine environment variable' {
                It 'Should return the correct unique path' {
                    Get-PSModulePath -FromTarget 'Machine', 'User', 'Session' | Should -Be '/tmp/path'

                    Should -Invoke -CommandName Get-EnvironmentVariable -Exactly -Times 3 -Scope It
                }
            }
        }

        Context 'When returning different paths from scopes' {
            BeforeAll {
                Mock -CommandName Get-EnvironmentVariable -MockWith {
                    switch ($PesterBoundParameters.FromTarget)
                    {
                        'Session'
                        {
                            return '/tmp/session_path'
                        }

                        'User'
                        {
                            return '/tmp/user_path'
                        }

                        'Machine'
                        {
                            return '/tmp/machine_path'
                        }

                        default
                        {
                            return $null
                        }
                    }
                }
            }

            Context 'When getting the PSModulePath from Session' {
                It 'Should return the correct session path' {
                    Get-PSModulePath -FromTarget 'Session' | Should -Be '/tmp/session_path'

                    Should -Invoke -CommandName Get-EnvironmentVariable -ParameterFilter {
                        $FromTarget -eq 'Session'
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When getting the PSModulePath from User' {
                It 'Should return the correct user path' {
                    Get-PSModulePath -FromTarget 'User' | Should -Be '/tmp/user_path'

                    Should -Invoke -CommandName Get-EnvironmentVariable -ParameterFilter {
                        $FromTarget -eq 'User'
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When getting the PSModulePath from Machine' {
                It 'Should return the correct machine path' {
                    Get-PSModulePath -FromTarget 'Machine' | Should -Be '/tmp/machine_path'

                    Should -Invoke -CommandName Get-EnvironmentVariable -ParameterFilter {
                        $FromTarget -eq 'Machine'
                    } -Exactly -Times 1 -Scope It
                }
            }

            Context 'When getting the PSModulePath from all targets' {
                It 'Should return the correct concatenated path' {
                    $result = Get-PSModulePath -FromTarget 'Session', 'User', 'Machine'

                    $result | Should -Match '/tmp/session_path'
                    $result | Should -Match '/tmp/user_path'
                    $result | Should -Match '/tmp/machine_path'

                    Should -Invoke -CommandName Get-EnvironmentVariable -Exactly -Times 3 -Scope It
                }

                It 'Should have the correct path separator in the result' {
                    $result = Get-PSModulePath -FromTarget 'Session', 'User', 'Machine'

                    $result | Should -Match ([System.Text.RegularExpressions.Regex]::Escape([System.IO.Path]::PathSeparator))

                    Should -Invoke -CommandName Get-EnvironmentVariable -Exactly -Times 3 -Scope It
                }
            }
        }
    }

    Context 'When using parameter Scope' {
        Context 'When Scope is CurrentUser' {
            It 'Should return correct path on Linux or MacOS' -Skip:($IsWindows -or -not $IsCoreCLR) {
                $result = Get-PSModulePath -Scope 'CurrentUser'

                $result | Should -Be (Join-Path -Path $HOME -ChildPath '.local/share/powershell/Modules')
            }

            It 'Should return correct path on Windows with CoreCLR' -Skip:($IsLinux -or $IsMacOS -or -not $IsCoreCLR) {
                $result = Get-PSModulePath -Scope 'CurrentUser'

                $result | Should -Be ([Environment]::GetFolderPath('MyDocuments') | Join-Path -ChildPath 'PowerShell' | Join-Path -ChildPath 'Modules')
            }

            It 'Should return correct path on Windows without CoreCLR' -Skip:($IsLinux -or $IsMacOS -or $IsCoreCLR) {
                $result = Get-PSModulePath -Scope 'CurrentUser'

                $result | Should -Be ([Environment]::GetFolderPath('MyDocuments') | Join-Path -ChildPath 'WindowsPowerShell' | Join-Path -ChildPath 'Modules')
            }
        }

        Context 'When Scope is AllUsers' {
            It 'Should return correct path on Linux or MacOS' -Skip:($IsWindows -or -not $IsCoreCLR) {
                $result = Get-PSModulePath -Scope 'AllUsers'

                $result | Should -Be '/usr/local/share/powershell/Modules'
            }

            It 'Should return correct path on Windows' -Skip:($IsLinux -or $IsMacOS) {
                $result = Get-PSModulePath -Scope 'AllUsers'

                $result | Should -Be (Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell/Modules')
            }
        }

        Context 'When Scope is BuiltIn' {
            It 'Should return correct path' {
                $result = Get-PSModulePath -Scope 'BuiltIn'

                # cSPell: ignore PSHOME
                $result | Should -Be (Join-Path -Path $PSHOME -ChildPath 'Modules')
            }
        }
    }
}
