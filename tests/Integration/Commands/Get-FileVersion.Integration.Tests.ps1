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
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks noop" first to set up the test environment.'
    }
}

BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Get-FileVersion' -Tag 'Integration' {
    Context 'When running on Windows' -Skip:(-not $IsWindows) {
        Context 'When getting version information from notepad.exe' {
            BeforeAll {
                $script:notepadPath = Join-Path -Path $env:SystemRoot -ChildPath 'System32\notepad.exe'
            }

            It 'Should return version information for notepad.exe' {
                $result = Get-FileVersion -Path $script:notepadPath -ErrorAction Stop

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.Diagnostics.FileVersionInfo]
                $result.ProductVersion | Should -Not -BeNullOrEmpty
                $result.FileVersion | Should -Not -BeNullOrEmpty
            }

            It 'Should return version information using pipeline input' {
                $result = $script:notepadPath | Get-FileVersion -ErrorAction Stop

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.Diagnostics.FileVersionInfo]
                $result.ProductVersion | Should -Not -BeNullOrEmpty
            }

            It 'Should return version information using Get-Item pipeline input' {
                $result = Get-Item -Path $script:notepadPath | Get-FileVersion -ErrorAction Stop

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.Diagnostics.FileVersionInfo]
                $result.ProductVersion | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When getting version information from powershell.exe' {
            BeforeAll {
                $script:powershellPath = Join-Path -Path $env:SystemRoot -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'
            }

            It 'Should return version information for powershell.exe' {
                $result = Get-FileVersion -Path $script:powershellPath -ErrorAction Stop

                $result | Should -Not -BeNullOrEmpty
                $result | Should -BeOfType [System.Diagnostics.FileVersionInfo]
                $result.ProductVersion | Should -Not -BeNullOrEmpty
                $result.FileVersion | Should -Not -BeNullOrEmpty
                $result.ProductName | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When passing an invalid path' {
            It 'Should throw an error for non-existent file' {
                { Get-FileVersion -Path 'C:\NonExistent\File.exe' -ErrorAction Stop } |
                    Should -Throw
            }
        }

        Context 'When passing a directory path' {
            It 'Should throw the correct error' {
                { Get-FileVersion -Path $env:SystemRoot -ErrorAction Stop } |
                    Should -Throw
            }
        }
    }

    Context 'When running on non-Windows platforms' -Skip:($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        Context 'When getting version information from a shell executable' -Skip:(-not (Test-Path -Path '/bin/bash')) {
            BeforeAll {
                $script:bashPath = '/bin/bash'
            }

            It 'Should handle Unix executables appropriately' {
                # Unix executables typically don't have version info like Windows executables
                # This test verifies the command can be called without error
                $result = Get-FileVersion -Path $script:bashPath -ErrorAction 'Stop'

                # Result may be null or empty on Unix systems
                $result | Should -BeOfType [System.Diagnostics.FileVersionInfo]
            }
        }
    }
}
