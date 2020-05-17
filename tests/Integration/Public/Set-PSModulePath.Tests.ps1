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

Describe 'Set-PSModulePath' -Tag 'SetPSModulePath' {
    BeforeAll {
        $currentPSModulePath = $env:PSModulePath

        if ($isWindows -or $PSEdition -eq 'Desktop')
        {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

            $skipTest = -not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }
        else
        {
            $skipTest = $true
        }

        if (-not $skipTest)
        {
            $currentMachinePSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
        }
    }

    Context 'When updating the session environment variable PSModulePath' {
        AfterAll {
            $env:PSModulePath = $currentPSModulePath
        }

        It 'Should not throw an error and have set the correct value' {
            { Set-PSModulePath -Path 'C:\Module' } | Should -Not -Throw

            $env:PSModulePath | Should -Be 'C:\Module'
        }
    }

    Context 'When updating the machine environment variable PSModulePath' {
        AfterAll {
            if (-not $skipTest)
            {
                [System.Environment]::SetEnvironmentVariable('PSModulePath', $currentMachinePSModulePath, [System.EnvironmentVariableTarget]::Machine)
            }
        }

        It 'Should not throw an error and have set the correct value' -Skip:$skipTest {
            { Set-PSModulePath -Path 'C:\Module' -Machine } | Should -Not -Throw

            [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine') | Should -Be 'C:\Module'
        }
    }

    Context 'When the tests have run for Set-PSModulePath' {
        It 'Should have returned the session PSModulePath to the original value' {
            $env:PSModulePath | Should -Be $currentPSModulePath
        }

        It 'Should have returned the machine PSModulePath to the original value' -Skip:$skipTest {
            [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine') | Should -Be $currentMachinePSModulePath
        }
    }
}

