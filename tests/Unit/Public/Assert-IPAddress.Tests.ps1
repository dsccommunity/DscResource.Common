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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Assert-IPAddress' -Tag 'AssertIPAddress' {
    Context 'When invoking with valid IPv4 Address' {
        It 'Should not throw an error' {
            $testIPAddressParameters = @{
                Address        = '192.168.0.1'
                AddressFamily  = 'IPv4'
            }

            { Assert-IPAddress @testIPAddressParameters } | Should -Not -Throw
        }
    }

    Context 'When invoking with valid IPv6 Address' {
        It 'Should not throw an error' {
            $testIPAddressParameters = @{
                Address        = 'fe80:ab04:30F5:002b::1'
                AddressFamily  = 'IPv6'
            }

            { Assert-IPAddress @testIPAddressParameters } | Should -Not -Throw
        }
    }

    Context 'When invoking with invalid IP Address' {
        Context 'When address family is supplied' {
            It 'Should throw an AddressFormatError error' {
                $testIPAddressParameters = @{
                    Address        = 'NotReal'
                    AddressFamily  = 'IPv4'
                }

                $errorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.AddressFormatError
                }

                $errorMessage = $errorMessage -f $testIPAddressParameters.Address

                { Assert-IPAddress @testIPAddressParameters } |
                    Should -Throw -ExpectedMessage "$errorMessage*"
            }
        }

        Context 'When address family is not supplied' {
            It 'Should throw an AddressFormatError error' {
                $testIPAddressParameters = @{
                    Address        = 'NotReal'
                }

                $errorMessage = InModuleScope -ScriptBlock {
                    $script:localizedData.AddressFormatError
                }

                $errorMessage = $errorMessage -f $testIPAddressParameters.Address

                { Assert-IPAddress @testIPAddressParameters } |
                    Should -Throw -ExpectedMessage "$errorMessage*"
            }
        }
    }

    Context 'When invoking with IPv4 Address and family mismatch' {
        It 'Should throw an AddressMismatchError error' {
            $testIPAddressParameters = @{
                Address        = '192.168.0.1'
                AddressFamily  = 'IPv6'
            }

            $errorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.AddressIPv4MismatchError
            }

            $errorMessage = $errorMessage -f $testIPAddressParameters.Address, $testIPAddressParameters.AddressFamily

            { Assert-IPAddress @testIPAddressParameters } | `
                Should -Throw -ExpectedMessage "$errorMessage*"
        }
    }

    Context 'When invoking with IPv6 Address and family mismatch' {
        It 'Should throw an AddressMismatchError error' {
            $testIPAddressParameters = @{
                Address        = 'fe80::'
                AddressFamily  = 'IPv4'
            }

            $errorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.AddressIPv6MismatchError
            }

            $errorMessage = $errorMessage -f $testIPAddressParameters.Address, $testIPAddressParameters.AddressFamily

            { Assert-IPAddress @testIPAddressParameters } | `
                Should -Throw -ExpectedMessage "$errorMessage*"
        }
    }

    Context 'When invoking with valid IPv4 Address with no address family' {
        It 'Should not throw an error' {
            $testIPAddressParameters = @{
                Address        = '192.168.0.1'
            }

            { Assert-IPAddress @testIPAddressParameters } | Should -Not -Throw
        }
    }

    Context 'When invoking with valid IPv6 Address with no address family' {
        It 'Should not throw an error' {
            $testIPAddressParameters = @{
                Address        = 'fe80:ab04:30F5:002b::1'
            }

            { Assert-IPAddress @testIPAddressParameters } | Should -Not -Throw
        }
    }
}
