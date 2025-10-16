[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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

Describe 'Test-DscParameterState' {
    BeforeAll {
        $verbose = $true
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeTrue
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
            }
        }

        Context 'When an scriptblock is mismatched' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String      = 'a string'
                    Bool        = $true
                    Int         = 1
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
                { $script:result = Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                $script:result | Should -BeFalse
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
                { $script:result = Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                $script:result | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -TurnOffTypeChecking `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -TurnOffTypeChecking `
                    -Verbose:$verbose | Should -BeTrue
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
                { $script:result = Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -ExcludeProperties $excludeProperties `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                $script:result | Should -BeTrue
            }
        }

        Context 'When a value is mismatched but it is not in Properties' {
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
            }

            Context 'When using the parameter alias ValuesToCheck' {
                BeforeAll {
                    $properties = @(
                        'Bool'
                        'Int'
                        'Array'
                        'Hashtable'
                        'ScriptBlock'
                    )
                }

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $properties `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -BeTrue
                }
            }

            Context 'When using parameter Properties' {
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
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -Properties $properties `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
            }
        }

        Context 'When array has an additional value' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 1
                    Array  = 'a', 'b', 'c', 1, 2
                }
            }

            It 'Should not throw exception' {
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
            }
        }

        Context 'When array has a different value' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 1
                    Array  = 'a', 'x', 'c', 1
                }
            }

            It 'Should not throw exception' {
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
            }
        }

        Context 'When array has different order' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 1
                    Array  = 'c', 'b', 'a', 1
                }
            }

            It 'Should not throw exception' {
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
            }
        }

        Context 'When array has different order but SortArrayValues is used' {
            BeforeAll {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 1
                    Array  = 'c', 'b', 'a', 1
                }
            }

            It 'Should not throw exception' {
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -SortArrayValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -SortArrayValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -TurnOffTypeChecking `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -TurnOffTypeChecking `
                    -Verbose:$verbose | Should -BeTrue
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -TurnOffTypeChecking `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -TurnOffTypeChecking `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeTrue
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
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -BeFalse
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
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -BeFalse
                }
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -TurnOffTypeChecking `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -TurnOffTypeChecking `
                    -Verbose:$verbose | Should -BeTrue
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeTrue
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -ReverseCheck `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -ReverseCheck `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Throw
            }
        }
    }

    # macOS and Linux does not support CimInstance.
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeTrue
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeTrue
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -ReverseCheck `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -ReverseCheck `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $false' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -Verbose:$verbose | Should -BeFalse
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
                { Test-DscParameterState `
                        -CurrentValues $currentValues `
                        -DesiredValues $desiredValues `
                        -TurnOffTypeChecking `
                        -Verbose:$verbose } | Should -Not -Throw
            }

            It 'Should return $true' {
                Test-DscParameterState `
                    -CurrentValues $currentValues `
                    -DesiredValues $desiredValues `
                    -TurnOffTypeChecking `
                    -Verbose:$verbose | Should -BeTrue
            }
        }
    }
}
