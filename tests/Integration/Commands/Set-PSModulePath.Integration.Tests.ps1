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

    # Determines if we should skip tests.
    if ($IsWindows -or $PSEdition -eq 'Desktop')
    {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

        $skipTest = -not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    else
    {
        $skipTest = $true
    }
}

BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Set-PSModulePath' -Tag 'SetPSModulePath' {
    Context 'When updating the session environment variable PSModulePath' {
        BeforeAll {
            $currentPSModulePath = $env:PSModulePath
        }

        AfterEach {
            $env:PSModulePath = $currentPSModulePath
        }

        It 'Should not throw an error and have set the correct value' {
            { Set-PSModulePath -Path 'C:\Module' } | Should -Not -Throw

            $env:PSModulePath | Should -Be 'C:\Module'
        }

        It 'Should have returned the session PSModulePath to the original value' {
            $env:PSModulePath | Should -Be $currentPSModulePath
        }
    }

    Context 'When updating the machine environment variable PSModulePath' -Skip:$skipTest {
        BeforeAll {
            $currentMachinePSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
        }

        AfterEach {
            [System.Environment]::SetEnvironmentVariable('PSModulePath', $currentMachinePSModulePath, [System.EnvironmentVariableTarget]::Machine)
        }

        It 'Should not throw an error and have set the correct value' {
            { Set-PSModulePath -Path 'C:\Module' -Machine } | Should -Not -Throw

            [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine') | Should -Be 'C:\Module'
        }

        It 'Should have returned the machine PSModulePath to the original value' -Skip:$skipTest {
            [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine') | Should -Be $currentMachinePSModulePath
        }
    }
}
