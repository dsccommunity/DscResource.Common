<#
    .SYNOPSIS
        Creates and throws or returns an invalid argument exception.

    .DESCRIPTION
        Creates and throws or returns an invalid argument exception.

    .PARAMETER Message
        The message explaining why this error is being thrown.

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown.

    .PARAMETER PassThru
        If specified, returns the error record instead of throwing it.

    .OUTPUTS
        None
        System.ArgumentException

    .EXAMPLE
        New-ArgumentException -ArgumentName 'Action' -Message 'My error message'

        Creates and throws an invalid argument exception for (parameter) 'Action'
        with the message 'My error message'.

    .EXAMPLE
        $errorRecord = New-ArgumentException -ArgumentName 'Action' -Message 'My error message' -PassThru

        Creates an invalid argument exception for (parameter) 'Action'
        with the message 'My error message' and returns the exception.
#>

function New-ArgumentException
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    [Alias('New-InvalidArgumentException')]
    [OutputType([System.ArgumentException])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ArgumentName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )

    $argumentException = [System.ArgumentException]::new($Message, $ArgumentName)

    if ($PassThru.IsPresent)
    {
        return $argumentException
    }
    else
    {
        $PSCmdlet.ThrowTerminatingError((New-ErrorRecord -Exception $argumentException -ErrorId $ArgumentName -ErrorCategory 'InvalidArgument'))
    }
}
