# Using InModuleScope so need to import the module outside an BeforeAll-block.
$script:moduleName = 'DscResource.Common'

#region HEADER
Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

Get-Module -Name $script:moduleName -ListAvailable |
    Select-Object -First 1 |
    Import-Module -Force -ErrorAction 'Stop'
#endregion HEADER

Describe 'Test-DscObjectHasProperty' {
    Context 'When the object contains the expected property' {
        InModuleScope $script:moduleName {
            BeforeAll {
                # Use the Get-Verb cmdlet to just get a simple object fast
                $testDscObject = (Get-Verb)[0]
            }

            It 'Should not throw exception' {
                { Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Verb' -Verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                $result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Verb' -Verbose

                $result | Should -BeTrue
            }
        }
    }

    Context 'When the object does not contain the expected property' {
        InModuleScope $script:moduleName {
            BeforeAll {
                # Use the Get-Verb cmdlet to just get a simple object fast
                $testDscObject = (Get-Verb)[0]
            }

            It 'Should not throw exception' {
                { Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Missing' -Verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                $result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Missing' -Verbose

                $result | Should -BeFalse
            }
        }
    }
}
