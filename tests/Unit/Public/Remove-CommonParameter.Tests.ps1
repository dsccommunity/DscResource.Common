BeforeAll {
    $script:moduleName = 'DscResource.Common'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
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
