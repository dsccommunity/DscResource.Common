BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
}

Describe 'Set-DscMachineRebootRequired' -Tag 'Set-DscMachineRebootRequired' {
    BeforeAll {
        $script:currentDSCMachineStatus = $global:DSCMachineStatus
    }

    Context 'When setting the DSC reboot status' {
        BeforeAll {
            $global:DSCMachineStatus = 0
        }

        AfterAll {
            if ($script:currentDSCMachineStatus -ne $global:DSCMachineStatus)
            {
                $global:DSCMachineStatus = $script:currentDSCMachineStatus
            }
        }

        It 'Should not throw an error and have set the correct value' {
            { Set-DscMachineRebootRequired } | Should -Not -Throw

            $global:DSCMachineStatus | Should -Be 1
        }
    }

    It 'Should have reverted the value of $global:DSCMachineStatus' {
        $global:DSCMachineStatus | Should -Be $script:currentDSCMachineStatus
    }
}
