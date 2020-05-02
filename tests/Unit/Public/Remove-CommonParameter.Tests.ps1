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
    Describe 'NetworkingDsc.Common\Remove-CommonParameter' {
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

        Context 'Hashtable contains all common parameters' {
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
}
