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
    Describe 'ComputerManagementDsc.Common\Compare-DscParameterState' {
        BeforeAll {
            $verbose = $true
        }

        Context 'When testing single values' {
            BeforeAll{
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
                BeforeAll{
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

                It 'Should return all compliance in $true' {
                    $script:result.Compliance  | Should -Not -Contain $false
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

                It 'Should return $false for String compliance' {
                    $script:result.where({$_.Property -eq 'String'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without String property) in $true' {
                    $script:result.where({$_.Property -ne 'String'}).Compliance | Should -Not -Contain $false
                }
            }

            Context 'When a boolean is mismatched' {
                BeforeAll{
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

                It 'Should return $false for Bool compliance' {
                    $script:result.where({$_.Property -eq 'Bool'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Bool property) in $true' {
                    $script:result.where({$_.Property -ne 'Bool'}).Compliance | Should -Not -Contain $false
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

                It 'Should return $false for Int compliance' {
                    $script:result.where({$_.Property -eq 'Int'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Int property) in $true' {
                    $script:result.where({$_.Property -ne 'Int'}).Compliance | Should -Not -Contain $false
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

                It 'Should return $false for ScriptBlock compliance' {
                    $script:result.where({$_.Property -eq 'ScriptBlock'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without ScriptBlock property) in $true' {
                    $script:result.where({$_.Property -ne 'ScriptBlock'}).Compliance | Should -Not -Contain $false
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

                It 'Should return $false for Int compliance' {
                    $script:result.where({$_.Property -eq 'Int'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Int property) in $true' {
                    $script:result.where({$_.Property -ne 'Int'}).Compliance | Should -Not -Contain $false
                }

                It 'Should not return property with ScriptBlock in value' {
                    $script:result.where({$_.Property -eq 'ScriptBlock'}) | Should -BeNullOrEmpty
                }
            }

            Context 'When a type is mismatched' {
                BeforeAll{
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

                It 'Should return $false for Int compliance' {
                    $script:result.where({$_.Property -eq 'Int'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Int property) in $true' {
                    $script:result.where({$_.Property -ne 'Int'}).Compliance | Should -Not -Contain $false
                }
            }

            Context 'When a type is mismatched but TurnOffTypeChecking is used' {
                BeforeAll{
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

                It 'Should return $true for Int compliance' {
                    $script:result.where({$_.Property -eq 'Int'}).Compliance | Should -BeTrue
                }

                It 'Should return all compliance in $true' {
                    $script:result.Compliance | Should -Not -Contain $false
                }
            }

            Context 'When a value is mismatched but ExcludeProperties is used to exclude then' {
                BeforeAll{
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

                $excludeProperties = @(
                    'String'
                )

                It 'Should not throw exception' {
                    { $script:result = Compare-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ExcludeProperties $excludeProperties `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return all compliance in $true' {
                    $script:result.Compliance | Should -Not -Contain $false
                }

                It 'Should not return property with String in value' {
                    $script:result.where({$_.Property -eq 'String'}) | Should -BeNullOrEmpty
                }
            }
            Context 'When a value is mismatched but it is not in Properties then' {
                BeforeAll{
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

                    It 'Should return all compliance in $true' {
                        $script:result.Compliance | Should -Not -Contain $false
                    }

                    It 'Should return all property in $properties' {
                        $script:result.Property.Count | Should -Be $Properties.Count
                        foreach ($Property in $Properties){
                            $property | Should -BeIn $script:result.Property
                        }
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Compare-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -Properties $properties `
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return all compliance in $true' {
                    $script:result.Compliance | Should -Not -Contain $false
                }

                It 'Should return all property in $properties' {
                    $script:result.Property.Count | Should -Be $Properties.Count
                    foreach ($Property in $Properties){
                        $property | Should -BeIn $script:result.Property
                    }
                }

                Context 'When a value is mismatched but it is in Properties then' {
                    BeforeAll{
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

                    It 'Should return $false for String compliance' {
                        $script:result.where({$_.Property -eq 'String'}).Compliance | Should -BeFalse
                    }

                    It 'Should return all compliance (without String property) in $true' {
                        $script:result.where({$_.Property -ne 'String'}).Compliance | Should -Not -Contain $false
                    }

                    It 'Should return all property in $properties' {
                        $script:result.Property.Count | Should -Be $Properties.Count
                        foreach ($Property in $Properties){
                            $property | Should -BeIn $script:result.Property
                        }
                    }

                    It 'Should not return property with ScriptBlock in value' {
                        $script:result.where({$_.Property -eq 'ScriptBlock'}) | Should -BeNullOrEmpty
                    }
                }
            }
        }

        Context 'When testing pscredential' {

            Context 'When currentValue is pscredential type' {
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
                        PScredential = [pscredential]::new(
                            'UserName',
                            $(ConvertTo-SecureString -String 'Pa55w.rd' -AsPlainText -Force)
                        )
                    }
                }

                Context 'When all values match' {
                    BeforeAll{
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
                            PScredential = [pscredential]::new(
                                'UserName',
                                $(ConvertTo-SecureString -String 'Pa55w.rd' -AsPlainText -Force)
                            )
                        }
                    }
                    It 'Should not throw exception' {
                        { $script:result = Compare-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return all compliance in $true' {
                        $script:result.Compliance  | Should -Not -Contain $false
                    }
                }

                Context 'When an pscredential is mismatched' {
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
                            PScredential = [pscredential]::new(
                                'SurName',
                                $(ConvertTo-SecureString -String 'Pa55w.rd' -AsPlainText -Force)
                            )
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Compare-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false for PScredential compliance' {
                        $script:result.where({$_.Property -eq 'PScredential'}).Compliance | Should -BeFalse
                    }

                    It 'Should return all compliance (without PScredential property) in $true' {
                        $script:result.where({$_.Property -ne 'PScredential'}).Compliance | Should -Not -Contain $false
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
                    BeforeAll{
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
                            PScredential = [pscredential]::new(
                                'UserName',
                                $(ConvertTo-SecureString -String 'Pa55w.rd' -AsPlainText -Force)
                            )
                        }
                    }
                    It 'Should not throw exception' {
                        { $script:result = Compare-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return all compliance in $true' {
                        $script:result.Compliance  | Should -Not -Contain $false
                    }
                }

                Context 'When an pscredential is mismatched' {
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
                            PScredential = [pscredential]::new(
                                'SurName',
                                $(ConvertTo-SecureString -String 'Pa55w.rd' -AsPlainText -Force)
                            )
                        }
                    }

                    It 'Should not throw exception' {
                        { $script:result = Compare-DscParameterState `
                                -CurrentValues $currentValues `
                                -DesiredValues $desiredValues `
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false for PScredential compliance' {
                        $script:result.where({$_.Property -eq 'PScredential'}).Compliance | Should -BeFalse
                    }

                    It 'Should return all compliance (without PScredential property) in $true' {
                        $script:result.where({$_.Property -ne 'PScredential'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Array compliance' {
                    $script:result.where({$_.Property -eq 'Array'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Array property) in $true' {
                    $script:result.where({$_.Property -ne 'Array'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Array compliance' {
                    $script:result.where({$_.Property -eq 'Array'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Array property) in $true' {
                    $script:result.where({$_.Property -ne 'Array'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Array compliance' {
                    $script:result.where({$_.Property -eq 'Array'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Array property) in $true' {
                    $script:result.where({$_.Property -ne 'Array'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Array compliance' {
                    $script:result.where({$_.Property -eq 'Array'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Array property) in $true' {
                    $script:result.where({$_.Property -ne 'Array'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true for Array compliance' {
                    $script:result.where({$_.Property -eq 'Array'}).Compliance | Should -BeTrue
                }

                It 'Should return all compliance (without Array property) in $true' {
                    $script:result.where({$_.Property -ne 'Array'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Array compliance' {
                    $script:result.where({$_.Property -eq 'Array'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Array property) in $true' {
                    $script:result.where({$_.Property -ne 'Array'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true for Array compliance' {
                    $script:result.where({$_.Property -eq 'Array'}).Compliance | Should -BeTrue
                }

                It 'Should return all compliance (without Array property) in $true' {
                    $script:result.where({$_.Property -ne 'Array'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true for Array compliance' {
                    $script:result.where({$_.Property -eq 'Array'}).Compliance | Should -BeTrue
                }

                It 'Should return all compliance (without Array property) in $true' {
                    $script:result.where({$_.Property -ne 'Array'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Array compliance' {
                    $script:result.where({$_.Property -eq 'Array'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Array property) in $true' {
                    $script:result.where({$_.Property -ne 'Array'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Array compliance' {
                    $script:result.where({$_.Property -eq 'Array'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Array property) in $true' {
                    $script:result.where({$_.Property -ne 'Array'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Hashtable compliance' {
                    $script:result.where({$_.Property -eq 'Hashtable'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Hashtable property) in $true' {
                    $script:result.where({$_.Property -ne 'Hashtable'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Hashtable compliance' {
                    $script:result.where({$_.Property -eq 'Hashtable'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Hashtable property) in $true' {
                    $script:result.where({$_.Property -ne 'Hashtable'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Hashtable compliance' {
                    $script:result.where({$_.Property -eq 'Hashtable'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Hashtable property) in $true' {
                    $script:result.where({$_.Property -ne 'Hashtable'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Hashtable compliance' {
                    $script:result.where({$_.Property -eq 'Hashtable'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Hashtable property) in $true' {
                    $script:result.where({$_.Property -ne 'Hashtable'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true for Hashtable compliance' {
                    $script:result.where({$_.Property -eq 'Hashtable'}).Compliance | Should -BeTrue
                }

                It 'Should return all compliance (without Hashtable property) in $true' {
                    $script:result.where({$_.Property -ne 'Hashtable'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for Hashtable compliance' {
                    $script:result.where({$_.Property -eq 'Hashtable'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Hashtable property) in $true' {
                    $script:result.where({$_.Property -ne 'Hashtable'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $true for Hashtable compliance' {
                    $script:result.where({$_.Property -eq 'Hashtable'}).Compliance | Should -BeTrue
                }

                It 'Should return all compliance (without Hashtable property) in $true' {
                    $script:result.where({$_.Property -ne 'Hashtable'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for all compliance' {
                    $script:result.Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Not -Throw
                }

                It 'Should return $false for missed property (Bool)' {
                    $script:result.where({$_.Property -eq 'Bool'}).Compliance | Should -BeFalse
                }

                It 'Should return all compliance (without Bool property) in $true' {
                    $script:result.where({$_.Property -ne 'Bool'}).Compliance | Should -Not -Contain $false
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
                            -Verbose:$verbose } | Should -Throw
                }
            }
        }

        # macOS and Linux does not support CimInstance.
        if ($isWindows -or $PSEdition -eq 'Desktop')
        {
            Context 'When testing CimInstances / hashtables' {
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
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return all compliance in $true' {
                        $script:result.Compliance | Should -Not -Contain $false
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
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return all compliance in $true' {
                        $script:result.Compliance | Should -Not -Contain $false
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
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false for CimInstances compliance' {
                        $script:result.where({$_.Property -eq 'CimInstances'}).Compliance | Should -BeFalse
                    }

                    It 'Should return all compliance (without CimInstances property) in $true' {
                        $script:result.where({$_.Property -ne 'CimInstances'}).Compliance | Should -Not -Contain $false
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
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false for CimInstances compliance' {
                        $script:result.where({$_.Property -eq 'CimInstances'}).Compliance | Should -BeFalse
                    }

                    It 'Should return all compliance (without CimInstances property) in $true' {
                        $script:result.where({$_.Property -ne 'CimInstances'}).Compliance | Should -Not -Contain $false
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
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false for CimInstances compliance' {
                        $script:result.where({$_.Property -eq 'CimInstances'}).Compliance | Should -BeFalse
                    }

                    It 'Should return all compliance (without CimInstances property) in $true' {
                        $script:result.where({$_.Property -ne 'CimInstances'}).Compliance | Should -Not -Contain $false
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
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $false for CimInstances compliance' {
                        $script:result.where({$_.Property -eq 'CimInstances'}).Compliance | Should -BeFalse
                    }

                    It 'Should return all compliance (without CimInstances property) in $true' {
                        $script:result.where({$_.Property -ne 'CimInstances'}).Compliance | Should -Not -Contain $false
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
                                -Verbose:$verbose } | Should -Not -Throw
                    }

                    It 'Should return $true for CimInstances compliance' {
                        $script:result.where({$_.Property -eq 'CimInstances'}).Compliance | Should -BeTrue
                    }

                    It 'Should return all compliance (without CimInstances property) in $true' {
                        $script:result.where({$_.Property -ne 'CimInstances'}).Compliance | Should -Not -Contain $false
                    }
                }
            }
        }
    }
}
