$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName -Force
Describe 'New-InvalidArgumentException' {
    Context 'When calling with both the Message and ArgumentName parameter' {
        It 'Should throw the correct error' {
            $mockErrorMessage = 'Mocked error'
            $mockArgumentName = 'MockArgument'

            { New-InvalidArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } | Should -Throw ('Parameter name: {0}' -f $mockArgumentName)
        }
    }

    Assert-VerifiableMock
}
