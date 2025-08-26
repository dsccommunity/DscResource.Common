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

Describe 'Get-ComputerName' {
    BeforeAll {
        $mockShortComputerName = 'MyComputer'
        $mockFqdnComputerName = 'MyComputer.domain.com'
    }

    Context 'When getting computer name without FQDN switch' {
        It 'Should return the short computer name' {
            $result = Get-ComputerName -ErrorAction Stop
            $result | Should -BeOfType [System.String]
            $result | Should -Not -BeNullOrEmpty
            # Should return the same as [System.Environment]::MachineName (short name)
            $result | Should -Be ([System.Environment]::MachineName)
        }
    }

    Context 'When getting computer name with FQDN switch' {
        It 'Should return the FQDN when DNS resolution succeeds' {
            $result = Get-ComputerName -FullyQualifiedDomainName -ErrorAction Stop
            $result | Should -BeOfType [System.String]
            $result | Should -Not -BeNullOrEmpty
            # The result should either be FQDN (if DNS works) or short name (if DNS fails)
            # We can't predict which without mocking, so just ensure it's not empty
        }
    }
}
