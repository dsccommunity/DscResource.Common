$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Test-DscObjectHasProperty' {

        # Use the Get-Verb cmdlet to just get a simple object fast
        $testDscObject = (Get-Verb)[0]

        Context 'When the object contains the expected property' {
            It 'Should not throw exception' {
                { $script:result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Verb' -Verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                $script:result | Should -Be $true
            }
        }

        Context 'When the object does not contain the expected property' {
            It 'Should not throw exception' {
                { $script:result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Missing' -Verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                $script:result | Should -Be $false
            }
        }
    }
}
