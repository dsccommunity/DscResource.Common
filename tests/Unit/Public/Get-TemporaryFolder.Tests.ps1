BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
}

Describe 'Get-TemporaryFolder' -Tag 'GetTemporaryFolder' {
    Context 'When getting the current temporary path' {
        BeforeAll {
            $mockExpectedTempPath = [IO.Path]::GetTempPath()
        }

        It 'Should return the expected temporary path' {
            Get-TemporaryFolder | Should -BeExactly $mockExpectedTempPath
        }
    }

    Context 'When comparing returned temporary folder to other method of getting temporary folder' {
        BeforeAll {
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
                    $mockTemporaryPath = '/tmp/'
                }

                Default
                {
                    throw 'Cannot set the temporary path. Unknown operating system.'
                }
            }
        }

        It 'Should return the same temporary path' {
            Get-TemporaryFolder | Should -BeExactly $mockTemporaryPath
        }
    }
}
