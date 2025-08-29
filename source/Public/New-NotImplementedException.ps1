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
        $notImplementedException = [System.NotImplementedException]::new($Message)
    }
    else
    {
        $notImplementedException = [System.NotImplementedException]::new($Message, $ErrorRecord.Exception)
    }

    if ($PassThru.IsPresent)
    {
        return $notImplementedException
    }
    else
    {
        throw (New-ErrorRecord -Exception $notImplementedException.ToString() -ErrorId 'MachineStateIncorrect' -ErrorCategory 'NotImplemented')
    }
}
