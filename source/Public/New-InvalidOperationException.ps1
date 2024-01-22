<#
    .SYNOPSIS
        Creates and throws or returns an invalid operation exception.

    .DESCRIPTION
        Creates and throws or returns an invalid operation exception.

    .OUTPUTS
        None. If the PassThru parameter is not specified the command throws an error record.
        System.Management.Automation.ErrorRecord. If the PassThru parameter is specified the command returns an error record.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.

    .PARAMETER PassThru
        If specified, returns the error record instead of throwing it.

    .EXAMPLE
        try
        {
            Start-Process @startProcessArguments
        }
        catch
        {
            New-InvalidOperationException -Message 'My error message' -ErrorRecord $_
        }

        Creates and throws an invalid operation exception with the message 'My error message'
        and includes the exception that caused this terminating error.

    .EXAMPLE
        $errorRecord = New-InvalidOperationException -Message 'My error message' -PassThru

        Creates and returns an invalid operation exception with the message 'My error message'.
    #>
function New-InvalidOperationException
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    if ($null -eq $ErrorRecord)
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
            -ArgumentList @($Message)
    }
    else
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $invalidOperationException.ToString(),
            'MachineStateIncorrect',
            'InvalidOperation',
            $null
        )
    }

    $errorRecordToReturn = New-Object @newObjectParameters

    if ($PassThru.IsPresent)
    {
        return $invalidOperationException
    }
    else
    {
        throw $errorRecordToReturn
    }
}
