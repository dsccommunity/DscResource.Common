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

Describe 'New-NotImplementedException' {
    Context 'When called with Message parameter only' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Mocked error'
            $mockExpectedErrorMessage = 'System.NotImplementedException: Mocked error'

            { New-NotImplementedException -Message $mockErrorMessage } | Should -Throw $mockExpectedErrorMessage
        }
    }

    Context 'When called with both the Message and ErrorRecord parameter' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Mocked error'
            $mockExceptionErrorMessage = 'Mocked exception error message'

            $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
            $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $mockException, $null, 'InvalidResult', $null

            # Wildcard processing needed to handle differing Powershell 5/6/7 exception output
            { New-NotImplementedException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } |
                Should -Throw -PassThru | Select-Object -ExpandProperty Exception |
                    Should -BeLike ('System.Exception: System.NotImplementedException: {0}*System.Exception: {1}*' -f
                        $mockErrorMessage, $mockExceptionErrorMessage)
        }
    }
}
