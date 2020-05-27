BeforeAll {
    $script:moduleName = 'DscResource.Common'

    #region HEADER
    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
    #endregion HEADER
}

Describe 'New-InvalidResultException' {
    Context 'When calling with Message parameter only' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Mocked error'
            $mockExpectedErrorMessage = 'System.Exception: Mocked error'

            { New-InvalidResultException -Message $mockErrorMessage } | Should -Throw $mockExpectedErrorMessage
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
            { New-InvalidResultException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } |
                Should -Throw -Passthru | Select-Object -ExpandProperty Exception |
                  Should -BeLike ('System.Exception: System.Exception: {0}*System.Exception: {1}*' -f
                        $mockErrorMessage, $mockExceptionErrorMessage)
        }
    }
}
