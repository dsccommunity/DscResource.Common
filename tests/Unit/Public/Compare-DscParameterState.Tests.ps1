[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'because ConvertTo-SecureString is used to simplify the tests.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:moduleName = 'DscResource.Common'

    # Make sure there are not other modules imported that will conflict with mocks.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

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

Describe 'DscResource.Common\Compare-DscParameterState' {
    BeforeAll {
        $verbose = $false
    }

    Context 'When comparing large hashtables' {
        BeforeAll {
            $currentValues = Get-Content -Path "$PSScriptRoot/Assets/CurrentState.yml" -Raw | ConvertFrom-Yaml
            $desiredValues = Get-Content -Path "$PSScriptRoot/Assets/DesiredState.yml" -Raw | ConvertFrom-Yaml
        }

        Context 'When all values match' {

            It 'Should not throw exception' {
                {
                    $script:result = Compare-DscParameterState -CurrentValues $currentValues -DesiredValues $desiredValues -Verbose:$verbose
                } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }
        }
    }


    Context 'When testing single values' {
        BeforeAll {
            $currentValues = @{
                String      = 'a string'
                Bool        = $true
                Int         = 99
                Array       = 'a', 'b', 'c'
                Hashtable   = @{
                    k1 = 'Test'
                    k2 = 123
                    k3 = 'v1', 'v2', 'v3'
                }
                ScriptBlock = { Get-Date }
            }
        }

        Context 'When all values match' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String      = 'a string'
                    Bool        = $true
                    Int         = 99
                    Array       = 'a', 'b', 'c'
                    Hashtable   = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                    ScriptBlock = { Get-Date }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return null' {
                $script:result | Should -BeNullOrEmpty
            }
        }

        Context 'When a string is mismatched' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'different string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for String InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'String'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return same type in values' {
                $script:result.Where({
                    $_.Property -eq 'String'
                }).ActualType | Should -Be $script:result.Where({
                    $_.Property -eq 'String'
                }).ExpectedType
            }

            It 'Should not return other property by default' {
                $script:result.Where({
                    $_.Property -ne 'String'
                }).InDesiredState | Should -BeNullOrEmpty
            }
        }

        Context 'When a boolean is mismatched' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $false
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Bool InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return same type in values' {
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).ActualType | Should -Be $script:result.Where({
                    $_.Property -eq 'Bool'
                }).ExpectedType
            }

            It 'Should not return other property by default' {
                $script:result.Where({
                    $_.Property -ne 'Bool'
                }).InDesiredState | Should -BeNullOrEmpty
            }
        }

        Context 'When an int is mismatched' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 1
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Int InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return same type in values' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).ActualType | Should -Be $script:result.Where({
                    $_.Property -eq 'Int'
                }).ExpectedType
            }

            It 'Should not return other property by default' {
                $script:result.Where({
                    $_.Property -ne 'Int'
                }).InDesiredState | Should -BeNullOrEmpty
            }
        }

        Context 'When an scriptblock is mismatched' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String      = 'a string'
                    Bool        = $true
                    Int         = 99
                    Array       = 'a', 'b', 'c'
                    Hashtable   = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                    ScriptBlock = { Get-Process }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for ScriptBlock InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'ScriptBlock'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return same type in values' {
                $script:result.Where({
                    $_.Property -eq 'ScriptBlock'
                }).ActualType | Should -Be $script:result.Where({
                    $_.Property -eq 'ScriptBlock'
                }).ExpectedType
            }

            It 'Should not return other property by default' {
                $script:result.Where({
                    $_.Property -ne 'ScriptBlock'
                }).InDesiredState | Should -BeNullOrEmpty
            }
        }

        Context 'When an int is mismatched without ScriptBlock' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 1
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Int InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return same type in values' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).ActualType | Should -Be $script:result.Where({
                    $_.Property -eq 'Int'
                }).ExpectedType
            }

            It 'Should not return other property by default' {
                $script:result.Where({
                    $_.Property -ne 'Int'
                }).InDesiredState | Should -BeNullOrEmpty
            }
        }

        Context 'When a type is mismatched' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = '99'
                    Array  = 'a', 'b', 'c'
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Int InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should not return same type in values' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).ActualType | Should -Not -Be $script:result.Where({
                    $_.Property -eq 'Int'
                }).ExpectedType
            }

            It 'Should not return other property by default' {
                $script:result.Where({
                    $_.Property -ne 'Int'
                }).InDesiredState | Should -BeNullOrEmpty
            }
        }

        Context 'When a type is mismatched but TurnOffTypeChecking is used' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = '99'
                    Array  = 'a', 'b', 'c'
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -TurnOffTypeChecking `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return null result' {
                $script:result | Should -BeNullOrEmpty
            }
        }

        Context 'When a value is mismatched but ExcludeProperties is used to exclude then' {
            BeforeAll {
                $desiredValues = @{
                    String      = 'some other string'
                    Bool        = $true
                    Int         = 99
                    Array       = 'a', 'b', 'c'
                    Hashtable   = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                    ScriptBlock = { Get-Date }
                }

                $excludeProperties = @(
                    'String'
                )
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -ExcludeProperties $excludeProperties `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return null result' {
                $script:result | Should -BeNullOrEmpty
            }
        }

        Context 'When a value is mismatched but it is not in Properties then' {
            BeforeAll {
                $desiredValues = @{
                    String      = 'some other string'
                    Bool        = $true
                    Int         = 99
                    Array       = 'a', 'b', 'c'
                    Hashtable   = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                    ScriptBlock = { Get-Date }
                }

                $properties = @(
                    'Bool'
                    'Int'
                    'Array'
                    'Hashtable'
                    'ScriptBlock'
                )
            }

            Context 'When using the alias ValuesToCheck' {
                It 'Should not throw exception' {
                    { $script:result = Compare-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $properties `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return null result' {
                    $script:result | Should -BeNullOrEmpty
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Properties $properties `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return null result' {
                $script:result | Should -BeNullOrEmpty
            }

            Context 'When a value is mismatched but it is in Properties then' {
                BeforeAll {
                    $properties = @(
                        'String'
                        'Bool'
                        'Int'
                        'Array'
                        'Hashtable'
                    )
                }

                It 'Should not throw exception' {
                    { $script:result = Compare-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -Properties $properties `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should not be null' {
                    $script:result | Should -Not -BeNullOrEmpty
                }

                It 'Should return $false for String InDesiredState' {
                    $script:result.Where({
                        $_.Property -eq 'String'
                    }).InDesiredState | Should -BeFalse
                }

                It 'Should return same type in values' {
                    $script:result.Where({
                        $_.Property -eq 'String'
                    }).ActualType | Should -Be $script:result.Where({
                        $_.Property -eq 'String'
                    }).ExpectedType
                }

                It 'Should not return other property by default' {
                    $script:result.Where({
                        $_.Property -ne 'String'
                    }).InDesiredState | Should -BeNullOrEmpty
                }
            }
        }
    }

    Context 'When testing single values and use IncludeInDesiredState parameter' {
        BeforeAll {
            $currentValues = @{
                String      = 'a string'
                Bool        = $true
                Int         = 99
                Array       = 'a', 'b', 'c'
                Hashtable   = @{
                    k1 = 'Test'
                    k2 = 123
                    k3 = 'v1', 'v2', 'v3'
                }
                ScriptBlock = { Get-Date }
            }
        }

        Context 'When all values match' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String      = 'a string'
                    Bool        = $true
                    Int         = 99
                    Array       = 'a', 'b', 'c'
                    Hashtable   = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                    ScriptBlock = { Get-Date }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose  } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return all InDesiredState in $true' {
                $script:result.InDesiredState  | Should -Not -Contain $false
            }
        }

        Context 'When a string is mismatched' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'different string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for String InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'String'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without String property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'String'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When a boolean is mismatched' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $false
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Bool InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Bool property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Bool'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When an int is mismatched' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 1
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Int InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Int property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Int'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When an scriptblock is mismatched' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String      = 'a string'
                    Bool        = $true
                    Int         = 99
                    Array       = 'a', 'b', 'c'
                    Hashtable   = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                    ScriptBlock = { Get-Process }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for ScriptBlock InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'ScriptBlock'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without ScriptBlock property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'ScriptBlock'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When an int is mismatched without ScriptBlock' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 1
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Int InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Int property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Int'
                }).InDesiredState | Should -Not -Contain $false
            }

            It 'Should not return property with ScriptBlock in value' {
                $script:result.Where({
                    $_.Property -eq 'ScriptBlock'
                }) | Should -BeNullOrEmpty
            }
        }

        Context 'When a type is mismatched' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = '99'
                    Array  = 'a', 'b', 'c'
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Int InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Int property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Int'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When a type is mismatched but TurnOffTypeChecking is used' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = '99'
                    Array  = 'a', 'b', 'c'
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -TurnOffTypeChecking `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for Int InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return all InDesiredState in $true' {
                $script:result.InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When a value is mismatched but ExcludeProperties is used to exclude then' {
            BeforeAll {
                $desiredValues = @{
                    String      = 'some other string'
                    Bool        = $true
                    Int         = 99
                    Array       = 'a', 'b', 'c'
                    Hashtable   = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                    ScriptBlock = { Get-Date }
                }

                $excludeProperties = @(
                    'String'
                )
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -ExcludeProperties $excludeProperties `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return all InDesiredState in $true' {
                $script:result.InDesiredState | Should -Not -Contain $false
            }

            It 'Should not return property with String in value' {
                $script:result.Where({
                    $_.Property -eq 'String'
                }) | Should -BeNullOrEmpty
            }
        }

        Context 'When a value is mismatched but it is not in Properties then' {
            BeforeAll {
                $desiredValues = @{
                    String      = 'some other string'
                    Bool        = $true
                    Int         = 99
                    Array       = 'a', 'b', 'c'
                    Hashtable   = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                    ScriptBlock = { Get-Date }
                }

                $properties = @(
                    'Bool'
                    'Int'
                    'Array'
                    'Hashtable'
                    'ScriptBlock'
                )
            }

            Context 'When using the alias ValuesToCheck' {
                It 'Should not throw exception' {
                    { $script:result = Compare-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $properties `
                            -IncludeInDesiredState `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should not be null' {
                    $script:result | Should -Not -BeNullOrEmpty
                }

                It 'Should return all InDesiredState in $true' {
                    $script:result.InDesiredState | Should -Not -Contain $false
                }

                It 'Should return all property in $properties' {
                    $script:result.Property.Count | Should -Be $properties.Count
                    foreach ($property in $properties)
                    {
                        $property | Should -BeIn $script:result.Property
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Properties $properties `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return all InDesiredState in $true' {
                $script:result.InDesiredState | Should -Not -Contain $false
            }

            It 'Should return all property in $properties' {
                $script:result.Property.Count | Should -Be $properties.Count

                foreach ($property in $properties)
                {
                    $property | Should -BeIn $script:result.Property
                }
            }

            Context 'When a value is mismatched but it is in Properties then' {
                BeforeAll {
                    $properties = @(
                        'String'
                        'Bool'
                        'Int'
                        'Array'
                        'Hashtable'
                    )
                }

                It 'Should not throw exception' {
                    { $script:result = Compare-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -Properties $properties `
                            -IncludeInDesiredState `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should not be null' {
                    $script:result | Should -Not -BeNullOrEmpty
                }

                It 'Should return $false for String InDesiredState' {
                    $script:result.Where({
                        $_.Property -eq 'String'
                    }).InDesiredState | Should -BeFalse
                }

                It 'Should return all InDesiredState (without String property) in $true' {
                    $script:result.Where({
                        $_.Property -ne 'String'
                    }).InDesiredState | Should -Not -Contain $false
                }

                It 'Should return all property in $properties' {
                    $script:result.Property.Count | Should -Be $properties.Count

                    foreach ($property in $properties)
                    {
                        $property | Should -BeIn $script:result.Property
                    }
                }

                It 'Should not return property with ScriptBlock in value' {
                    $script:result.Where({
                        $_.Property -eq 'ScriptBlock'
                    }) | Should -BeNullOrEmpty
                }
            }
        }
    }

    Context 'When testing PSCredential' {

        Context 'When currentValue is PSCredential type' {
            BeforeAll {
                $currentValues = @{
                    String      = 'a string'
                    Bool        = $true
                    Int         = 99
                    Array       = 'a', 'b', 'c'
                    Hashtable   = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                    ScriptBlock = { Get-Date }
                    PSCredential = [System.Management.Automation.PSCredential]::new(
                        'UserName',
                        $(ConvertTo-SecureString -String 'Pa55w.rd' -AsPlainText -Force)
                    )
                }
            }

            Context 'When all values match' {
                BeforeAll {
                    $desiredValues = [PSObject] @{
                        String      = 'a string'
                        Bool        = $true
                        Int         = 99
                        Array       = 'a', 'b', 'c'
                        Hashtable   = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                        ScriptBlock = { Get-Date }
                        PSCredential = [System.Management.Automation.PSCredential]::new(
                            'UserName',
                            $(ConvertTo-SecureString -String 'Pa55w.rd' -AsPlainText -Force)
                        )
                    }
                }
                It 'Should not throw exception' {
                    { $script:result = Compare-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -IncludeInDesiredState `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should not be null' {
                    $script:result | Should -Not -BeNullOrEmpty
                }

                It 'Should return all InDesiredState in $true' {
                    $script:result.InDesiredState  | Should -Not -Contain $false
                }
            }

            Context 'When an PSCredential is mismatched' {
                BeforeAll {
                    $desiredValues = [PSObject] @{
                        String      = 'a string'
                        Bool        = $true
                        Int         = 99
                        Array       = 'a', 'b', 'c'
                        Hashtable   = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                        ScriptBlock = { Get-Date }
                        PSCredential = [System.Management.Automation.PSCredential]::new(
                            'SurName',
                            $(ConvertTo-SecureString -String 'Pa55w.rd' -AsPlainText -Force)
                        )
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Compare-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -IncludeInDesiredState `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should not be null' {
                    $script:result | Should -Not -BeNullOrEmpty
                }

                It 'Should return $false for PSCredential InDesiredState' {
                    $script:result.Where({
                        $_.Property -eq 'PSCredential'
                    }).InDesiredState | Should -BeFalse
                }

                It 'Should return all InDesiredState (without PSCredential property) in $true' {
                    $script:result.Where({
                        $_.Property -ne 'PSCredential'
                    }).InDesiredState | Should -Not -Contain $false
                }
            }
        }

        Context 'When currentValue is string type' {
            BeforeAll {
                $currentValues = @{
                    String      = 'a string'
                    Bool        = $true
                    Int         = 99
                    Array       = 'a', 'b', 'c'
                    Hashtable   = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                    ScriptBlock = { Get-Date }
                    PScredential = 'UserName'
                }
            }

            Context 'When all values match' {
                BeforeAll {
                    $desiredValues = [PSObject] @{
                        String      = 'a string'
                        Bool        = $true
                        Int         = 99
                        Array       = 'a', 'b', 'c'
                        Hashtable   = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                        ScriptBlock = { Get-Date }
                        PSCredential = [System.Management.Automation.PSCredential]::new(
                            'UserName',
                            $(ConvertTo-SecureString -String 'Pa55w.rd' -AsPlainText -Force)
                        )
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Compare-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -IncludeInDesiredState `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should not be null' {
                    $script:result | Should -Not -BeNullOrEmpty
                }

                It 'Should return all InDesiredState in $true' {
                    $script:result.InDesiredState  | Should -Not -Contain $false
                }
            }

            Context 'When an PSCredential is mismatched' {
                BeforeAll {
                    $desiredValues = [PSObject] @{
                        String      = 'a string'
                        Bool        = $true
                        Int         = 99
                        Array       = 'a', 'b', 'c'
                        Hashtable   = @{
                            k1 = 'Test'
                            k2 = 123
                            k3 = 'v1', 'v2', 'v3'
                        }
                        ScriptBlock = { Get-Date }
                        PSCredential = [System.Management.Automation.PSCredential]::new(
                            'SurName',
                            $(ConvertTo-SecureString -String 'Pa55w.rd' -AsPlainText -Force)
                        )
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Compare-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -IncludeInDesiredState `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should not be null' {
                    $script:result | Should -Not -BeNullOrEmpty
                }

                It 'Should return $false for PSCredential InDesiredState' {
                    $script:result.Where({
                        $_.Property -eq 'PSCredential'
                    }).InDesiredState | Should -BeFalse
                }

                It 'Should return all InDesiredState (without PSCredential property) in $true' {
                    $script:result.Where({
                        $_.Property -ne 'PSCredential'
                    }).InDesiredState | Should -Not -Contain $false
                }
            }
        }
    }

    Context 'When testing array values' {
        BeforeAll {
            $currentValues = @{
                String    = 'a string'
                Bool      = $true
                Int       = 99
                Array     = 'a', 'b', 'c', 1
                SingleValueArray = 'v1', 'v2' #for testing the comparison of single value arrays in the desired state
                Hashtable = @{
                    k1 = 'Test'
                    k2 = 123
                    k3 = 'v1', 'v2', 'v3'
                }
            }
        }

        Context 'When array is missing a value' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Array InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Array property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Array'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When array has an additional value' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 99
                    Array  = 'a', 'b', 'c', 1, 2
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Array InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Array property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Array'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When array has a different value' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 99
                    Array  = 'a', 'x', 'c', 1
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Array InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Array property) in $true' {
                $script:result.Where({$_.Property -ne 'Array'}).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When array has different order' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 99
                    Array  = 'c', 'b', 'a', 1
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Array InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Array property) in $true' {
                $script:result.Where({$_.Property -ne 'Array'}).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When array has different order but SortArrayValues is used' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 99
                    Array  = 'c', 'b', 'a', 1
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -SortArrayValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for Array InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return all InDesiredState (without Array property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Array'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When array has a value with a different type' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 99
                    Array  = 'a', 'b', 'c', '1'
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Array InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Array property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Array'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When array has a value with a different type but TurnOffTypeChecking is used' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 99
                    Array  = 'a', 'b', 'c', '1'
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -TurnOffTypeChecking `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for Array InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return all InDesiredState (without Array property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Array'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When there is a single-valued array and TurnOffTypeChecking is used' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c', 1
                    SingleValueArray = 'v1' #for testing the comparison of single value arrays in the desired state
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -TurnOffTypeChecking `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for SingleValueArray InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'SingleValueArray'
                }).InDesiredState | Should -BeFalse
            }
        }

        Context 'When both arrays are empty' {
            BeforeAll {
                $currentValues = @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = @()
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = @()
                    }
                }

                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = @()
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = @()
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for Array InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return all InDesiredState (without Array property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Array'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When a current value array is empty' {
            BeforeAll {
                $currentValues = @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = @('a','b','c')
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = @()
                    }
                }

                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = @()
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = @()
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Array InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Array property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Array'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When a desired value array is empty' {
            BeforeAll {
                $currentValues = @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = @()
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = @()
                    }
                }

                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = @('a','b','c')
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = @()
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Array InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Array property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Array'
                }).InDesiredState | Should -Not -Contain $false
            }
        }
    }

    Context 'When testing hashtables' {
        BeforeAll {
            $currentValues = @{
                String    = 'a string'
                Bool      = $true
                Int       = 99
                Array     = 'a', 'b', 'c'
                Hashtable = @{
                    k1 = 'Test'
                    k2 = 123
                    k3 = 'v1', 'v2', 'v3', 99
                }
            }
        }

        Context 'When hashtable is missing a value' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Hashtable InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Hashtable'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Hashtable property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Hashtable'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When hashtable has an additional value' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99, 100
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Hashtable InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Hashtable'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Hashtable property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Hashtable'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When hashtable has a different value' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'xx', 'v2', 'v3', 99
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Hashtable InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Hashtable'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Hashtable property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Hashtable'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When an array in hashtable has different order' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v3', 'v2', 'v1', 99
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Hashtable InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Hashtable'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Hashtable property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Hashtable'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When an array in hashtable has different order but SortArrayValues is used' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v3', 'v2', 'v1', 99
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -SortArrayValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for Hashtable InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Hashtable'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return all InDesiredState (without Hashtable property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Hashtable'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When hashtable has a value with a different type' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', '99'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for Hashtable InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Hashtable'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Hashtable property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Hashtable'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When hashtable has a value with a different type but TurnOffTypeChecking is used' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -TurnOffTypeChecking `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for Hashtable InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Hashtable'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return all InDesiredState (without Hashtable property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Hashtable'
                }).InDesiredState | Should -Not -Contain $false
            }
        }
    }

    Context 'When reverse checking' {
        BeforeAll {
            $currentValues = @{
                String    = 'a string'
                Bool      = $true
                Int       = 99
                Array     = 'a', 'b', 'c', 1
                Hashtable = @{
                    k1 = 'Test'
                    k2 = 123
                    k3 = 'v1', 'v2', 'v3'
                }
            }
        }

        Context 'When even if missing property in the desired state' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    Array     = 'a', 'b', 'c', 1
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -ReverseCheck `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for property Array and Hashtable' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeTrue
                $script:result.Where({
                    $_.Property -eq 'Hashtable'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return $false for property String, Bool, Int' {
                $script:result.Where({
                    $_.Property -eq 'String'
                }).InDesiredState | Should -BeFalse
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).InDesiredState | Should -BeFalse
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).InDesiredState | Should -BeFalse
            }
        }

        Context 'When missing property in the desired state' {
            BeforeAll {
                $currentValues = @{
                    String = 'a string'
                    Bool   = $true
                }

                $desiredValues = [PSObject] @{
                    String = 'a string'
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -ReverseCheck `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for missed property (Bool)' {
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without Bool property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'Bool'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When desired state has one more property' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String    = 'a string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c', 1
                    ArrayTest     = 'a', 'b', 'c', 1
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -ReverseCheck `
                        -IncludeInDesiredState `
                        -Verbose:$true } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for property Array, Hashtable, String, Bool and Int' {
                $script:result.Where({
                    $_.Property -eq 'Array'
                }).InDesiredState | Should -BeTrue
                $script:result.Where({
                    $_.Property -eq 'Hashtable'
                }).InDesiredState | Should -BeTrue
                $script:result.Where({
                    $_.Property -eq 'String'
                }).InDesiredState | Should -BeTrue
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).InDesiredState | Should -BeTrue
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return not null value for property ArrayTest' {
                $script:result.Where({
                    $_.Property -eq 'ArrayTest'
                }).InDesiredState | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for property ArrayTest' {
                $script:result.Where({
                    $_.Property -eq 'ArrayTest'
                }).InDesiredState | Should -BeFalse
            }
        }
    }

    Context 'When testing parameter types' {
        Context 'When desired value is of the wrong type' {
            BeforeAll {
                $currentValues = @{
                    String = 'a string'
                }

                $desiredValues = 1, 2, 3
            }

            It 'Should throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Throw
            }
        }

        Context 'When current value is of the wrong type' {
            BeforeAll {
                $currentValues = 1, 2, 3

                $desiredValues = @{
                    String = 'a string'
                }
            }

            It 'Should throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Throw
            }
        }
    }

    # Skip on macOS and Linux. macOS and Linux does not support CimInstance.
    Context 'When testing CimInstances / hashtables' -Skip:(-not ($IsWindows -or $PSEdition -eq 'Desktop')) {
        BeforeAll {
            $currentValues = @{
                String       = 'a string'
                Bool         = $true
                Int          = 99
                Array        = 'a', 'b', 'c'
                Hashtable    = @{
                    k1 = 'Test'
                    k2 = 123
                    k3 = 'v1', 'v2', 'v3', 99
                }

                CimInstances = [Microsoft.Management.Infrastructure.CimInstance[]] (
                    ConvertTo-CimInstance -Hashtable @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 99
                        Array  = 'a, b, c'
                    }
                )
            }
        }

        Context 'When everything matches' {
            BeforeAll {
                $desiredValues = [PSObject]@{
                    String       = 'a string'
                    Bool         = $true
                    Int          = 99
                    Array        = 'a', 'b', 'c'
                    Hashtable    = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }

                    CimInstances = [Microsoft.Management.Infrastructure.CimInstance[]] (
                        ConvertTo-CimInstance -Hashtable @{
                            String = 'a string'
                            Bool   = $true
                            Int    = 99
                            Array  = 'a, b, c'
                        }
                    )
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return all InDesiredState in $true' {
                $script:result.InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When CimInstances missing a value in the desired state (not recognized)' {
            BeforeAll {
                $desiredValues = [PSObject]@{
                    String       = 'a string'
                    Bool         = $true
                    Int          = 99
                    Array        = 'a', 'b', 'c'
                    Hashtable    = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }
                    CimInstances = @{
                        String = 'a string'
                        Bool   = $true
                        Array  = 'a, b, c'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return all InDesiredState in $true' {
                $script:result.InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When CimInstances missing a value in the desired state (recognized using ReverseCheck)' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String       = 'a string'
                    Bool         = $true
                    Int          = 99
                    Array        = 'a', 'b', 'c'
                    Hashtable    = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }
                    CimInstances = @{
                        String = 'a string'
                        Bool   = $true
                        Array  = 'a, b, c'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -ReverseCheck `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for CimInstances InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'CimInstances'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without CimInstances property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'CimInstances'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When CimInstances have an additional value' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String       = 'a string'
                    Bool         = $true
                    Int          = 99
                    Array        = 'a', 'b', 'c'
                    Hashtable    = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }
                    CimInstances = @{
                        String = 'a string'
                        Bool   = $true
                        Int    = 99
                        Array  = 'a, b, c'
                        Test   = 'Some string'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for CimInstances InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'CimInstances'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without CimInstances property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'CimInstances'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When CimInstances have a different value' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String       = 'a string'
                    Bool         = $true
                    Int          = 99
                    Array        = 'a', 'b', 'c'
                    Hashtable    = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }
                    CimInstances = @{
                        String = 'some other string'
                        Bool   = $true
                        Int    = 99
                        Array  = 'a, b, c'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for CimInstances InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'CimInstances'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without CimInstances property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'CimInstances'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When CimInstances have a value with a different type' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String       = 'a string'
                    Bool         = $true
                    Int          = 99
                    Array        = 'a', 'b', 'c'
                    Hashtable    = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }
                    CimInstances = @{
                        String = 'a string'
                        Bool   = $true
                        Int    = '99'
                        Array  = 'a, b, c'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $false for CimInstances InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'CimInstances'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return all InDesiredState (without CimInstances property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'CimInstances'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        Context 'When CimInstances have a value with a different type but TurnOffTypeChecking is used' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String       = 'a string'
                    Bool         = $true
                    Int          = 99
                    Array        = 'a', 'b', 'c'
                    Hashtable    = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3', 99
                    }
                    CimInstances = @{
                        String = 'a string'
                        Bool   = $true
                        Int    = '99'
                        Array  = 'a, b, c'
                    }
                }
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -TurnOffTypeChecking `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should not be null' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for CimInstances InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'CimInstances'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return all InDesiredState (without CimInstances property) in $true' {
                $script:result.Where({
                    $_.Property -ne 'CimInstances'
                }).InDesiredState | Should -Not -Contain $false
            }
        }

        # Test added to cover issue #65 https://github.com/dsccommunity/DscResource.Common/issues/65
        Context "When a property is empty in DesriredValues" {
            BeforeAll {
                $nameServers = [Microsoft.Management.Infrastructure.CimInstance[]] @(
                    New-CimInstance -ClassName 'MSFT_KeyValuePair' -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -Property @{
                        Key   = 'B.ROOT-SERVERS.NET.'
                        Value = '199.9.14.201'
                    } -ClientOnly

                    New-CimInstance -ClassName 'MSFT_KeyValuePair' -Namespace 'root/microsoft/Windows/DesiredStateConfiguration' -Property @{
                        Key   = 'M.ROOT-SERVERS.NET.'
                        Value = '202.12.27.33'
                    } -ClientOnly
                )
            }
            Context 'When one property is an empty array in CurrentValues and -ReverseCheck, -TurnOffTypeChecking are used' {
                BeforeAll {
                    $desiredValues = @{
                        NameServers = $nameServers
                        IsSingleInstance = 'Yes'
                        Verbose = $true
                    }

                    $currentValues = @{
                        IsSingleInstance = 'Yes'
                        NameServers = @()
                    }
                }

                It 'Should not throw' {
                    $script:compareTargetResourceStateResult = Compare-DscParameterState -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -TurnOffTypeChecking `
                            -ReverseCheck `
                            -Verbose:$verbose
                }

                It 'Should not be Null or Empty' {
                    $script:compareTargetResourceStateResult | Should -Not -BeNullOrEmpty
                }

                It 'Should have one value' {
                    $script:compareTargetResourceStateResult | Should -HaveCount 1
                }

                It 'Should be False in InDesiredState' {
                    $script:compareTargetResourceStateResult.InDesiredState | Should -BeFalse
                }
            }

            Context 'When one property is an empty collection of CimInstance in CurrentValues and -ReverseCheck, -TurnOffTypeChecking are used' {
                BeforeAll {
                    $desiredValues = @{
                        NameServers = $nameServers
                        IsSingleInstance = 'Yes'
                        Verbose = $true
                    }

                    $currentValues = @{
                        IsSingleInstance = 'Yes'
                        NameServers = [Microsoft.Management.Infrastructure.CimInstance[]]@()
                    }
                }

                It 'Should not throw' {
                    $script:compareTargetResourceStateResult = Compare-DscParameterState -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -TurnOffTypeChecking `
                            -ReverseCheck `
                            -Verbose:$verbose
                }

                It 'Should not be Null or Empty' {
                    $script:compareTargetResourceStateResult | Should -Not -BeNullOrEmpty
                }

                It 'Should have one value' {
                    $script:compareTargetResourceStateResult | Should -HaveCount 1
                }

                It 'Should be False in InDesiredState' {
                    $script:compareTargetResourceStateResult.InDesiredState | Should -BeFalse
                }
            }

            Context 'When one property is an empty array in DesiredValues and -TurnOffTypeChecking is used' {
                BeforeAll {
                    $desiredValues = @{
                        NameServers = @()
                        IsSingleInstance = 'Yes'
                        Verbose = $true
                    }

                    $currentValues = @{
                        IsSingleInstance = 'Yes'
                        NameServers = $nameServers
                    }
                }

                It 'Should not throw' {
                    $script:compareTargetResourceStateResult = Compare-DscParameterState -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -TurnOffTypeChecking `
                            -Verbose:$verbose
                }

                It 'Should not be Null or Empty' {
                    $script:compareTargetResourceStateResult | Should -Not -BeNullOrEmpty
                }

                It 'Should have one value' {
                    $script:compareTargetResourceStateResult | Should -HaveCount 1
                }

                It 'Should be False in InDesiredState' {
                    $script:compareTargetResourceStateResult.InDesiredState | Should -BeFalse
                }
            }

            Context 'When one property is an empty collection of CimInstance in DesiredValues and -TurnOffTypeChecking is used' {
                BeforeAll {
                    $desiredValues = @{
                        NameServers = [Microsoft.Management.Infrastructure.CimInstance[]] @()
                        IsSingleInstance = 'Yes'
                        Verbose = $true
                    }

                    $currentValues = @{
                        IsSingleInstance = 'Yes'
                        NameServers = $nameServers
                    }
                }

                It 'Should not throw' {
                    $script:compareTargetResourceStateResult = Compare-DscParameterState -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -TurnOffTypeChecking `
                            -Verbose:$verbose
                }

                It 'Should not be Null or Empty' {
                    $script:compareTargetResourceStateResult | Should -Not -BeNullOrEmpty
                }

                It 'Should have one value' {
                    $script:compareTargetResourceStateResult | Should -HaveCount 1
                }

                It 'Should be False in InDesiredState' {
                    $script:compareTargetResourceStateResult.InDesiredState | Should -BeFalse
                }
            }
        }
    }

    Context 'When using an ordered dictionary' {
        Context 'When some values does not match' {
            BeforeAll {
                $currentValues = [ordered]@{
                    String = 'This is a string'
                    Int = 1
                    Bool = $true
                }
                $desiredValues = [ordered]@{
                    String = 'This is a string'
                    Int = 99
                    Bool = $false
                }
            }

            BeforeEach {
                $verbose = $true
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return non-null result' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for String in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'String'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return $false for Int in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return $true for Bool in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).InDesiredState | Should -BeFalse
            }
        }

        Context 'When all values match' {
            BeforeAll {
                $currentValues = [ordered] @{
                    String = 'This is a string'
                    Int = 99
                    Bool = $true
                }
                $desiredValues = [ordered] @{
                    String = 'This is a string'
                    Int = 99
                    Bool = $true
                }
            }

            BeforeEach {
                $verbose = $true
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return non-null result' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for String in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'String'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return $false for Int in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Int'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return $true for Bool in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).InDesiredState | Should -BeTrue
            }
        }
    }

    Context 'When a property has an ordered dictionary' {
        Context 'When the property with ordered property does not match' {
            BeforeAll {
                $currentValues = [ordered] @{
                    String = 'This is a string'
                    OrderedProperty = [ordered] @{
                        Int = 99
                    }
                    Bool = $true
                }
                $desiredValues = [ordered] @{
                    String = 'This is a string'
                    OrderedProperty = [ordered] @{
                        Int = 1
                    }
                    Bool = $false
                }
            }

            BeforeEach {
                $verbose = $true
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return non-null result' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for String in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'String'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return $false for OrderedProperty in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'OrderedProperty'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return $true for Bool in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).InDesiredState | Should -BeFalse
            }
        }

        Context 'When all values match' {
            BeforeAll {
                $currentValues = [ordered] @{
                    String = 'This is a string'
                    OrderedProperty = [ordered] @{
                        Int = 99
                    }
                    Bool = $true
                }
                $desiredValues = [ordered] @{
                    String = 'This is a string'
                    OrderedProperty = [ordered] @{
                        Int = 99
                    }
                    Bool = $true
                }
            }

            BeforeEach {
                $verbose = $true
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return non-null result' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for String in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'String'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return $false for OrderedProperty in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'OrderedProperty'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return $true for Bool in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).InDesiredState | Should -BeTrue
            }
        }
    }

    Context 'When a property has an ordered dictionary array' {
        Context 'When the property with ordered property does not match' {
            BeforeAll {
                $currentValues = [ordered] @{
                    String = 'This is a string'
                    OrderedProperty = @(
                        [ordered] @{
                            Int = 99
                        }
                        [ordered] @{
                            String = 'Yes'
                        }
                    )
                    Bool = $true
                }
                $desiredValues = [ordered] @{
                    String = 'This is a string'
                    OrderedProperty = @(
                        [ordered] @{
                            Int = 99
                        }
                        [ordered] @{
                            String = 'No'
                        }
                    )
                    Bool = $false
                }
            }

            BeforeEach {
                $verbose = $true
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return non-null result' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for String in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'String'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return $false for OrderedProperty in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'OrderedProperty'
                }).InDesiredState | Should -BeFalse
            }

            It 'Should return $true for Bool in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).InDesiredState | Should -BeFalse
            }
        }

        Context 'When all values match' {
            BeforeAll {
                $currentValues = [ordered] @{
                    String = 'This is a string'
                    OrderedProperty = [ordered] @{
                        Int = 99
                    }
                    Bool = $true
                }
                $desiredValues = [ordered] @{
                    String = 'This is a string'
                    OrderedProperty = [ordered] @{
                        Int = 99
                    }
                    Bool = $true
                }
            }

            BeforeEach {
                $verbose = $true
            }

            It 'Should not throw exception' {
                { $script:result = Compare-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -IncludeInDesiredState `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return non-null result' {
                $script:result | Should -Not -BeNullOrEmpty
            }

            It 'Should return $true for String in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'String'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return $false for OrderedProperty in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'OrderedProperty'
                }).InDesiredState | Should -BeTrue
            }

            It 'Should return $true for Bool in property InDesiredState' {
                $script:result.Where({
                    $_.Property -eq 'Bool'
                }).InDesiredState | Should -BeTrue
            }
        }
    }
}
