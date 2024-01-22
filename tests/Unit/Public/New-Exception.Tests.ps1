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

Describe 'New-Exception' {
    Context 'When calling with Message parameter only' {
        It 'Should return the correct exception' {
            $mockMessage = 'Test exception message'
            $result = New-Exception -Message $mockMessage
            $result | Should -BeOfType System.Exception
            $result.Message | Should -Be $mockMessage
        }
    }

    Context 'When calling with both the Message and ErrorRecord parameter' {
        It 'Should return the correct exception' {
            $mockMessage = 'Test exception message'
            $mockInnerExceptionMessage = 'Test inner exception message'

            $mockInnerException = New-Object -TypeName System.Exception -ArgumentList $mockInnerExceptionMessage
            $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
                -ArgumentList $mockInnerException, $null, 'NotSpecified', $null

            $result = New-Exception -Message $mockMessage -ErrorRecord $mockErrorRecord

            $result | Should -BeOfType System.Exception
            $result.Message | Should -Be $mockMessage
            $result.InnerException.Message | Should -Be $mockInnerExceptionMessage
        }
    }
}
