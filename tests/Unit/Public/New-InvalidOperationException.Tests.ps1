BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
}

Describe 'New-InvalidOperationException' {
    Context 'When calling with Message parameter only' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Mocked error'
            $mockExpectedErrorMessage = 'System.InvalidOperationException: Mocked error'

            { New-InvalidOperationException -Message $mockErrorMessage } | Should -Throw $mockExpectedErrorMessage
        }
    }

    Context 'When calling with both the Message and ErrorRecord parameter' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Mocked error'
            $mockExceptionErrorMessage = 'Mocked exception error message'

            $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
            $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $mockException, $null, 'InvalidResult', $null

            # Wildcard processing needed to handle differing Powershell 5/6/7 exception output
            { New-InvalidOperationException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } |
                Should -Throw -PassThru | Select-Object -ExpandProperty Exception |
                 Should -BeLike ('System.Exception: System.InvalidOperationException: {0}*System.Exception: {1}*' -f
                        $mockErrorMessage, $mockExceptionErrorMessage)
        }
    }
}
