$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

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
    }
}
