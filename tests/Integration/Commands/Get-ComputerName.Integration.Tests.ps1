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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Get-ComputerName' -Tag 'GetComputerName' {
    Context 'When getting computer name in real environment' {
        It 'Should return a valid computer name without FQDN switch' {
            $result = Get-ComputerName -ErrorAction Stop

            $result | Should -BeOfType [System.String]
            $result | Should -Not -BeNullOrEmpty
            # Should match the actual machine name from .NET
            $result | Should -Be ([System.Environment]::MachineName)
            # Should not contain dots (short name)
            $result | Should -Not -Match '\.'
        }

        It 'Should return a computer name with FQDN switch' {
            $result = Get-ComputerName -FullyQualifiedDomainName -ErrorAction Stop

            $result | Should -BeOfType [System.String]
            $result | Should -Not -BeNullOrEmpty
            # Should be at least as long as the short name
            $result.Length | Should -BeGreaterOrEqual ([System.Environment]::MachineName.Length)
        }

        It 'Should return consistent results on multiple calls' {
            $result1 = Get-ComputerName -ErrorAction Stop
            $result2 = Get-ComputerName -ErrorAction Stop

            $result1 | Should -Be $result2
        }

        It 'Should return consistent FQDN results on multiple calls' {
            $result1 = Get-ComputerName -FullyQualifiedDomainName -ErrorAction Stop
            $result2 = Get-ComputerName -FullyQualifiedDomainName -ErrorAction Stop

            $result1 | Should -Be $result2
        }
    }
}
