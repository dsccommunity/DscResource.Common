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

    Import-Module -Name $script:moduleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force
}

Describe 'Assert-ElevatedUser' -Tag 'Public' {
    BeforeDiscovery {
        <#
            Since it is not possible to elevated (or un-elevate) a user during testing
            the test that cannot run need to be skipped.
        #>
        if ($IsMacOS -or $IsLinux)
        {
            $mockIsElevated = (id -u) -eq 0
        }
        else
        {
            [Security.Principal.WindowsPrincipal] $mockCurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()

            $mockIsElevated = $mockCurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        }
    }

    Context 'When not supplying an error message' {
        It 'Should throw the correct error' -Skip:$mockIsElevated {
            $mockErrorMessage = InModuleScope -ScriptBlock {
                $script:localizedData.ElevatedUser_UserNotElevated
            }

            { Assert-ElevatedUser } | Should -Throw -ExpectedMessage $mockErrorMessage
        }

        It 'Should not throw an exception' -Skip:(-not $mockIsElevated) {
            { Assert-ElevatedUser } | Should -Not -Throw
        }
    }

    Context 'When supplying a custom error message' {
        BeforeAll {
            $mockCustomMessage = 'This is a custom error message'
        }

        It 'Should throw the correct error' -Skip:$mockIsElevated {
            { Assert-ElevatedUser -ErrorMessage $mockCustomMessage } | Should -Throw -ExpectedMessage $mockCustomMessage
        }


        It 'Should not throw an exception' -Skip:(-not $mockIsElevated) {
            { Assert-ElevatedUser -ErrorMessage $mockCustomMessage} | Should -Not -Throw
        }
    }

    Context 'When on Linux or macOS' {
        BeforeAll {
            $previousIsMacOS = InModuleScope -ScriptBlock {
                $IsMacOS
            }

            InModuleScope -ScriptBlock {
                $script:IsMacOS = $true

                # Stub for command 'id'.
                function id
                {
                    throw '{0}: StubNotImplemented' -f $MyInvocation.MyCommand
                }

                Mock -CommandName id -MockWith {
                    return 0
                }
            }
        }

        AfterAll {
            $inModuleScopeParameters = @{
                PreviousIsMacOS = $previousIsMacOS
            }

            InModuleScope -Parameters $inModuleScopeParameters -ScriptBlock {
                $script:IsMacOS = $PreviousIsMacOS
            }
        }

        It 'Should not throw an exception' {
            { Assert-ElevatedUser } | Should -Not -Throw
        }
    }
}
