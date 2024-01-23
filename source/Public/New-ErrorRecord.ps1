<#
    .SYNOPSIS
        Creates a new ErrorRecord.

    .DESCRIPTION
        The New-ErrorRecord function creates a new ErrorRecord with the specified parameters.

    .PARAMETER ErrorRecord
        Specifies an existing ErrorRecord.

    .PARAMETER Exception
        Specifies the exception that caused the error.

        If an error record is passed to parameter ErrorRecord and if the wrapped exception
        in the error record contains a `[System.Management.Automation.ParentContainsErrorRecordException]`,
        the new ErrorRecord should have this exception as its Exception instead.

    .PARAMETER ErrorCategory
        Specifies the category of the error.

    .PARAMETER TargetObject
        Specifies the object that was being manipulated when the error occurred.

    .PARAMETER ErrorId
        Specifies a string that uniquely identifies the error.

    .EXAMPLE
        $ex = New-Exception -Message 'An error occurred.'
        $errorRecord = New-ErrorRecord -Exception $ex -ErrorCategory 'InvalidOperation'

        This example creates a new ErrorRecord with the specified parameters. Passing
        'InvalidOperation' which is one available value of the enum `[System.Management.Automation.ErrorCategory]`.

    .EXAMPLE
        $ex = New-Exception -Message 'An error occurred.'
        $errorRecord = New-ErrorRecord -Exception $ex -ErrorCategory 'InvalidOperation' -TargetObject $myObject

        This example creates a new ErrorRecord with the specified parameters. TargetObject
        is set to the object that was being manipulated when the error occurred.

    .EXAMPLE
        $ex = New-Exception -Message 'An error occurred.'
        $errorRecord = New-ErrorRecord -Exception $ex -ErrorCategory 'InvalidOperation' -ErrorId 'MyErrorId'

        This example creates a new ErrorRecord with the specified parameters. Passing
        ErrorId that will be set as the FullyQualifiedErrorId in the error record.

    .EXAMPLE
        $existingErrorRecord = [System.Management.Automation.ErrorRecord]::new(
            [System.Management.Automation.ParentContainsErrorRecordException]::new('Existing error'),
            'ExistingErrorId',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
        $newException = [System.Exception]::new('New error')
        $newErrorRecord = New-ErrorRecord -ErrorRecord $existingErrorRecord -Exception $newException
        $newErrorRecord.Exception.Message

        This example first creates an emulated ErrorRecord that contain a `ParentContainsErrorRecordException`
        which will be replaced by the new exception passed to New-ErrorRecord. The
        result of `$newErrorRecord.Exception.Message` will be 'New error'.

    .INPUTS
        System.Management.Automation.ErrorRecord, System.Exception, System.Management.Automation.ErrorCategory, System.Object, System.String

    .OUTPUTS
        System.Management.Automation.ErrorRecord

    .NOTES
        The function supports two parameter sets: 'ErrorRecord' and 'Exception'.
        If the 'ErrorRecord' parameter set is used, the function creates a new ErrorRecord based on an existing one and an exception.
        If the 'Exception' parameter set is used, the function creates a new ErrorRecord based on an exception, an error category, a target object, and an error ID.
#>
function New-ErrorRecord
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'The command does not change state.')]
    [CmdletBinding(DefaultParameterSetName = 'Exception')]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'ErrorRecord')]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord,

        [Parameter(Mandatory = $true, ParameterSetName = 'ErrorRecord')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Exception')]
        [System.Exception]
        $Exception,

        [Parameter(Mandatory = $true, ParameterSetName = 'Exception')]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory,

        [Parameter(ParameterSetName = 'Exception')]
        [System.Object]
        $TargetObject = $null,

        [Parameter(ParameterSetName = 'Exception')]
        [System.String]
        $ErrorId = $null
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'ErrorRecord'
        {
            $errorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList @(
                $ErrorRecord,
                $Exception
            )

            break
        }

        'Exception'
        {
            $errorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList @(
                $Exception,
                $ErrorId,
                $ErrorCategory,
                $TargetObject
            )

            break
        }
    }

    return $errorRecord
}
