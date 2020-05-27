BeforeAll {
    $script:moduleName = 'DscResource.Common'

    #region HEADER
    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
    #endregion HEADER
}

Describe 'Remove-CommonParameter' {
    Context 'Hashtable contains all common parameters' {
        BeforeAll {
            $removeCommonParameter = @{
                Parameter1          = 'value1'
                Parameter2          = 'value2'
                Verbose             = $true
                Debug               = $true
                ErrorAction         = 'Stop'
                WarningAction       = 'Stop'
                InformationAction   = 'Stop'
                ErrorVariable       = 'errorVariable'
                WarningVariable     = 'warningVariable'
                OutVariable         = 'outVariable'
                OutBuffer           = 'outBuffer'
                PipelineVariable    = 'pipelineVariable'
                InformationVariable = 'informationVariable'
                WhatIf              = $true
                Confirm             = $true
                UseTransaction      = $true
            }
        }

        It 'Should not throw exception' {
            {
                $script:result = Remove-CommonParameter -Hashtable $removeCommonParameter -Verbose
            } | Should -Not -Throw
        }

        It 'Should have retained parameters in the hashtable' {
            $script:result.Contains('Parameter1') | Should -BeTrue
            $script:result.Contains('Parameter2') | Should -BeTrue
        }

        It 'Should have removed the common parameters from the hashtable' {
            $script:result.Contains('Verbose') | Should -BeFalse
            $script:result.Contains('Debug') | Should -BeFalse
            $script:result.Contains('ErrorAction') | Should -BeFalse
            $script:result.Contains('WarningAction') | Should -BeFalse
            $script:result.Contains('InformationAction') | Should -BeFalse
            $script:result.Contains('ErrorVariable') | Should -BeFalse
            $script:result.Contains('WarningVariable') | Should -BeFalse
            $script:result.Contains('OutVariable') | Should -BeFalse
            $script:result.Contains('OutBuffer') | Should -BeFalse
            $script:result.Contains('PipelineVariable') | Should -BeFalse
            $script:result.Contains('InformationVariable') | Should -BeFalse
            $script:result.Contains('WhatIf') | Should -BeFalse
            $script:result.Contains('Confirm') | Should -BeFalse
            $script:result.Contains('UseTransaction') | Should -BeFalse
        }
    }
}
