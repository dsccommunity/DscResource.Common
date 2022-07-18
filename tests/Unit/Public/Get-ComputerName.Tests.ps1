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
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe 'Get-ComputerName' {
    BeforeAll {
        $mockComputerName = 'MyComputer'

        if ($IsLinux -or $IsMacOs)
        {
            function hostname
            {
            }

            Mock -CommandName 'hostname' -MockWith {
                return $mockComputerName
            } -ModuleName 'DscResource.Common'
        }
        else
        {
            $mockComputerName = $env:COMPUTERNAME
        }
    }

    Context 'When getting computer name' {
        It 'Should return the correct computer name' {
            Get-ComputerName | Should -Be $mockComputerName
        }
    }
}
