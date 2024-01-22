<#
    .SYNOPSIS
        Creates and returns an exception.

    .DESCRIPTION
        Creates and returns an exception.

    .OUTPUTS
        None

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error.

    .OUTPUTS
        System.Management.Automation.ErrorRecord

    .EXAMPLE
        $errorRecord = New-Exception -Message 'An error occurred'

        Creates and returns an exception with the message 'An error occurred'.

    .EXAMPLE
        try
        {
            Get-ChildItem -Path $path -ErrorAction 'Stop'
        }
        catch
        {
            $exception = New-Exception -Message 'Could not get files' -ErrorRecord $_
        }

        Returns an exception with the message 'Could not get files' and includes
        the exception that caused this terminating error.

#>
function New-Exception
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

    if ($null -eq $ErrorRecord)
    {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message)
    }
    else
    {
        $exception = New-Object -TypeName 'System.Exception' `
            -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    return $exception
}
