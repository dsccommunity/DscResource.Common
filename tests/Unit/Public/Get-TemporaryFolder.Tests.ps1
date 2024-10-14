[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:moduleName = 'DscResource.Common'

    # Make sure there are not other modules imported that will conflict with mocks.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

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
