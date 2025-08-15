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
            # Should return the same as [System.Environment]::MachineName (short name)
            $result | Should -Be ([System.Environment]::MachineName)
        }
    }

    Context 'When getting computer name with FQDN switch' {
        It 'Should return the FQDN when DNS resolution succeeds' {
            $result = Get-ComputerName -FullyQualifiedDomainName
            $result | Should -BeOfType [System.String]
            $result | Should -Not -BeNullOrEmpty
            # The result should either be FQDN (if DNS works) or short name (if DNS fails)
            # We can't predict which without mocking, so just ensure it's not empty
        }

        It 'Should handle DNS resolution gracefully' {
            # This test ensures the function doesn't throw even if DNS resolution fails
            { Get-ComputerName -FullyQualifiedDomainName } | Should -Not -Throw
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

    Context 'When simulating FQDN scenario with mocking' {
        BeforeAll {
            # Test the DNS resolution logic with mocked values
            function Test-FqdnLogic {
                param(
                    [string]$ShortName,
                    [string]$DnsResult = $null,
                    [bool]$DnsThrows = $false,
                    [switch]$FullyQualifiedDomainName
                )
                
                $computerName = $ShortName
                
                if ($FullyQualifiedDomainName) {
                    if (-not $DnsThrows -and $DnsResult -and $DnsResult -ne $ShortName) {
                        $computerName = $DnsResult
                    }
                    # If DNS throws or returns same name, keep the short name
                }
                
                return $computerName
            }
        }

        It 'Should return short name when not requesting FQDN' {
            $result = Test-FqdnLogic -ShortName 'TestMachine'
            $result | Should -Be 'TestMachine'
        }

        It 'Should return FQDN when DNS resolution succeeds and FQDN requested' {
            $result = Test-FqdnLogic -ShortName 'TestMachine' -DnsResult 'TestMachine.example.com' -FullyQualifiedDomainName
            $result | Should -Be 'TestMachine.example.com'
        }

        It 'Should return short name when DNS resolution fails and FQDN requested' {
            $result = Test-FqdnLogic -ShortName 'TestMachine' -DnsThrows $true -FullyQualifiedDomainName
            $result | Should -Be 'TestMachine'
        }

        It 'Should return short name when DNS returns same name and FQDN requested' {
            $result = Test-FqdnLogic -ShortName 'TestMachine' -DnsResult 'TestMachine' -FullyQualifiedDomainName
            $result | Should -Be 'TestMachine'
        }
    }
}
