BeforeAll {
    $script:moduleName = 'DscResource.Common'

    #region HEADER
    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
    #endregion HEADER
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

                { Assert-IPAddress @testIPAddressParameters } | `
                    Should -Throw ($script:localizedData.AddressFormatError -f $testIPAddressParameters.Address)
            }
        }

        Context 'When address family is not supplied' {
            It 'Should throw an AddressFormatError error' {
                $testIPAddressParameters = @{
                    Address        = 'NotReal'
                }

                { Assert-IPAddress @testIPAddressParameters } | `
                    Should -Throw ($script:localizedData.AddressFormatError -f $testIPAddressParameters.Address)
            }
        }
    }

    Context 'When invoking with IPv4 Address and family mismatch' {
        It 'Should throw an AddressMismatchError error' {
            $testIPAddressParameters = @{
                Address        = '192.168.0.1'
                AddressFamily  = 'IPv6'
            }

            { Assert-IPAddress @testIPAddressParameters } | `
                Should -Throw ($script:localizedData.AddressIPv4MismatchError -f $testIPAddressParameters.Address, $testIPAddressParameters.AddressFamily)
        }
    }

    Context 'When invoking with IPv6 Address and family mismatch' {
        It 'Should throw an AddressMismatchError error' {
            $testIPAddressParameters = @{
                Address        = 'fe80::'
                AddressFamily  = 'IPv4'
            }

            { Assert-IPAddress @testIPAddressParameters } | `
                Should -Throw ($script:localizedData.AddressIPv6MismatchError -f $testIPAddressParameters.Address, $testIPAddressParameters.AddressFamily)
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
