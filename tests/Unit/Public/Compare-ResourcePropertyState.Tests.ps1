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
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
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

Describe 'Compare-ResourcePropertyState' -Tag 'CompareResourcePropertyState' {
    Context 'When one property is in desired state' {
        BeforeAll {
            $mockCurrentValues = @{
                ComputerName = 'DC01'
            }

            $mockDesiredValues = @{
                ComputerName = 'DC01'
            }
        }

        It 'Should return the correct values' {
            $compareTargetResourceStateParameters = @{
                CurrentValues = $mockCurrentValues
                DesiredValues = $mockDesiredValues
            }

            $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
            $compareTargetResourceStateResult | Should -HaveCount 1

            $property = $compareTargetResourceStateResult.Where({$_.ParameterName -eq 'ComputerName'})
            $property | Should -Not -BeNulLorEmpty
            $property.Expected | Should -Be 'DC01'
            $property.Actual | Should -Be 'DC01'
            $property.InDesiredState | Should -BeTrue
        }
    }

    Context 'When two properties are in desired state' {
        BeforeAll {
            $mockCurrentValues = @{
                ComputerName = 'DC01'
                Location     = 'Sweden'
            }

            $mockDesiredValues = @{
                ComputerName = 'DC01'
                Location     = 'Sweden'
                <#
                    This is used to increase code coverage so that the code
                    that removes common parameters are hit.
                #>
                ErrorAction = 'Stop'
            }
        }

        It 'Should return the correct values' {
            $compareTargetResourceStateParameters = @{
                CurrentValues = $mockCurrentValues
                DesiredValues = $mockDesiredValues
            }

            $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
            $compareTargetResourceStateResult | Should -HaveCount 2

            $property = $compareTargetResourceStateResult.Where({$_.ParameterName -eq 'ComputerName'})
            $property | Should -Not -BeNulLorEmpty
            $property.Expected | Should -Be 'DC01'
            $property.Actual | Should -Be 'DC01'
            $property.InDesiredState | Should -BeTrue

            $property = $compareTargetResourceStateResult.Where({$_.ParameterName -eq 'Location'})
            $property | Should -Not -BeNulLorEmpty
            $property.Expected | Should -Be 'Sweden'
            $property.Actual | Should -Be 'Sweden'
            $property.InDesiredState | Should -BeTrue
        }
    }

    Context 'When passing just one property and that property is not in desired state' {
        BeforeAll {
            $mockCurrentValues = @{
                ComputerName = 'DC01'
            }

            $mockDesiredValues = @{
                ComputerName = 'APP01'
            }
        }

        It 'Should return the correct values' {
            $compareTargetResourceStateParameters = @{
                CurrentValues = $mockCurrentValues
                DesiredValues = $mockDesiredValues
            }

            $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
            $compareTargetResourceStateResult | Should -HaveCount 1

            $property = $compareTargetResourceStateResult.Where({$_.ParameterName -eq 'ComputerName'})
            $property | Should -Not -BeNulLorEmpty
            $property.Expected | Should -Be 'APP01'
            $property.Actual | Should -Be 'DC01'
            $property.InDesiredState | Should -BeFalse
        }
    }

    Context 'When passing two properties and one property is not in desired state' {
        BeforeAll {
            $mockCurrentValues = @{
                ComputerName = 'DC01'
                Location     = 'Sweden'
            }

            $mockDesiredValues = @{
                ComputerName = 'DC01'
                Location     = 'Europe'
            }
        }

        It 'Should return the correct values' {
            $compareTargetResourceStateParameters = @{
                CurrentValues = $mockCurrentValues
                DesiredValues = $mockDesiredValues
            }

            $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
            $compareTargetResourceStateResult | Should -HaveCount 2

            $property = $compareTargetResourceStateResult.Where({$_.ParameterName -eq 'ComputerName'})
            $property | Should -Not -BeNulLorEmpty
            $property.Expected | Should -Be 'DC01'
            $property.Actual | Should -Be 'DC01'
            $property.InDesiredState | Should -BeTrue

            $property = $compareTargetResourceStateResult.Where({$_.ParameterName -eq 'Location'})
            $property | Should -Not -BeNulLorEmpty
            $property.Expected | Should -Be 'Europe'
            $property.Actual | Should -Be 'Sweden'
            $property.InDesiredState | Should -BeFalse
        }
    }

    Context 'When passing a common parameter set to desired value' {
        BeforeAll {
            $mockCurrentValues = @{
                ComputerName = 'DC01'
            }

            $mockDesiredValues = @{
                ComputerName = 'DC01'
            }
        }

        It 'Should return the correct values' {
            $compareTargetResourceStateParameters = @{
                CurrentValues = $mockCurrentValues
                DesiredValues = $mockDesiredValues
            }

            $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
            $compareTargetResourceStateResult | Should -HaveCount 1

            $property = $compareTargetResourceStateResult.Where({$_.ParameterName -eq 'ComputerName'})
            $property | Should -Not -BeNulLorEmpty
            $property.Expected | Should -Be 'DC01'
            $property.Actual | Should -Be 'DC01'
            $property.InDesiredState | Should -BeTrue
        }
    }

    Context 'When using parameter Properties to compare desired values' {
        BeforeAll {
            $mockCurrentValues = @{
                ComputerName = 'DC01'
                Location     = 'Sweden'
            }

            $mockDesiredValues = @{
                ComputerName = 'DC01'
                Location     = 'Europe'
            }
        }

        It 'Should return the correct values' {
            $compareTargetResourceStateParameters = @{
                CurrentValues = $mockCurrentValues
                DesiredValues = $mockDesiredValues
                Properties    = @(
                    'ComputerName'
                )
            }

            $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
            $compareTargetResourceStateResult | Should -HaveCount 1

            $property = $compareTargetResourceStateResult.Where({$_.ParameterName -eq 'ComputerName'})
            $property | Should -Not -BeNulLorEmpty
            $property.Expected | Should -Be 'DC01'
            $property.Actual | Should -Be 'DC01'
            $property.InDesiredState | Should -BeTrue
        }
    }

    Context 'When using parameter Properties and IgnoreProperties to compare desired values' {
        BeforeAll {
            $mockCurrentValues = @{
                ComputerName = 'DC01'
                Location     = 'Sweden'
                Ensure       = 'Present'
            }

            $mockDesiredValues = @{
                ComputerName = 'DC01'
                Location     = 'Europe'
                Ensure       = 'Absent'
            }
        }

        It 'Should return the correct values' {
            $compareTargetResourceStateParameters = @{
                CurrentValues    = $mockCurrentValues
                DesiredValues    = $mockDesiredValues
                IgnoreProperties = @(
                    'Ensure'
                )
            }

            $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
            $compareTargetResourceStateResult | Should -HaveCount 2

            $property = $compareTargetResourceStateResult.Where({$_.ParameterName -eq 'ComputerName'})
            $property | Should -Not -BeNulLorEmpty
            $property.Expected | Should -Be 'DC01'
            $property.Actual | Should -Be 'DC01'
            $property.InDesiredState | Should -BeTrue

            $property = $compareTargetResourceStateResult.Where({$_.ParameterName -eq 'Location'})
            $property | Should -Not -BeNulLorEmpty
            $property.Expected | Should -Be 'Europe'
            $property.Actual | Should -Be 'Sweden'
            $property.InDesiredState | Should -BeFalse
        }
    }

    Context 'When using parameter Properties and IgnoreProperties to compare desired values' {
        BeforeAll {
            $mockCurrentValues = @{
                ComputerName = 'DC01'
                Location     = 'Sweden'
                Ensure       = 'Present'
            }

            $mockDesiredValues = @{
                ComputerName = 'DC01'
                Location     = 'Europe'
                Ensure       = 'Absent'
            }
        }

        It 'Should return and empty array' {
            $compareTargetResourceStateParameters = @{
                CurrentValues    = $mockCurrentValues
                DesiredValues    = $mockDesiredValues
                Properties       = @(
                    'ComputerName'
                )
                IgnoreProperties = @(
                    'ComputerName'
                )
            }

            $compareTargetResourceStateResult = Compare-ResourcePropertyState @compareTargetResourceStateParameters
            $compareTargetResourceStateResult | Should -BeNullOrEmpty
        }
    }
}
