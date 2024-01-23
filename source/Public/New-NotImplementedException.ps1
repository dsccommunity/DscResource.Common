<#
    .SYNOPSIS
        Creates and throws or returns an not implemented exception.

    .DESCRIPTION
        Creates and throws or returns an not implemented exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.

    .PARAMETER PassThru
        If specified, returns the error record instead of throwing it.

    .OUTPUTS
        None
        System.NotImplementedException

    .EXAMPLE
        if ($notImplementedFeature)
        {
            New-NotImplementedException -Message 'This feature is not implemented yet'
        }

        Creates and throws an not implemented exception with the message 'This feature
        is not implemented yet'.

    .EXAMPLE
        $errorRecord = New-NotImplementedException -Message 'This feature is not implemented yet' -PassThru

        Creates and returns an not implemented exception with the message 'This feature
        is not implemented yet'.
#>
function New-NotImplementedException
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    [OutputType([System.NotImplementedException])]
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
        $notImplementedException = New-Object -TypeName 'System.NotImplementedException' `
            -ArgumentList @($Message)
    }
    else
    {
        $notImplementedException = New-Object -TypeName 'System.NotImplementedException' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParameters = @{
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @(
            $notImplementedException.ToString(),
            'MachineStateIncorrect',
            'NotImplemented',
            $null
        )
    }

    $errorRecord = New-Object @newObjectParameters

    if ($PassThru.IsPresent)
    {
        return $invalidOperationException
    }
    else
    {
        throw $errorRecord
    }
}
