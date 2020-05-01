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
                $script:result.Contains('Parameter1') | Should -Be $true
                $script:result.Contains('Parameter2') | Should -Be $true
            }

            It 'Should have removed the common parameters from the hashtable' {
                $script:result.Contains('Verbose') | Should -Be $false
                $script:result.Contains('Debug') | Should -Be $false
                $script:result.Contains('ErrorAction') | Should -Be $false
                $script:result.Contains('WarningAction') | Should -Be $false
                $script:result.Contains('InformationAction') | Should -Be $false
                $script:result.Contains('ErrorVariable') | Should -Be $false
                $script:result.Contains('WarningVariable') | Should -Be $false
                $script:result.Contains('OutVariable') | Should -Be $false
                $script:result.Contains('OutBuffer') | Should -Be $false
                $script:result.Contains('PipelineVariable') | Should -Be $false
                $script:result.Contains('InformationVariable') | Should -Be $false
                $script:result.Contains('WhatIf') | Should -Be $false
                $script:result.Contains('Confirm') | Should -Be $false
                $script:result.Contains('UseTransaction') | Should -Be $false
            }
        }
    }
}
