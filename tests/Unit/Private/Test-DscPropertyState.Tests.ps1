$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(
            try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            }
        )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Test-DscPropertyState' -Tag 'TestDscPropertyState' {
        Context 'When comparing tables' {
            It 'Should return true for two identical tables' {
                $mockValues = @{
                    CurrentValue = 'Test'
                    DesiredValue = 'Test'
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }
        }

        Context 'When comparing strings' {
            It 'Should return false when a value is different for [System.String]' {
                $mockValues = @{
                    CurrentValue = [System.String] 'something'
                    DesiredValue = [System.String] 'test'
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return false when a String value is missing' {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = [System.String] 'Something'
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return true when two strings are equal' {
                $mockValues = @{
                    CurrentValue = [System.String] 'Something'
                    DesiredValue = [System.String] 'Something'
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }
        }

        Context 'When comparing integers' {
            It 'Should return false when a value is different for [System.Int32]' {
                $mockValues = @{
                    CurrentValue = [System.Int32] 1
                    DesiredValue = [System.Int32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return true when the values are the same for [System.Int32]' {
                $mockValues = @{
                    CurrentValue = [System.Int32] 2
                    DesiredValue = [System.Int32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }

            It 'Should return false when a value is different for [System.UInt32]' {
                $mockValues = @{
                    CurrentValue = [System.UInt32] 1
                    DesiredValue = [System.UInt32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $false
            }

            It 'Should return true when the values are the same for [System.UInt32]' {
                $mockValues = @{
                    CurrentValue = [System.UInt32] 2
                    DesiredValue = [System.UInt32] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }

            It 'Should return false when a value is different for [System.Int16]' {
                $mockValues = @{
                    CurrentValue = [System.Int16] 1
                    DesiredValue = [System.Int16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return true when the values are the same for [System.Int16]' {
                $mockValues = @{
                    CurrentValue = [System.Int16] 2
                    DesiredValue = [System.Int16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }

            It 'Should return false when a value is different for [System.UInt16]' {
                $mockValues = @{
                    CurrentValue = [System.UInt16] 1
                    DesiredValue = [System.UInt16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return true when the values are the same for [System.UInt16]' {
                $mockValues = @{
                    CurrentValue = [System.UInt16] 2
                    DesiredValue = [System.UInt16] 2
                }

                Test-DscPropertyState -Values $mockValues | Should -Be $true
            }

            It 'Should return false when a Integer value is missing' {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = [System.Int32] 1
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        Context 'When comparing booleans' {
            It 'Should return false when a value is different for [System.Boolean]' {
                $mockValues = @{
                    CurrentValue = [System.Boolean] $true
                    DesiredValue = [System.Boolean] $false
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return false when a Boolean value is missing' {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = [System.Boolean] $true
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }
        }

        Context 'When comparing arrays' {
            It 'Should return true when evaluating an array' {
                $mockValues = @{
                    CurrentValue = @('1', '2')
                    DesiredValue = @('1', '2')
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }

            It 'Should return false when evaluating an array with wrong values' {
                $mockValues = @{
                    CurrentValue = @('CurrentValueA', 'CurrentValueB')
                    DesiredValue = @('DesiredValue1', 'DesiredValue2')
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return false when evaluating an array, but the current value is $null' {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = @('1', '2')
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return false when evaluating an array, but the desired value is $null' {
                $mockValues = @{
                    CurrentValue = @('1', '2')
                    DesiredValue = $null
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return false when evaluating an array, but the current value is an empty array' {
                $mockValues = @{
                    CurrentValue = @()
                    DesiredValue = @('1', '2')
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return false when evaluating an array, but the desired value is an empty array' {
                $mockValues = @{
                    CurrentValue = @('1', '2')
                    DesiredValue = @()
                }

                Test-DscPropertyState -Values $mockValues | Should -BeFalse
            }

            It 'Should return true when evaluating an array, when both values are $null' {
                $mockValues = @{
                    CurrentValue = $null
                    DesiredValue = $null
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }

            It 'Should return true when evaluating an array, when both values are an empty array' {
                $mockValues = @{
                    CurrentValue = @()
                    DesiredValue = @()
                }

                Test-DscPropertyState -Values $mockValues | Should -BeTrue
            }
        }

        # macOS and Linux does not support CimInstance.
        if ($IsWindows -or $PSEdition -eq 'Desktop')
        {
            Context 'When comparing a CIM instance' {
                BeforeAll {
                    $mockClassName = 'DSC_MockResourceClassName'
                    $mockNamespace = 'root/microsoft/Windows/DesiredStateConfiguration'
                }

                It 'Should return true when evaluating properties of a CIM instance' {
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

                It 'Should return false when evaluating a CIM instance property that is an array with wrong values' {
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

                It 'Should return false when evaluating a CIM instance property that is a string with wrong value' {
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

                It 'Should return false when evaluating a CIM instance, but the current value is $null' {
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

                It 'Should return false when evaluating a CIM instance, but the desired value is $null' {
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

                It 'Should return false when evaluating a CIM instance, but the current CIM instance does not have any properties' {
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

                It 'Should return false when evaluating a CIM instance, but the desired CIM instance does not have any properties' {
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

                It 'Should return false when evaluating a CIM instance, but the current CIM instance is missing a property' {
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

                Context 'When the desired CIM instance has less properties than the current CIM properties' {
                    It 'Should return true when evaluating a CIM instance where all CIM properties are in desired state' {
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

                    It 'Should return false when evaluating a CIM instance when a CIM property is not in desired state' {
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

                It 'Should return true when evaluating a CIM instance, when both current and desired value does not have any CIM properties' {
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

            Context 'When comparing a CIM instance collection' {
                BeforeAll {
                    $mockTypeName = 'System.Collections.ObjectModel.Collection`1[Microsoft.Management.Infrastructure.CimInstance]'
                    $mockClassName = 'DSC_MockResourceClassName'
                    $mockNamespace = 'root/microsoft/Windows/DesiredStateConfiguration'
                }

                BeforeEach {
                    $currentCimInstancePermissionCollection = New-Object -TypeName $mockTypeName
                    $desiredCimInstancePermissionCollection = New-Object -TypeName $mockTypeName
                }

                Context 'When not passing the key ''KeyProperties'' in the hashtable' {
                    It 'Should throw the correct error message' {
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

                        $currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters
                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters

                        $mockValues = @{
                            CurrentValue = $currentCimInstancePermissionCollection
                            DesiredValue = $desiredCimInstancePermissionCollection
                        }

                        { Test-DscPropertyState -Values $mockValues } | Should -Throw $script:localizedData.KeyPropertiesMissing
                    }
                }

                Context 'When current value contain two CIM instances that have the same ''KeyProperties''' {
                    It 'Should throw the correct error message' {
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

                        $currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters
                        $currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters

                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters
                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters

                        $mockValues = @{
                            CurrentValue  = $currentCimInstancePermissionCollection
                            DesiredValue  = $desiredCimInstancePermissionCollection
                            KeyProperties = @('State')
                        }

                        { Test-DscPropertyState -Values $mockValues } | Should -Throw $script:localizedData.TooManyCimInstances
                    }
                }

                Context 'When current and desired collection contain one CIM instance each with equally property values' {
                    It 'Should return true when evaluating properties of each CIM instance of a collection of CIM instances' {
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

                        $currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters
                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters

                        $mockValues = @{
                            CurrentValue  = $currentCimInstancePermissionCollection
                            DesiredValue  = $desiredCimInstancePermissionCollection
                            KeyProperties = @('State')
                        }

                        Test-DscPropertyState -Values $mockValues | Should -BeTrue
                    }
                }

                Context 'When current and desired collection contain two CIM instance each with equally property values' {
                    It 'Should return true when evaluating properties of each CIM instance of a collection of CIM instances' {
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

                        $currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters1
                        $currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters2

                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters1
                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters2

                        $mockValues = @{
                            CurrentValue  = $currentCimInstancePermissionCollection
                            DesiredValue  = $desiredCimInstancePermissionCollection
                            KeyProperties = @('State')
                        }

                        Test-DscPropertyState -Values $mockValues | Should -BeTrue
                    }
                }

                Context 'When current CIM instance collection have more CIM instance than the desired state, but with equally property values' {
                    It 'Should return true when evaluating properties of each CIM instance of a collection of CIM instances' {
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

                        $currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters1
                        $currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters2

                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters1

                        $mockValues = @{
                            CurrentValue  = $currentCimInstancePermissionCollection
                            DesiredValue  = $desiredCimInstancePermissionCollection
                            KeyProperties = @('State')
                        }

                        Test-DscPropertyState -Values $mockValues | Should -BeTrue
                    }
                }

                Context 'When desired CIM instance collection have more CIM instance than the current state' {
                    It 'Should return false when evaluating properties of each CIM instance of a collection of CIM instances' {
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

                        $currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters1

                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters1
                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters2

                        $mockValues = @{
                            CurrentValue  = $currentCimInstancePermissionCollection
                            DesiredValue  = $desiredCimInstancePermissionCollection
                            KeyProperties = @('State')
                        }

                        Test-DscPropertyState -Values $mockValues | Should -BeFalse
                    }
                }

                Context 'When desired CIM instance collection have more CIM instance than the current state, and the CIM instances in the current state is not in desired state' {
                    It 'Should return false when evaluating properties of each CIM instance of a collection of CIM instances' {
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

                        $currentCimInstancePermissionCollection += New-CimInstance @currentCimInstanceParameters1

                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters1
                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters2

                        $mockValues = @{
                            CurrentValue  = $currentCimInstancePermissionCollection
                            DesiredValue  = $desiredCimInstancePermissionCollection
                            KeyProperties = @('State')
                        }

                        Test-DscPropertyState -Values $mockValues | Should -BeFalse
                    }
                }

                <#
                    There is only need to test empty collection in the current state
                    because the desired state must always provide at least one item.
                #>
                Context 'When current CIM instance collection have no CIM instances' {
                    It 'Should return false when evaluating properties of each CIM instance of a collection of CIM instances' {
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

                        $desiredCimInstancePermissionCollection += New-CimInstance @desiredCimInstanceParameters

                        $mockValues = @{
                            CurrentValue  = $currentCimInstancePermissionCollection
                            DesiredValue  = $desiredCimInstancePermissionCollection
                            KeyProperties = @('State')
                        }

                        Test-DscPropertyState -Values $mockValues | Should -BeFalse
                    }
                }
            }
        }

        Context -Name 'When passing invalid types for DesiredValue' {
            It 'Should write a warning when DesiredValue contain an unsupported type' {
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

                Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope It
            }
        }
    }
}
