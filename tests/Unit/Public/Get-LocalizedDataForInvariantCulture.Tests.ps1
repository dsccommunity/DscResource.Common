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

Describe 'DscResource.Common\Get-LocalizedDataForInvariantCulture' {
    BeforeAll {
        $verbose = $false
    }

    Context 'Finding data for DefaultUICulture' {
        BeforeAll {
            New-Item -Force -Path 'TestDrive:\ar-SA' -ItemType Directory

            $null = "
                ConvertFrom-StringData @`'
                # English strings
                ParameterBlockParameterAttributeMissing    = A [Parameter()] attribute must be the first attribute of each parameter and be on its own line. See https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-parameter-block
'@
            " | Out-File -Force -FilePath 'TestDrive:\ar-SA\Strings.psd1'
        }

        It 'Should fail finding a Strings file in locale different from default' {
            "Get-LocalizedDataForInvariantCulture -FileName 'Strings' -BaseDirectory 'TestDrive:\' -EA Stop" |
            Out-File -Force -FilePath 'TestDrive:\execute.ps1' # will default to en-US

            { $null = &'TestDrive:\execute.ps1' } | Should -Throw
        }

        It 'Should fail finding a Strings file in different locale' {
            "Get-LocalizedDataForInvariantCulture -FileName 'Strings' -BaseDirectory 'TestDrive:\' -EA Stop -DefaultUICulture 'en-GB'" |
                Out-File -Force -FilePath 'TestDrive:\execute.ps1'

            { $null = &'TestDrive:\execute.ps1' } | Should -Throw
        }

        It 'Should succeed finding a Strings file in correct locale' {
            "Get-LocalizedDataForInvariantCulture -FileName 'Strings' -BaseDirectory 'TestDrive:\' -EA Stop -DefaultUICulture 'ar-SA'" |
                Out-File -Force -FilePath 'TestDrive:\execute.ps1'

            { $null = &'TestDrive:\execute.ps1' } | Should -Not -Throw
        }

        It 'Should fail finding a Strings file if fileName doesn''t exist' {
            "Get-LocalizedDataForInvariantCulture -FileName 'execute' -BaseDirectory 'TestDrive:\' -EA Stop -DefaultUICulture 'ar-SA'" |
                Out-File -Force -FilePath 'TestDrive:\execute.ps1'

            { $null = &'TestDrive:\execute.ps1' } | Should -Throw
        }

        It 'Should succeed finding the strings.psd1 file of caller''s basename' {

            $null = "
                        ConvertFrom-StringData @`'
                        # English strings
                        ParameterBlockParameterAttributeMissing    = A [Parameter()] attribute must be the first attribute of each parameter and be on its own line. See https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md#correct-format-for-parameter-block
'@
                    " | Out-File -Force -FilePath 'TestDrive:\ar-SA\execute.strings.psd1'

            "Get-LocalizedDataForInvariantCulture -FileName 'execute' -BaseDirectory 'TestDrive:\' -EA Stop -DefaultUICulture 'ar-SA'" |
              Out-File -Force -FilePath 'TestDrive:\execute.ps1'
            { $null = &'TestDrive:\execute.ps1' } | Should -Not -Throw
        }
    }
}
