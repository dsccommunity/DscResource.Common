[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Suppressing this rule because Script Analyzer does not understand Pester syntax.')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies have been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 3>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies have not been resolved, this will throw an error.
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

    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'
}

Describe 'Assert-BoundParameter Integration Tests' -Tag 'AssertBoundParameterIntegration' {
    Context 'When using MutuallyExclusiveParameters parameter set' {
        Context 'When no conflicting parameters are bound' {
            It 'Should not throw when no parameters are bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{}
                        MutuallyExclusiveList1 = @('Param1')
                        MutuallyExclusiveList2 = @('Param2')
                        ErrorAction            = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }

            It 'Should not throw when only parameters from the first list are bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{ Param1 = 'Value1' }
                        MutuallyExclusiveList1 = @('Param1')
                        MutuallyExclusiveList2 = @('Param2')
                        ErrorAction            = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }

            It 'Should not throw when only parameters from the second list are bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{ Param2 = 'Value2' }
                        MutuallyExclusiveList1 = @('Param1')
                        MutuallyExclusiveList2 = @('Param2')
                        ErrorAction            = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }

            It 'Should not throw when parameters from neither list are bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{ Param3 = 'Value3' }
                        MutuallyExclusiveList1 = @('Param1')
                        MutuallyExclusiveList2 = @('Param2')
                        ErrorAction            = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }
        }

        Context 'When conflicting parameters are bound' {
            It 'Should throw when parameters from both lists are bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{
                            Param1 = 'Value1'
                            Param2 = 'Value2'
                        }
                        MutuallyExclusiveList1 = @('Param1')
                        MutuallyExclusiveList2 = @('Param2')
                        ErrorAction            = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }

            It 'Should throw when multiple parameters from both lists are bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{
                            Param1  = 'Value1'
                            Param1b = 'Value1b'
                            Param2  = 'Value2'
                            Param2b = 'Value2b'
                        }
                        MutuallyExclusiveList1 = @('Param1', 'Param1b')
                        MutuallyExclusiveList2 = @('Param2', 'Param2b')
                        ErrorAction            = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }
        }
    }

    Context 'When using RequiredParameter parameter set' {
        Context 'When required parameters are bound' {
            It 'Should not throw when all required parameters are bound with default behavior' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            Param1 = 'Value1'
                            Param2 = 'Value2'
                        }
                        RequiredParameter   = @('Param1', 'Param2')
                        ErrorAction         = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }

            It 'Should not throw when all required parameters are bound with explicit All behavior' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            Param1 = 'Value1'
                            Param2 = 'Value2'
                        }
                        RequiredParameter  = @('Param1', 'Param2')
                        RequiredBehavior   = 'All'
                        ErrorAction        = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }

            It 'Should not throw when at least one required parameter is bound with Any behavior' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{ Param1 = 'Value1' }
                        RequiredParameter  = @('Param1', 'Param2')
                        RequiredBehavior   = 'Any'
                        ErrorAction        = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }

            It 'Should not throw when all required parameters are bound with Any behavior' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            Param1 = 'Value1'
                            Param2 = 'Value2'
                        }
                        RequiredParameter  = @('Param1', 'Param2')
                        RequiredBehavior   = 'Any'
                        ErrorAction        = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }
        }

        Context 'When required parameters are not bound' {
            It 'Should throw when not all required parameters are bound with default behavior' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{ Param1 = 'Value1' }
                        RequiredParameter = @('Param1', 'Param2')
                        ErrorAction = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }

            It 'Should throw when not all required parameters are bound with explicit All behavior' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{ Param1 = 'Value1' }
                        RequiredParameter = @('Param1', 'Param2')
                        RequiredBehavior = 'All'
                        ErrorAction = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }

            It 'Should throw when no required parameters are bound with Any behavior' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{ Param3 = 'Value3' }
                        RequiredParameter = @('Param1', 'Param2')
                        RequiredBehavior = 'Any'
                        ErrorAction = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }
        }

        Context 'When using IfParameterPresent condition' {
            It 'Should not throw when condition parameter is not present' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{ OtherParam = 'Value' }
                        RequiredParameter = @('Param1', 'Param2')
                        IfParameterPresent = @('TriggerParam')
                        ErrorAction = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }

            It 'Should not throw when condition parameter is present and required parameters are bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            TriggerParam = 'TriggerValue'
                            Param1       = 'Value1'
                            Param2       = 'Value2'
                        }
                        RequiredParameter  = @('Param1', 'Param2')
                        IfParameterPresent = @('TriggerParam')
                        ErrorAction        = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }

            It 'Should throw when condition parameter is present but required parameters are not bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{ TriggerParam = 'TriggerValue' }
                        RequiredParameter = @('Param1', 'Param2')
                        IfParameterPresent = @('TriggerParam')
                        ErrorAction = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }

            It 'Should not throw when condition parameter is present and at least one required parameter is bound with Any behavior' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            TriggerParam = 'TriggerValue'
                            Param1       = 'Value1'
                        }
                        RequiredParameter  = @('Param1', 'Param2')
                        RequiredBehavior   = 'Any'
                        IfParameterPresent = @('TriggerParam')
                        ErrorAction        = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }
        }
    }

    Context 'When using AtLeastOne parameter set' {
        Context 'When at least one parameter from the list is bound' {
            It 'Should not throw when one parameter from the list is bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{ Severity = 'Warning'; OtherParam = 'Value' }
                        AtLeastOneList = @('Severity', 'MessageId')
                        ErrorAction = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }

            It 'Should not throw when multiple parameters from the list are bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            Severity   = 'Warning'
                            MessageId  = '12345'
                            OtherParam = 'Value'
                        }
                        AtLeastOneList = @('Severity', 'MessageId')
                        ErrorAction    = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }

            It 'Should not throw when all parameters from the list are bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            Severity  = 'Warning'
                            MessageId = '12345'
                            Level     = 'Info'
                        }
                        AtLeastOneList = @('Severity', 'MessageId', 'Level')
                        ErrorAction    = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }

            It 'Should not throw when only the last parameter from the list is bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{ MessageId = '12345'; OtherParam = 'Value' }
                        AtLeastOneList = @('Severity', 'MessageId')
                        ErrorAction = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw
            }
        }

        Context 'When no parameters from the list are bound' {
            It 'Should throw when no parameters from the list are bound' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{ OtherParam = 'Value' }
                        AtLeastOneList = @('Severity', 'MessageId')
                        ErrorAction = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }

            It 'Should throw when no parameters are bound at all' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{}
                        AtLeastOneList = @('Severity', 'MessageId')
                        ErrorAction = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }

            It 'Should throw when bound parameters do not match any in the list' {
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            UnrelatedParam1 = 'Value1'
                            UnrelatedParam2 = 'Value2'
                        }
                        AtLeastOneList = @('Severity', 'MessageId')
                        ErrorAction    = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }
        }
    }

    Context 'When using complex real-world scenarios' {
        Context 'When simulating DSC resource parameter validation' {
            It 'Should validate SQL Server connection parameters correctly' {
                # Simulate a scenario where either ServerInstance or ConnectionString must be provided
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            ServerInstance = 'localhost'
                            Database       = 'TestDB'
                        }
                        AtLeastOneList = @('ServerInstance', 'ConnectionString')
                        ErrorAction    = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw

                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            ConnectionString = 'Server=localhost;Database=TestDB'
                            Database         = 'TestDB'
                        }
                        AtLeastOneList = @('ServerInstance', 'ConnectionString')
                        ErrorAction    = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw

                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{ Database = 'TestDB' }
                        AtLeastOneList = @('ServerInstance', 'ConnectionString')
                        ErrorAction = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }

            It 'Should validate certificate parameters correctly' {
                # Simulate a scenario where certificate can be specified by Thumbprint or Subject, but not both
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            Thumbprint = 'ABC123'
                            Store      = 'My'
                        }
                        MutuallyExclusiveList1 = @('Thumbprint')
                        MutuallyExclusiveList2 = @('Subject')
                        ErrorAction            = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw

                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            Subject = 'CN=Test'
                            Store   = 'My'
                        }
                        MutuallyExclusiveList1 = @('Thumbprint')
                        MutuallyExclusiveList2 = @('Subject')
                        ErrorAction            = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw

                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            Thumbprint = 'ABC123'
                            Subject    = 'CN=Test'
                            Store      = 'My'
                        }
                        MutuallyExclusiveList1 = @('Thumbprint')
                        MutuallyExclusiveList2 = @('Subject')
                        ErrorAction            = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }

            It 'Should validate conditional parameters correctly' {
                # Simulate a scenario where if EnableSsl is specified, then CertificateThumbprint is required
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            ServerName             = 'localhost'
                            EnableSsl              = $true
                            CertificateThumbprint  = 'ABC123'
                        }
                        RequiredParameter  = @('CertificateThumbprint')
                        IfParameterPresent = @('EnableSsl')
                        ErrorAction        = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw

                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{ ServerName = 'localhost' }
                        RequiredParameter  = @('CertificateThumbprint')
                        IfParameterPresent = @('EnableSsl')
                        ErrorAction        = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw

                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList = @{
                            ServerName = 'localhost'
                            EnableSsl  = $true
                        }
                        RequiredParameter  = @('CertificateThumbprint')
                        IfParameterPresent = @('EnableSsl')
                        ErrorAction        = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }
        }
    }

    Context 'When using IfEqualParameterList parameter' {
        Context 'When using with MutuallyExclusiveParameters parameter set' {
            Context 'When the IfEqualParameterList condition is met' {
                It 'Should throw when mutually exclusive parameters are both present and condition is met' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList     = @{
                                ConfigType = 'Advanced'
                                Param1     = 'Value1'
                                Param2     = 'Value2'
                            }
                            MutuallyExclusiveList1 = @('Param1')
                            MutuallyExclusiveList2 = @('Param2')
                            IfEqualParameterList   = @{ ConfigType = 'Advanced' }
                            ErrorAction            = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Throw
                }

                It 'Should not throw when mutually exclusive parameters are not both present and condition is met' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList     = @{
                                ConfigType = 'Advanced'
                                Param1     = 'Value1'
                            }
                            MutuallyExclusiveList1 = @('Param1')
                            MutuallyExclusiveList2 = @('Param2')
                            IfEqualParameterList   = @{ ConfigType = 'Advanced' }
                            ErrorAction            = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }

                It 'Should throw when multiple conditions are met and mutually exclusive parameters are present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList     = @{
                                ConfigType  = 'Advanced'
                                Environment = 'Production'
                                Param1      = 'Value1'
                                Param2      = 'Value2'
                            }
                            MutuallyExclusiveList1 = @('Param1')
                            MutuallyExclusiveList2 = @('Param2')
                            IfEqualParameterList   = @{
                                ConfigType  = 'Advanced'
                                Environment = 'Production'
                            }
                            ErrorAction            = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Throw
                }
            }

            Context 'When the IfEqualParameterList condition is not met' {
                It 'Should not throw even when mutually exclusive parameters are both present but condition is not met' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList     = @{
                                ConfigType = 'Basic'
                                Param1     = 'Value1'
                                Param2     = 'Value2'
                            }
                            MutuallyExclusiveList1 = @('Param1')
                            MutuallyExclusiveList2 = @('Param2')
                            IfEqualParameterList   = @{ ConfigType = 'Advanced' }
                            ErrorAction            = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }

                It 'Should not throw when the parameter in IfEqualParameterList is not present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList     = @{
                                Param1 = 'Value1'
                                Param2 = 'Value2'
                            }
                            MutuallyExclusiveList1 = @('Param1')
                            MutuallyExclusiveList2 = @('Param2')
                            IfEqualParameterList   = @{ ConfigType = 'Advanced' }
                            ErrorAction            = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }

                It 'Should not throw when only some conditions are met' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList     = @{
                                ConfigType  = 'Advanced'
                                Environment = 'Development'
                                Param1      = 'Value1'
                                Param2      = 'Value2'
                            }
                            MutuallyExclusiveList1 = @('Param1')
                            MutuallyExclusiveList2 = @('Param2')
                            IfEqualParameterList   = @{
                                ConfigType  = 'Advanced'
                                Environment = 'Production'
                            }
                            ErrorAction            = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }
        }

        Context 'When using with RequiredParameter parameter set' {
            Context 'When the IfEqualParameterList condition is met' {
                It 'Should not throw when condition is met and required parameters are bound' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList   = @{
                                ConfigType = 'Advanced'
                                Param1     = 'Value1'
                                Param2     = 'Value2'
                            }
                            RequiredParameter    = @('Param1', 'Param2')
                            IfEqualParameterList = @{ ConfigType = 'Advanced' }
                            ErrorAction          = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }

                It 'Should throw when condition is met but required parameters are not bound' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList   = @{
                                ConfigType = 'Advanced'
                                Param1     = 'Value1'
                            }
                            RequiredParameter    = @('Param1', 'Param2')
                            IfEqualParameterList = @{ ConfigType = 'Advanced' }
                            ErrorAction          = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Throw
                }

                It 'Should not throw when condition is met and at least one required parameter is bound with Any behavior' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList   = @{
                                ConfigType = 'Advanced'
                                Param1     = 'Value1'
                            }
                            RequiredParameter    = @('Param1', 'Param2')
                            RequiredBehavior     = 'Any'
                            IfEqualParameterList = @{ ConfigType = 'Advanced' }
                            ErrorAction          = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }

            Context 'When the IfEqualParameterList condition is not met' {
                It 'Should not throw even when required parameters are not bound but condition is not met' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList   = @{
                                ConfigType = 'Basic'
                                Param1     = 'Value1'
                            }
                            RequiredParameter    = @('Param1', 'Param2')
                            IfEqualParameterList = @{ ConfigType = 'Advanced' }
                            ErrorAction          = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }

                It 'Should not throw when the parameter in IfEqualParameterList is not present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList   = @{ Param1 = 'Value1' }
                            RequiredParameter    = @('Param1', 'Param2')
                            IfEqualParameterList = @{ ConfigType = 'Advanced' }
                            ErrorAction          = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }
        }

        Context 'When using with AtLeastOne parameter set' {
            Context 'When the IfEqualParameterList condition is met' {
                It 'Should not throw when condition is met and at least one required parameter is present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList   = @{
                                ConfigType = 'Advanced'
                                Severity   = 'Warning'
                            }
                            AtLeastOneList       = @('Severity', 'MessageId')
                            IfEqualParameterList = @{ ConfigType = 'Advanced' }
                            ErrorAction          = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }

                It 'Should throw when condition is met but none of the required parameters are present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList   = @{
                                ConfigType = 'Advanced'
                                OtherParam = 'Value'
                            }
                            AtLeastOneList       = @('Severity', 'MessageId')
                            IfEqualParameterList = @{ ConfigType = 'Advanced' }
                            ErrorAction          = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Throw
                }

                It 'Should not throw when condition is met and multiple required parameters are present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList   = @{
                                ConfigType = 'Advanced'
                                Severity   = 'Warning'
                                MessageId  = '12345'
                            }
                            AtLeastOneList       = @('Severity', 'MessageId')
                            IfEqualParameterList = @{ ConfigType = 'Advanced' }
                            ErrorAction          = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }

            Context 'When the IfEqualParameterList condition is not met' {
                It 'Should not throw even when none of the required parameters are present but condition is not met' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList   = @{
                                ConfigType = 'Basic'
                                OtherParam = 'Value'
                            }
                            AtLeastOneList       = @('Severity', 'MessageId')
                            IfEqualParameterList = @{ ConfigType = 'Advanced' }
                            ErrorAction          = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }

                It 'Should not throw when the parameter in IfEqualParameterList is not present' {
                    {
                        $assertBoundParameterParameters = @{
                            BoundParameterList   = @{ OtherParam = 'Value' }
                            AtLeastOneList       = @('Severity', 'MessageId')
                            IfEqualParameterList = @{ ConfigType = 'Advanced' }
                            ErrorAction          = 'Stop'
                        }

                        Assert-BoundParameter @assertBoundParameterParameters
                    } | Should -Not -Throw
                }
            }
        }

        Context 'When using real-world DSC resource scenarios with conditional validation' {
            It 'Should validate SQL Server authentication parameters only when authentication type is specified' {
                # Should not validate credentials when using Windows Authentication
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList   = @{
                            AuthenticationType = 'Windows'
                            ServerInstance     = 'localhost'
                        }
                        RequiredParameter    = @('Username', 'Password')
                        IfEqualParameterList = @{ AuthenticationType = 'SQL' }
                        ErrorAction          = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw

                # Should validate credentials when using SQL Authentication and they are provided
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList   = @{
                            AuthenticationType = 'SQL'
                            ServerInstance     = 'localhost'
                            Username           = 'sa'
                            Password           = 'password'
                        }
                        RequiredParameter    = @('Username', 'Password')
                        IfEqualParameterList = @{ AuthenticationType = 'SQL' }
                        ErrorAction          = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw

                # Should throw when using SQL Authentication but credentials are missing
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList   = @{
                            AuthenticationType = 'SQL'
                            ServerInstance     = 'localhost'
                        }
                        RequiredParameter    = @('Username', 'Password')
                        IfEqualParameterList = @{ AuthenticationType = 'SQL' }
                        ErrorAction          = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }

            It 'Should validate certificate parameters only for secure connections' {
                # Should not require certificate when connection is not secure
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList   = @{
                            ConnectionType = 'Standard'
                            ServerName     = 'localhost'
                        }
                        AtLeastOneList       = @('CertificateThumbprint', 'CertificateSubject')
                        IfEqualParameterList = @{ ConnectionType = 'Secure' }
                        ErrorAction          = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw

                # Should require certificate parameters when connection is secure and they are provided
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList   = @{
                            ConnectionType        = 'Secure'
                            ServerName            = 'localhost'
                            CertificateThumbprint = 'ABC123'
                        }
                        AtLeastOneList       = @('CertificateThumbprint', 'CertificateSubject')
                        IfEqualParameterList = @{ ConnectionType = 'Secure' }
                        ErrorAction          = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw

                # Should throw when connection is secure but no certificate parameters are provided
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList   = @{
                            ConnectionType = 'Secure'
                            ServerName     = 'localhost'
                        }
                        AtLeastOneList       = @('CertificateThumbprint', 'CertificateSubject')
                        IfEqualParameterList = @{ ConnectionType = 'Secure' }
                        ErrorAction          = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }

            It 'Should validate environment-specific parameters correctly' {
                # Should allow conflicting parameters in development but not in production
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{
                            Environment    = 'Development'
                            DebugMode      = $true
                            OptimizedMode  = $true
                        }
                        MutuallyExclusiveList1 = @('DebugMode')
                        MutuallyExclusiveList2 = @('OptimizedMode')
                        IfEqualParameterList   = @{ Environment = 'Production' }
                        ErrorAction            = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Not -Throw

                # Should throw when conflicting parameters are used in production
                {
                    $assertBoundParameterParameters = @{
                        BoundParameterList     = @{
                            Environment    = 'Production'
                            DebugMode      = $true
                            OptimizedMode  = $true
                        }
                        MutuallyExclusiveList1 = @('DebugMode')
                        MutuallyExclusiveList2 = @('OptimizedMode')
                        IfEqualParameterList   = @{ Environment = 'Production' }
                        ErrorAction            = 'Stop'
                    }

                    Assert-BoundParameter @assertBoundParameterParameters
                } | Should -Throw
            }
        }
    }
}
