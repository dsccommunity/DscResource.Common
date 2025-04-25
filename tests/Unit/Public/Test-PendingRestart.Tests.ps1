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

Describe 'Test-PendingRestart' {
    BeforeAll {
        Mock -CommandName Get-RegistryPropertyValue -MockWith {
            return $null
        }

        Mock -CommandName Get-ItemProperty -MockWith {
            return [PSCustomObject] @{
                ComputerName = 'TestComputer'
            }
        }
    }

    Context 'When running on a non-Windows system' -Skip:($IsWindows -or $PSEdition -eq 'Desktop') {
        BeforeAll {
            Mock -CommandName Write-Error
        }

        It 'Should write an error and return $false' {
            Test-PendingRestart | Should -BeFalse

            Should -Invoke -CommandName Write-Error -Exactly -Times 1 -Scope It
        }
    }

    Context 'When all checks return no pending restart' -Skip:($IsLinux -or $IsMacOS) {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith { return $null }

            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Path -match 'ActiveComputerName$')
                {
                    return @{
                        ComputerName = 'COMPUTER1'
                    }
                }
                elseif ($Path -match 'ComputerName$')
                {
                    return @{
                        ComputerName = 'COMPUTER1'
                    }
                }
            }
        }

        It 'Should return $false' {
            Test-PendingRestart | Should -BeFalse
        }
    }

    Context 'When ComponentBasedServicing check returns pending restart' -Skip:($IsLinux -or $IsMacOS) {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                if ($Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending')
                {
                    return @{
                        RebootPending = 1
                    }
                }

                return $null
            }
        }

        It 'Should return $true' {
            Test-PendingRestart | Should -BeTrue
        }

        It 'Should return $true when only ComponentBasedServicing check is specified' {
            $mockCheckValue = InModuleScope -ScriptBlock {
                [PendingRestartCheck]::ComponentBasedServicing
            }

            Test-PendingRestart -Check $mockCheckValue | Should -BeTrue
        }

        It 'Should return $false when only WindowsUpdate check is specified' {
            $mockCheckValue = InModuleScope -ScriptBlock {
                [PendingRestartCheck]::WindowsUpdate
            }

            Test-PendingRestart -Check $mockCheckValue | Should -BeFalse
        }
    }

    Context 'When WindowsUpdate check returns pending restart' -Skip:($IsLinux -or $IsMacOS) {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                if ($Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
                {
                    return @{
                        RebootRequired = 1
                    }
                }

                return $null
            }
        }

        It 'Should return $true' {
            Test-PendingRestart | Should -BeTrue
        }

        It 'Should return $false when only ComponentBasedServicing check is specified' {
            $mockCheckValue = InModuleScope -ScriptBlock {
                [PendingRestartCheck]::ComponentBasedServicing
            }

            Test-PendingRestart -Check $mockCheckValue | Should -BeFalse
        }

        It 'Should return $true when only WindowsUpdate check is specified' {
            $mockCheckValue = InModuleScope -ScriptBlock {
                [PendingRestartCheck]::WindowsUpdate
            }

            Test-PendingRestart -Check $mockCheckValue | Should -BeTrue
        }
    }

    Context 'When PendingFileRename check returns pending restart' -Skip:($IsLinux -or $IsMacOS) {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                if ($Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -and $Name -eq 'PendingFileRenameOperations')
                {
                    return @{
                        PendingFileRenameOperations = @('file1', 'file2')
                    }
                }

                return $null
            }
        }

        It 'Should return $true' {
            Test-PendingRestart | Should -BeTrue
        }

        It 'Should return $true when only PendingFileRename check is specified' {
            $mockCheckValue = InModuleScope -ScriptBlock {
                [PendingRestartCheck]::PendingFileRename
            }

            Test-PendingRestart -Check $mockCheckValue | Should -BeTrue
        }
    }

    Context 'When PendingComputerRename check returns pending restart' -Skip:($IsLinux -or $IsMacOS) {
        BeforeAll {
            Mock -CommandName Get-ItemProperty -MockWith {
                if ($Path -match 'ActiveComputerName$')
                {
                    return @{
                        ComputerName = 'COMPUTER1'
                    }
                }
                elseif ($Path -match 'ComputerName$')
                {
                    return @{
                        ComputerName = 'COMPUTER2'
                    }
                }

                return $null
            }
        }

        It 'Should return $true' {
            Test-PendingRestart | Should -BeTrue
        }

        It 'Should return $true when only PendingComputerRename check is specified' {
            $mockCheckValue = InModuleScope -ScriptBlock {
                [PendingRestartCheck]::PendingComputerRename
            }

            Test-PendingRestart -Check $mockCheckValue | Should -BeTrue
        }
    }

    Context 'When PendingDomainJoin check returns pending restart' -Skip:($IsLinux -or $IsMacOS) {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                # cSpell:ignore Netlogon
                if ($Path -eq 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon' -and $Name -eq 'JoinDomain')
                {
                    return @{
                        JoinDomain = 1
                    }
                }

                return $null
            }
        }

        It 'Should return $true' {
            Test-PendingRestart | Should -BeTrue
        }

        It 'Should return $true when only PendingDomainJoin check is specified' {
            $mockCheckValue = InModuleScope -ScriptBlock {
                [PendingRestartCheck]::PendingDomainJoin
            }

            Test-PendingRestart -Check $mockCheckValue | Should -BeTrue
        }
    }

    Context 'When ConfigurationManagerClient check returns pending restart' -Skip:($IsLinux -or $IsMacOS) {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                if ($Path -eq 'HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Reboot Management\RebootData')
                {
                    return @{
                        RebootData = 1
                    }
                }

                return $null
            }
        }

        It 'Should return $true' {
            Test-PendingRestart | Should -BeTrue
        }

        It 'Should return $true when only ConfigurationManagerClient check is specified' {
            $mockCheckValue = InModuleScope -ScriptBlock {
                [PendingRestartCheck]::ConfigurationManagerClient
            }

            Test-PendingRestart -Check $mockCheckValue | Should -BeTrue
        }
    }

    Context 'When multiple checks are specified' -Skip:($IsLinux -or $IsMacOS) {
        BeforeAll {
            Mock -CommandName Get-RegistryPropertyValue -MockWith {
                if ($Path -eq 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
                {
                    return @{
                        RebootRequired = 1
                    }
                }

                return $null
            }
        }

        It 'Should return $true when one of the checks returns true' {
            $mockCheckValue = InModuleScope -ScriptBlock {
                [PendingRestartCheck]::WindowsUpdate -bor [PendingRestartCheck]::ComponentBasedServicing
            }

            Test-PendingRestart -Check $mockCheckValue | Should -BeTrue
        }
    }
}
