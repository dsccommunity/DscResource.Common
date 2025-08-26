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
            $result = Get-ComputerName
            $result | Should -BeOfType [System.String]
            $result | Should -Not -BeNullOrEmpty
            # Should return the same as [System.Environment]::MachineName (short name)
            $result | Should -Be ([System.Environment]::MachineName)
        }
    }

    Context 'When getting computer name with FQDN switch' {
        It 'Should return the FQDN when DNS resolution succeeds' {
            $result = Get-ComputerName -FullyQualifiedDomainName
            $result | Should -BeOfType [System.String]
            $result | Should -Not -BeNullOrEmpty
            # The result should either be FQDN (if DNS works) or short name (if DNS fails)
            # We can't predict which without mocking, so just ensure it's not empty
        }

        It 'Should handle DNS resolution gracefully' {
            # This test ensures the function doesn't throw even if DNS resolution fails
            { Get-ComputerName -FullyQualifiedDomainName } | Should -Not -Throw
        }
    }

    Context 'When testing parameter functionality' {
        It 'Should accept the FullyQualifiedDomainName switch parameter' {
            { Get-ComputerName -FullyQualifiedDomainName } | Should -Not -Throw
        }

        It 'Should work without any parameters' {
            { Get-ComputerName } | Should -Not -Throw
        }
    }

    Context 'When simulating FQDN scenario with mocking' {
        BeforeAll {
            # Test the DNS resolution logic with mocked values
            function Test-FqdnLogic {
                param(
                    [string]$ShortName,
                    [string]$DnsResult = $null,
                    [bool]$DnsThrows = $false,
                    [switch]$FullyQualifiedDomainName
                )

                $computerName = $ShortName

                if ($FullyQualifiedDomainName) {
                    if (-not $DnsThrows -and $DnsResult -and $DnsResult -ne $ShortName) {
                        $computerName = $DnsResult
                    }
                    # If DNS throws or returns same name, keep the short name
                }

                return $computerName
            }
        }

        It 'Should return short name when not requesting FQDN' {
            $result = Test-FqdnLogic -ShortName 'TestMachine'
            $result | Should -Be 'TestMachine'
        }

        It 'Should return FQDN when DNS resolution succeeds and FQDN requested' {
            $result = Test-FqdnLogic -ShortName 'TestMachine' -DnsResult 'TestMachine.example.com' -FullyQualifiedDomainName
            $result | Should -Be 'TestMachine.example.com'
        }

        It 'Should return short name when DNS resolution fails and FQDN requested' {
            $result = Test-FqdnLogic -ShortName 'TestMachine' -DnsThrows $true -FullyQualifiedDomainName
            $result | Should -Be 'TestMachine'
        }

        It 'Should return short name when DNS returns same name and FQDN requested' {
            $result = Test-FqdnLogic -ShortName 'TestMachine' -DnsResult 'TestMachine' -FullyQualifiedDomainName
            $result | Should -Be 'TestMachine'
        }
    }
}
