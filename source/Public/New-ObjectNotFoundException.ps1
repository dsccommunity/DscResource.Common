<#
    .SYNOPSIS
        Creates and throws an object not found exception.

    .DESCRIPTION
        Creates and throws an object not found exception.

    .OUTPUTS
        None

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.

    .OUTPUTS
        None

    .EXAMPLE
        try
        {
            Get-ChildItem -Path $path
        }
        catch
        {
            New-ObjectNotFoundException -Message 'Could not get files' -ErrorRecord $_
        }

        Creates and throws an object not found exception with the message 'Could not
        get files' and includes the exception that caused this terminating error.
#>
function New-ObjectNotFoundException
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
        $ErrorRecord
    )

    $exception = New-Exception @PSBoundParameters

    throw (New-ErrorRecord -Exception $exception.ToString() -ErrorId 'MachineStateIncorrect' -ErrorCategory 'ObjectNotFound')
}
