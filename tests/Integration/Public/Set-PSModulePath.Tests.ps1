BeforeAll {
    $script:moduleName = 'DscResource.Common'

    #region HEADER
    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
    #endregion HEADER
}

Describe 'Set-PSModulePath' -Tag 'SetPSModulePath' {
    # Determines if we should skip tests.
    if ($isWindows -or $PSEdition -eq 'Desktop')
    {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

        $skipTest = -not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    else
    {
        $skipTest = $true
    }

    Context 'When updating the session environment variable PSModulePath' {
        BeforeAll {
            $currentPSModulePath = $env:PSModulePath
        }

        AfterEach {
            $env:PSModulePath = $currentPSModulePath
        }

        It 'Should not throw an error and have set the correct value' {
            { Set-PSModulePath -Path 'C:\Module' } | Should -Not -Throw

            $env:PSModulePath | Should -Be 'C:\Module'
        }

        It 'Should have returned the session PSModulePath to the original value' {
            $env:PSModulePath | Should -Be $currentPSModulePath
        }
    }

    Context 'When updating the machine environment variable PSModulePath' -Skip:$skipTest {
        BeforeAll {
            $currentMachinePSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
        }

        AfterEach {
            [System.Environment]::SetEnvironmentVariable('PSModulePath', $currentMachinePSModulePath, [System.EnvironmentVariableTarget]::Machine)
        }

        It 'Should not throw an error and have set the correct value' {
            { Set-PSModulePath -Path 'C:\Module' -Machine } | Should -Not -Throw

            [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine') | Should -Be 'C:\Module'
        }

        It 'Should have returned the machine PSModulePath to the original value' -Skip:$skipTest {
            [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine') | Should -Be $currentMachinePSModulePath
        }
    }
}

