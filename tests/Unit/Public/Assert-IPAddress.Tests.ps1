$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

<#
    .SYNOPSIS
        Returns an invalid argument exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
function Get-InvalidArgumentRecord
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' -ArgumentList @( $Message,
        $ArgumentName )
    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $argumentException, $ArgumentName, 'InvalidArgument', $null )
    }
    return New-Object @newObjectParams
}

InModuleScope $ProjectName {
    Describe 'ComputerManagementDsc.Common\Assert-IPAddress' -Tag 'AssertIPAddress' {
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
            It 'Should throw an AddressFormatError error' {
                $testIPAddressParameters = @{
                    Address        = 'NotReal'
                    AddressFamily  = 'IPv4'
                }

                $errorRecord = Get-InvalidArgumentRecord `
                    -Message ($script:localizedData.AddressFormatError -f $testIPAddressParameters.Address) `
                    -ArgumentName 'Address'

                { Assert-IPAddress @testIPAddressParameters } | Should -Throw $errorRecord
            }
        }
        Context 'When invoking with IPv4 Address and family mismatch' {
            It 'Should throw an AddressMismatchError error' {
                $testIPAddressParameters = @{
                    Address        = '192.168.0.1'
                    AddressFamily  = 'IPv6'
                }

                $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv4MismatchError -f $testIPAddressParameters.Address, $testIPAddressParameters.AddressFamily) `
                        -ArgumentName 'AddressFamily'

                { Assert-IPAddress @testIPAddressParameters } | Should -Throw $errorRecord
            }
        }
        Context 'When invoking with IPv6 Address and family mismatch' {
            It 'Should throw an AddressMismatchError error' {
                $testIPAddressParameters = @{
                    Address        = 'fe80::'
                    AddressFamily  = 'IPv4'
                }

                $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($script:localizedData.AddressIPv6MismatchError -f $testIPAddressParameters.Address, $testIPAddressParameters.AddressFamily) `
                        -ArgumentName 'AddressFamily'

                { Assert-IPAddress @testIPAddressParameters } | Should -Throw $errorRecord
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
}
