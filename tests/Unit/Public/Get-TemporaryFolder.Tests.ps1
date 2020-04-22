$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'SqlServerDsc.Common\Get-TemporaryFolder' -Tag 'GetTemporaryFolder' {
        Context 'When getting the current temporary path' {
            BeforeAll {
                $mockExpectedTempPath = [IO.Path]::GetTempPath()
            }

            It 'Should return the expected temporary path' {
                Get-TemporaryFolder | Should -BeExactly $mockExpectedTempPath
            }
        }

        switch ($true)
        {
            # Windows PowerShell or PowerShell 6+ on Windows
            (-not (Test-Path -Path variable:IsWindows) -or $IsWindows)
            {
                <#
                    $env:TEMP used short filename, Get-Item expands it then we
                    need to add a backslash to the path. Because $env:TEMP
                    is the only one not ending the path with a backslash.
                #>
                $mockTemporaryPath = (Get-Item -Path $env:TEMP).FullName + '\'
            }

            $IsMacOS
            {
                $mockTemporaryPath = $env:TMPDIR
            }

            $IsLinux
            {
                $mockTemporaryPath = '/tmp'
            }

            Default
            {
                throw 'Cannot set the temporary path. Unknown operating system.'
            }
        }

        Context 'When comparing returned temporary folder to other method of getting temporary folder' {
            It 'Should return the same temporary path' {
                Get-TemporaryFolder | Should -BeExactly $mockTemporaryPath
            }
        }
    }
}
