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

    Import-Module -Name $script:moduleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Format-Path' {
    Context 'When formatting paths without any formatting parameters' {
        It 'Should not modify any paths' {
            Format-Path -Path 'C:' | Should -Be 'C:'
            Format-Path -Path 'C:\' | Should -Be 'C:\'
            Format-Path -Path 'C:\MyFolder' | Should -Be 'C:\MyFolder'
            Format-Path -Path 'C:\MyFolder\' | Should -Be 'C:\MyFolder\'
        }

        It 'Should add a trailing backslash to a drive letter' {
            Format-Path -Path 'C:/' | Should -Be 'C:\'
        }

        It 'Should not modify paths that already have a trailing backslash' {
            Format-Path -Path 'C:\' | Should -Be 'C:\'
        }

        It 'Should not modify paths that are not just drive letters' {
            Format-Path -Path 'C:\MyFolder' | Should -Be 'C:\MyFolder'
            Format-Path -Path 'C:\MyFolder\' | Should -Be 'C:\MyFolder\'
            Format-Path -Path 'C:\MyFolder/' | Should -Be 'C:\MyFolder\'
            Format-Path -Path 'C:/MyFolder/' | Should -Be 'C:\MyFolder\'
        }

        It 'Should not modify paths that are not just drive letters on Linux or macOS' -Skip:($PSEdition -eq 'Desktop' -or $IsWindows) {
            Format-Path -Path '/temp/folder' | Should -Be '/temp/folder'
            Format-Path -Path '/temp/folder/' | Should -Be '/temp/folder/'
            Format-Path -Path '/temp\folder/' | Should -Be '/temp/folder/'
            Format-Path -Path '\temp\folder\' | Should -Be '/temp/folder/'
        }

        It 'Should not modify paths that are not just drive letters on Windows' -Skip:($IsLinux -or $IsMacOS) {
            Format-Path -Path '/temp/folder' | Should -Be '\temp\folder'
            Format-Path -Path '/temp/folder/' | Should -Be '\temp\folder\'
            Format-Path -Path '/temp\folder/' | Should -Be '\temp\folder\'
            Format-Path -Path '\temp\folder\' | Should -Be '\temp\folder\'
            Format-Path -Path '\temp\folder/' | Should -Be '\temp\folder\'
            Format-Path -Path '\temp\folder' | Should -Be '\temp\folder'
        }
    }

    Context 'When formatting paths with EnsureDriveLetterRoot parameter' {
        It 'Should add a trailing backslash to a drive letter' {
            Format-Path -Path 'C:' -EnsureDriveLetterRoot | Should -Be 'C:\'
        }

        It 'Should not modify paths that already have a trailing backslash' {
            Format-Path -Path 'C:\' -EnsureDriveLetterRoot | Should -Be 'C:\'
        }

        It 'Should not modify paths that are not just drive letters' {
            Format-Path -Path 'C:\MyFolder' -EnsureDriveLetterRoot | Should -Be 'C:\MyFolder'
            Format-Path -Path 'C:\MyFolder\' -EnsureDriveLetterRoot | Should -Be 'C:\MyFolder\'
        }
    }

    Context 'When formatting paths with NoTrailingDirectorySeparator parameter' {
        It 'Should remove trailing backslash from paths' {
            Format-Path -Path 'C:\MyFolder\' -NoTrailingDirectorySeparator | Should -Be 'C:\MyFolder'
        }

        It 'Should not remove backslash from drive root paths' {
            Format-Path -Path 'C:\' -NoTrailingDirectorySeparator | Should -Be 'C:'
        }

        It 'Should not modify paths without trailing backslash' {
            Format-Path -Path 'C:\MyFolder' -NoTrailingDirectorySeparator | Should -Be 'C:\MyFolder'
        }
    }

    Context 'When using both EnsureDriveLetterRoot and NoTrailingDirectorySeparator parameters' {
        It 'Should add trailing backslash to drive letter paths but remove it from other paths' {
            Format-Path -Path 'C:' -EnsureDriveLetterRoot -NoTrailingDirectorySeparator | Should -Be 'C:\'
            Format-Path -Path 'C:\MyFolder\' -EnsureDriveLetterRoot -NoTrailingDirectorySeparator | Should -Be 'C:\MyFolder'
        }
    }

    Context 'When handling UNC paths' {
        It 'Should properly handle UNC paths with NoTrailingDirectorySeparator parameter' {
            Format-Path -Path '\\server\share\' -NoTrailingDirectorySeparator | Should -Be '\\server\share'
        }

        It 'Should not modify UNC paths without trailing backslash' {
            Format-Path -Path '\\server\share' | Should -Be '\\server\share'
        }

        It 'Should keep trailing backslash on UNC root' {
            Format-Path -Path '\\server\share\' | Should -Be '\\server\share\'
        }
    }

    Context 'When formatting a path with drive letter and no backslash after colon' {
        It 'Should add a backslash after the drive letter for paths like "C:temp/folder"' {
            Format-Path -Path 'C:temp/folder' | Should -Be 'C:temp\folder'
        }

        It 'Should add a backslash after the drive letter for paths like "C:temp/folder"' {
            Format-Path -Path 'C:temp/folder' -EnsureDriveLetterRoot  | Should -Be 'C:\temp\folder'
        }

        It 'Should add a backslash after the drive letter for paths like "C:temp\folder"' {
            Format-Path -Path 'C:temp\folder' -EnsureDriveLetterRoot | Should -Be 'C:\temp\folder'
        }

        It 'Should handle multiple instances of forward slashes' {
            Format-Path -Path 'C:temp/folder/subfolder' -EnsureDriveLetterRoot | Should -Be 'C:\temp\folder\subfolder'
        }

        Context 'When using EnsureDriveLetterRoot parameter' {
            It 'Should properly format a path with drive letter and no backslash after colon' {
                Format-Path -Path 'C:temp/folder' -EnsureDriveLetterRoot | Should -Be 'C:\temp\folder'
            }
        }

        Context 'When using NoTrailingDirectorySeparator parameter' {
            It 'Should remove trailing separators and properly format the path' {
                Format-Path -Path 'C:temp/folder/' -EnsureDriveLetterRoot -NoTrailingDirectorySeparator | Should -Be 'C:\temp\folder'
            }
        }
    }

    Context 'When using ExpandEnvironmentVariable parameter' {
        It 'Should expand environment variables in the path' {
            $env:TestPath = 'C:\TestFolder'
            Format-Path -Path '%TestPath%' -ExpandEnvironmentVariable | Should -Be 'C:\TestFolder'
        }

        It 'Should handle paths with multiple environment variables' -Skip:($IsLinux -or $IsMacOS) {
            $env:BasePath = 'C:\Base'
            $env:SubPath = 'SubFolder'
            Format-Path -Path '%BasePath%\%SubPath%' -ExpandEnvironmentVariable | Should -Be 'C:\Base\SubFolder'
        }

        It 'Should not modify paths without environment variables' {
            Format-Path -Path 'C:\NoEnvVar' -ExpandEnvironmentVariable | Should -Be 'C:\NoEnvVar'
        }
    }
}
