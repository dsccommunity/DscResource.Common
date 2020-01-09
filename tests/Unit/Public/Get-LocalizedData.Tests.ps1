$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Get-LocalizedData' {
        Context 'When specifying a specific filename' {
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

        Context 'When specifying a specific filename and falling back to a DefaultUICulture' {
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

        Context 'When a filename is not specified' {
            BeforeAll {
                <#
                    We need to mock the test using the current OS UI culture so
                    that the tests passes.
                #>
                $mockCurrentUICulture = Get-UICulture
            }

            Context 'When no localized string file is found' {
                BeforeAll {
                    New-Item -Force -Path ('TestDrive:\{0}' -f $mockCurrentUICulture) -ItemType Directory

                    "Get-LocalizedData -DefaultUICulture 'en-US' -EA Stop" |
                        Out-File -Force -FilePath 'TestDrive:\DSC_Resource.psm1'
                }

                It 'Should throw if no file is found' {
                    { Import-Module -Name 'TestDrive:\DSC_Resource.psm1' -ErrorAction 'Stop' } | Should -Throw
                }
            }

            Context 'When expecting to find a localized string filename without suffix' {
                BeforeAll {
                    New-Item -Force -Path ('TestDrive:\{0}' -f $mockCurrentUICulture) -ItemType Directory

                    $null = "
ConvertFrom-StringData @`'
# en-US strings
StringKey    = String value
'@
                    " | Out-File -Force -FilePath ('TestDrive:\{0}\DSC_Resource1.psd1' -f $mockCurrentUICulture)

                    "Get-LocalizedData -DefaultUICulture 'en-US' -EA Stop" |
                        Out-File -Force -FilePath 'TestDrive:\DSC_Resource1.psm1'
                }

                It 'Should retrieve the data' {
                    { Import-Module -Name 'TestDrive:\DSC_Resource1.psm1' -ErrorAction 'Stop' } | Should -Not -Throw
                }
            }

            Context 'When expecting to find the default culture''s localized string filename without suffix' {
                BeforeAll {
                    New-Item -Force -Path 'TestDrive:\sv-SE' -ItemType Directory

                    $null = "
ConvertFrom-StringData @`'
# sv-SE strings
StringKey    = Sträng värde
'@
                    " | Out-File -Force -FilePath 'TestDrive:\sv-SE\DSC_Resource1.psd1'

                    "Get-LocalizedData -DefaultUICulture 'sv-SE' -EA Stop" |
                        Out-File -Force -FilePath 'TestDrive:\DSC_Resource1.psm1'
                }

                It 'Should retrieve the data' {
                    { Import-Module -Name 'TestDrive:\DSC_Resource1.psm1' -ErrorAction 'Stop' } | Should -Not -Throw
                }
            }

            Context "When expecting to find a localized string filename using the suffix '.strings'" {
                BeforeAll {
                    New-Item -Force -Path ('TestDrive:\{0}' -f $mockCurrentUICulture) -ItemType Directory

                    $null = "
ConvertFrom-StringData @`'
# en-US strings
StringKey    = String value
'@
                    " | Out-File -Force -FilePath ('TestDrive:\{0}\DSC_Resource2.strings.psd1' -f $mockCurrentUICulture)

                    "Get-LocalizedData -DefaultUICulture 'en-US' -EA Stop" |
                        Out-File -Force -FilePath 'TestDrive:\DSC_Resource2.psm1'
                }

                It 'Should retrieve the data' {
                    { Import-Module -Name 'TestDrive:\DSC_Resource2.psm1' -ErrorAction 'Stop' } | Should -Not -Throw
                }
            }

            Context "When expecting to find the default culture's localized string filename with the suffix '.strings'" {
                BeforeAll {
                    New-Item -Force -Path 'TestDrive:\sv-SE' -ItemType Directory

                    $null = "
ConvertFrom-StringData @`'
# sv-SE strings
StringKey    = Sträng värde
'@
                    " | Out-File -Force -FilePath 'TestDrive:\sv-SE\DSC_Resource2.strings.psd1'

                    "Get-LocalizedData -DefaultUICulture 'sv-SE' -EA Stop" |
                        Out-File -Force -FilePath 'TestDrive:\DSC_Resource2.psm1'
                }

                It 'Should retrieve the data' {
                    { Import-Module -Name 'TestDrive:\DSC_Resource2.psm1' -ErrorAction 'Stop' } | Should -Not -Throw
                }
            }
        }
    }
}
