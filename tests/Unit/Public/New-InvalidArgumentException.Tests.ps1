BeforeAll {
    $script:moduleName = 'DscResource.Common'

    #region HEADER
    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
    #endregion HEADER
}

Describe 'New-InvalidArgumentException' {
    Context 'When calling with both the Message and ArgumentName parameter' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Mocked error'
            $mockArgumentName = 'MockArgument'

            # Wildcard processing needed to handle differing Powershell 5/6/7 exception output
            { New-InvalidArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } |
                Should -Throw -PassThru | Select-Object -ExpandProperty Exception |
                    Should -BeLike ('{0}*Parameter*{1}*' -f $mockErrorMesssage, $mockArgumentName)
        }
    }
}
