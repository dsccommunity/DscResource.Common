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

        Context 'When called with just DefaultUICulture' {
            Context 'When expected to find a localized string file' {
                BeforeAll {
                    New-Item -Force -Path 'TestDrive:\en-US' -ItemType Directory

                    "Get-LocalizedData -DefaultUICulture 'en-US' -EA Stop" |
                        Out-File -Force -FilePath 'TestDrive:\DSC_Resource.psm1'
                }

                It 'Should throw if no file is found' {
                    { Import-Module -Name 'TestDrive:\DSC_Resource.psm1' -ErrorAction 'Stop' } | Should -Throw
                }
            }

            Context 'When expected to find a localized string filename without suffix' {
                BeforeAll {
                    New-Item -Force -Path 'TestDrive:\en-US' -ItemType Directory

                    $null = "
ConvertFrom-StringData @`'
# en-US strings
ParameterBlockParameterAttributeMissing    = A [Parameter()] attribute must be the first attribute of each parameter and be on its own line. See https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-parameter-block
'@
                    " | Out-File -Force -FilePath 'TestDrive:\en-US\DSC_Resource1.psd1'

                    "Get-LocalizedData -DefaultUICulture 'en-US' -EA Stop" |
                        Out-File -Force -FilePath 'TestDrive:\DSC_Resource1.psm1'
                }

                It 'Should retrieve the data' {
                    { Import-Module -Name 'TestDrive:\DSC_Resource1.psm1' -ErrorAction 'Stop' } | Should -Not -Throw
                }
            }

            Context "When expected to find a localized string filename using suffix '.strings'" {
                BeforeAll {
                    New-Item -Force -Path 'TestDrive:\en-US' -ItemType Directory

                    $null = "
ConvertFrom-StringData @`'
# en-US strings
ParameterBlockParameterAttributeMissing    = A [Parameter()] attribute must be the first attribute of each parameter and be on its own line. See https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-parameter-block
'@
                    " | Out-File -Force -FilePath 'TestDrive:\en-US\DSC_Resource2.strings.psd1'

                    "Get-LocalizedData -DefaultUICulture 'en-US' -EA Stop" |
                        Out-File -Force -FilePath 'TestDrive:\DSC_Resource2.psm1'
                }

                It 'Should retrieve the data' {
                    { Import-Module -Name 'TestDrive:\DSC_Resource2.psm1' -ErrorAction 'Stop' } | Should -Not -Throw
                }
            }
        }
    }
}
