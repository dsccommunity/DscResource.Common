$script:moduleName = 'DscResource.Common'

#region HEADER
Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

$mut = Get-Module -Name $script:moduleName -ListAvailable |
    Select-Object -First 1 |
    Import-Module -Force -ErrorAction 'Stop' -PassThru
#endregion HEADER

BeforeAll {
    $script:moduleName = 'DscResource.Common'

    # Convert-path required for PS7 or Join-Path fails
    $ProjectPath = "$($PSScriptRoot)\..\.." | Convert-Path

    $SourcePath = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch { $false }) }
    ).Directory.FullName
}

Describe 'General module control' -Tags 'FunctionalQuality' {
    It 'imports without errors' {
        { Import-Module -Name $script:moduleName -Force -ErrorAction Stop } | Should -Not -Throw

        Get-Module $script:moduleName | Should -Not -BeNullOrEmpty
    }

    It 'Removes without error' {
        { Remove-Module -Name $script:moduleName -ErrorAction Stop } | Should -Not -Throw

        Get-Module $script:moduleName | Should -BeNullOrEmpty
    }
}

# Must use the imported module to build test cases.
$allModuleFunctions = & $mut {Get-Command -Module $args[0] -CommandType Function } $script:moduleName

# Build test cases.
$testCases = @()
foreach ($function in $allModuleFunctions)
{
    $testCases += @{
        Name = $function.Name
    }

}

Describe "Quality for module" -Tags 'TestQuality' {
    BeforeAll {
        if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue)
        {
            $scriptAnalyzerRules = Get-ScriptAnalyzerRule
        }
        else
        {
            if ($ErrorActionPreference -ne 'Stop')
            {
                Write-Warning "ScriptAnalyzer not found!"
            }
            else
            {
                Throw "ScriptAnalyzer not found!"
            }
        }
    }

    It "<Name> has a unit test" -TestCases $testCases {
        $functionFile = Get-ChildItem -path $SourcePath -Recurse -Include "$Name.ps1"

        Get-ChildItem "tests\" -Recurse -Include "$Name.Tests.ps1" | Should -Not -BeNullOrEmpty
    }

    It "Script Analyzer for <Name>" -TestCases $testCases -Skip:(-not $scriptAnalyzerRules) {
        $functionFile = Get-ChildItem -path $SourcePath -Recurse -Include "$Name.ps1"

        $PSSAResult = (Invoke-ScriptAnalyzer -Path $functionFile.FullName)
        $Report = $PSSAResult | Format-Table -AutoSize | Out-String -Width 110
        $PSSAResult  | Should -BeNullOrEmpty -Because `
            "some rule triggered.`r`n`r`n $Report"
    }
}

Describe "Help for module" -Tags 'helpQuality' {
    It '<Name> has a SYNOPSIS' -TestCases $testCases {
        $functionFile = Get-ChildItem -Path $SourcePath -Recurse -Include "$Name.ps1"

        $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
        ParseInput((Get-Content -Raw $functionFile.FullName), [ref] $null, [ref] $null)

        $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
        $ParsedFunction = $AbstractSyntaxTree.FindAll( $AstSearchDelegate, $true ) |
            ? Name -eq $Name

        $FunctionHelp = $ParsedFunction.GetHelpContent()

        $FunctionHelp.Synopsis | Should -Not -BeNullOrEmpty
    }

    It '<Name> has a Description, with length > 40' -TestCases $testCases {
        $functionFile = Get-ChildItem -Path $SourcePath -Recurse -Include "$Name.ps1"

        $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
        ParseInput((Get-Content -Raw $functionFile.FullName), [ref] $null, [ref] $null)

        $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
        $ParsedFunction = $AbstractSyntaxTree.FindAll( $AstSearchDelegate, $true ) |
            ? Name -eq $Name

        $FunctionHelp = $ParsedFunction.GetHelpContent()

        $FunctionHelp.Description.Length | Should -BeGreaterThan 40
    }

    It '<Name> has at least 1 example' -TestCases $testCases {
        $functionFile = Get-ChildItem -Path $SourcePath -Recurse -Include "$Name.ps1"

        $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
        ParseInput((Get-Content -Raw $functionFile.FullName), [ref] $null, [ref] $null)

        $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
        $ParsedFunction = $AbstractSyntaxTree.FindAll( $AstSearchDelegate, $true ) |
            ? Name -eq $Name

        $FunctionHelp = $ParsedFunction.GetHelpContent()

        $FunctionHelp.Examples.Count | Should -BeGreaterThan 0
        $FunctionHelp.Examples[0] | Should -Match ([regex]::Escape($function.Name))
        $FunctionHelp.Examples[0].Length | Should -BeGreaterThan ($function.Name.Length + 10)

    }

    It '<Name> has described the parameters' -TestCases $testCases {
        $functionFile = Get-ChildItem -Path $SourcePath -Recurse -Include "$Name.ps1"

        $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::
        ParseInput((Get-Content -Raw $functionFile.FullName), [ref] $null, [ref] $null)

        $AstSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
        $ParsedFunction = $AbstractSyntaxTree.FindAll( $AstSearchDelegate, $true ) |
            ? Name -eq $Name

        $FunctionHelp = $ParsedFunction.GetHelpContent()

        $parameters = $ParsedFunction.Body.ParamBlock.Parameters.Name.VariablePath.ForEach{ $_.ToString() }
        foreach ($parameter in $parameters)
        {
            $FunctionHelp.Parameters.($parameter.ToUpper()) | Should -Not -BeNullOrEmpty -Because ('the parameter {0} must have a description' -f $parameter)
            $FunctionHelp.Parameters.($parameter.ToUpper()).Length | Should -BeGreaterThan 25 -Because ('the parameter {0} must have descriptive description' -f $parameter)
        }
    }
}
