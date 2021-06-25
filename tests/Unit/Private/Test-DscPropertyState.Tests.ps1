BeforeAll {
    $script:moduleName = 'DscResource.Common'

    Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

    Get-Module -Name $script:moduleName -ListAvailable |
        Select-Object -First 1 |
        Import-Module -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
}

Describe 'Test-DscPropertyState' -Tag 'TestDscPropertyState' {
    Context 'When comparing tables' {
        It 'Should return true for two identical tables' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = 'Test'
                    DesiredValue = 'Test'
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }
        }
    }

    Context 'When comparing strings' {
        It 'Should return false when a value is different for [System.String]' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = [System.String] 'something'
                    DesiredValue = [System.String] 'test'
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when a String value is missing' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = [System.String] 'Something'
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return true when two strings are equal' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = [System.String] 'Something'
                    DesiredValue = [System.String] 'Something'
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }
        }
    }

    Context 'When comparing integers' {
        It 'Should return false when a value is different for [System.Int32]' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = [System.Int32] 1
                    DesiredValue = [System.Int32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return true when the values are the same for [System.Int32]' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = [System.Int32] 2
                    DesiredValue = [System.Int32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }
        }

        It 'Should return false when a value is different for [System.UInt32]' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = [System.UInt32] 1
                    DesiredValue = [System.UInt32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $false
            }
        }

        It 'Should return true when the values are the same for [System.UInt32]' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = [System.UInt32] 2
                    DesiredValue = [System.UInt32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }
        }

        It 'Should return false when a value is different for [System.Int16]' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = [System.Int16] 1
                    DesiredValue = [System.Int16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return true when the values are the same for [System.Int16]' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = [System.Int16] 2
                    DesiredValue = [System.Int16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }
        }

        It 'Should return false when a value is different for [System.UInt16]' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = [System.UInt16] 1
                    DesiredValue = [System.UInt16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return true when the values are the same for [System.UInt16]' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = [System.UInt16] 2
                    DesiredValue = [System.UInt16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }
        }

        It 'Should return false when a Integer value is missing' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = [System.Int32] 1
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }
    }

    Context 'When comparing booleans' {
        It 'Should return false when a value is different for [System.Boolean]' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = [System.Boolean] $true
                    DesiredValue = [System.Boolean] $false
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when a Boolean value is missing' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = [System.Boolean] $true
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }
    }

    Context 'When comparing arrays' {
        It 'Should return true when evaluating an array' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = @('1', '2')
                    DesiredValue = @('1', '2')
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }
        }

        It 'Should return false when evaluating an array with wrong values' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = @('CurrentValueA', 'CurrentValueB')
                    DesiredValue = @('DesiredValue1', 'DesiredValue2')
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when evaluating an array, but the current value is $null' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = @('1', '2')
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when evaluating an array, but the desired value is $null' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = @('1', '2')
                    DesiredValue = $null
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when evaluating an array, but the current value is an empty array' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = @()
                    DesiredValue = @('1', '2')
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when evaluating an array, but the desired value is an empty array' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = @('1', '2')
                    DesiredValue = @()
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return true when evaluating an array, when both values are $null' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = $null
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }
        }

        It 'Should return true when evaluating an array, when both values are an empty array' {
            InModuleScope -ScriptBlock {
                $mockValues = @{
                    CurrentValue = @()
                    DesiredValue = @()
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }
        }
    }

    # Skip on macOS and Linux. macOS and Linux does not support CimInstance.
    Context 'When comparing a CIM instance' -Skip:(-not ($IsWindows -or $PSEdition -eq 'Desktop')) {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockClassName = 'DSC_MockResourceClassName'
                $script:mockNamespace = 'root/microsoft/Windows/DesiredStateConfiguration'
            }
        }

        It 'Should return true when evaluating properties of a CIM instance' {
            InModuleScope -ScriptBlock {
                $currentCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State      = 'Deny'
                        Permission = @('Delete', 'Select')
                        Ensure     = 'Present'
                    }
                    ClientOnly = $true
                }

                $desiredCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State      = 'Deny'
                        Permission = @('Delete', 'Select')
                        Ensure     = 'Present'
                    }
                    ClientOnly = $true
                }

                $mockValues = @{
                    CurrentValue = New-CimInstance @currentCimInstanceParameters
                    DesiredValue = New-CimInstance @desiredCimInstanceParameters
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }
        }

        It 'Should return false when evaluating a CIM instance property that is an array with wrong values' {
            InModuleScope -ScriptBlock {
                $currentCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State      = 'Deny'
                        Permission = @('Delete', 'Select')
                        Ensure     = 'Present'
                    }
                    ClientOnly = $true
                }

                $desiredCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State      = 'Deny'
                        Permission = @('Delete', 'Update')
                        Ensure     = 'Present'
                    }
                    ClientOnly = $true
                }

                $mockValues = @{
                    CurrentValue = New-CimInstance @currentCimInstanceParameters
                    DesiredValue = New-CimInstance @desiredCimInstanceParameters
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when evaluating a CIM instance property that is a string with wrong value' {
            InModuleScope -ScriptBlock {
                $currentCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State      = 'Deny'
                        Permission = @('Delete', 'Select')
                        Ensure     = 'Present'
                    }
                    ClientOnly = $true
                }

                $desiredCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State      = 'Grant'
                        Permission = @('Delete', 'Select')
                        Ensure     = 'Present'
                    }
                    ClientOnly = $true
                }

                $mockValues = @{
                    CurrentValue = New-CimInstance @currentCimInstanceParameters
                    DesiredValue = New-CimInstance @desiredCimInstanceParameters
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when evaluating a CIM instance, but the current value is $null' {
            InModuleScope -ScriptBlock {
                $desiredCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State      = 'Grant'
                        Permission = @('Delete', 'Select')
                        Ensure     = 'Present'
                    }
                    ClientOnly = $true
                }

                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = New-CimInstance @desiredCimInstanceParameters
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when evaluating a CIM instance, but the desired value is $null' {
            InModuleScope -ScriptBlock {
                $currentCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State      = 'Deny'
                        Permission = @('Delete', 'Select')
                        Ensure     = 'Present'
                    }
                    ClientOnly = $true
                }

                $mockValues = @{
                    CurrentValue = New-CimInstance @currentCimInstanceParameters
                    DesiredValue = $null
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when evaluating a CIM instance, but the current CIM instance does not have any properties' {
            InModuleScope -ScriptBlock {
                $currentCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{}
                    ClientOnly = $true
                }

                $desiredCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State      = 'Grant'
                        Permission = @('Delete', 'Select')
                        Ensure     = 'Present'
                    }
                    ClientOnly = $true
                }

                $mockValues = @{
                    CurrentValue = New-CimInstance @currentCimInstanceParameters
                    DesiredValue = New-CimInstance @desiredCimInstanceParameters
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when evaluating a CIM instance, but the desired CIM instance does not have any properties' {
            InModuleScope -ScriptBlock {
                $currentCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State      = 'Grant'
                        Permission = @('Delete', 'Select')
                        Ensure     = 'Present'
                    }
                    ClientOnly = $true
                }

                $desiredCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{}
                    ClientOnly = $true
                }

                $mockValues = @{
                    CurrentValue = New-CimInstance @currentCimInstanceParameters
                    DesiredValue = New-CimInstance @desiredCimInstanceParameters
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        It 'Should return false when evaluating a CIM instance, but the current CIM instance is missing a property' {
            InModuleScope -ScriptBlock {
                $currentCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State  = 'Grant'
                        Ensure = 'Present'
                    }
                    ClientOnly = $true
                }

                $desiredCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{
                        State      = 'Grant'
                        Permission = @('Delete', 'Select')
                        Ensure     = 'Present'
                    }
                    ClientOnly = $true
                }

                $mockValues = @{
                    CurrentValue = New-CimInstance @currentCimInstanceParameters
                    DesiredValue = New-CimInstance @desiredCimInstanceParameters
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        Context 'When the desired CIM instance has less properties than the current CIM properties' {
            It 'Should return true when evaluating a CIM instance where all CIM properties are in desired state' {
                InModuleScope -ScriptBlock {
                    $currentCimInstanceParameters = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State  = 'Grant'
                            Ensure = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $mockValues = @{
                        CurrentValue = New-CimInstance @currentCimInstanceParameters
                        DesiredValue = New-CimInstance @desiredCimInstanceParameters
                    }

                    Test-DscPropertyState -Values $mockValues | Should -BeTrue
                }
            }

            It 'Should return false when evaluating a CIM instance when a CIM property is not in desired state' {
                InModuleScope -ScriptBlock {
                    $currentCimInstanceParameters = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State  = 'Deny'
                            Ensure = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $mockValues = @{
                        CurrentValue = New-CimInstance @currentCimInstanceParameters
                        DesiredValue = New-CimInstance @desiredCimInstanceParameters
                    }

                    Test-DscPropertyState -Values $mockValues | Should -BeFalse
                }
            }
        }

        It 'Should return true when evaluating a CIM instance, when both current and desired value does not have any CIM properties' {
            InModuleScope -ScriptBlock {
                $currentCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{}
                    ClientOnly = $true
                }

                $desiredCimInstanceParameters = @{
                    ClassName  = $mockClassName
                    Namespace  = $mockNamespace
                    Property   = @{}
                    ClientOnly = $true
                }

                $mockValues = @{
                    CurrentValue = New-CimInstance @currentCimInstanceParameters
                    DesiredValue = New-CimInstance @desiredCimInstanceParameters
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }
        }
    }

    Context 'When comparing a CIM instance collection' -Skip:(-not ($IsWindows -or $PSEdition -eq 'Desktop')) {
        BeforeAll {
            InModuleScope -ScriptBlock {
                $script:mockTypeName = 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'
                $script:mockClassName = 'DSC_MockResourceClassName'
                $script:mockNamespace = 'root/microsoft/Windows/DesiredStateConfiguration'
            }
        }

        BeforeEach {
            InModuleScope -ScriptBlock {
                $script:currentCimInstancePermissionCollection = New-Object -TypeName $script:mockTypeName
                $script:desiredCimInstancePermissionCollection = New-Object -TypeName $script:mockTypeName
            }
        }

        Context 'When not passing the key ''KeyProperties'' in the hashtable' {
            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    $currentCimInstanceParameters = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Deny'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Deny'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters
                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters

                    $mockValues = @{
                        CurrentValue = $currentCimInstancePermissionCollection
                        DesiredValue = $desiredCimInstancePermissionCollection
                    }

                    $mockErrorRecord = Get-InvalidOperationRecord -Message $script:localizedData.KeyPropertiesMissing

                    { Test-DscPropertyState -Values $mockValues } | Should -Throw -ExpectedMessage $mockErrorRecord.Exception.Message
                }
            }
        }

        Context 'When current value contain two CIM instances that have the same ''KeyProperties''' {
            It 'Should throw the correct error message' {
                InModuleScope -ScriptBlock {
                    $currentCimInstanceParameters = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Deny'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Deny'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters
                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters

                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters
                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters

                    $mockValues = @{
                        CurrentValue  = $currentCimInstancePermissionCollection
                        DesiredValue  = $desiredCimInstancePermissionCollection
                        KeyProperties = @('State')
                    }

                    $mockErrorRecord = Get-InvalidOperationRecord -Message $script:localizedData.TooManyCimInstances

                    { Test-DscPropertyState -Values $mockValues } | Should -Throw -ExpectedMessage $mockErrorRecord.Exception.Message
                }
            }
        }

        Context 'When current and desired collection contain one CIM instance each with equally property values' {
            It 'Should return true when evaluating properties of each CIM instance of a collection of CIM instances' {
                InModuleScope -ScriptBlock {
                    $currentCimInstanceParameters = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Deny'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Deny'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters
                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters

                    $mockValues = @{
                        CurrentValue  = $currentCimInstancePermissionCollection
                        DesiredValue  = $desiredCimInstancePermissionCollection
                        KeyProperties = @('State')
                    }

                    Test-DscPropertyState -Values $mockValues | Should -BeTrue
                }
            }
        }

        Context 'When current and desired collection contain two CIM instance each with equally property values' {
            It 'Should return true when evaluating properties of each CIM instance of a collection of CIM instances' {
                InModuleScope -ScriptBlock {
                    $currentCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $currentCimInstanceParameters2 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Deny'
                            Permission = @('Drop')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters2 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Deny'
                            Permission = @('Drop')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters1
                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters2

                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters1
                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters2

                    $mockValues = @{
                        CurrentValue  = $currentCimInstancePermissionCollection
                        DesiredValue  = $desiredCimInstancePermissionCollection
                        KeyProperties = @('State')
                    }

                    Test-DscPropertyState -Values $mockValues | Should -BeTrue
                }
            }
        }

        Context 'When current CIM instance collection have more CIM instance than the desired state, but with equally property values' {
            It 'Should return true when evaluating properties of each CIM instance of a collection of CIM instances' {
                InModuleScope -ScriptBlock {
                    $currentCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $currentCimInstanceParameters2 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Deny'
                            Permission = @('Drop')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters1
                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters2

                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters1

                    $mockValues = @{
                        CurrentValue  = $currentCimInstancePermissionCollection
                        DesiredValue  = $desiredCimInstancePermissionCollection
                        KeyProperties = @('State')
                    }

                    Test-DscPropertyState -Values $mockValues | Should -BeTrue
                }
            }
        }

        Context 'When desired CIM instance collection have more CIM instance than the current state' {
            It 'Should return false when evaluating properties of each CIM instance of a collection of CIM instances' {
                InModuleScope -ScriptBlock {
                    $currentCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }


                    $desiredCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters2 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Deny'
                            Permission = @('Drop')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters1

                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters1
                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters2

                    $mockValues = @{
                        CurrentValue  = $currentCimInstancePermissionCollection
                        DesiredValue  = $desiredCimInstancePermissionCollection
                        KeyProperties = @('State')
                    }

                    Test-DscPropertyState -Values $mockValues | Should -BeFalse
                }
            }
        }

        Context 'When desired CIM instance collection have more CIM instance than the current state, and the CIM instances in the current state is not in desired state' {
            It 'Should return false when evaluating properties of each CIM instance of a collection of CIM instances' {
                InModuleScope -ScriptBlock {
                    $currentCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Permission = @('Delete', 'Select')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }


                    $desiredCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Permission = @('Delete', 'Select', 'Update')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters2 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Deny'
                            Permission = @('Drop')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters1

                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters1
                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters2

                    $mockValues = @{
                        CurrentValue  = $currentCimInstancePermissionCollection
                        DesiredValue  = $desiredCimInstancePermissionCollection
                        KeyProperties = @('State')
                    }

                    Test-DscPropertyState -Values $mockValues | Should -BeFalse
                }
            }
        }

        <#
            There is only need to test empty collection in the current state
            because the desired state must always provide at least one item.
        #>
        Context 'When current CIM instance collection have no CIM instances' {
            It 'Should return false when evaluating properties of each CIM instance of a collection of CIM instances' {
                InModuleScope -ScriptBlock {
                    $desiredCimInstanceParameters = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Permission = @('Delete', 'Select', 'Update')
                            Ensure     = 'Present'
                        }
                        ClientOnly = $true
                    }

                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters

                    $mockValues = @{
                        CurrentValue  = $currentCimInstancePermissionCollection
                        DesiredValue  = $desiredCimInstancePermissionCollection
                        KeyProperties = @('State')
                    }

                    Test-DscPropertyState -Values $mockValues | Should -BeFalse
                }
            }
        }

        Context 'When the CIM instance are using two key properties' {
            It 'Should return true when evaluating properties of one CIM instance that matches the key properties' {
                InModuleScope -ScriptBlock {
                    $currentCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Ensure     = 'Present'
                            Permission = @('Delete', 'Select')
                        }
                        ClientOnly = $true
                    }

                    $currentCimInstanceParameters2 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Ensure     = 'Absent'
                            Permission = @('Drop')
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Ensure     = 'Present'
                            Permission = @('Delete', 'Select')
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters2 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Ensure     = 'Absent'
                            Permission = @('Drop')
                        }
                        ClientOnly = $true
                    }

                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters1
                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters2

                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters1
                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters2

                    $mockValues = @{
                        CurrentValue  = $currentCimInstancePermissionCollection
                        DesiredValue  = $desiredCimInstancePermissionCollection
                        KeyProperties = @(
                            'State'
                            'Ensure'
                        )
                    }

                    Test-DscPropertyState -Values $mockValues | Should -BeTrue
                }
            }
        }

        Context 'When the CIM instance are using two key properties, and one CIM instance is not in desired state' {
            It 'Should return false when evaluating properties of one CIM instance that matches the key properties' {
                InModuleScope -ScriptBlock {
                    $currentCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Ensure     = 'Present'
                            Permission = @('Select')
                        }
                        ClientOnly = $true
                    }

                    $currentCimInstanceParameters2 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Ensure     = 'Absent'
                            Permission = @('Drop')
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters1 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Ensure     = 'Present'
                            Permission = @('Select')
                        }
                        ClientOnly = $true
                    }

                    $desiredCimInstanceParameters2 = @{
                        ClassName  = $mockClassName
                        Namespace  = $mockNamespace
                        Property   = @{
                            State      = 'Grant'
                            Ensure     = 'Absent'
                            Permission = @('Delete')
                        }
                        ClientOnly = $true
                    }

                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters1
                    $script:currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters2

                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters1
                    $script:desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters2

                    $mockValues = @{
                        CurrentValue  = $currentCimInstancePermissionCollection
                        DesiredValue  = $desiredCimInstancePermissionCollection
                        KeyProperties = @(
                            'State'
                            'Ensure'
                        )
                    }

                    Test-DscPropertyState -Values $mockValues | Should -BeFalse
                }
            }
        }
    }

    Context 'When passing invalid types for DesiredValue' {
        It 'Should write a warning when DesiredValue contain an unsupported type' {
            InModuleScope -ScriptBlock {
                Mock -CommandName Write-Warning

                # This is a dummy type to test with a type that could never be a correct one.
                class MockUnknownType
                {
                    [ValidateNotNullOrEmpty()]
                    [System.String]
                    $Property1

                    [ValidateNotNullOrEmpty()]
                    [System.String]
                    $Property2

                    MockUnknownType()
                    {
                    }
                }

                $mockValues = @{
                    CurrentValue = New-Object -TypeName 'MockUnknownType'
                    DesiredValue = New-Object -TypeName 'MockUnknownType'
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse

                Should -Invoke -CommandName Write-Warning -Exactly -Times 1 -Scope It
            }
        }
    }
}
