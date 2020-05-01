# macOS and Linux does not support CimInstance.
if (-not ($isWindows -or $PSEdition -eq 'Desktop'))
{
    return
}

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
    Describe 'NetworkingDsc.Common\ConvertTo-CimInstance' {
        $hashtable = @{
            k1 = 'v1'
            k2 = 100
            k3 = 1, 2, 3
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
}
