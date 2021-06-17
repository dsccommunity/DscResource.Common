BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
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
