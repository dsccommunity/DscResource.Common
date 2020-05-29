$script:moduleName = 'DscResource.Common'

#region HEADER
Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

Get-Module -Name $script:moduleName -ListAvailable |
    Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
#endregion HEADER

Describe 'Test-IsNanoServer' -Tag 'TestIsNanoServer' {
    InModuleScope 'DscResource.Common' {
        BeforeAll {
            function Get-CimInstance
            {
                param
                (
                    [Parameter()]
                    [System.String]
                    $ClassName
                )
            }
        }
    }

    Context 'When the current computer is a Datacenter Nano server' {
        BeforeAll {
            Mock -CommandName Get-CimInstance `
                -ModuleName 'DscResource.Common' `
                -MockWith {
                    [PSCustomObject] @{
                        OperatingSystemSKU = 143
                    }
                }
        }

        It 'Should return true' {
            Test-IsNanoServer -Verbose | Should -BeTrue
        }
    }

    Context 'When the current computer is a Standard Nano server' {
        BeforeAll {
            Mock -CommandName Get-CimInstance `
                -ModuleName 'DscResource.Common' `
                -MockWith {
                    [PSCustomObject] @{
                        OperatingSystemSKU = 144
                    }
                }
        }

        It 'Should return true' {
            Test-IsNanoServer -Verbose | Should -BeTrue
        }
    }

    Context 'When the current computer is not a Nano server' {
        BeforeAll {
            Mock -CommandName Get-CimInstance `
                -ModuleName 'DscResource.Common' `
                -MockWith {
                    [PSCustomObject] @{
                        OperatingSystemSKU = 1
                    }
                }
        }

        It 'Should return false' {
            Test-IsNanoServer -Verbose | Should -BeFalse
        }
    }
}
