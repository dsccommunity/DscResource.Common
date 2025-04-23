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
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'New-ArgumentException' {
    Context 'When calling with both the Message and ArgumentName parameter' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Mocked error'
            $mockArgumentName = 'MockArgument'

            # Wildcard processing needed to handle differing Powershell 5/6/7 exception output
            { New-ArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } |
                Should -Throw -PassThru | Select-Object -ExpandProperty Exception |
                    Should -BeLike ('{0}*Parameter*{1}*' -f $mockErrorMesssage, $mockArgumentName)
        }
    }

    Context 'When using command alias New-InvalidArgumentException' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Mocked error'
            $mockArgumentName = 'MockArgument'

            # Wildcard processing needed to handle differing Powershell 5/6/7 exception output
            { New-InvalidArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } |
                Should -Throw -PassThru | Select-Object -ExpandProperty Exception |
                    Should -BeLike ('{0}*Parameter*{1}*' -f $mockErrorMesssage, $mockArgumentName)
        }
    }

    Context 'When calling with the PassThru parameter' {
        It 'Should return the correct error record' {
            $mockErrorMessage = 'Mocked error'
            $mockArgumentName = 'MockArgument'

            $result = New-ArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName -PassThru
            $result | Should -BeOfType 'System.ArgumentException'
            <#
                There is a difference between how Windows PowerShell and PowerShell
                outputs this error message. The regular expression handles both cases.

                Windows PowerShell message:
                    Mocked error
                    Parameter name: MockArgument

                PowerShell message:
                    Mocked error (Parameter 'MockArgument')
            #>
            $result.Message | Should -Match ("{0}\r?\n?.*\(?Parameter (?:name: )?'?{1}'?\)?" -f $mockErrorMessage, $mockArgumentName)
            $result.ParamName | Should -Be $mockArgumentName
        }
    }

    Context 'When calling without the PassThru parameter' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Mocked error'
            $mockArgumentName = 'MockArgument'

            $result = { New-ArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } |
                Should -Throw -PassThru

            $result | Should -BeOfType 'System.Management.Automation.ErrorRecord'
            $result | Select-Object -ExpandProperty 'Exception' |
                    Should -BeLike ('System.ArgumentException: {0}*Parameter*{1}*' -f $mockErrorMessage, $mockArgumentName)
        }
    }
}
