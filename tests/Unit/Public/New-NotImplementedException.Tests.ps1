BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
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
