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
    $script:dscModuleName = 'DscResource.Common'

    # Make sure there are not other modules imported that will conflict with mocks.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Assert-RequiredCommandParameter' -Tag 'Private' {
    Context 'When required parameter is missing' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSet -f 'Parameter1'

                { Assert-RequiredCommandParameter -BoundParameterList @{} -RequiredParameter 'Parameter1' } |
                    Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When the parameter in IfParameterPresent is not present' {
        It 'Should not throw an error' {
            InModuleScope -ScriptBlock {
                { Assert-RequiredCommandParameter -BoundParameterList @{} -RequiredParameter 'Parameter1' -IfParameterPresent 'Parameter2' } |
                    Should -Not -Throw
            }
        }
    }

    Context 'When the parameter in IfParameterPresent is not present' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSetWhenParameterExist -f 'Parameter1', 'Parameter2'

                {
                    Assert-RequiredCommandParameter -BoundParameterList @{
                        Parameter2 = 'Value2'
                    } -RequiredParameter 'Parameter1' -IfParameterPresent 'Parameter2'
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When the parameters in IfParameterPresent is present and the required parameters are not present' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                $mockErrorMessage = $script:localizedData.RequiredCommandParameter_SpecificParametersMustAllBeSetWhenParameterExist -f "Parameter3', 'Parameter4", "Parameter1', 'Parameter2"

                {
                    Assert-RequiredCommandParameter -BoundParameterList @{
                        Parameter1 = 'Value1'
                        Parameter2 = 'Value2'
                    } -RequiredParameter @('Parameter3', 'Parameter4') -IfParameterPresent @('Parameter1', 'Parameter2')
                } | Should -Throw -ExpectedMessage $mockErrorMessage
            }
        }
    }

    Context 'When the parameters in IfParameterPresent is present and required parameters are present' {
        It 'Should throw the correct error' {
            InModuleScope -ScriptBlock {
                {
                    Assert-RequiredCommandParameter -BoundParameterList @{
                        Parameter1 = 'Value1'
                        Parameter2 = 'Value2'
                    } -RequiredParameter @('Parameter1', 'Parameter2') -IfParameterPresent @('Parameter1', 'Parameter2')
                } | Should -Not -Throw
            }
        }
    }
}
