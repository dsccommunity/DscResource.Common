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

Describe 'Test-AccountRequirePassword' -Tag 'Public' {
    Context 'When service account is a built-in account' {
        It 'Should return $false' {
            Test-AccountRequirePassword -Name 'NT Authority\NETWORK SERVICE' | Should -BeFalse
        }
    }

    Context 'When service account is a virtual account' {
        It 'Should return $false' {
            Test-AccountRequirePassword -Name 'NT SERVICE\MSSQL$PAYROLL' | Should -BeFalse
        }
    }

    Context 'When service account is a (global) managed service account' {
        It 'Should return $false' {
            Test-AccountRequirePassword -Name 'DOMAIN\MyMSA$' | Should -BeFalse
        }
    }

    Context 'When service account is a local user account' {
        It 'Should return $true' {
            Test-AccountRequirePassword -Name 'MySqlUser' | Should -BeTrue
        }
    }

    Context 'When service account is a domain user account' {
        It 'Should return $true' {
            Test-AccountRequirePassword -Name 'DOMAIN\MySqlUser' | Should -BeTrue
        }
    }
}
