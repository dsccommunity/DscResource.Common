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
    $script:dscModuleName = 'DscResource.Common'

    Import-Module -Name $script:dscModuleName -Force -ErrorAction 'Stop'
}

Describe 'Assert-BoundParameter Integration Tests' -Tag 'AssertBoundParameterIntegration' {
    Context 'When using MutuallyExclusiveParameters parameter set' {
        Context 'When no conflicting parameters are bound' {
            It 'Should not throw when no parameters are bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{} -MutuallyExclusiveList1 @('Param1') -MutuallyExclusiveList2 @('Param2') -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should not throw when only parameters from the first list are bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param1 = 'Value1' } -MutuallyExclusiveList1 @('Param1') -MutuallyExclusiveList2 @('Param2') -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should not throw when only parameters from the second list are bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param2 = 'Value2' } -MutuallyExclusiveList1 @('Param1') -MutuallyExclusiveList2 @('Param2') -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should not throw when parameters from neither list are bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param3 = 'Value3' } -MutuallyExclusiveList1 @('Param1') -MutuallyExclusiveList2 @('Param2') -ErrorAction Stop
                } | Should -Not -Throw
            }
        }

        Context 'When conflicting parameters are bound' {
            It 'Should throw when parameters from both lists are bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param1 = 'Value1'; Param2 = 'Value2' } -MutuallyExclusiveList1 @('Param1') -MutuallyExclusiveList2 @('Param2') -ErrorAction Stop
                } | Should -Throw
            }

            It 'Should throw when multiple parameters from both lists are bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param1 = 'Value1'; Param1b = 'Value1b'; Param2 = 'Value2'; Param2b = 'Value2b' } -MutuallyExclusiveList1 @('Param1', 'Param1b') -MutuallyExclusiveList2 @('Param2', 'Param2b') -ErrorAction Stop
                } | Should -Throw
            }
        }
    }

    Context 'When using RequiredParameter parameter set' {
        Context 'When required parameters are bound' {
            It 'Should not throw when all required parameters are bound with default behavior' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param1 = 'Value1'; Param2 = 'Value2' } -RequiredParameter @('Param1', 'Param2') -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should not throw when all required parameters are bound with explicit All behavior' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param1 = 'Value1'; Param2 = 'Value2' } -RequiredParameter @('Param1', 'Param2') -RequiredBehavior All -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should not throw when at least one required parameter is bound with Any behavior' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param1 = 'Value1' } -RequiredParameter @('Param1', 'Param2') -RequiredBehavior Any -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should not throw when all required parameters are bound with Any behavior' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param1 = 'Value1'; Param2 = 'Value2' } -RequiredParameter @('Param1', 'Param2') -RequiredBehavior Any -ErrorAction Stop
                } | Should -Not -Throw
            }
        }

        Context 'When required parameters are not bound' {
            It 'Should throw when not all required parameters are bound with default behavior' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param1 = 'Value1' } -RequiredParameter @('Param1', 'Param2') -ErrorAction Stop
                } | Should -Throw
            }

            It 'Should throw when not all required parameters are bound with explicit All behavior' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param1 = 'Value1' } -RequiredParameter @('Param1', 'Param2') -RequiredBehavior All -ErrorAction Stop
                } | Should -Throw
            }

            It 'Should throw when no required parameters are bound with Any behavior' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Param3 = 'Value3' } -RequiredParameter @('Param1', 'Param2') -RequiredBehavior Any -ErrorAction Stop
                } | Should -Throw
            }
        }

        Context 'When using IfParameterPresent condition' {
            It 'Should not throw when condition parameter is not present' {
                {
                    Assert-BoundParameter -BoundParameterList @{ OtherParam = 'Value' } -RequiredParameter @('Param1', 'Param2') -IfParameterPresent @('TriggerParam') -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should not throw when condition parameter is present and required parameters are bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ TriggerParam = 'TriggerValue'; Param1 = 'Value1'; Param2 = 'Value2' } -RequiredParameter @('Param1', 'Param2') -IfParameterPresent @('TriggerParam') -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should throw when condition parameter is present but required parameters are not bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ TriggerParam = 'TriggerValue' } -RequiredParameter @('Param1', 'Param2') -IfParameterPresent @('TriggerParam') -ErrorAction Stop
                } | Should -Throw
            }

            It 'Should not throw when condition parameter is present and at least one required parameter is bound with Any behavior' {
                {
                    Assert-BoundParameter -BoundParameterList @{ TriggerParam = 'TriggerValue'; Param1 = 'Value1' } -RequiredParameter @('Param1', 'Param2') -RequiredBehavior Any -IfParameterPresent @('TriggerParam') -ErrorAction Stop
                } | Should -Not -Throw
            }
        }
    }

    Context 'When using AtLeastOne parameter set' {
        Context 'When at least one parameter from the list is bound' {
            It 'Should not throw when one parameter from the list is bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Severity = 'Warning'; OtherParam = 'Value' } -AtLeastOneList @('Severity', 'MessageId') -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should not throw when multiple parameters from the list are bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Severity = 'Warning'; MessageId = '12345'; OtherParam = 'Value' } -AtLeastOneList @('Severity', 'MessageId') -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should not throw when all parameters from the list are bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ Severity = 'Warning'; MessageId = '12345'; Level = 'Info' } -AtLeastOneList @('Severity', 'MessageId', 'Level') -ErrorAction Stop
                } | Should -Not -Throw
            }

            It 'Should not throw when only the last parameter from the list is bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ MessageId = '12345'; OtherParam = 'Value' } -AtLeastOneList @('Severity', 'MessageId') -ErrorAction Stop
                } | Should -Not -Throw
            }
        }

        Context 'When no parameters from the list are bound' {
            It 'Should throw when no parameters from the list are bound' {
                {
                    Assert-BoundParameter -BoundParameterList @{ OtherParam = 'Value' } -AtLeastOneList @('Severity', 'MessageId') -ErrorAction Stop
                } | Should -Throw
            }

            It 'Should throw when no parameters are bound at all' {
                {
                    Assert-BoundParameter -BoundParameterList @{} -AtLeastOneList @('Severity', 'MessageId') -ErrorAction Stop
                } | Should -Throw
            }

            It 'Should throw when bound parameters do not match any in the list' {
                {
                    Assert-BoundParameter -BoundParameterList @{ UnrelatedParam1 = 'Value1'; UnrelatedParam2 = 'Value2' } -AtLeastOneList @('Severity', 'MessageId') -ErrorAction Stop
                } | Should -Throw
            }
        }
    }

    Context 'When using complex real-world scenarios' {
        Context 'When simulating DSC resource parameter validation' {
            It 'Should validate SQL Server connection parameters correctly' {
                # Simulate a scenario where either ServerInstance or ConnectionString must be provided
                {
                    Assert-BoundParameter -BoundParameterList @{ ServerInstance = 'localhost'; Database = 'TestDB' } -AtLeastOneList @('ServerInstance', 'ConnectionString') -ErrorAction Stop
                } | Should -Not -Throw

                {
                    Assert-BoundParameter -BoundParameterList @{ ConnectionString = 'Server=localhost;Database=TestDB'; Database = 'TestDB' } -AtLeastOneList @('ServerInstance', 'ConnectionString') -ErrorAction Stop
                } | Should -Not -Throw

                {
                    Assert-BoundParameter -BoundParameterList @{ Database = 'TestDB' } -AtLeastOneList @('ServerInstance', 'ConnectionString') -ErrorAction Stop
                } | Should -Throw
            }

            It 'Should validate certificate parameters correctly' {
                # Simulate a scenario where certificate can be specified by Thumbprint or Subject, but not both
                {
                    Assert-BoundParameter -BoundParameterList @{ Thumbprint = 'ABC123'; Store = 'My' } -MutuallyExclusiveList1 @('Thumbprint') -MutuallyExclusiveList2 @('Subject') -ErrorAction Stop
                } | Should -Not -Throw

                {
                    Assert-BoundParameter -BoundParameterList @{ Subject = 'CN=Test'; Store = 'My' } -MutuallyExclusiveList1 @('Thumbprint') -MutuallyExclusiveList2 @('Subject') -ErrorAction Stop
                } | Should -Not -Throw

                {
                    Assert-BoundParameter -BoundParameterList @{ Thumbprint = 'ABC123'; Subject = 'CN=Test'; Store = 'My' } -MutuallyExclusiveList1 @('Thumbprint') -MutuallyExclusiveList2 @('Subject') -ErrorAction Stop
                } | Should -Throw
            }

            It 'Should validate conditional parameters correctly' {
                # Simulate a scenario where if EnableSsl is specified, then CertificateThumbprint is required
                {
                    Assert-BoundParameter -BoundParameterList @{ ServerName = 'localhost'; EnableSsl = $true; CertificateThumbprint = 'ABC123' } -RequiredParameter @('CertificateThumbprint') -IfParameterPresent @('EnableSsl') -ErrorAction Stop
                } | Should -Not -Throw

                {
                    Assert-BoundParameter -BoundParameterList @{ ServerName = 'localhost' } -RequiredParameter @('CertificateThumbprint') -IfParameterPresent @('EnableSsl') -ErrorAction Stop
                } | Should -Not -Throw

                {
                    Assert-BoundParameter -BoundParameterList @{ ServerName = 'localhost'; EnableSsl = $true } -RequiredParameter @('CertificateThumbprint') -IfParameterPresent @('EnableSsl') -ErrorAction Stop
                } | Should -Throw
            }
        }
    }
}
