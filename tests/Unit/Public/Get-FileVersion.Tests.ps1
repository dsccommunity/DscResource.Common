[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
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

Describe 'Get-FileVersion' -Tag 'Public' {
    Context 'When passing path as string' {
        BeforeAll {
            $script:mockFilePath = (New-Item -Path $TestDrive -Name 'setup.exe' -ItemType 'File' -Force).FullName

            Mock -CommandName Get-Item -MockWith {
                return @{
                    PSIsContainer = $false
                    FullName      = $mockFilePath
                    VersionInfo   = @{
                        ProductVersion = '16.0.1000.6'
                        FileVersion    = '2022.160.1000.6'
                        ProductName    = 'Microsoft SQL Server'
                    }
                }
            }
        }

        Context 'When passing as a named parameter' {
            It 'Should return the correct result' {
                $result = Get-FileVersion -Path $mockFilePath

                $result.ProductVersion | Should -Be '16.0.1000.6'
            }
        }

        Context 'When passing over the pipeline' {
            It 'Should return the correct result' {
                $result = $mockFilePath | Get-FileVersion

                $result.ProductVersion | Should -Be '16.0.1000.6'
            }
        }
    }

    Context 'When passing path as the type FileInfo' {
        BeforeAll {
            $script:mockFilePath = (New-Item -Path $TestDrive -Name 'setup.exe' -ItemType 'File' -Force).FullName
            $script:mockFileInfo = [System.IO.FileInfo]::new($script:mockFilePath)

            Mock -CommandName Get-Item -MockWith {
                # Create a mock object that looks like a FileInfo with VersionInfo
                $mockVersionInfo = [PSCustomObject]@{
                    ProductVersion = '16.0.1000.6'
                    FileVersion    = '2022.160.1000.6'
                    ProductName    = 'Microsoft SQL Server'
                }

                $mockItem = [PSCustomObject]@{
                    PSIsContainer = $false
                    FullName      = $mockFilePath
                    VersionInfo   = $mockVersionInfo
                }

                return $mockItem
            }
        }

        Context 'When passing as a named parameter' {
            It 'Should return the correct result' {
                $result = Get-FileVersion -Path $mockFileInfo

                $result.ProductVersion | Should -Be '16.0.1000.6'
            }
        }

        Context 'When passing over the pipeline' {
            It 'Should return the correct result' {
                $result = $mockFileInfo | Get-FileVersion

                $result.ProductVersion | Should -Be '16.0.1000.6'
            }
        }
    }

    Context 'When passing in a FileInfo that represents a directory' {
        BeforeAll {
            Mock -CommandName Get-Item -MockWith {
                return @{
                    PSIsContainer = $true
                    FullName      = $TestDrive
                }
            }

            $localizedString = InModuleScope -ScriptBlock {
                $script:localizedData.Get_FileVersion_PathIsNotFile
            }

            $script:expectedMessage = $localizedString -f $TestDrive
        }

        It 'Should throw the correct error' {
            { [System.IO.FileInfo] $TestDrive | Get-FileVersion } |
                Should -Throw -ExpectedMessage $script:expectedMessage
        }
    }

    Context 'When passing in a directory that was accessed from Get-Item' {
        BeforeAll {
            $localizedString = InModuleScope -ScriptBlock {
                $script:localizedData.Get_FileVersion_PathIsNotFile
            }

            $script:expectedMessage = $localizedString -f $TestDrive
        }

        It 'Should throw the correct error' {
            { Get-Item -Path $TestDrive | Get-FileVersion -ErrorAction 'Stop' } |
                Should -Throw -ExpectedMessage $script:expectedMessage
        }
    }

    Context 'When validating parameter sets' {
        BeforeDiscovery {
            $parameterSetTestCases = @(
                @{
                    ExpectedParameterSetName = '__AllParameterSets'
                    ExpectedParameters       = '[-Path] <FileInfo> [<CommonParameters>]'
                }
            )
        }

        It 'Should have the correct parameters in parameter set <ExpectedParameterSetName>' -ForEach $parameterSetTestCases {
            $result = (Get-Command -Name 'Get-FileVersion').ParameterSets |
                Where-Object -FilterScript { $_.Name -eq $ExpectedParameterSetName } |
                Select-Object -Property @(
                    @{ Name = 'ParameterSetName'; Expression = { $_.Name } },
                    @{ Name = 'ParameterListAsString'; Expression = { $_.ToString() } }
                )
            $result.ParameterSetName | Should -Be $ExpectedParameterSetName
            $result.ParameterListAsString | Should -Be $ExpectedParameters
        }
    }

    Context 'When validating parameter properties' {
        It 'Should have Path as a mandatory parameter' {
            $parameterInfo = (Get-Command -Name 'Get-FileVersion').Parameters['Path']
            $parameterInfo.Attributes.Mandatory | Should -BeTrue
        }

        It 'Should accept pipeline input for Path parameter' {
            $parameterInfo = (Get-Command -Name 'Get-FileVersion').Parameters['Path']
            $parameterInfo.Attributes.ValueFromPipeline | Should -Not -Contain $false
        }

        It 'Should accept pipeline input by property name for Path parameter' {
            $parameterInfo = (Get-Command -Name 'Get-FileVersion').Parameters['Path']
            $parameterInfo.Attributes.ValueFromPipelineByPropertyName | Should -Not -Contain $false
        }

        It 'Should have FullName as an alias for Path parameter' {
            $parameterInfo = (Get-Command -Name 'Get-FileVersion').Parameters['Path']
            $parameterInfo.Aliases | Should -Contain 'FullName'
        }
    }
}
