BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'
}

Describe 'New-InvalidDataException' {
    Context 'When calling with both the ErrorId and ErrorMessage parameter' {
        It 'Should throw the correct error' {
            $mockErrorId = 'MockedErrorId'
            $mockErrorMessage = 'Mocked error'

            $exception = { New-InvalidDataException -ErrorId $mockErrorId -ErrorMessage $mockErrorMessage } |
                Should -Throw -PassThru

            $exception.CategoryInfo.Category | Should -Be 'InvalidData'
            $exception.FullyQualifiedErrorId | Should -Be $mockErrorId
            $exception.Exception.Message | Should -Be $mockErrorMessage
        }
    }
}
