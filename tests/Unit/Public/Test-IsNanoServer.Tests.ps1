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

Describe 'Test-IsNanoServer' -Tag TestIsNanoServer {
    Context 'When the current computer is a Datacenter Nano server' {
        Mock -CommandName Get-CimInstance `
            -ModuleName $ProjectName `
            -MockWith {
                [PSCustomObject] @{
                    OperatingSystemSKU = 143
                }
            }

        It 'Should retrun true' {
            Test-IsNanoServer -Verbose | Should -BeTrue
        }
    }

    Context 'When the current computer is a Standard Nano server' {
        Mock -CommandName Get-CimInstance `
            -ModuleName $ProjectName `
            -MockWith {
                [PSCustomObject] @{
                    OperatingSystemSKU = 144
                }
            }

        It 'Should retrun true' {
            Test-IsNanoServer -Verbose | Should -BeTrue
        }
    }

    Context 'When the current computer is not a Nano server' {
        Mock -CommandName Get-CimInstance `
            -ModuleName $ProjectName `
            -MockWith {
                [PSCustomObject] @{
                    OperatingSystemSKU = 1
                }
            }

        It 'Should retrun false' {
            Test-IsNanoServer -Verbose | Should -BeFalse
        }
    }
}
