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
