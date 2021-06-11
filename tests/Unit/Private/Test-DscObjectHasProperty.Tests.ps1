BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
}

Describe 'Test-DscObjectHasProperty' {
    Context 'When the object contains the expected property' {
        BeforeAll {
            # Use the Get-Verb cmdlet to just get a simple object fast
            InModuleScope -ScriptBlock {
                $script:testDscObject = (Get-Verb)[0]
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                { Test-DscObjectHasProperty -Object $script:testDscObject -PropertyName 'Verb' -Verbose } | Should -Not -Throw
            }
        }

        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                $result = Test-DscObjectHasProperty -Object $script:testDscObject -PropertyName 'Verb' -Verbose

                $result | Should -BeTrue
            }
        }
    }

    Context 'When the object does not contain the expected property' {
        BeforeAll {
            # Use the Get-Verb cmdlet to just get a simple object fast
            InModuleScope -ScriptBlock {
                $script:testDscObject = (Get-Verb)[0]
            }
        }

        It 'Should not throw exception' {
            InModuleScope -ScriptBlock {
                { Test-DscObjectHasProperty -Object $script:testDscObject -PropertyName 'Missing' -Verbose } | Should -Not -Throw
            }
        }

        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                $result = Test-DscObjectHasProperty -Object $script:testDscObject -PropertyName 'Missing' -Verbose

                $result | Should -BeFalse
            }
        }
    }
}
