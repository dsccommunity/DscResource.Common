BeforeAll {
    $moduleName = 'DscResource.Common'
    $stubModuleName = 'DscResource.Common.Stubs'

    #region HEADER
    Remove-Module -Name $moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $moduleName -ListAvailable |
        Select-Object -First 1 |
            Import-Module -Force -ErrorAction 'Stop'
    #endregion HEADER

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

Describe 'Test-IsNanoServer' -Tag 'TestIsNanoServer' {
    BeforeAll {
        <#
            Must set this again as the variable from the initialization
            BeforeAll-block because we can't assume that it is passed into
            the Run-step (scope that runs the tests).
        #>
        $moduleName = 'DscResource.Common'
    }

    AfterAll {
        <#
            This removes the stub module that was imported in the
            initialization BeforeAll-block.
        #>
        Remove-Module -Name 'DscResource.Common.Stubs' -Force -ErrorAction 'SilentlyContinue'
    }

    Context 'When the current computer is a Datacenter Nano server' {
        BeforeAll {
            Mock -CommandName Get-CimInstance `
                -ModuleName $moduleName `
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
                -ModuleName $moduleName `
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
                -ModuleName $moduleName `
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
