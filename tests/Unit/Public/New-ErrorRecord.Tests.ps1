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

Describe 'New-ErrorRecord' {
    Context 'ErrorRecord parameter set' {
        It 'creates a new ErrorRecord based on an existing one and an exception' {
            $existingErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Management.Automation.ParentContainsErrorRecordException]::new('Existing error'),
                'ExistingErrorId',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
            $newException = [System.Exception]::new('New error')
            $newErrorRecord = New-ErrorRecord -ErrorRecord $existingErrorRecord -Exception $newException

            $newErrorRecord.Exception.Message | Should -Be 'New error'
            $newErrorRecord.FullyQualifiedErrorId | Should -Be 'ExistingErrorId'
            $newErrorRecord.CategoryInfo.Category | Should -Be 'InvalidOperation'
        }
    }

    Context 'Exception parameter set' {
        It 'creates a new ErrorRecord based on an exception, an error category, a target object, and an error ID' {
            $exception = [System.Exception]::new('An error occurred.')
            $targetObject = New-Object -TypeName PSObject
            $errorRecord = New-ErrorRecord -Exception $exception -ErrorCategory 'InvalidOperation' -TargetObject $targetObject -ErrorId 'MyErrorId'

            $errorRecord.Exception.Message | Should -Be 'An error occurred.'
            $errorRecord.FullyQualifiedErrorId | Should -Be 'MyErrorId'
            $errorRecord.CategoryInfo.Category | Should -Be 'InvalidOperation'
            $errorRecord.TargetObject | Should -Be $targetObject
        }
    }
}
