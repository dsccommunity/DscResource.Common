BeforeAll {
    $moduleName = 'DscResource.Common'
    $stubModuleName = 'DscResource.Common.Stubs'

    Remove-Module -Name $moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $moduleName -ListAvailable |
        Select-Object -First 1 |
            Import-Module -Force -ErrorAction 'Stop'

    <#
        This mocks the Get-CimInstance on platforms where the cmdlet does not
        exist, like Linux anc macOS.
    #>
    Remove-Module -Name $stubModuleName -Force -ErrorAction 'SilentlyContinue'
    New-Module -Name $stubModuleName -ScriptBlock {
        function Get-CimInstance
        {
            param
            (
                [Parameter()]
                [System.String]
                $ClassName
            )
        }
    } | Import-Module
}

AfterAll {
    <#
        This removes the stub module that was imported in the
        BeforeAll-block.
    #>
    Remove-Module -Name 'DscResource.Common.Stubs' -Force -ErrorAction 'SilentlyContinue'
}

Describe 'Test-IsNanoServer' -Tag 'TestIsNanoServer' {
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
