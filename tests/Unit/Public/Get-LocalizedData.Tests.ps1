$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Get-LocalizedData' {
        Context 'When using the default Import-LocalizedData behavior' {
            BeforeAll {
                New-Item -Force -Path 'TestDrive:\ar-SA' -ItemType Directory
                $null = "
                    ConvertFrom-StringData @`'
                    # English strings
                    ParameterBlockParameterAttributeMissing    = A [Parameter()] attribute must be the first attribute of each parameter and be on its own line. See https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-parameter-block
                    '@
                " | Out-File -Force -FilePath 'TestDrive:\ar-SA\Strings.psd1'
                "Get-LocalizedData -FileName 'Strings' -EA Stop" |
                    Out-File -Force -FilePath 'TestDrive:\execute.ps1'
            }


            It 'Should fail finding a Strings file in different locale' {
                { $null = &'TestDrive:\execute.ps1' } | Should -Throw
            }


        }

        Context 'When falling back to a DefaultUICulture' {
            BeforeAll {
                New-Item -Force -Path 'TestDrive:\ar-SA' -ItemType Directory
                $null = "
ConvertFrom-StringData @`'
# ar-SA strings
ParameterBlockParameterAttributeMissing    = A [Parameter()] attribute must be the first attribute of each parameter and be on its own line. See https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-parameter-block
'@
                " | Out-File -Force -FilePath 'TestDrive:\ar-SA\Strings.psd1'
                "Get-LocalizedData -FileName 'Strings' -DefaultUICulture 'ar-SA' -EA Stop" |
                    Out-File -Force -FilePath 'TestDrive:\execute.ps1'
            }

            It 'Should retrieve the data' {
                { $null = &'TestDrive:\execute.ps1' } | Should -Not -Throw
                &'TestDrive:\execute.ps1' | Should -Not -BeNullOrEmpty
            }
        }
    }
}
