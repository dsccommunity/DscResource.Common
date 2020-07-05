$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName -Force

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

    Assert-VerifiableMock
}
