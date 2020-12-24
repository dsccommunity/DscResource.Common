$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
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
                }
            }
            else
            {
                $previousComputerName = [Environment]::GetEnvironmentVariable('COMPUTERNAME', 'User')

                [Environment]::SetEnvironmentVariable('COMPUTERNAME', $mockComputerName, 'User')
            }
        }

        AfterAll {
            if (-not ($IsLinux -or $IsMacOs))
            {
                [Environment]::SetEnvironmentVariable('COMPUTERNAME', $previousComputerName, 'User')
            }
        }

        Context 'When getting computer name' {
            It 'Should return the correct computer name' {
                Get-ComputerName | Should -Be $mockComputerName
            }
        }
    }
}
