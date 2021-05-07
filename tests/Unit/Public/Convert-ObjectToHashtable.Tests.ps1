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
    Describe 'Convert-ObjectToHashTable' {
        $psObject = [pscustomobject]@{
            k1 = 'v1'
            k2 = 100
            k3 = 1, 2, 3
        },[pscustomobject]@{
            k1 = 'v2'
            k2 = 101
            k3 = 1, 2, 3, 4
        }

        Context 'When the array contains the expected record count through the pipeline' {
            It 'Should not throw exception' {
                { $script:result = $psObject | Convert-ObjectToHashTable } | Should -Not -Throw
            }

            It "Should return record count of $($psObject.Count)" {
                $script:result.Count | Should -Be $psObject.Count
            }

            It 'Should return result of type [System.Collections.Hashtable]' {
                $script:result | Should -BeOfType [System.Collections.Hashtable]
            }

            Context 'When the first object of array contains the expected record' {

                It 'Should return value "k1" in the hashtable should be "v1"' {
                    $script:result[0].k1 | Should -Be 'v1'
                }

                It 'Should return value "k2" in the hashtable should be "100"' {
                    $script:result[0].k2 | Should -Be 100
                }

                It 'Should return value "k3" in the hashtable should be "1,2,3"' {
                    $script:result[0].k3 -join ',' | Should -Be '1,2,3'
                }
            }

            Context 'When the second object of array contains the expected record' {

                It 'Should return value "k1" in the hashtable should be "v2"' {
                    $script:result[1].k1 | Should -Be 'v2'
                }

                It 'Should return value "k2" in the hashtable should be "101"' {
                    $script:result[1].k2 | Should -Be 101
                }

                It 'Should return value "k3" in the hashtable should be "1,2,3,4"' {
                    $script:result[1].k3 -join ',' | Should -Be '1,2,3,4'
                }
            }
        }

        Context 'When the array contains the expected record count' {
            It 'Should not throw exception' {
                { $script:result = Convert-ObjectToHashTable -InputObject $psObject[0] } | Should -Not -Throw
            }

            It "Should return record count of $($psObject.Count)" {
                ($script:result | Measure-Object).Count | Should -Be $psObject.Count
            }

            It 'Should return result of type [System.Collections.Hashtable]' {
                $script:result | Should -BeOfType [System.Collections.Hashtable]
            }

            Context 'When the object contains the expected record' {

                It 'Should return value "k1" in the hashtable should be "v1"' {
                    $script:result.k1 | Should -Be 'v1'
                }

                It 'Should return value "k2" in the hashtable should be "100"' {
                    $script:result.k2 | Should -Be 100
                }

                It 'Should return value "k3" in the hashtable should be "1,2,3"' {
                    $script:result.k3 -join ',' | Should -Be '1,2,3'
                }
            }
        }
    }
}
