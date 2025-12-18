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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Get-FileProductVersion' {
    BeforeDiscovery {
        $parameterSetTestCases = @(
            @{
                ExpectedParameterSetName = '__AllParameterSets'
                ExpectedParameters       = '[-Path] <string> [<CommonParameters>]'
            }
        )
    }

    It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach $parameterSetTestCases {
        $result = (Get-Command -Name 'Get-FileProductVersion').ParameterSets |
            Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
            Select-Object -Property @(
                @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
            )

        $result.ParameterSetName | Should -Be $ExpectedParameterSetName
        $result.ParameterListAsString | Should -Be $ExpectedParameters
    }

    It 'Should have Path as a mandatory parameter' {
        $parameterInfo = (Get-Command -Name 'Get-FileProductVersion').Parameters['Path']

        $parameterInfo.Attributes.Mandatory | Should -BeTrue
    }

    Context 'When the file exists and has a product version as a string' {
        BeforeAll {
            Mock -CommandName Get-FileVersion -MockWith {
                return [PSCustomObject] @{
                    ProductVersion = '15.0.2000.5'
                }
            }
        }

        It 'Should return the correct product version as a System.Version object' {
            $result = Get-FileProductVersion -Path (Join-Path -Path $TestDrive -ChildPath 'testfile.dll')

            $result | Should -BeOfType [System.Version]
            $result.Major | Should -Be 15
            $result.Minor | Should -Be 0
            $result.Build | Should -Be 2000
            $result.Revision | Should -Be 5
        }
    }

    Context 'When the file has a product version as a System.Version object' {
        BeforeAll {
            Mock -CommandName Get-FileVersion -MockWith {
                return [PSCustomObject] @{
                    ProductVersion = [System.Version] '10.5.3.2'
                }
            }
        }

        It 'Should return the correct product version as a System.Version object' {
            $result = Get-FileProductVersion -Path (Join-Path -Path $TestDrive -ChildPath 'testfile.dll')

            $result | Should -BeOfType [System.Version]
            $result.Major | Should -Be 10
            $result.Minor | Should -Be 5
            $result.Build | Should -Be 3
            $result.Revision | Should -Be 2
        }
    }

    Context 'When the file has a non-numeric product version' {
        BeforeAll {
            Mock -CommandName Get-FileVersion -MockWith {
                return [PSCustomObject] @{
                    ProductVersion = 'Not-A-Version-String'
                }
            }
        }

        It 'Should throw a terminating error with the correct error message' {
            $mockFilePath = Join-Path -Path $TestDrive -ChildPath 'testfile.dll'

            $mockInvalidVersionFormatMessage = InModuleScope -ScriptBlock {
                $script:localizedData.Get_FileProductVersion_InvalidVersionFormat
            }

            {
                Get-FileProductVersion -Path $mockFilePath -ErrorAction 'Stop'
            } | Should -Throw ($mockInvalidVersionFormatMessage -f 'Not-A-Version-String', $mockFilePath)
        }

        It 'Should throw an error with the correct error ID' {
            $mockFilePath = Join-Path -Path $TestDrive -ChildPath 'testfile.dll'

            $result = {
                Get-FileProductVersion -Path $mockFilePath -ErrorAction 'Stop'
            } | Should -Throw -PassThru

            # Verify the error ID is GFPV0002 for invalid version format
            $result.FullyQualifiedErrorId | Should -BeLike 'GFPV0002,*'
        }
    }

    Context 'When Get-FileVersion throws an exception' {
        BeforeAll {
            Mock -CommandName Get-FileVersion -MockWith {
                throw 'Mock exception message'
            }
        }

        It 'Should throw an error with the correct error ID' {
            $mockFilePath = Join-Path -Path $TestDrive -ChildPath 'testfile.dll'

            $result = {
                Get-FileProductVersion -Path $mockFilePath -ErrorAction 'Stop'
            } | Should -Throw -PassThru

            # Verify the error ID is correct
            $result.FullyQualifiedErrorId | Should -BeLike 'GFPV0001,*'
        }
    }
}
