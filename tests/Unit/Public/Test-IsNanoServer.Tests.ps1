BeforeAll {
    $script:moduleName = 'DscResource.Common'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName

    <#
        This mocks the Get-CimInstance on platforms where the cmdlet does not
        exist, like Linux anc macOS.
    #>
    $stubModuleName = 'DscResource.Common.Stubs'
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
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName

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
