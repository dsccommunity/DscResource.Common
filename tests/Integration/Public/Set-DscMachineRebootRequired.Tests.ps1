$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            } )
    }).BaseName

Import-Module $ProjectName -Force

Describe 'Set-DscMachineRebootRequired' -Tag 'Set-DscMachineRebootRequired' {
    BeforeAll {
        $script:currentDSCMachineStatus = $global:DSCMachineStatus
    }

    Context 'When setting the DSC reboot status' {
        BeforeAll {
            $global:DSCMachineStatus = 0
        }

        AfterAll {
            if ($script:currentDSCMachineStatus -ne $global:DSCMachineStatus)
            {
                $global:DSCMachineStatus = $script:currentDSCMachineStatus
            }
        }

        It 'Should not throw an error and have set the correct value' {
            { Set-DscMachineRebootRequired } | Should -Not -Throw

            $global:DSCMachineStatus | Should -Be 1
        }
    }
}
