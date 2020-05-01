$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            } )
    }).BaseName

Import-Module $ProjectName -Force

InModuleScope $ProjectName {
    Describe 'NetworkingDsc.Common\ConvertTo-HashTable' {
        [CimInstance[]] $cimInstances = ConvertTo-CimInstance -Hashtable @{
            k1 = 'v1'
            k2 = 100
            k3 = 1, 2, 3
        }

        Context 'When the array contains the expected record count' {
            It 'Should not throw exception' {
                { $script:result = $cimInstances | ConvertTo-HashTable } | Should -Not -Throw
            }

            It "Should return record count of $($cimInstances.Count)" {
                $script:result.Count | Should -Be $cimInstances.Count
            }

            It 'Should return result of type [System.Collections.Hashtable]' {
                $script:result | Should -BeOfType [System.Collections.Hashtable]
            }

            It 'Should return value "k1" in the hashtable should be "v1"' {
                $script:result.k1 | Should -Be 'v1'
            }

            It 'Should return value "k2" in the hashtable should be "100"' {
                $script:result.k2 | Should -Be 100
            }

            It 'Should return value "k3" in the hashtable should be "1,2,3"' {
                $script:result.k3 | Should -Be '1,2,3'
            }
        }
    }
}
