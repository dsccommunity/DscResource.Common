[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:moduleName = 'DscResource.Common'

    # Make sure there are not other modules imported that will conflict with mocks.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

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

Describe 'Get-LocalizedData' -Tag 'GetLocalizedData' {
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
            $mockCurrentUICulture = 'en-US'
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

            <#
                Regression test for issues loading the *.strings.psd1 from default
                culture when OS has different culture for which no localized strings
                exist.
            #>
            Context "When the operating system UI culture does not exist and the default culture has a '.strings.psd1' file" {
                BeforeAll {
                    New-Item -Force -Path 'TestDrive:\en-US' -ItemType Directory

                    $null = "
ConvertFrom-StringData @`'
# sv-SE strings
StringKey    = String value
'@
                    " | Out-File -Force -FilePath 'TestDrive:\en-US\Get-LocalizedData.Tests.strings.psd1'

                    Mock -CommandName Get-UICulture -MockWith {
                        return @{
                            Parent                         = @{
                                Parent                         = $null
                                LCID                           = '7'
                                KeyboardLayoutId               = '7'
                                Name                           = 'de'
                                IetfLanguageTag                = 'de'
                                DisplayName                    = 'German'
                                NativeName                     = 'Deutsch'
                                EnglishName                    = 'German'
                                TwoLetterISOLanguageName       = 'de'
                                ThreeLetterISOLanguageName     = 'deu'
                                ThreeLetterWindowsLanguageName = 'DEU'
                            }
                            LCID                           = '1031'
                            KeyboardLayoutId               = '1031'
                            Name                           = 'de-DE'
                            IetfLanguageTag                = 'de-DE'
                            DisplayName                    = 'Deutsch (Deutschland)'
                            NativeName                     = 'Deutsch (Deutschland)'
                            EnglishName                    = 'German (Germany)'
                            TwoLetterISOLanguageName       = 'de'
                            ThreeLetterISOLanguageName     = 'deu'
                            ThreeLetterWindowsLanguageName = 'DEU'
                        }
                    } -ModuleName 'DscResource.Common'
                }

                It 'Should retrieve the data' {
                    { Get-LocalizedData -DefaultUICulture 'en-US' -BaseDirectory 'TestDrive:\' -ErrorAction 'Stop' } | Should -Not -Throw
                }
            }
        }
    }
}
