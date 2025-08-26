BeforeAll {
    $script:moduleName = 'DscResource.Common'

    # Import the function directly since module build may not be available
    . "$PSScriptRoot/../../../source/Public/Get-ComputerName.ps1"
}

Describe 'Get-ComputerName Integration Tests' -Tag 'GetComputerName' {
    Context 'When getting computer name in real environment' {
        It 'Should return a valid computer name without FQDN switch' {
            $result = Get-ComputerName
            
            $result | Should -BeOfType [System.String]
            $result | Should -Not -BeNullOrEmpty
            # Should match the actual machine name from .NET
            $result | Should -Be ([System.Environment]::MachineName)
            # Should not contain dots (short name)
            $result | Should -Not -Match '\.'
        }

        It 'Should return a computer name with FQDN switch' {
            $result = Get-ComputerName -FullyQualifiedDomainName
            
            $result | Should -BeOfType [System.String]
            $result | Should -Not -BeNullOrEmpty
            # Should be at least as long as the short name
            $result.Length | Should -BeGreaterOrEqual ([System.Environment]::MachineName.Length)
        }

        It 'Should handle the function without throwing errors' {
            { Get-ComputerName } | Should -Not -Throw
            { Get-ComputerName -FullyQualifiedDomainName } | Should -Not -Throw
        }

        It 'Should return consistent results on multiple calls' {
            $result1 = Get-ComputerName
            $result2 = Get-ComputerName
            
            $result1 | Should -Be $result2
        }

        It 'Should return consistent FQDN results on multiple calls' {
            $result1 = Get-ComputerName -FullyQualifiedDomainName
            $result2 = Get-ComputerName -FullyQualifiedDomainName
            
            $result1 | Should -Be $result2
        }
    }

    Context 'When comparing with system methods' {
        It 'Should return the same short name as Environment.MachineName' {
            $functionResult = Get-ComputerName
            $environmentResult = [System.Environment]::MachineName
            
            $functionResult | Should -Be $environmentResult
        }

        It 'Should handle DNS resolution appropriately for FQDN' {
            $fqdnResult = Get-ComputerName -FullyQualifiedDomainName
            $shortResult = Get-ComputerName
            
            # FQDN should either be the same as short name (if no domain) or longer
            $fqdnResult.Length | Should -BeGreaterOrEqual $shortResult.Length
            
            # If FQDN is longer, it should start with the short name
            if ($fqdnResult.Length -gt $shortResult.Length) {
                $fqdnResult | Should -BeLike "$shortResult.*"
            }
        }
    }
}
