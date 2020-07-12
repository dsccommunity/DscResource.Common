$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            } )
    }).BaseName

Import-Module $ProjectName -Force

InModuleScope $ProjectName {
    Describe 'ComputerManagementDsc.Common\Test-DscParameterState' {
        $verbose = $true

        Context 'When testing single values' {
            $currentValues = @{
                String    = 'a string'
                Bool      = $true
                Int       = 99
                Array     = 'a', 'b', 'c'
                Hashtable = @{
                    k1 = 'Test'
                    k2 = 123
                    k3 = 'v1', 'v2', 'v3'
                }
                ScriptBlock = { Get-Date }
            }

            Context 'When all values match' {
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
                    ScriptBlock = { Get-Date }
                }

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -BeTrue
                }
            }

            Context 'When a string is mismatched' {
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

            Context 'When a boolean is mismatched' {
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

            Context 'When an scriptblock is mismatched' {
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
                    ScriptBlock = { Get-Process }
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
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = '99'
                    Array  = 'a', 'b', 'c'
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

            Context 'When a type is mismatched but TurnOffTypeChecking is used' {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = '99'
                    Array  = 'a', 'b', 'c'
                }

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -TurnOffTypeChecking `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -BeTrue
                }
            }

            Context 'When a value is mismatched but ExcludeProperties is used to exclude then' {
                $desiredValues = @{
                    String    = 'some other string'
                    Bool      = $true
                    Int       = 99
                    Array     = 'a', 'b', 'c'
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                    ScriptBlock = { Get-Date }
                }

                $excludeProperties = @(
                    'String'
                )

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
        }

        Context 'When testing array values' {
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

            Context 'When array is missing a value' {
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

            Context 'When array has an additional value' {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 1
                    Array  = 'a', 'b', 'c', 1, 2
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

            Context 'When array has a different value' {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 1
                    Array  = 'a', 'x', 'c', 1
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

            Context 'When array has different order' {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 1
                    Array  = 'c', 'b', 'a', 1
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

            Context 'When array has different order but SortArrayValues is used' {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 1
                    Array  = 'c', 'b', 'a', 1
                }

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -SortArrayValues `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -BeFalse
                }
            }


            Context 'When array has a value with a different type' {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 99
                    Array  = 'a', 'b', 'c', '1'
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

            Context 'When array has a value with a different type but TurnOffTypeChecking is used' {
                $desiredValues = [PSObject] @{
                    String = 'a string'
                    Bool   = $true
                    Int    = 99
                    Array  = 'a', 'b', 'c', '1'
                }

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -TurnOffTypeChecking `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -BeTrue
                }
            }

            Context 'When both arrays are empty' {
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

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -BeTrue
                }
            }
        }

        Context 'When testing hashtables' {
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

            Context 'When hashtable is missing a value' {
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

            Context 'When hashtable has an additional value' {
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

            Context 'When hashtable has a different value' {
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

            Context 'When an array in hashtable has different order' {
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

            Context 'When an array in hashtable has different order but SortArrayValues is used' {
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

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -SortArrayValues `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -BeTrue
                }
            }


            Context 'When hashtable has a value with a different type' {
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

            Context 'When hashtable has a value with a different type but TurnOffTypeChecking is used' {
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

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -TurnOffTypeChecking `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -BeTrue
                }
            }
        }

        Context 'When reverse checking' {
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

            Context 'When even if missing property in the desired state' {
                $desiredValues = [PSObject] @{
                    Array     = 'a', 'b', 'c', 1
                    Hashtable = @{
                        k1 = 'Test'
                        k2 = 123
                        k3 = 'v1', 'v2', 'v3'
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -BeTrue
                }
            }

            Context 'When missing property in the desired state' {
                $currentValues = @{
                    String = 'a string'
                    Bool   = $true
                }

                $desiredValues = [PSObject] @{
                    String = 'a string'
                }

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ReverseCheck `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -BeFalse
                }
            }
        }

        Context 'When testing parameter types' {
            Context 'When desired value is of the wrong type' {
                $currentValues = @{
                    String = 'a string'
                }

                $desiredValues = 1, 2, 3

                It 'Should throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -Verbose:$verbose } | Should -Throw
                }
            }

            Context 'When current value is of the wrong type' {
                $currentValues = 1, 2, 3

                $desiredValues = @{
                    String = 'a string'
                }

                It 'Should throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -Verbose:$verbose } | Should -Throw
                }
            }
        }

        # macOS and Linux does not support CimInstance.
        if ($isWindows -or $PSEdition -eq 'Desktop')
        {
            Context 'When testing CimInstances / hashtables' {
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

                Context 'When everything matches' {
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

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -BeTrue
                    }
                }

                Context 'When CimInstances missing a value in the desired state (not recognized)' {
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

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -BeTrue
                    }
                }

                Context 'When CimInstances missing a value in the desired state (recognized using ReverseCheck)' {
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

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -ReverseCheck `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -BeFalse
                    }
                }

                Context 'When CimInstances have an additional value' {
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

                Context 'When CimInstances have a different value' {
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

                Context 'When CimInstances have a value with a different type' {
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

                Context 'When CimInstances have a value with a different type but TurnOffTypeChecking is used' {
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

                    It 'Should not throw exception' {
                        { $script:result = Test-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -TurnOffTypeChecking `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -BeTrue
                    }
                }
            }
        }
    }
}
