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

            # Wildcard processing needed to handle differing Powershell 5/6/7 exception output
            { New-InvalidArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } |
                Should -Throw -PassThru | Select-Object -ExpandProperty Exception |
                    Should -BeLike ('{0}*Parameter*{1}*' -f $mockErrorMesssage, $mockArgumentName)
        }
    }

    Assert-VerifiableMock
}
