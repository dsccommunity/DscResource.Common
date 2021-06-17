BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
}

# macOS and Linux does not support CimInstance.
Describe 'ConvertTo-CimInstance' -Skip:(-not ($IsWindows -or $PSEdition -eq 'Desktop')) {
    BeforeAll {
        $hashtable = @{
            k1 = 'v1'
            k2 = 100
            k3 = 1, 2, 3
        }
    }

    Context 'When the array contains the expected record count' {
        It 'Should not throw exception' {
            {
                $script:result = [Microsoft.Management.Infrastructure.CimInstance[]] (
                    $hashtable | ConvertTo-CimInstance
                )
            } | Should -Not -Throw
        }

        It "Should record count should be $($hashTable.Count)" {
            $script:result.Count | Should -Be $hashtable.Count
        }

        It 'Should return result of type CimInstance[]' {
            $script:result.GetType().Name | Should -Be 'CimInstance[]'
        }

        It 'Should return value "k1" in the CimInstance array should be "v1"' {
            ($script:result | Where-Object Key -eq k1).Value | Should -Be 'v1'
        }

        It 'Should return value "k2" in the CimInstance array should be "100"' {
            ($script:result | Where-Object Key -eq k2).Value | Should -Be 100
        }

        It 'Should return value "k3" in the CimInstance array should be "1,2,3"' {
            ($script:result | Where-Object Key -eq k3).Value | Should -Be '1,2,3'
        }
    }
}
