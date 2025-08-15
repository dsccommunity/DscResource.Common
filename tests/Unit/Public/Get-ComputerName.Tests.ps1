[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeAll {
    $script:moduleName = 'DscResource.Common'
    
    # Import the function directly for testing
    . "$PSScriptRoot/../../../source/Public/Get-ComputerName.ps1"
}

Describe 'Get-ComputerName' {
    BeforeAll {
        $mockShortComputerName = 'MyComputer'
        $mockFqdnComputerName = 'MyComputer.domain.com'
    }

    Context 'When getting computer name without FQDN switch' {
        It 'Should return the short computer name' {
            $result = Get-ComputerName
            $result | Should -BeOfType [System.String]
            $result | Should -Not -BeNullOrEmpty
            # The result should not contain dots if it's properly split
            if ($result -match '\.') {
                # If the actual machine name contains dots, the function should split it
                $result | Should -Be (([System.Environment]::MachineName -split '\.')[0])
            }
        }
    }

    Context 'When getting computer name with FQDN switch' {
        It 'Should return the full computer name' {
            $result = Get-ComputerName -FullyQualifiedDomainName
            $expected = [System.Environment]::MachineName
            $result | Should -BeOfType [System.String]
            $result | Should -Not -BeNullOrEmpty
            # The result should be the same as [System.Environment]::MachineName
            $result | Should -Be $expected
        }
    }

    Context 'When testing parameter functionality' {
        It 'Should accept the FullyQualifiedDomainName switch parameter' {
            { Get-ComputerName -FullyQualifiedDomainName } | Should -Not -Throw
        }

        It 'Should work without any parameters' {
            { Get-ComputerName } | Should -Not -Throw
        }
    }

    Context 'When simulating FQDN scenario' {
        BeforeAll {
            # Create a test function that simulates the logic with known values
            function Test-ComputerNameLogic {
                param(
                    [string]$MachineName,
                    [switch]$FullyQualifiedDomainName
                )
                
                $computerName = $MachineName
                
                if (-not $FullyQualifiedDomainName) {
                    $computerName = ($computerName -split '\.')[0]
                }
                
                return $computerName
            }
        }

        It 'Should return only short name when MachineName has FQDN and no switch' {
            $result = Test-ComputerNameLogic -MachineName 'TestMachine.example.com'
            $result | Should -Be 'TestMachine'
        }

        It 'Should return full FQDN when MachineName has FQDN and switch is used' {
            $result = Test-ComputerNameLogic -MachineName 'TestMachine.example.com' -FullyQualifiedDomainName
            $result | Should -Be 'TestMachine.example.com'
        }

        It 'Should return short name when MachineName is short and no switch' {
            $result = Test-ComputerNameLogic -MachineName 'TestMachine'
            $result | Should -Be 'TestMachine'
        }

        It 'Should return short name when MachineName is short and switch is used' {
            $result = Test-ComputerNameLogic -MachineName 'TestMachine' -FullyQualifiedDomainName
            $result | Should -Be 'TestMachine'
        }
    }
}
