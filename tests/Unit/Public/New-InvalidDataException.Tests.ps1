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
